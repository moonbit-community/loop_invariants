# Challenge: TSP (Bitmask DP)

This challenge solves the Traveling Salesman Problem (TSP) exactly for small n
using dynamic programming over subsets.

You start at node 0, must visit every node exactly once, and return to 0 with
minimum total cost.

## Problem statement

Given a complete distance matrix `dist`:

```
ans = min cost cycle: 0 -> ... -> 0, visiting all nodes once
```

## DP state

We use bitmasks to represent visited sets:

```
dp[mask][v] = minimum cost to start at 0, visit exactly mask, and end at v
```

Initialization:

```
dp[1 << 0][0] = 0
```

Transition:

```
for each mask, for each u in mask:
  for each v not in mask:
    dp[mask | (1<<v)][v] = min(dp[mask | (1<<v)][v], dp[mask][u] + dist[u][v])
```

Closing the tour:

```
answer = min over u != 0: dp[all][u] + dist[u][0]
```

## Diagram: bit positions

For n = 4:

```
bit:  3 2 1 0
node: 3 2 1 0

mask 1011 = visited {0,1,3}
```

## Diagram: one DP layer

Suppose we are at:

```
mask = 0011 (visited {0,1})
end  = 1
```

We can extend to node 2 or 3:

```
add 2: dp[0111][2] = min(dp[0111][2], dp[0011][1] + dist[1][2])
add 3: dp[1011][3] = min(dp[1011][3], dp[0011][1] + dist[1][3])
```

## Examples

### Example 1: classic 4-node TSP

```mbt check
///|
test "tsp example" {
  let dist : Array[Array[Int]] = [
    [0, 10, 15, 20],
    [10, 0, 35, 25],
    [15, 35, 0, 30],
    [20, 25, 30, 0],
  ]
  let ans = @challenge_bitmask_tsp.tsp_min_cycle(dist)
  inspect(ans, content="80")
}
```

One optimal tour is:

```
0 -> 1 -> 3 -> 2 -> 0
cost = 10 + 25 + 30 + 15 = 80
```

### Example 2: triangle

```mbt check
///|
test "tsp triangle" {
  let dist : Array[Array[Int]] = [[0, 2, 4], [2, 0, 1], [4, 1, 0]]
  let ans = @challenge_bitmask_tsp.tsp_min_cycle(dist)
  inspect(ans, content="7")
}
```

### Example 3: 5 nodes with a clear ring

Here the ring edges are cheap, and all other edges are expensive.
The best tour is the ring.

```
0 - 1 - 2 - 3 - 4 - 0
(cheap edges = 2 or 3)
```

```mbt check
///|
test "tsp ring" {
  let dist : Array[Array[Int]] = [
    [0, 3, 8, 9, 2],
    [3, 0, 2, 8, 9],
    [8, 2, 0, 2, 8],
    [9, 8, 2, 0, 2],
    [2, 9, 8, 2, 0],
  ]
  let ans = @challenge_bitmask_tsp.tsp_min_cycle(dist)
  inspect(ans, content="11")
}
```

### Example 4: asymmetric distances

The DP works even when `dist[u][v] != dist[v][u]`.

```mbt check
///|
test "tsp asymmetric" {
  let dist : Array[Array[Int]] = [[0, 1, 10], [2, 0, 3], [4, 5, 0]]
  // Possible cycles:
  // 0->1->2->0 = 1 + 3 + 4 = 8
  // 0->2->1->0 = 10 + 5 + 2 = 17
  let ans = @challenge_bitmask_tsp.tsp_min_cycle(dist)
  inspect(ans, content="8")
}
```

## Complexity

- Time: O(n^2 * 2^n)
- Space: O(n * 2^n)

This is feasible for n <= ~20 in practice.

## Practical notes and pitfalls

- The distance matrix should be complete; missing edges can be modeled with a
  very large number.
- If missing edges exist, the answer can be extremely large (effectively INF).
- If you need the actual path, store predecessors along with `dp`.

## When to use it

Use this exact DP when n is small and you need guaranteed optimal solutions.
For large n, use heuristics or approximation algorithms.
