# Line Segment Intersection

## Overview

**Line segment intersection** determines whether two line segments intersect,
including handling collinear and endpoint cases. Uses cross-product orientation
tests for robust geometric computation.

- **Time**: O(1)
- **Space**: O(1)
- **Key Feature**: Handles all edge cases correctly

## The Key Insight

```
Problem: Do segments (a,b) and (c,d) intersect?

Geometric insight:
  Two segments intersect if and only if:
  1. Points c,d are on OPPOSITE sides of line ab, AND
  2. Points a,b are on OPPOSITE sides of line cd

  "Opposite sides" means orientations have different signs.

Orientation via cross product:
  cross(a,b,c) = (b-a) × (c-a)
               = (bx-ax)(cy-ay) - (by-ay)(cx-ax)

  > 0: c is LEFT of line a→b (counter-clockwise)
  = 0: c is ON line a→b (collinear)
  < 0: c is RIGHT of line a→b (clockwise)

Special case: Collinear segments
  When cross products are zero, check bounding box overlap.
```

## Visual: Orientation Test

```
                    c
                   /
                  /  cross(a,b,c) > 0
                 /   (c is LEFT of a→b)
    a ─────────► b
                 \
                  \  cross(a,b,d) < 0
                   \ (d is RIGHT of a→b)
                    d

c and d on OPPOSITE sides → they straddle line ab
```

## Visual: Intersection Cases

```
Case 1: Proper crossing
        c
        │
    a───┼───b     cross(a,b,c) and cross(a,b,d) have opposite signs
        │         cross(c,d,a) and cross(c,d,b) have opposite signs
        d         → INTERSECT ✓

Case 2: T-intersection (endpoint touch)
        c
        │
    a───┴───b     cross(a,b,c) = 0 (c on line ab)
                  c is between a and b
                  → INTERSECT ✓

Case 3: No intersection
    a───────b
                  All orientation tests same sign
        c───d     → NO INTERSECT

Case 4: Collinear overlap
    a───────b
          c───────d   Both segments on same line
                      Check if ranges [a,b] and [c,d] overlap
                      → INTERSECT ✓

Case 5: Collinear no overlap
    a───b     c───d   Both on same line, but disjoint
                      → NO INTERSECT
```

## The Algorithm

```
segments_intersect(a, b, c, d):
  // Compute orientations
  o1 = sign(cross(a, b, c))
  o2 = sign(cross(a, b, d))
  o3 = sign(cross(c, d, a))
  o4 = sign(cross(c, d, b))

  // General case: opposite orientations
  if o1 != o2 and o3 != o4:
    return true

  // Collinear cases: check if point lies on segment
  if o1 == 0 and on_segment(a, b, c): return true
  if o2 == 0 and on_segment(a, b, d): return true
  if o3 == 0 and on_segment(c, d, a): return true
  if o4 == 0 and on_segment(c, d, b): return true

  return false

on_segment(p, q, r):
  // Check if r lies within bounding box of segment pq
  return min(p.x, q.x) <= r.x <= max(p.x, q.x) and
         min(p.y, q.y) <= r.y <= max(p.y, q.y)

cross(a, b, c):
  return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
```

## Example Usage

```mbt check
///|
test "segment intersection crossing" {
  let a = @line_segment_intersection.Point::{ x: 0L, y: 0L }
  let b = @line_segment_intersection.Point::{ x: 4L, y: 4L }
  let c = @line_segment_intersection.Point::{ x: 0L, y: 4L }
  let d = @line_segment_intersection.Point::{ x: 4L, y: 0L }
  inspect(
    @line_segment_intersection.segments_intersect(a, b, c, d),
    content="true",
  )
}
```

```mbt check
///|
test "segment intersection touch" {
  let a = @line_segment_intersection.Point::{ x: 0L, y: 0L }
  let b = @line_segment_intersection.Point::{ x: 2L, y: 2L }
  let c = @line_segment_intersection.Point::{ x: 2L, y: 2L }
  let d = @line_segment_intersection.Point::{ x: 3L, y: 0L }
  inspect(
    @line_segment_intersection.segments_intersect(a, b, c, d),
    content="true",
  )
}
```

