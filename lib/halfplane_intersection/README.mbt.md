# Half-Plane Intersection (Convex Feasible Region)

## Overview

A **half-plane** is a directed line plus the half of the plane to its left. The
intersection of finitely many half-planes is always a **convex polygon** (or
empty, or unbounded). This package implements the classic O(n log n) deque
algorithm to compute that polygon.

- **Input**: half-planes as directed lines (feasible region is to the left).
- **Output**: the convex polygon in counterclockwise order, or `None` if the
  region is empty or unbounded.
- **Time**: O(n log n) for sorting + O(n) deque processing.
- **Space**: O(n).

---

## 1. What Is a Half-Plane?

A **half-plane** divides the 2D plane into two regions along a boundary line.
We represent the boundary as a directed line `p -> p+v`; the feasible region is
the half that lies to the **left** of the direction vector `v`.

```
          feasible (left of v)
               |
    v          |
    -------->  |  <-- boundary line through p
               |
       infeasible (right of v)
```

A point `q` is inside half-plane `(p, v)` when:

```
cross(v, q - p) >= 0
```

where `cross(a, b) = a.x * b.y - a.y * b.x`.

---

## 2. Constructing Half-Planes from Inequalities

### Representation

```
HalfPlane {
  p : Point   -- any point on the boundary line
  v : Point   -- direction of the boundary; left side is feasible
}
```

Use `HalfPlane::from_points(a, b)` when you know two boundary points:

```
  a ----------> b
  |
  | left side = feasible
  |
```

### Common constraints

```
Constraint        Two boundary points       Explanation
---------         -------------------       -----------
y >= 0            (0,0) -> (1,0)            east direction; north is left
x <= 1            (1,0) -> (1,1)            north direction; west is left
y <= 1            (1,1) -> (0,1)            west direction; south is left
x >= 0            (0,1) -> (0,0)            south direction; east is left
```

Algebraically: for a constraint `ax + by + c >= 0`, pick any point `p` where
equality holds, then set `v = (-b, a)` (rotate the normal 90 degrees CCW).

---

## 3. The Intersection of Multiple Half-Planes

The intersection of `n` half-planes is a convex polygon (possibly empty or
unbounded). The diagram below shows four half-planes forming the unit square.

```
        ^ y
        |
   1 ---+---*-----------*--- H3: y <= 1  (<-- direction)
        |   |           |
        |   |  feasible |
   H4   |   |  region   |   H2
  x>=0  |   |  [0,1]^2  |   x<=1
        |   |           |
   0 ---+---*-----------*---> x
        0   0           1
             H1: y >= 0  (--> direction)
```

Each arrow shows the direction of the boundary line; the feasible region is
always to the arrow's left.

---

## 4. Algorithm: Incremental Angle Sweep with a Deque

### Key Insight

Sort half-planes by the angle of their direction vectors. Because the sort
produces a counterclockwise sweep, any new half-plane can only cut off the
**front** or **back** of the currently active deque -- never the middle. This
monotonicity property reduces the otherwise O(n^2) update to O(n) amortised.

### Angle Ordering

Direction vectors are split into two halves by the x-axis:

```
half = 0  (upper semicircle, including rightward x-axis):
           y > 0
           OR (y == 0 AND x >= 0)

half = 1  (lower semicircle):
           y < 0
           OR (y == 0 AND x < 0)
```

Within the same half, vectors are sorted by cross product so they appear in
counterclockwise (CCW) order:

```
         angle = 90 deg
              |
              |   half 0
              |  (CCW sweep)
   180 -------+------- 0 deg
              |  (CCW sweep)
              |   half 1
              |
         angle = 270 deg
```

### Deduplication of Parallel Lines

Among half-planes with the same direction (parallel boundaries), only the most
restrictive one matters. Given two parallel half-planes A and B with the same
direction:

```
  A ------>        (boundary A)
  feasible A

  B ------>        (boundary B, further "inward")
  feasible B  <-- stricter; feasible B is a subset of feasible A
```

We keep only B, because the intersection must satisfy the stricter constraint.

### Deque Processing

The deque holds the active candidate half-planes in angle order. At each step
we hold the invariant:

```
  deque[head .. end]:  a valid partial intersection
  pts[i] = line_intersection(deque[i], deque[i+1]):  the "witness" vertices
```

For each new half-plane `L`:

```
Step A -- pop back:

  deque: [ ... | A | B ]    new: L
                     ^
  intersection(A, B) outside L?
  -> pop B; repeat
  -> push L when safe

  Why correct: B can no longer reach the feasible region of L, so it cannot
  appear on the final polygon boundary.

Step B -- pop front:

  deque: [ A | B | ... ]    new: L
           ^
  intersection(A, B) outside L?
  -> advance head past A; repeat
  -> head is stable when the front witness is inside L
```

