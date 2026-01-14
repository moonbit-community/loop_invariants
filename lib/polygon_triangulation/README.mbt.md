# Polygon Triangulation (Minimum Weight)

## Overview

Find the **minimum weight triangulation** of a convex polygon, where weight
is defined as the sum of triangle perimeters (using squared edge lengths
to stay in integers).

- **Time**: O(n³)
- **Space**: O(n²)
- **Key Feature**: Optimal triangulation via interval DP

## The Key Insight

```
Problem: Triangulate a convex n-gon into n-2 triangles

Any triangulation works, but which minimizes total weight?

Interval DP insight:
  - Consider the polygon edge (i, j)
  - Every triangulation must have exactly one triangle with edge (i, j)
  - That triangle has form (i, k, j) for some i < k < j
  - Recursively triangulate (i..k) and (k..j)

dp[i][j] = min cost to triangulate polygon from vertex i to j
         = min_{i<k<j} (dp[i][k] + dp[k][j] + cost(triangle i,k,j))

Base case: dp[i][i+1] = 0 (an edge, no triangulation needed)
```

## Visual: Interval DP Structure

```
Polygon vertices: 0, 1, 2, 3, 4 (pentagon)

     1
    / \
   /   \
  0-----2
   \   /
    \ /
  4--3

Triangulate (0, 4):
  Choose k ∈ {1, 2, 3} as the apex of triangle with edge (0, 4)

  k=1: Triangle (0,1,4) + triangulate (0,1) + triangulate (1,4)
       = cost(0,1,4) + 0 + dp[1][4]

  k=2: Triangle (0,2,4) + triangulate (0,2) + triangulate (2,4)
       = cost(0,2,4) + dp[0][2] + dp[2][4]

  k=3: Triangle (0,3,4) + triangulate (0,3) + triangulate (3,4)
       = cost(0,3,4) + dp[0][3] + 0

dp[0][4] = min of all these options
```

## Algorithm

```
min_weight_triangulation(points):
  n = length(points)
  if n < 3: return None

  // dp[i][j] = min cost to triangulate from vertex i to j
  dp = 2D array of size n×n, initialized to 0

  // Fill DP table for increasing chain lengths
  for len = 2 to n-1:           // Length of chain (number of edges)
    for i = 0 to n-len-1:       // Start vertex
      j = i + len               // End vertex
      dp[i][j] = ∞

      for k = i+1 to j-1:       // Try each intermediate vertex
        cost = dp[i][k] + dp[k][j] + triangle_cost(i, k, j)
        dp[i][j] = min(dp[i][j], cost)

  return dp[0][n-1]
```

## Example Usage

```mbt check
///|
test "triangulation square" {
  let points : Array[@polygon_triangulation.Point] = [
    @polygon_triangulation.Point::{ x: 0L, y: 0L },
    @polygon_triangulation.Point::{ x: 1L, y: 0L },
    @polygon_triangulation.Point::{ x: 1L, y: 1L },
    @polygon_triangulation.Point::{ x: 0L, y: 1L },
  ]
  inspect(
    @polygon_triangulation.min_weight_triangulation(points).unwrap(),
    content="8",
  )
}
```

## Walkthrough: Square Triangulation

```
Square: (0,0), (1,0), (1,1), (0,1)
Vertices: 0, 1, 2, 3

Edge squared lengths:
  0→1: 1, 1→2: 1, 2→3: 1, 3→0: 1 (sides)
  0→2: 2, 1→3: 2 (diagonals)

Two possible triangulations:
  Option A: (0,1,2) + (0,2,3)
    Triangle (0,1,2): edges 1+1+2 = 4
    Triangle (0,2,3): edges 2+1+1 = 4
    Total: 8

  Option B: (0,1,3) + (1,2,3)
    Triangle (0,1,3): edges 1+2+1 = 4
    Triangle (1,2,3): edges 1+1+2 = 4
    Total: 8

Both have same cost! Result: 8 ✓
```

## DP Table Construction

```
For a pentagon (n=5), we fill the table:

      j→  0   1   2   3   4
    i↓
    0     0   0   c   ?   ?     c = cost(0,1,2)
    1         0   0   c   ?
    2             0   0   c
    3                 0   0
    4                     0

Fill order: len=2 first (triangles), then len=3, len=4

len=2:
  dp[0][2] = dp[0][1] + dp[1][2] + cost(0,1,2)
           = 0 + 0 + cost(0,1,2)
  dp[1][3] = 0 + 0 + cost(1,2,3)
  dp[2][4] = 0 + 0 + cost(2,3,4)

len=3:
  dp[0][3] = min(
    dp[0][1] + dp[1][3] + cost(0,1,3),  // k=1
    dp[0][2] + dp[2][3] + cost(0,2,3)   // k=2
  )

len=4:
  dp[0][4] = min over k ∈ {1,2,3} of (dp[0][k] + dp[k][4] + cost(0,k,4))
```

## Triangle Cost Functions

```
Common cost definitions:

1. Perimeter (sum of edge lengths):
   cost(i,j,k) = |p_i - p_j| + |p_j - p_k| + |p_k - p_i|

2. Squared perimeter (used here, avoids sqrt):
   cost(i,j,k) = |p_i - p_j|² + |p_j - p_k|² + |p_k - p_i|²

3. Area:
   cost(i,j,k) = |(p_j - p_i) × (p_k - p_i)| / 2

4. Maximum edge:
   cost(i,j,k) = max(|p_i - p_j|, |p_j - p_k|, |p_k - p_i|)

Different cost functions lead to different optimal triangulations.
```

## Common Applications

### 1. Computer Graphics
```
Triangulate polygons for rendering.
Minimize "skinny" triangles for better shading.
```

### 2. Mesh Generation
```
Create triangular meshes for FEM analysis.
Quality depends on triangle shape.
```

### 3. Computational Geometry
```
Preprocessing step for polygon algorithms.
Many operations simpler on triangulated polygons.
```

### 4. Game Development
```
Triangulate terrain and collision shapes.
Efficient rendering and physics.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Build DP table | O(n³) | O(n²) states, O(n) transitions |
| Space | O(n²) | Store DP table |
| Triangle cost | O(1) | Per triangle |

## Why O(n³)?

```
Number of subproblems: O(n²)
  - All (i, j) pairs where i < j

Work per subproblem: O(n)
  - Try all k between i and j

Total: O(n²) × O(n) = O(n³)
```

## Minimum Weight Triangulation of General Polygons

```
For convex polygons: O(n³) by this DP

For simple (non-convex) polygons:
  - Much harder!
  - NP-hard in general
  - Heuristics or approximation algorithms used

For point sets (Delaunay triangulation):
  - Different problem: triangulate a point set
  - Delaunay maximizes minimum angle
  - O(n log n) algorithms exist
```

## Implementation Notes

- Polygon must be convex and in CCW (or CW) order
- Use squared distances to avoid floating point
- DP table indices correspond to vertex indices
- Base case: adjacent vertices (no triangulation needed)
- Result is dp[0][n-1] for the full polygon

## Related Problems

```
1. Optimal BST: Similar interval DP structure
2. Matrix chain multiplication: Same recurrence pattern
3. Ear clipping: O(n²) any triangulation (not optimal)
4. Delaunay triangulation: Optimizes different criterion
```

