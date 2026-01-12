# Convex Hull

## Overview

The **Convex Hull** of a set of points is the smallest convex polygon containing
all points. Think of stretching a rubber band around pins on a board.

- **Time**: O(n log n) for most algorithms
- **Space**: O(n)

## Visual Intuition

```
Input points:           Convex Hull:
    *                       *
  *   *                   /   \
    *                    /  *  \
  *     *              *       *
      *                 \  *  /
    *                    \   /
                          *

Points inside are NOT on the hull.
Hull vertices form a convex polygon.
```

## The Cross Product Test

The key operation: determine if three points make a left turn, right turn, or are collinear.

```
Cross product of vectors OA and OB:
  cross(O, A, B) = (A.x - O.x)(B.y - O.y) - (A.y - O.y)(B.x - O.x)

      B                    A
     /                      \
    O ─── A                O ─── B

  cross > 0              cross < 0            cross = 0
  (left turn)            (right turn)         (collinear)
  counterclockwise       clockwise
```

## Monotone Chain Algorithm (Andrew's)

The most practical algorithm: build lower and upper hulls separately.

### Step 1: Sort Points
```
Sort by x-coordinate (then y for ties):

Before: (3,1) (1,2) (2,3) (0,0) (3,3) (2,1)
After:  (0,0) (1,2) (2,1) (2,3) (3,1) (3,3)
```

### Step 2: Build Lower Hull (Left to Right)
```
Process points left to right.
Maintain convex chain by removing right turns.

Stack: []
Add (0,0): [(0,0)]
Add (1,2): [(0,0), (1,2)]
Add (2,1): cross((0,0), (1,2), (2,1)) < 0? Yes, right turn!
           Pop (1,2)
           [(0,0), (2,1)]
Add (2,3): [(0,0), (2,1), (2,3)]
Add (3,1): cross((2,1), (2,3), (3,1)) < 0? Yes, right turn!
           Pop (2,3)
           cross((0,0), (2,1), (3,1)) < 0? No
           [(0,0), (2,1), (3,1)]
Add (3,3): [(0,0), (2,1), (3,1), (3,3)]

Lower hull: (0,0) → (2,1) → (3,1) → (3,3)
```

### Step 3: Build Upper Hull (Right to Left)
```
Process points right to left.
Same logic: remove right turns.

Upper hull: (3,3) → (2,3) → (1,2) → (0,0)
```

### Step 4: Combine
```
Concatenate, removing duplicate endpoints:

Final hull: (0,0) → (2,1) → (3,1) → (3,3) → (2,3) → (1,2) → (back to start)
```

## Other Algorithms

### Graham Scan
```
1. Find lowest point P (pivot)
2. Sort other points by polar angle from P
3. Process sorted points, maintaining convex stack

Good for: When you need counterclockwise ordering from specific point
```

### Jarvis March (Gift Wrapping)
```
1. Start from leftmost point
2. Find point making smallest counterclockwise angle
3. Repeat until back to start

Time: O(nh) where h = hull size
Good for: When hull has few points (h << n)
```

## Example Usage

```mbt check
///|
test "convex hull example" {
  let pts : Array[@convex_hull.Point] = [
    { x: 0, y: 0 },
    { x: 2, y: 0 },
    { x: 2, y: 2 },
    { x: 0, y: 2 },
    { x: 1, y: 1 }, // Interior point
  ]
  let hull = @convex_hull.convex_hull_monotone(pts)
  inspect(hull.length(), content="4") // Square has 4 corners
}
```

## Common Applications

### 1. Collision Detection
```
Game objects: Use convex hull for fast collision tests.
Two convex shapes don't collide if a separating axis exists.
```

### 2. Smallest Enclosing Structures
```
Smallest enclosing circle/rectangle often has
vertices on the convex hull.
```

### 3. Farthest Pair (Diameter)
```
The two farthest points are always on the convex hull.
Use rotating calipers: O(n) after hull computation.

        A ─────────────── B
       / \               /
      /   \             /
     C─────D───────────E

Diameter = max distance between antipodal pairs
```

### 4. Computational Geometry Preprocessing
```
Many algorithms work faster on convex hulls:
- Point location: O(log n) with binary search
- Line intersection: O(log n)
- Area computation: O(n) shoelace formula
```

## Helper Operations

### Polygon Area (Shoelace Formula)
```
Area = (1/2) |Σ (x[i] * y[i+1] - x[i+1] * y[i])|

For hull [(0,0), (4,0), (4,4), (0,4)]:
Area = (1/2) |0*0 - 4*0 + 4*4 - 4*0 + 4*4 - 0*4 + 0*0 - 0*4|
     = (1/2) |0 + 16 + 16 + 0| = 16
```

### Point in Hull Test
```
For convex polygon: Check if point is on left side of all edges.
Time: O(n) naive, O(log n) with binary search
```

## Complexity Analysis

| Algorithm | Time | Space | Best For |
|-----------|------|-------|----------|
| Monotone Chain | O(n log n) | O(n) | General use |
| Graham Scan | O(n log n) | O(n) | CCW ordering |
| Jarvis March | O(nh) | O(h) | Small hulls |
| QuickHull | O(n log n)* | O(n) | Random points |

*O(n²) worst case

## Special Cases

```
Collinear points:       All same point:      Two points:
    * * * * *                *                  *     *

Hull: 2 endpoints      Hull: 1 point        Hull: 2 points
(degenerate line)
```

## Implementation Notes

- Handle collinear points consistently (include or exclude?)
- Watch for integer overflow in cross product
- Consider using Int64 for coordinates
- Degenerate cases: 0, 1, or 2 points

