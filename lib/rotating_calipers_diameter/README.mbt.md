# Rotating Calipers Diameter

## Overview

The **diameter** of a convex polygon is the maximum distance between any two of
its vertices. Rotating calipers finds this in linear time by tracking antipodal
pairs.

- **Time**: O(n)
- **Space**: O(1)
- **Output**: Pair of vertices at maximum distance

## The Key Insight

```
Naive approach: Check all O(n²) vertex pairs → too slow

Rotating calipers insight:
  - For each edge, there's exactly ONE farthest vertex (antipodal point)
  - As we rotate around the polygon, this farthest vertex only moves forward
  - We can track it with a single pointer!

This monotonicity gives us O(n) time.
```

## Understanding Antipodal Points

```
A convex polygon with parallel tangent lines at antipodal points:

       .---.
      /     \
   A *       * B    ← A and B are antipodal
    /         \        (parallel tangents)
   /           \
  *-------------*

For edge e, the antipodal vertex is the one that maximizes
the perpendicular distance (or area of triangle).
```

## Visual: The Rotating Calipers Method

```
Imagine two parallel lines (calipers) touching the polygon:

Step 1: Start with horizontal calipers
    ═══════════════════════   ← top caliper
           .---.
          /     \
         *       *
        /         \
    ═══*═══════════*═══════   ← bottom caliper
       ^           ^
    vertex i    vertex j (antipodal)

Step 2: Rotate calipers to align with next edge
    The calipers rotate together, maintaining parallel lines
    The antipodal vertex j either stays or moves forward

Step 3: Track maximum distance as we rotate
    diameter = max distance between touching vertices
```

## Algorithm Walkthrough

```
Polygon: Square with vertices (0,0), (2,0), (2,2), (0,2)

     3=(0,2)──────2=(2,2)
        │            │
        │            │
        │            │
     0=(0,0)──────1=(2,0)

Process each edge, track antipodal vertex j:

Edge 0→1 (bottom edge):
  j = 2 (farthest from this edge)
  Distance: 0→2 = √8, 1→2 = √4
  Current max: √8

Edge 1→2 (right edge):
  j moves? Area(1,2,3) vs Area(1,2,2)
  j = 3 (farthest from right edge)
  Distance: 1→3 = √8, 2→3 = √4
  Current max: √8

Edge 2→3 (top edge):
  j = 0 (farthest from top edge)
  Distance: 2→0 = √8, 3→0 = √4
  Current max: √8

Edge 3→0 (left edge):
  j = 1 (farthest from left edge)
  Distance: 3→1 = √8, 0→1 = √4
  Current max: √8

Result: diameter² = 8 (diagonal distance)
```

## Why the Antipodal Vertex Only Moves Forward

```
Key insight: Cross product determines "farthest"

For edge (i, i+1), vertex j is antipodal if:
  Area(i, i+1, j) ≥ Area(i, i+1, j+1)

As i increases (we rotate clockwise around polygon):
  - The perpendicular direction from edge rotates
  - The farthest vertex in that direction only moves forward
  - Never need to go backward!

Total pointer movements: i moves n times, j moves at most n times
→ O(n) total operations
```

## Visual: Why It's Called "Rotating Calipers"

```
The algorithm simulates rotating a physical caliper around the shape:

     │     │            ╲     ╲           ─────
     │     │             ╲     ╲             ───────
     *─────*              *─────*              *─────*
    /       \            /       \            /       \
   *         *          *         *          *         *
    ╲       ╱            ╲       ╱            ╲       ╱
     *─────*              *─────*              *─────*
     │     │               ╱   ╱
     │     │              ╱   ╱

   Step 1: Vertical     Step 2: Tilted      Step 3: Horizontal

As we rotate, we track:
1. Which vertices touch the calipers
2. Distance between them
3. Maximum distance seen so far
```

## API

- `convex_diameter(points)` returns `{ i, j, dist2 }`.
- `dist2` is the squared distance to avoid floating point.

## Example Usage

```mbt check
///|
test "diameter square" {
  let points : Array[@rotating_calipers_diameter.Point] = [
    @rotating_calipers_diameter.Point::{ x: 0L, y: 0L },
    @rotating_calipers_diameter.Point::{ x: 2L, y: 0L },
    @rotating_calipers_diameter.Point::{ x: 2L, y: 2L },
    @rotating_calipers_diameter.Point::{ x: 0L, y: 2L },
  ]
  let result = @rotating_calipers_diameter.convex_diameter(points).unwrap()
  inspect(result.dist2, content="8")
}
```

## More Examples

```mbt check
///|
test "diameter triangle" {
  // Equilateral-ish triangle
  let points : Array[@rotating_calipers_diameter.Point] = [
    @rotating_calipers_diameter.Point::{ x: 0L, y: 0L },
    @rotating_calipers_diameter.Point::{ x: 4L, y: 0L },
    @rotating_calipers_diameter.Point::{ x: 2L, y: 3L },
  ]
  let result = @rotating_calipers_diameter.convex_diameter(points).unwrap()
  // Diameter is the longest edge: either 0→1 (length 4) or others
  // 0→1: 16, 1→2: 4+9=13, 0→2: 4+9=13
  inspect(result.dist2, content="16")
}
```

## Common Applications

### 1. Smallest Enclosing Circle
```
The diameter gives a lower bound on the circle radius.
Diameter endpoints are often on the circle boundary.
```

### 2. Minimum Bounding Box
```
Rotating calipers can find the minimum area bounding rectangle.
Track 4 parallel support lines instead of 2.
```

### 3. Furthest Pair of Points
```
Given n points, find the pair with maximum distance.
1. Compute convex hull: O(n log n)
2. Run rotating calipers on hull: O(h) where h = hull size
Total: O(n log n)
```

### 4. Bridge Finding
```
Find the "bridge" connecting two convex hulls during merge.
Used in divide-and-conquer convex hull algorithms.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Single diameter query | O(n) |
| With convex hull from points | O(n log n) |
| Building convex hull dominates | O(n log n) |

## Rotating Calipers vs Brute Force

| Method | Time | When to Use |
|--------|------|-------------|
| **Rotating Calipers** | O(n) | Convex polygon |
| Brute Force | O(n²) | Any point set, small n |
| With Convex Hull | O(n log n) | General point set |

## Requirements

- The input polygon must be **convex** and in **counter‑clockwise** order.
- No duplicate consecutive vertices.

## Implementation Notes

- Use cross product to determine which vertex is "farther" from an edge
- Compare areas (or 2× areas) to avoid division
- Use squared distances to avoid floating-point square roots
- Handle degenerate cases: collinear points, triangles