### Final Trim

After processing all half-planes, wrap around: the last half-plane may
invalidate the back or front of the deque via the circular closure:

```
  deque: [ H0 | H1 | H2 | ... | Hk ]

  trim back:   remove Hk while intersection(H_{k-1}, Hk) outside H0
  trim front:  remove H0 while intersection(H0, H1) outside Hk
```

### Full Algorithm in Pseudocode

```
halfplane_intersection(planes):
  sort planes by angle (half-based CCW order)
  unique = deduplicate parallel planes (keep most restrictive)

  deque = []
  head  = 0
  for each line L in unique:
    -- pop back
    while len(deque) - head >= 2 and
          intersection(deque[-2], deque[-1]) not inside L:
      pop deque back
    -- pop front
    while len(deque) - head >= 2 and
          intersection(deque[head], deque[head+1]) not inside L:
      head += 1
    push L onto deque back

  -- final back trim
  while len(deque) - head >= 3 and
        intersection(deque[-2], deque[-1]) not inside deque[head]:
    pop deque back

  -- final front trim
  while len(deque) - head >= 3 and
        intersection(deque[head], deque[head+1]) not inside deque[-1]:
    head += 1

  m = len(deque) - head
  if m < 3: return None

  return [ intersection(deque[head+i], deque[head+(i+1)%m])
           for i in 0..m ]
```

---

## 5. Worked Example: Unit Square

Half-planes (CCW direction, left = inside):

```
H1: (0,0) -> (1,0)   direction east,  feasible above  (y >= 0)
H2: (1,0) -> (1,1)   direction north, feasible left   (x <= 1)
H3: (1,1) -> (0,1)   direction west,  feasible below  (y <= 1)
H4: (0,1) -> (0,0)   direction south, feasible right  (x >= 0)
```

Angle sweep order (CCW from 0 deg): H1 (0), H2 (90), H3 (180), H4 (270).

Deque evolution:

```
Process H1: deque = [H1]
Process H2: deque = [H1, H2]
Process H3: intersection(H1,H2) = (1,0), inside H3? yes
            deque = [H1, H2, H3]
Process H4: intersection(H2,H3) = (1,1), inside H4? yes
            intersection(H1,H2) = (1,0), inside H4? yes
            deque = [H1, H2, H3, H4]
Final trim: intersection(H3,H4) = (0,1), inside H1? yes  -> no trim needed
            intersection(H1,H2) = (1,0), inside H4? yes  -> no trim needed
```

Polygon vertices (intersecting consecutive pairs cyclically):

```
intersection(H1,H2) = (1,0)
intersection(H2,H3) = (1,1)
intersection(H3,H4) = (0,1)
intersection(H4,H1) = (0,0)

Result: [(1,0), (1,1), (0,1), (0,0)]  -- 4 vertices, CCW
```

Diagram:

```
        ^ y
        |
   1 ---+---(0,1)-------(1,1)
        |    |           |
        |    |   [0,1]^2 |
        |    |           |
   0 ---+---(0,0)-------(1,0)--> x
        0    0           1
```

---

## 6. Worked Example: Triangle

Three half-planes forming a triangle with vertices (0,0), (2,0), (1,2):

```
H1: (0,0) -> (2,0)   direction east,       feasible above  (y >= 0)
H2: (2,0) -> (1,2)   direction NW (-1,+2), feasible left of that edge
H3: (1,2) -> (0,0)   direction SW (-1,-2), feasible left of that edge
```

```
        ^ y
        |
   2 ---+------*(1,2)
        |     / \
        |    /   \
        |   /     \
   0 ---+--*(0,0)--*(2,0)--> x
        0   0      2
```

The algorithm finds 3 surviving lines and produces 3 vertices.

---

## 7. Empty and Unbounded Cases

### Empty intersection

When two half-planes have opposite directions and their boundaries do not
overlap, no point satisfies both:

```
Constraint 1:  y >= 1   boundary at y=1, feasible above
Constraint 2:  y <= 0   boundary at y=0, feasible below

      y=1  --------  (feasible: y >= 1)
           ~~~~~~~~  gap
      y=0  --------  (feasible: y <= 0)

No point is in both regions -> return None.
```

### Unbounded intersection

With only two or three half-planes pointing generally the same way, the
intersection extends infinitely in at least one direction:

```
Only  x >= 0  and  y >= 0:

        ^ y
        |  feasible (infinite quadrant)
        |
   -----+-----------> x
        0

Returns None (fewer than 3 deque entries survive).
```

### Adding a bounding box

Append four half-planes forming a large box before calling the algorithm:

