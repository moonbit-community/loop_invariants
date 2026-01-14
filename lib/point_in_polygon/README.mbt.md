# Point in Polygon

## Overview

Determine if a point lies **Inside**, **Outside**, or on the **Boundary** of a
polygon using the **ray casting** algorithm.

- **Time**: O(n)
- **Space**: O(1)
- **Key Feature**: Handles all edge cases including collinear points

## The Key Insight

```
Problem: Is point P inside polygon?

Ray casting insight:
  Cast a horizontal ray from P to infinity (rightward).
  Count how many edges the ray crosses.

  Odd crossings → Inside
  Even crossings → Outside

Why it works:
  - Start outside (at infinity)
  - Each edge crossing toggles inside/outside
  - End up with correct classification!

Special cases:
  - Point exactly on edge → Boundary
  - Ray passes through vertex → Count carefully (use half-open intervals)
```

## Visual: Ray Casting

```
               ╱╲
              ╱  ╲
             ╱    ╲
    P1 ●────╱──────╲────► ∞    (1 crossing → Inside)
           ╱        ╲
          ╱    P2 ●──╲────► ∞  (0 crossings → Outside, wait...)
         ╱            ╲
        ╱──────────────╲
       ╱                ╲

Actually P2 example:
         ●
        ╱╲
       ╱  ╲
      ╱    ╲
     ╱      ╲
    ╱   P2 ●─╲────► ∞   (1 crossing → Inside)
   ╱          ╲
  ╱────────────╲

Edge cases:
  ●────●────●
        ↑
    Point on edge → Boundary

  Ray through vertex:
       ●
      ╱╲
     ●  ●←─── Count as 1 crossing (not 2!)
```

## Algorithm

```
point_in_polygon(polygon, point):
  n = length(polygon)
  crossings = 0

  for i = 0 to n-1:
    j = (i + 1) % n
    p1, p2 = polygon[i], polygon[j]

    // Check if point is on this edge
    if point_on_segment(point, p1, p2):
      return Boundary

    // Check if horizontal ray from point crosses this edge
    // Use half-open interval [p1.y, p2.y) to avoid double-counting vertices
    if ray_crosses_edge(point, p1, p2):
      crossings++

  return if crossings % 2 == 1 then Inside else Outside

ray_crosses_edge(point, p1, p2):
  // Edge must straddle the horizontal line through point
  // (one endpoint above, one below or on the line)
  if not ((p1.y <= point.y < p2.y) or (p2.y <= point.y < p1.y)):
    return false

  // Compute x-coordinate where edge crosses the horizontal line
  // x = p1.x + (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
  // Ray crosses if this x is to the right of point.x
  return point.x < x_intersection
```

## Example Usage

```mbt check
///|
test "point in polygon square" {
  let poly : Array[@point_in_polygon.Point] = [
    @point_in_polygon.Point::{ x: 0L, y: 0L },
    @point_in_polygon.Point::{ x: 4L, y: 0L },
    @point_in_polygon.Point::{ x: 4L, y: 4L },
    @point_in_polygon.Point::{ x: 0L, y: 4L },
  ]
  inspect(
    @point_in_polygon.point_in_polygon(poly, @point_in_polygon.Point::{
      x: 2L,
      y: 2L,
    }),
    content="Inside",
  )
  inspect(
    @point_in_polygon.point_in_polygon(poly, @point_in_polygon.Point::{
      x: 5L,
      y: 2L,
    }),
    content="Outside",
  )
}
```

## Algorithm Walkthrough

```
Square: (0,0), (4,0), (4,4), (0,4)
Query point: (2, 2)

Ray from (2,2) to the right: y = 2

Edge (0,0)→(4,0): y range [0,0], doesn't straddle y=2
Edge (4,0)→(4,4): y range [0,4], straddles y=2
  x-intersection = 4 (where edge crosses y=2)
  4 > 2? Yes, ray crosses this edge. crossings = 1

Edge (4,4)→(0,4): y range [4,4], doesn't straddle y=2
Edge (0,4)→(0,0): y range [0,4], straddles y=2
  x-intersection = 0 (where edge crosses y=2)
  0 > 2? No, ray doesn't cross this edge

crossings = 1 (odd) → Inside ✓
```

## Handling Edge Cases

```
1. Point on vertex:
   Check if point equals any polygon vertex.
   Return Boundary.

2. Point on edge:
   Check collinearity and range.
   Return Boundary.

3. Ray through vertex:
   Use half-open interval [y1, y2) to count each vertex once.
   This avoids double-counting when ray passes exactly through a vertex.

4. Horizontal edges:
   These don't affect crossing count (ray is horizontal too).
   But check if point lies on them (Boundary case).
```

## Common Applications

### 1. Geographic Information Systems
```
Is a GPS coordinate inside a city boundary?
Map queries, geofencing, location services.
```

### 2. Computer Graphics
```
Click detection: Is mouse click inside a shape?
Collision detection in 2D games.
```

### 3. CAD/CAM
```
Determine if a point is inside a design region.
Path planning for CNC machines.
```

### 4. Game Development
```
Hit testing for irregular shapes.
AI navigation mesh queries.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Point in Polygon | O(n) | Check each edge once |
| Space | O(1) | Only need counters |

## Point in Polygon Variants

| Method | Time | Preprocessing |
|--------|------|---------------|
| Ray Casting | O(n) | None |
| Winding Number | O(n) | None |
| Trapezoidal Map | O(log n) | O(n log n) |
| Grid-based | O(1) average | O(n) |

**Choose Ray Casting when**: Simple implementation needed, few queries per polygon.

## Winding Number Alternative

```
Winding number method:
  - Compute how many times polygon winds around point
  - Handles self-intersecting polygons correctly
  - Same O(n) complexity

winding_number = Σ (signed angle change for each edge)

Non-zero winding → Inside
Zero winding → Outside
```

## Implementation Notes

- Use integer arithmetic when possible (avoid floating-point edge cases)
- Be careful with horizontal edges
- Half-open intervals prevent vertex double-counting
- Test thoroughly with edge cases (point on vertex, on edge, near edge)
- Consider numerical precision for near-boundary points

## Edge Case Testing

```
Important test cases:
1. Point inside convex polygon
2. Point inside concave polygon
3. Point outside polygon
4. Point on edge (horizontal, vertical, diagonal)
5. Point on vertex
6. Point on extension of edge (but outside polygon)
7. Ray passes through exactly one vertex
8. Ray passes through two vertices
```

