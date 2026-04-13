# Convex Hull

The **convex hull** of a set of points is the smallest convex polygon that
contains all the points. Imagine stretching a rubber band around pins on a
board: when you let go, it snaps to the outermost pins. Those pins are the hull
vertices.

This package implements three classic algorithms and a small set of helper
operations (area, point-in-hull, diameter).

---

## 1. What is a convex hull?

```
Input points (x marks interior, * marks hull):

  y
  8 |         *
  7 |
  6 |    x
  5 |  *           *
  4 |        x
  3 |     x
  2 |       x
  1 |    *       *
  0 +------------------  x
    0  1  2  3  4  5  6

Hull vertices (in counterclockwise order):
  (1,1) -> (5,1) -> (6,5) -> (4,8) -> (1,5) -> back to (1,1)

Interior points (1,3), (2,4), (3,3), (3,6) are NOT on the hull.
```

Key facts:
- Every hull vertex is an extreme point: it cannot be written as a weighted
  average of the other points.
- The hull is the intersection of all half-planes that contain the entire set.
- Hull vertices appear in counterclockwise (CCW) order in all algorithms below.

---

## 2. The cross product (turn test)

All three algorithms depend on a single primitive: given three ordered points
O, A, B, is the turn O -> A -> B a left turn, a right turn, or straight?

```
cross(O, A, B) = (A.x - O.x) * (B.y - O.y)
               - (A.y - O.y) * (B.x - O.x)
```

```
  B              A
   \              \
    A              B
   /              /
  O              O

cross > 0        cross < 0        cross = 0
left turn        right turn       collinear
(CCW)            (CW)
```

Intuitively, `cross(O, A, B)` is twice the signed area of triangle OAB.
A positive sign means CCW orientation; negative means CW.

---

## 3. Monotone chain (Andrew's algorithm) - O(n log n)

The simplest algorithm to implement correctly. It builds two chains (lower and
upper) and concatenates them.

### Step 1: Sort the points lexicographically

```
Input:  (3,1) (1,5) (4,8) (1,1) (5,1) (6,5)

Sorted: (1,1) (1,5) (3,1) (4,8) (5,1) (6,5)
         ^^^   ^^^
         same x -> sort by y next
```

### Step 2: Build the lower hull (left to right)

Process sorted points left to right. Maintain a stack. Before pushing a new
point, pop the stack top while the last three points make a non-left turn
(cross product <= 0).

```
Sorted points: P0=(1,1)  P1=(1,5)  P2=(3,1)  P3=(4,8)  P4=(5,1)  P5=(6,5)

Stack after P0: [(1,1)]
Stack after P1: [(1,1), (1,5)]
Add P2=(3,1):
  cross((1,1), (1,5), (3,1)) = (0)(0) - (4)(2) = -8  <= 0  -> pop (1,5)
  Stack: [(1,1), (3,1)]
Add P3=(4,8):
  cross((1,1), (3,1), (4,8)) = (2)(7) - (0)(3) = 14  > 0   -> keep
  Stack: [(1,1), (3,1), (4,8)]
Add P4=(5,1):
  cross((3,1), (4,8), (5,1)) = (1)(0) - (7)(2) = -14 <= 0  -> pop (4,8)
  cross((1,1), (3,1), (5,1)) = (2)(0) - (0)(4) = 0   <= 0  -> pop (3,1)
  Stack: [(1,1), (5,1)]
Add P5=(6,5):
  cross((1,1), (5,1), (6,5)) = (4)(4) - (0)(5) = 16  > 0   -> keep
  Stack: [(1,1), (5,1), (6,5)]

Lower hull: (1,1) -> (5,1) -> (6,5)
```

Visually, the lower hull traces the bottom-right boundary:

```
  y
  8 |
  6 |                    * (6,5)
  4 |
  2 |
  0 +----(1,1)----(5,1)------ x
             lower hull
```

### Step 3: Build the upper hull (right to left)

Same rule, but process sorted points in reverse order (right to left):