```
let big = 1.0e6
// bottom: y >= -big
HalfPlane::from_points({ x: -big, y: -big }, { x:  big, y: -big })
// right:  x <= +big
HalfPlane::from_points({ x:  big, y: -big }, { x:  big, y:  big })
// top:    y <= +big
HalfPlane::from_points({ x:  big, y:  big }, { x: -big, y:  big })
// left:   x >= -big
HalfPlane::from_points({ x: -big, y:  big }, { x: -big, y: -big })
```

---

## 8. Polygon Construction from Surviving Lines

After the deque trim, `m` half-plane boundary lines survive. The polygon vertex
between line `i` and line `(i+1) % m` is found by solving the linear system:

```
line i:    p_i + t * v_i  for some t
line i+1:  p_{i+1} + s * v_{i+1}  for some s

Intersection:
  u   = p_{i+1} - p_i
  den = cross(v_i, v_{i+1})
  t   = cross(u, v_{i+1}) / den
  vertex = p_i + t * v_i
```

The `m` vertices are returned in counterclockwise order, matching the CCW sort
of the boundary line directions.

---

## 9. Example Usage

```mbt check
///|
test "halfplane square" {
  let planes : Array[@halfplane_intersection.HalfPlane] = [
    @halfplane_intersection.HalfPlane::from_points({ x: 0.0, y: 0.0 }, {
      x: 1.0,
      y: 0.0,
    }),
    @halfplane_intersection.HalfPlane::from_points({ x: 1.0, y: 0.0 }, {
      x: 1.0,
      y: 1.0,
    }),
    @halfplane_intersection.HalfPlane::from_points({ x: 1.0, y: 1.0 }, {
      x: 0.0,
      y: 1.0,
    }),
    @halfplane_intersection.HalfPlane::from_points({ x: 0.0, y: 1.0 }, {
      x: 0.0,
      y: 0.0,
    }),
  ]
  let poly = @halfplane_intersection.halfplane_intersection(planes).unwrap()
  inspect(poly.length(), content="4")
}
```

```mbt check
///|
test "halfplane triangle" {
  let planes : Array[@halfplane_intersection.HalfPlane] = [
    @halfplane_intersection.HalfPlane::from_points({ x: 0.0, y: 0.0 }, {
      x: 2.0,
      y: 0.0,
    }),
    @halfplane_intersection.HalfPlane::from_points({ x: 2.0, y: 0.0 }, {
      x: 1.0,
      y: 2.0,
    }),
    @halfplane_intersection.HalfPlane::from_points({ x: 1.0, y: 2.0 }, {
      x: 0.0,
      y: 0.0,
    }),
  ]
  let poly = @halfplane_intersection.halfplane_intersection(planes).unwrap()
  inspect(poly.length(), content="3")
}
```

---

## 10. Deque Invariants (Proof Annotations)

The implementation carries four `proof_invariant` annotations in the loop
bodies. Each asserts `head >= 0 && head <= deque.length()`:

```
Pass          What gets removed          Why safe to remove
----          ------------------         ------------------
pop back      deque.back                 Its witness is outside the new line
pop front     deque[head]                Its witness is outside the new line
final back    deque.back (wrap check)    Violates the front half-plane (H0)
final front   deque[head] (wrap check)   Violates the back half-plane (Hm-1)
```

The invariant `head <= deque.length()` ensures the virtual front pointer never
overtakes the physical array end, so all index expressions `deque[head]` and
`deque[head+1]` are guarded by the condition `deque.length() - head >= 2`.

---

## 11. Common Applications

- **Linear programming (2D feasibility)** -- check if a system of linear
  constraints has a solution, and find an extreme point.
- **Polygon clipping** -- clip a convex polygon against a set of half-plane
  constraints (each edge of the clip region gives one half-plane).
- **Visibility regions** -- compute the area visible from a point past a set
  of blocking line segments.
- **Safe operating envelopes** -- find the set of states satisfying multiple
  linear safety constraints simultaneously.
- **Competitive programming** -- canonical O(n log n) solution for problems
  asking for the area or existence of a convex feasible region.

---

## 12. Complexity Summary

| Step | Time | Notes |
|------|------|-------|
| Sort by angle | O(n log n) | Dominant cost |
| Deduplicate parallel lines | O(n) | Single pass after sort |
| Deque main loop | O(n) | Each line enters/leaves deque at most once |
| Final trim | O(n) | At most n additional pops total |
| Build polygon vertices | O(n) | One intersection per surviving line |
| **Total** | **O(n log n)** | |

---

## 13. Implementation Notes

- `EPS = 1e-12` guards all floating-point comparisons.
- Parallel half-planes are reduced to the most restrictive before the deque
  phase.
- The output polygon is in **counterclockwise** order.
- The algorithm requires the intersection, if non-empty, to be **bounded**;
  unbounded intersections return `None`.
- `Point` serves double duty as a geometric point and as a 2D direction vector.
