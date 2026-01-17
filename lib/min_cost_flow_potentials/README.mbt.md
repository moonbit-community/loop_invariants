# Min-Cost Max-Flow with Potentials (Dijkstra)

## 1. Problem statement

Given a directed graph where each edge has:

- **capacity** (how much flow can pass)
- **cost per unit** (price to send 1 unit)

Find the **maximum flow** from source `s` to sink `t`, and among all maximum
flows choose the one with **minimum total cost**.

## 2. Why potentials are needed

In the residual graph, every forward edge has cost `+w`, and every reverse edge
has cost `-w`. Those negative costs break Dijkstra.

Potentials fix this by reweighting edges:

```
reduced_cost(u,v) = cost(u,v) + pi[u] - pi[v]
```

If the potential `pi[v]` is a shortest-path distance from `s`, then every
reduced cost is **non-negative**, and Dijkstra works.

## 3. Residual graph diagram

```
Original edge: u -> v with cap=c, cost=w, flow=f

Residual graph:
  u -> v with cap=(c-f), cost=+w
  v -> u with cap=f,   cost=-w
```

The negative reverse edge allows canceling expensive flow later.

## 4. Algorithm (successive shortest paths)

```
flow = 0, cost = 0
pi[v] = 0 for all v

while Dijkstra finds a path in reduced costs:
  path_cost = dist[t] + pi[t] - pi[s]
  bottleneck = min residual capacity on path
  augment flow by bottleneck
  cost += bottleneck * path_cost
  for each reachable vertex v:
    pi[v] += dist[v]

return (flow, cost)
```

Key invariant:

```
reduced_cost(u,v) >= 0 for all residual edges
```

## 5. Worked example (same as test)

Edges:

```
0 -> 1 (cap 2, cost 1)
0 -> 2 (cap 1, cost 2)
1 -> 2 (cap 1, cost 1)
1 -> 3 (cap 1, cost 3)
2 -> 3 (cap 2, cost 1)
```

Picture:

```
        1        3
    0 ----> 1 ------> 3
    |        \       ^
 2  |         \1     |1
    v          v     |
    2 ---------> 3
         1
```

Shortest augmenting paths by cost:

- 0->1->2->3 cost = 1+1+1 = 3 (push 1)
- 0->1->3 cost = 1+3 = 4 (push 1)
- 0->2->3 cost = 2+1 = 3 (push 1)

Total: flow 3, cost 10.

## 6. Public API

From `pkg.generated.mbti`:

- `MinCostFlowPotentials::new(n)`
- `add_edge(u, v, cap, cost)`
- `compute(source, sink)` -> `(flow, cost)`
- `compute_with_limit(source, sink, max_flow)` -> `(flow, cost)`

## 7. Example usage

```mbt check
///|
test "min-cost flow basics" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(4)
  mcf.add_edge(0, 1, 2L, 1L)
  mcf.add_edge(0, 2, 1L, 2L)
  mcf.add_edge(1, 2, 1L, 1L)
  mcf.add_edge(1, 3, 1L, 3L)
  mcf.add_edge(2, 3, 2L, 1L)
  let (flow, cost) = mcf.compute(0, 3)
  inspect(flow, content="3")
  inspect(cost, content="10")
}
```

```mbt check
///|
test "min-cost flow limited" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(3)
  mcf.add_edge(0, 1, 1L, 1L)
  mcf.add_edge(1, 2, 1L, 1L)
  let (flow, cost) = mcf.compute_with_limit(0, 2, 1L)
  inspect(flow, content="1")
  inspect(cost, content="2")
}
```

```mbt check
///|
test "min-cost flow no path" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(2)
  let (flow, cost) = mcf.compute(0, 1)
  inspect(flow, content="0")
  inspect(cost, content="0")
}
```

## 8. Complexity

Let `F` be the max flow value:

```
Dijkstra per path: O(E log V)
Total:            O(F * E log V)
```

This is much faster than SPFA for large graphs when all reduced costs are
non-negative.

## 9. When can you use this version?

This implementation assumes **non-negative original edge costs**, so with
`pi = 0` the reduced costs are already non-negative.

If your graph has negative costs, you should either:

- Run a Bellman-Ford/SPFA pass to initialize potentials, or
- Use the SPFA-based MCMF package (`lib/mcmf`).

## 10. Common pitfalls

- Forgetting reverse edges -> residual graph is wrong
- Overflow in `cost += flow * path_cost` for large flows
- Using this without non-negative costs (Dijkstra may fail)
- Not resetting distance/parent arrays each iteration

## 11. Summary

Potentials + Dijkstra is the fast, standard MCMF implementation when costs are
non-negative. It keeps the residual graph valid, ensures shortest paths are
found quickly, and produces the cheapest possible maximum flow.
