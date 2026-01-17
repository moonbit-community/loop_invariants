# Half-Plane Intersection (Convex Feasible Region)

## Overview

A **half-plane** is a line plus one chosen side. The intersection of multiple
half-planes is always a **convex polygon** (or empty/unbounded). This package
implements the classic O(n log n) deque algorithm to compute that polygon.

- **Input**: half-planes as directed lines (keep points to the left).
- **Output**: the convex polygon in counter-clockwise order, or `None` if
  the region is empty or unbounded.
- **Time**: O(n log n) for sorting + linear deque processing.

## How a Half-Plane Is Represented

We store a half-plane by a point `p` and a direction vector `v`:

```
Line is: p + t * v
Feasible side: points to the LEFT of v (looking from p)
```

That means a point `q` is inside if:

```
cross(v, q - p) >= 0
```

### Visual Intuition

```
Directed line A -> B

      (left side is feasible)

          feasible
            ^
            |
xxxxxxxxxxxx|xxxxxxxxxxxx  (boundary line)
            |    direction
            A ----------> B
            |
          infeasible
```

## From Inequalities to Half-Planes

Many constraints are written as `ax + by + c >= 0`.

To create a matching half-plane:

1) Pick any point `p` on the line `ax + by + c = 0`
2) Choose a direction vector `v` so that the left side satisfies the inequality

Example: `x >= 0` (keep the right half-plane)

```
Line: x = 0
Pick p = (0, 0)
Direction v = (0, 1) (upwards)
Left side of (0,1) is x >= 0
```

## The Key Insight (Why a Deque Works)

Sort half-planes by their direction angle. When processed in that order,
any new half-plane can only invalidate the **front** or **back** of the
current candidate intersection, never the middle. That lets us maintain a
deque of active half-planes in linear time.

## Algorithm Outline (Readable Pseudocode)

```
1) Sort by angle
2) Remove redundant parallel lines (keep the most restrictive)
3) Process in angle order with a deque:
   - pop back while the last intersection is outside the new half-plane
   - pop front while the first intersection is outside the new half-plane
   - push new half-plane
4) Final trim: reconcile front/back
5) If fewer than 3 lines remain -> empty or unbounded
6) Intersect consecutive lines to get polygon vertices
```

## Worked Example 1: Unit Square

Half-planes:

```
H1: y >= 0   (0,0)->(1,0)
H2: x <= 1   (1,0)->(1,1)
H3: y <= 1   (1,1)->(0,1)
H4: x >= 0   (0,1)->(0,0)
```

Diagram:

```
      H3 (y <= 1)
   <----------------
   |                |
   |   feasible     |
H4 |    region      | H2
   |   [0,1]^2      |
   |                |
   ----------------->
        H1 (y >= 0)
```

After sorting by angle, the deque keeps all four lines. Intersect consecutive
pairs to get the polygon:

```
(1,0), (1,1), (0,1), (0,0)
```

## Worked Example 2: Triangle With a Bounding Box

Suppose you have only these three constraints:

```
y >= 0
x + y <= 2
x >= 0
```

This region is unbounded (it extends upward). The algorithm returns `None`
unless you add a bounding box, such as:

```
-1000 <= x <= 1000
-1000 <= y <= 1000
```

Now the intersection is bounded, and the true polygon appears inside the box.

## Example Usage

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

## Empty and Unbounded Cases

```
Empty:
  y >= 1
  y <= 0
  -> no feasible point

Unbounded:
  x >= 0
  y >= 0
  -> infinite quadrant (returns None)
```

To force a bounded result, add a large bounding box:

```
-1e6 <= x <= 1e6
-1e6 <= y <= 1e6
```

## Implementation Notes

- Parallel half-planes are reduced: we keep the most restrictive one.
- `EPS` is used to guard floating-point comparisons.
- Output polygon is in counter-clockwise order.
- The algorithm assumes the intersection, if non-empty, is bounded.

## Common Applications

- Linear programming feasibility (2D)
- Clipping a convex polygon by many constraints
- Visibility and shadow regions in computational geometry
- Safe operating envelopes for robotic motion

## Complexity

| Step | Time |
|------|------|
| Sort by angle | O(n log n) |
| Deque processing | O(n) |
| Build polygon | O(n) |