```
Right-to-left: P5=(6,5)  P4=(5,1)  P3=(4,8)  P2=(3,1)  P1=(1,5)  P0=(1,1)

Starting from end of lower hull (size = 3), add P4=(5,1):
  cross((6,5), (5,1), ...) -> only one point so far, push
  ...

Upper hull: (6,5) -> (4,8) -> (1,5) -> (1,1)
```

### Step 4: Combine

```
Lower:  (1,1) -> (5,1) -> (6,5)
Upper:  (6,5) -> (4,8) -> (1,5) -> (1,1)

Combined (drop duplicated endpoints):
  (1,1) -> (5,1) -> (6,5) -> (4,8) -> (1,5)   [5 hull vertices, CCW]
```

The full hull drawn:

```
  y
  8 |             *(4,8)
  7 |           /       \
  6 |         /           *(6,5)
  5 | *(1,5)/               |
  4 |     |                 |
  3 |     |                 |
  2 |     |                 |
  1 | *(1,1)-----------*(5,1)
  0 +--------------------------------- x
      1   2   3   4   5   6
```

---

## 4. Graham scan - O(n log n)

Graham scan uses a polar-angle sort around a pivot instead of a lexicographic
sort. It is most useful when you need the result in CCW order starting from a
specific point (the bottom-most).

### Step-by-step example

```
Input: (3,1) (1,5) (4,8) (1,1) (5,1) (6,5)

Step 1 - Pick pivot = bottom-most point (leftmost on tie):
  pivot = (1,1)

Step 2 - Sort remaining points by polar angle from (1,1):
  angle of (3,1) = 0 deg    (due east)
  angle of (5,1) = 0 deg    (same direction, farther -> second)
  angle of (6,5) = ~53 deg
  angle of (4,8) = ~73 deg
  angle of (1,5) = 90 deg   (due north)

  Sorted: (5,1) (3,1) (6,5) (4,8) (1,5)
          (collinear with pivot: farthest first)

Step 3 - Graham scan with stack:
  Stack: [(1,1)]
  Push (5,1): [(1,1), (5,1)]
  Push (3,1): cross((1,1),(5,1),(3,1)) = -8 <= 0 -> pop (5,1)
              [(1,1), (3,1)]  -- wait, (3,1) is collinear and closer, skip it
              [(1,1), (5,1), (3,1)] -> implementation keeps farthest
  ...
  Final stack (CCW from pivot): [(1,1), (5,1), (6,5), (4,8), (1,5)]
```

---

## 5. Jarvis march (gift wrapping) - O(n * h)

Jarvis march is the most intuitive algorithm: it simulates wrapping a string
around the point set.

```
Step 1: Start at leftmost point L = (1,1).

                  *(4,8)
                /       \
              /           *(6,5)
  *(1,5)    /               |
     |    /                 |
     |  /                   |
     |/                     |
   *(1,1) <-- start here
              gift wrap going CCW ->
```

```
Step 2: From (1,1), find the point P such that all others are to the left of
  the ray (1,1)->P. That is: no point makes a right turn relative to (1,1)->P.
  Scan every point:
    - Try (5,1): is any point to the right of (1,1)->(5,1)? No -> candidate.
    - Check others ... (5,1) wins.

Step 3: From (5,1), repeat. Winner: (6,5).
Step 4: From (6,5), winner: (4,8).
Step 5: From (4,8), winner: (1,5).
Step 6: From (1,5), winner: (1,1) -> back to start, done.

Hull: (1,1) -> (5,1) -> (6,5) -> (4,8) -> (1,5)
```

When h (hull size) is small, Jarvis march is fast. In the worst case (all
points on the hull), it is O(n^2).

---

## 6. Quick-start usage

```mbt check
///|
test "convex hull example" {
  let pts : Array[@convex_hull.Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
    { x: 2L, y: 2L }, // Interior point - will be excluded
  ]
  let hull = @convex_hull.convex_hull(pts[:])
  inspect(hull.length(), content="4") // Square has 4 corners
}
```

---

## 7. Helper operations

### Polygon area (shoelace formula)

`polygon_area_2x` returns `2 * area` as an integer, avoiding floating point.

