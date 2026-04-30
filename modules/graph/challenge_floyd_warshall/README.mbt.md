# Challenge: Floyd-Warshall

Floyd-Warshall computes **all-pairs shortest paths** in O(n^3) time using
simple dynamic programming over intermediate vertices. It works with negative
edges (but not negative cycles).

## Problem statement

Given a weighted directed graph as an adjacency matrix:

- `matrix[i][j]` is the edge weight from i to j
- use a large `inf` value if there is no edge

Compute the shortest distance between **every pair** of vertices.

## Core idea

We allow intermediate vertices step by step:

- After processing `k`, paths may use only vertices `0..k` as intermediates.
- Update:

```
dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
```

## Diagram: intermediate vertex idea

Imagine you are building a route from i to j:

```
 i ----> j        (direct edge)
 i ----> k ----> j (via k)
```

At step k, we decide if going through k is better than the current best.

## Example matrix

```
inf means "no direct edge"

matrix:
[ 0   1  10  inf ]
[ inf 0   2  inf ]
[ inf inf 0   3  ]
[ inf inf inf 0  ]
```

Shortest path 0 -> 3 becomes 0 -> 1 -> 2 -> 3 with cost 1 + 2 + 3 = 6.

## Examples

### Example 1: basic DAG-like graph

```mbt check
///|
test "floyd warshall basic" {
  let inf = 1_000_000_000
  let matrix : Array[Array[Int]] = [
    [0, 1, 10, inf],
    [inf, 0, 2, inf],
    [inf, inf, 0, 3],
    [inf, inf, inf, 0],
  ]
  let dist = @challenge_floyd_warshall.floyd_warshall(matrix, inf)
  inspect(dist[0][2], content="3")
  inspect(dist[0][3], content="6")
  inspect(dist[1][3], content="5")
}
```

### Example 2: graph with a negative edge (no negative cycle)

```mbt check
///|
test "floyd warshall negative edge" {
  let inf = 1_000_000_000
  let matrix : Array[Array[Int]] = [[0, 2, inf], [inf, 0, -4], [3, inf, 0]]
  let dist = @challenge_floyd_warshall.floyd_warshall(matrix, inf)
  inspect(dist[0][2], content="-2") // 0->1->2
  inspect(dist[2][1], content="5") // 2->0->1
}
```

### Example 3: unreachable nodes

```mbt check
///|
test "floyd warshall unreachable" {
  let inf = 1_000_000_000
  let matrix : Array[Array[Int]] = [[0, 1, inf], [inf, 0, inf], [inf, inf, 0]]
  let dist = @challenge_floyd_warshall.floyd_warshall(matrix, inf)
  inspect(dist[0][1], content="1")
  inspect(dist[0][2] > 100000000, content="true")
}
```

### Example 4: detecting a negative cycle

Floyd-Warshall itself does not prevent negative cycles, but you can **detect**
them afterward: if any `dist[i][i] < 0`, then a negative cycle is reachable
from i.

```mbt check
///|
test "floyd warshall negative cycle detection" {
  let inf = 1_000_000_000
  let matrix : Array[Array[Int]] = [[0, 1, inf], [inf, 0, -2], [-2, inf, 0]]
  let dist = @challenge_floyd_warshall.floyd_warshall(matrix, inf)
  inspect(dist[0][0] < 0, content="true")
}
```

## Complexity

- Time: O(n^3)
- Space: O(n^2)

## Practical notes and pitfalls

- Use a very large `inf` and avoid overflow when adding distances.
- Works with negative edges, but a negative cycle makes shortest paths
  undefined.
- The algorithm is simple but expensive; use it for n up to a few hundred.

## When to use it

Use Floyd-Warshall when you need **all-pairs** distances on small graphs,
especially if edge weights can be negative.