```mbt check
///|
test "segment intersection disjoint" {
  let a = @line_segment_intersection.Point::{ x: 0L, y: 0L }
  let b = @line_segment_intersection.Point::{ x: 1L, y: 1L }
  let c = @line_segment_intersection.Point::{ x: 2L, y: 2L }
  let d = @line_segment_intersection.Point::{ x: 3L, y: 3L }
  inspect(
    @line_segment_intersection.segments_intersect(a, b, c, d),
    content="false",
  )
}
```

## Algorithm Walkthrough

```
Example: Do (0,0)-(4,4) and (0,4)-(4,0) intersect?

Segment 1: a=(0,0), b=(4,4)
Segment 2: c=(0,4), d=(4,0)

Step 1: Compute orientations

cross(a,b,c) = (4-0)(4-0) - (4-0)(0-0)
             = 4*4 - 4*0 = 16 > 0
o1 = +1 (c is LEFT of line ab)

cross(a,b,d) = (4-0)(0-0) - (4-0)(4-0)
             = 4*0 - 4*4 = -16 < 0
o2 = -1 (d is RIGHT of line ab)

cross(c,d,a) = (4-0)(0-4) - (0-4)(0-0)
             = 4*(-4) - (-4)*0 = -16 < 0
o3 = -1 (a is RIGHT of line cd)

cross(c,d,b) = (4-0)(4-4) - (0-4)(4-0)
             = 4*0 - (-4)*4 = 16 > 0
o4 = +1 (b is LEFT of line cd)

Step 2: Check intersection condition
o1 != o2? (+1 != -1) YES
o3 != o4? (-1 != +1) YES

Both conditions satisfied → INTERSECT ✓

The segments cross each other (X shape).
```

## Why It Works

```
Theorem: Two segments intersect iff each segment
         "straddles" the line containing the other.

"Straddles" means endpoints are on opposite sides.

Proof sketch:
  If (a,b) straddles line cd AND (c,d) straddles line ab:
    - The segments must cross somewhere in the middle

  If one doesn't straddle:
    - Both endpoints on same side of other segment
    - No crossing possible (except collinear case)

Collinear case:
  All cross products are zero.
  Segments intersect iff their 1D projections overlap.
  Checked via bounding box test.
```

## Common Applications

### 1. Computational Geometry
```
Foundation for polygon intersection,
convex hull, and visibility algorithms.
```

### 2. Collision Detection
```
Check if two edges of polygons intersect.
Used in physics engines and games.
```

### 3. Geographic Information Systems
```
Road network intersections.
Boundary overlap detection.
```

### 4. Computer Graphics
```
Line clipping algorithms.
Ray-segment intersection tests.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Cross product | O(1) | 2 multiplications, 1 subtraction |
| Orientation tests | O(1) | 4 cross products |
| Bounding box check | O(1) | 4 comparisons |
| **Total** | **O(1)** | Constant time |

## Integer vs Floating Point

```
Integer coordinates (this package):
  - Exact computation, no precision issues
  - Cross product: Int64 to avoid overflow
  - Recommended for discrete geometry

Floating point coordinates:
  - Need epsilon tolerance for comparisons
  - cross(a,b,c) ≈ 0 means "nearly collinear"
  - More care needed for robustness
```

## Edge Cases Summary

| Case | Handling |
|------|----------|
| Proper crossing | Opposite orientations |
| T-intersection | Zero orientation + on segment |
| Shared endpoint | Zero orientation + on segment |
| Collinear overlap | All zero + bounding box |
| Collinear disjoint | All zero + no overlap |
| Parallel disjoint | Same sign orientations |

## Implementation Notes

- Use Int64 for cross product to avoid overflow
- Sign function: return -1, 0, or +1
- Bounding box check must be inclusive (≤ not <)
- Order of orientation checks doesn't matter
- Both "straddle" conditions needed for general case

## Related Algorithms

```
Finding intersection point:
  After confirming intersection exists,
  solve parametric line equations.

Bentley-Ottmann:
  Find ALL intersections among n segments.
  O((n + k) log n) where k = number of intersections.

Segment intersection counting:
  Count pairs of intersecting segments.
  Various algorithms depending on setting.
```

