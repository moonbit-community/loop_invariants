# Challenge: Bitmask DP (Traveling Salesman)

This challenge solves the Traveling Salesman Problem (TSP) for **small n**
using dynamic programming over subsets (bitmasks).

TSP: visit every node exactly once and return to the start with minimum cost.
The exact solution is exponential, but for n <= ~20 this DP is practical.

## Problem statement

Given a complete weighted graph with `n` nodes and distance matrix `dist`, find

```
min cost cycle starting at 0, visiting all nodes once, and returning to 0
```

If no Hamiltonian cycle exists (edges are effectively missing), return -1.

## Bitmask encoding

We use an integer mask of length n to represent the visited set.
Bit i is 1 if node i is visited.

For n = 4, bits look like this:

```
bit:  3 2 1 0
node: 3 2 1 0

mask 0101 = visited {0,2}
mask 1111 = visited {0,1,2,3}
```

## DP state and meaning

```
dp[mask][u] = minimum cost to start at 0, visit exactly mask, and end at u
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
answer = min over u: dp[all][u] + dist[u][0]
```

## Diagram: one transition step

Suppose n = 4 and we are at:

```
mask = 0101 (visited {0,2})
end  = 2
```

We can add node 1 or 3:

```
add 1: new_mask = 0111, dp[0111][1] = dp[0101][2] + dist[2][1]
add 3: new_mask = 1101, dp[1101][3] = dp[0101][2] + dist[2][3]
```

## Examples

### Example 1: 4 nodes (baseline)

```mbt check
///|
test "bitmask dp tsp basic" {
  let inf = 1_000_000
  let dist : Array[Array[Int]] = [
    [0, 1, 3, 4],
    [1, 0, 2, 5],
    [3, 2, 0, 6],
    [4, 5, 6, 0],
  ]
  let best = @challenge_bitmask_dp.tsp_min_cycle(dist, inf)
  inspect(best, content="13")
}
```

One optimal tour is:

```
0 -> 1 -> 2 -> 3 -> 0
cost = 1 + 2 + 6 + 4 = 13
```

### Example 2: triangle

```mbt check
///|
test "bitmask dp tsp triangle" {
  let inf = 1_000_000
  let dist : Array[Array[Int]] = [[0, 2, 4], [2, 0, 1], [4, 1, 0]]
  let best = @challenge_bitmask_dp.tsp_min_cycle(dist, inf)
  inspect(best, content="7")
}
```

### Example 3: 5 nodes with a clear ring

We create a ring of low-cost edges and make all other edges expensive.
The optimal cycle uses the ring.

```
0 - 1 - 2 - 3 - 4 - 0
(cheap edges = 2)
(all other edges = 9)
```

```mbt check
///|
test "bitmask dp tsp ring" {
  let inf = 1_000_000
  let dist : Array[Array[Int]] = [
    [0, 2, 9, 9, 2],
    [2, 0, 2, 9, 9],
    [9, 2, 0, 2, 9],
    [9, 9, 2, 0, 2],
    [2, 9, 9, 2, 0],
  ]
  let best = @challenge_bitmask_dp.tsp_min_cycle(dist, inf)
  inspect(best, content="10")
}
```

### Example 4: no Hamiltonian cycle

Here missing edges are represented by a very large `inf` cost.
There is no way to return to the start while visiting all nodes.

```mbt check
///|
test "bitmask dp tsp unreachable" {
  let inf = 1_000_000
  let dist : Array[Array[Int]] = [
    [0, 1, inf, inf],
    [1, 0, 1, inf],
    [inf, 1, 0, 1],
    [inf, inf, 1, 0],
  ]
  let best = @challenge_bitmask_dp.tsp_min_cycle(dist, inf)
  inspect(best, content="-1")
}
```

## Complexity

- Time: O(n^2 * 2^n)
- Space: O(n * 2^n)

This is why the method is suitable only for small n.

## Practical notes and pitfalls

- Use a very large `inf` so that unreachable edges do not get chosen.
- Distances can be asymmetric; the DP still works.
- If you need the actual tour, store predecessor pointers in a second table.

## When to use it

Use bitmask DP for exact TSP when n is small (typically n <= 20) and you need
an exact answer, not an approximation.
