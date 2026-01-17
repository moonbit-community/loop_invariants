# Minimum Cost Maximum Flow (MCMF)

## 1. Problem statement

You have a directed graph with **capacity** and **cost** on every edge.
You want to send as much flow as possible from source `s` to sink `t` and
**minimize the total cost** of that maximum flow.

Flow rules:

- `0 <= flow(e) <= capacity(e)`
- For every node except `s` and `t`, inflow = outflow

## 2. Why this is harder than max flow

In max flow, any augmenting path is fine. In MCMF, **the path must be cheapest**
per unit flow, otherwise the total cost is not minimal.

So the algorithm repeatedly finds a **minimum-cost augmenting path** in the
residual graph and pushes as much as possible along it.

## 3. Residual graph and negative costs

For each edge `u -> v` with capacity `c` and current flow `f`:

- Forward residual: `c - f` with cost `+w`
- Backward residual: `f` with cost `-w`

Diagram:

```
Original:  u --(cap=c, cost=w)--> v
Residual:  u --(cap=c-f, cost=+w)--> v
           v --(cap=f,   cost=-w)--> u
```

The backward edge lets you **undo** expensive flow later. This is why shortest
path must handle negative edges (SPFA is used here).

## 4. Algorithm: successive shortest augmenting paths

```
flow = 0, cost = 0
while shortest path s->t exists (by cost) in residual graph:
  bottleneck = min residual capacity on that path
  push bottleneck flow along the path
  flow += bottleneck
  cost += bottleneck * path_cost
return (flow, cost)
```

This greedy-by-cost strategy is correct for each flow value, and by repeating
it until no path exists, we get **min-cost max-flow**.

## 5. A small worked example

Graph:

```
0 -> 1 (cap 2, cost 1)
0 -> 2 (cap 1, cost 2)
1 -> 2 (cap 1, cost 1)
1 -> 3 (cap 1, cost 3)
2 -> 3 (cap 2, cost 1)
```

```
        1        3
    0 ----> 1 ------> 3
    |        \       ^
 2  |         \1     |1
    v          v     |
    2 ---------> 3
         1
```

Cheapest augmenting paths are found in cost order until no more paths exist.
The tests in this package confirm the expected flow and a reasonable cost.

## 6. Public API in this package

The public surface includes:

- `MinCostMaxFlow::new(n)`
- `add_edge(u, v, cap, cost)`
- `compute(source, sink)` -> `(flow, cost)`
- `compute_with_limit(source, sink, max_flow)` -> `(flow, cost)`
- `solve_assignment(cost_matrix)` for assignment problems

## 7. Example: single edge

```mbt check
///|
test "mcmf simple edge" {
  let mcmf = @mcmf.MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 5L, 2L)
  let (flow, cost) = mcmf.compute(0, 1)
  inspect(flow, content="5")
  inspect(cost, content="10")
}
```

## 8. Example: diamond network

```
0 -> 1 (cap 3, cost 1)
0 -> 2 (cap 3, cost 2)
1 -> 3 (cap 3, cost 1)
2 -> 3 (cap 3, cost 1)
```

```
    0
   / \
 1/   \2
 /     \
1       2
 \     /
  \1  /1
    3
```

All 6 units can pass, but the top path is cheaper:

- 3 units through 0-1-3 (cost 2 per unit)
- 3 units through 0-2-3 (cost 3 per unit)

Total cost = 3*2 + 3*3 = 15.

```mbt check
///|
test "mcmf diamond" {
  let mcmf = @mcmf.MinCostMaxFlow::new(4)
  mcmf.add_edge(0, 1, 3L, 1L)
  mcmf.add_edge(0, 2, 3L, 2L)
  mcmf.add_edge(1, 3, 3L, 1L)
  mcmf.add_edge(2, 3, 3L, 1L)
  let (flow, cost) = mcmf.compute(0, 3)
  inspect(flow, content="6")
  inspect(cost, content="15")
}
```

## 9. Example: flow limit

If you only need `k` units of flow, use `compute_with_limit`:

```mbt check
///|
test "mcmf limited flow" {
  let mcmf = @mcmf.MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 10L, 1L)
  let (flow, cost) = mcmf.compute_with_limit(0, 1, 5L)
  inspect(flow, content="5")
  inspect(cost, content="5")
}
```

## 10. Assignment problem

`solve_assignment` converts a cost matrix into a flow network and solves the
minimum cost perfect matching.

```
Workers: rows
Jobs:    columns
```

Example:

```
Costs:
  [1, 3]
  [2, 2]

Best assignment: 0->0 (1), 1->1 (2) => total = 3
```

```mbt check
///|
test "assignment example" {
  let cost : Array[Array[Int64]] = [[1L, 3L], [2L, 2L]]
  inspect(@mcmf.solve_assignment(cost), content="3")
}
```

## 11. Complexity

Let `F` be the max flow value:

```
SPFA per path:     O(V * E) worst case
Total:            O(V * E * F)
```

SPFA is usually fast in practice, and it handles negative edges from the
residual graph correctly. For faster asymptotic bounds, Dijkstra with
potentials (Johnson) is a common upgrade.

## 12. Common pitfalls

- Forgetting reverse edges (breaks residual correctness)
- Overflow in `cost += flow * dist[sink]`
- Negative cycles in residual graph (rare in standard MCMF usage)
- Not resetting `dist`/`prev` arrays before each shortest path

## 13. Summary

MCMF finds the **cheapest way** to push the **maximum amount** of flow.
This package uses the classic **successive shortest augmenting path** method
with SPFA, and exposes a simple API for building graphs and computing results.
