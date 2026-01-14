# Half-Plane Intersection

## Overview

**Half-plane intersection** computes the convex polygon formed by the intersection
of multiple half-planes. Each half-plane is defined by a directed line, keeping
all points to the **left** of the direction.

- **Time**: O(n log n)
- **Space**: O(n)
- **Key Feature**: Finds feasible region of linear constraints

## The Key Insight

```
Problem: Find region satisfying all linear constraints

Naive: Intersect half-planes one by one → O(n²)

Sorting insight:
  Sort half-planes by angle (direction).
  Process in angular order using a deque.

  Key observation:
    When processing half-plane H in sorted order,
    H can only "cut off" the front or back of current polygon.
    Never the middle! (due to convexity)

  Deque maintains active half-planes:
    - Remove from back if new line makes back intersection infeasible
    - Remove from front if new line makes front intersection infeasible
    - Finally, wrap around to trim front against back

  Each half-plane enters and exits deque at most once → O(n)
```

## Visual: Half-Plane Representation

```
Half-plane from point A to point B:

    feasible region
    (left of A→B)
          │
    xxxxxx│
    xxxxxx│
    xxxxxx│A ─────────────► B
    xxxxxx│    direction
    xxxxxx│
          │
    infeasible region
    (right of A→B)

Half-plane keeps everything to the LEFT of direction vector.
```

## Visual: Intersection Process

```
Four half-planes forming a square:

  H1: (0,0)→(1,0)  keeps y ≥ 0 (above)
  H2: (1,0)→(1,1)  keeps x ≤ 1 (left of)
  H3: (1,1)→(0,1)  keeps y ≤ 1 (below)
  H4: (0,1)→(0,0)  keeps x ≥ 0 (right of)

         H3
    ←─────────
    │         │
    │ feasible│
 H4 │ region  │ H2
    │         │
    │         │
    ─────────→
         H1

Intersection: unit square [0,1] × [0,1]
```

## The Algorithm

```
halfplane_intersection(planes):
  // Step 1: Sort by angle
  sort planes by atan2(dy, dx)

  // Step 2: Remove parallel duplicates (keep most restrictive)
  remove_parallel_duplicates()

  // Step 3: Process with deque
  deque = []

  for each plane H:
    // Remove from back while H invalidates back intersection
    while |deque| ≥ 2 and
          intersection(deque[-2], deque[-1]) is right of H:
      deque.pop_back()

    // Remove from front while H invalidates front intersection
    while |deque| ≥ 2 and
          intersection(deque[0], deque[1]) is right of H:
      deque.pop_front()

    deque.push_back(H)

  // Step 4: Wrap-around trimming
  while |deque| ≥ 3 and
        intersection(deque[-2], deque[-1]) is right of deque[0]:
    deque.pop_back()

  while |deque| ≥ 3 and
        intersection(deque[0], deque[1]) is right of deque[-1]:
    deque.pop_front()

  // Step 5: Build polygon from consecutive intersections
  if |deque| < 3:
    return None  // Empty or unbounded

  polygon = []
  for i in 0..|deque|-1:
    polygon.append(intersection(deque[i], deque[i+1]))
  polygon.append(intersection(deque[-1], deque[0]))

  return polygon
```

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

## Algorithm Walkthrough

```
Input: 4 half-planes forming a square

H1: (0,0)→(1,0), angle = 0°
H2: (1,0)→(1,1), angle = 90°
H3: (1,1)→(0,1), angle = 180°
H4: (0,1)→(0,0), angle = 270°

After sorting by angle: [H1, H2, H3, H4]

Processing:
  Add H1: deque = [H1]
  Add H2: deque = [H1, H2]
  Add H3:
    Check back: intersection(H1,H2) = (1,0), left of H3 ✓
    deque = [H1, H2, H3]
  Add H4:
    Check back: intersection(H2,H3) = (1,1), left of H4 ✓
    deque = [H1, H2, H3, H4]

Wrap-around:
  Check: intersection(H3,H4) = (0,1), left of H1 ✓
  Check: intersection(H1,H2) = (1,0), left of H4 ✓
  No trimming needed

Build polygon:
  intersection(H1,H2) = (1, 0)
  intersection(H2,H3) = (1, 1)
  intersection(H3,H4) = (0, 1)
  intersection(H4,H1) = (0, 0)

Result: [(1,0), (1,1), (0,1), (0,0)] - unit square ✓
```

## Empty and Unbounded Cases

```
Empty intersection:
  H1: y ≥ 1 (above y=1)
  H2: y ≤ 0 (below y=0)

  No point satisfies both → returns None

Unbounded intersection:
  H1: x ≥ 0
  H2: y ≥ 0

  First quadrant is unbounded → returns None
  (Only bounded regions form valid polygons)

To make bounded:
  Add "bounding box" half-planes at large distance
```

## Common Applications

### 1. Linear Programming
```
Feasible region of linear constraints.
Intersection is the set of valid solutions.
```

### 2. Voronoi Diagrams
```
Each Voronoi cell is intersection of half-planes.
Cell for site p: all points closer to p than others.
```

### 3. Visibility Problems
```
What region can see point P?
Each obstacle edge creates a blocking half-plane.
```

### 4. Robot Motion Planning
```
Configuration space obstacles.
Robot must stay in intersection of constraints.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Sort by angle | O(n log n) | Dominates complexity |
| Remove duplicates | O(n) | Linear scan |
| Deque processing | O(n) | Each plane enters/exits once |
| Build polygon | O(n) | One intersection per plane |
| **Total** | **O(n log n)** | Sorting is bottleneck |

## Requirements and Edge Cases

```
Requirements:
  - Lines must not be degenerate (zero direction)
  - Intersection must be bounded for polygon output
  - At least 3 non-parallel half-planes for bounded region

Edge cases handled:
  - Parallel lines: keep most restrictive
  - Nearly parallel: numerical stability issues
  - Unbounded region: returns None
  - Empty region: returns None
```

## Half-Plane vs Other Representations

| Representation | Use Case |
|----------------|----------|
| Point + Direction | This package |
| ax + by + c ≤ 0 | Linear programming |
| Normal vector | Physics simulations |

## Implementation Notes

- Use atan2 for correct angle computation
- Handle parallel half-planes by keeping tighter one
- Numerical precision: use epsilon comparisons
- Result polygon is in CCW order
- Deque allows efficient front/back operations