```
Area = (1/2) |sum over edges of (x_i * y_{i+1} - x_{i+1} * y_i)|

For square (0,0)-(4,0)-(4,4)-(0,4):
  = (1/2) |0*0 - 4*0 + 4*4 - 4*0 + 4*4 - 0*4 + 0*0 - 0*4|
  = (1/2) |0 + 16 + 16 + 0|
  = 16
```

```mbt check
///|
test "area example" {
  let square : Array[@convex_hull.Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]
  // Area = 16, so 2 * area = 32
  inspect(@convex_hull.polygon_area_2x(square), content="32")
}
```

### Point-in-hull test

Returns `1` (inside), `0` (on boundary), or `-1` (outside).

```
   (0,4) ------- (4,4)
     |       |       |
     |   in  | on    |
     |   (2,2)|  (2,0)|
     |       |       |
   (0,0) ------- (4,0)     (5,5) outside
```

```mbt check
///|
test "point in hull example" {
  let square : Array[@convex_hull.Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]
  inspect(@convex_hull.point_in_hull(square, { x: 2L, y: 2L }), content="1")
  inspect(@convex_hull.point_in_hull(square, { x: 2L, y: 0L }), content="0")
  inspect(@convex_hull.point_in_hull(square, { x: 5L, y: 5L }), content="-1")
}
```

### Diameter (rotating calipers)

`hull_diameter_squared` finds the farthest pair of hull vertices in O(n) time
using rotating calipers.

```
Rotating calipers on a square:

  (0,4) =========== (4,4)
   ||                 ||
   ||  farthest pair  ||
   ||  is a diagonal  ||
   ||  dist^2 = 32    ||
  (0,0) =========== (4,0)

For each hull edge, advance the antipodal pointer (the vertex on the
"opposite side") as long as doing so increases the distance. Because
the hull is convex, the antipodal pointer only ever moves forward,
giving O(n) total work.
```

```mbt check
///|
test "diameter example" {
  let square : Array[@convex_hull.Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]
  // Diagonal = sqrt(32), so diameter^2 = 32
  inspect(@convex_hull.hull_diameter_squared(square), content="32")
}
```

---

## 8. Degenerate inputs

```
Zero points:       One point:   Two points:   Collinear points:

  (empty)              *           *   *         * - * - * - *

Hull: []           Hull: [*]   Hull: [*,*]   Hull: [first, last]
                                             (degenerate line segment)
```

The implementation handles all of these without panicking. For two or fewer
points the input is returned as-is. For collinear inputs, `convex_hull_monotone`
returns just the two endpoints.

---

## 9. All three algorithms on the same input

```mbt check
///|
test "all algorithms same result" {
  let pts : Array[@convex_hull.Point] = [
    { x: 1L, y: 2L },
    { x: 5L, y: 1L },
    { x: 8L, y: 4L },
    { x: 6L, y: 8L },
    { x: 2L, y: 7L },
    { x: 4L, y: 4L }, // Interior
  ]
  let h1 = @convex_hull.convex_hull_monotone(pts)
  let h2 = @convex_hull.convex_hull_graham(pts)
  let h3 = @convex_hull.convex_hull_jarvis(pts)
  // All three return the same number of hull vertices
  inspect(h1.length(), content="5")
  inspect(
    h1.length() == h2.length() && h2.length() == h3.length(),
    content="true",
  )
}
```

---

## 10. Complexity summary

| Algorithm | Time | Space | Notes |
|-----------|------|-------|-------|
| Monotone chain | O(n log n) | O(n) | Simple, robust, general-purpose |
| Graham scan | O(n log n) | O(n) | CCW order from a specific pivot |
| Jarvis march | O(n * h) | O(h) | Best when hull is tiny (h << n) |

---

## 11. Common applications

- **Collision detection** - convex hulls enable fast GJK and SAT tests.
- **Farthest pair** - the two farthest points in a set are always hull vertices.
- **Minimum enclosing circle / rectangle** - derived from the hull.
- **Area / perimeter** - apply shoelace / edge-length sum to hull vertices.
- **Point location** - test inside/outside in O(log n) after hull is built.
