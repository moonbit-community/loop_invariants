# Min-Cost Max-Flow with Potentials (Dijkstra)

## 1. Problem statement

Given a directed graph where each edge has:

- **capacity** (how much flow can pass)
- **cost per unit** (price to send 1 unit)

Find the **maximum flow** from source `s` to sink `t`, and among all maximum
flows choose the one with **minimum total cost**.

Think of it as shipping goods: you want to send as much as possible, and pay
as little as possible per unit.

## 2. Flow network diagram

Below is a labeled flow network. Each edge is annotated as `cap/cost`:

```
         [cap=2, cost=1]
    0 ─────────────────────> 1
    |                        |  \
    |  [cap=1, cost=2]       |   \  [cap=1, cost=3]
    |                [1/1]   |    \
    v                        v     \
    2 <──────────────────── (1) ─> 3
         [cap=2, cost=1]               ^
    |                                  |
    └──────────────────────────────────┘
              [cap=2, cost=1]
```

More precisely:

```
         (2/1)
    0 ──────────> 1
    |  \          | \
 (1/2)  \      (1/1) \(1/3)
    |    \        |    \
    v     \       v     v
    2 <────────── *     3
       reversed       ^
    |                  |
    └──────────────────┘
          (2/1)
```

Simplified ASCII art of the five edges:

```
                  [1]         [3]
              0 ──────> 1 ──────> 3
              |         |         ^
         [2]  |    [1]  |    [1]  |
              v         v         |
              2 ─────────────────>
                     [1]
```

Edges (from, to, cap, cost):

```
  0 -> 1   cap=2  cost=1
  0 -> 2   cap=1  cost=2
  1 -> 2   cap=1  cost=1
  1 -> 3   cap=1  cost=3
  2 -> 3   cap=2  cost=1
```

## 3. Why potentials are needed

In the residual graph, every forward edge has cost `+w` and every reverse edge
has cost `-w`. Those negative costs break Dijkstra.

Potentials (also called Johnson's reweighting) fix this by reweighting edges:

```
reduced_cost(u, v) = cost(u, v) + pi[u] - pi[v]
```

If `pi[v]` is a shortest-path distance from `s` in the current residual graph,
then every reduced cost is **non-negative**, and Dijkstra works.

### Johnson's reweighting technique

Initial state: all potentials `pi[v] = 0`, all edge costs >= 0.

After the first Dijkstra, `dist[v]` gives shortest-path distances in the
original costs. Update potentials:

```
  pi'[v] = pi[v] + dist[v]
```

For the next Dijkstra iteration, the reduced cost of each residual edge is:

```
  reduced_cost(u, v) = cost(u, v) + pi[u] - pi[v]
```

Illustration of reweighting a single edge:

```
  Before update:
    u ──[cost=2]──> v      pi[u]=1, pi[v]=4
    reduced = 2 + 1 - 4 = -1   (dangerous!)

  After Dijkstra assigns dist[u]=0, dist[v]=3:
    pi'[u] = 1+0 = 1
    pi'[v] = 4+3 = 7
    reduced' = 2 + 1 - 7 = -4  ...

  Correct perspective – use dist[], not old pi, as the increment:
    pi_new[u] = 0 + 0 = 0  (dist from source)
    pi_new[v] = 0 + 3 = 3
    reduced = 2 + 0 - 3 = -1  -> pick potentials from Dijkstra distances

  Key insight: set pi[v] = dist[v] from Dijkstra in reduced-cost space.
  Then reduced_cost'(u,v) = old_reduced(u,v) + dist[u] - dist[v] >= 0
  because Dijkstra's triangle inequality: dist[v] <= dist[u] + old_reduced(u,v)
```

Concrete example with the worked graph (initial pi = 0):

```
  After first Dijkstra (path 0->1->2->3, reduced costs = original costs):
    dist = [0, 1, 2, 3]
    pi   = [0, 1, 2, 3]   <- updated to dist[]

  Edge 1->3, cost=3, reduced = 3 + pi[1] - pi[3] = 3 + 1 - 3 = 1  (>= 0, safe)
  Reverse edge 3->1, cost=-3, reduced = -3 + pi[3] - pi[1] = -3 + 3 - 1 = -1 (< 0!)
  But 3->1 has zero residual capacity after augmentation, so Dijkstra skips it.
```

The invariant is maintained because:
- Edges with positive residual capacity have non-negative reduced cost.
- Zero-capacity residual edges are skipped.

## 4. Residual graph diagram

```
Original edge: u -> v   cap=c, cost=w, current flow=f

Residual:
  u -> v   cap=(c-f), cost=+w    (forward: can push more)
  v -> u   cap=f,     cost=-w    (backward: can cancel flow)
```

The negative-cost backward edge allows rerouting expensive flow later.

Example with edge `0->1, cap=2, cost=1, flow=1`:

```
  Residual forward:  0->1  cap=1, cost=+1
  Residual backward: 1->0  cap=1, cost=-1
```

## 5. Algorithm (successive shortest paths)

```
flow = 0, cost = 0
pi[v] = 0 for all v

repeat:
  if Dijkstra on reduced costs cannot reach sink:
    break
  path_cost = dist[t] + pi[t] - pi[s]   // recover true cost
  bottleneck = min residual capacity on path
  augment flow by bottleneck along path
  cost += bottleneck * path_cost
  for each reachable vertex v:
    pi[v] += dist[v]                     // update potentials

return (flow, cost)
```

Key invariant after each potential update:

```
reduced_cost(u, v) >= 0   for all edges (u,v) with positive residual capacity
```

### Why the invariant holds

After Dijkstra in reduced costs, by the shortest-path triangle inequality:

```
  dist[v] <= dist[u] + reduced_cost(u, v)
  => reduced_cost(u, v) >= dist[v] - dist[u]
```

New potentials `pi'[v] = pi[v] + dist[v]` give:

```
  reduced_cost'(u, v) = cost(u,v) + pi'[u] - pi'[v]
                      = cost(u,v) + pi[u] - pi[v] + dist[u] - dist[v]
                      = reduced_cost(u,v) + dist[u] - dist[v]
                      >= 0
```

So the next Dijkstra run is guaranteed to be safe.

## 6. Step-by-step augmentation example

Network: same five edges as section 2.

```
  0 -> 1   cap=2  cost=1
  0 -> 2   cap=1  cost=2
  1 -> 2   cap=1  cost=1
  1 -> 3   cap=1  cost=3
  2 -> 3   cap=2  cost=1
```

Initial potentials: `pi = [0, 0, 0, 0]`

### Iteration 1

Dijkstra finds shortest paths (reduced costs = original costs):

```
  dist = [0, 1, 2, 3]
  Shortest path to sink 3: 0->1->2->3  (cost 1+1+1=3)
```

Augment along `0->1->2->3`, bottleneck = min(2,1,2) = 1:

```
  Flow state after augment:
    0->1: flow=1/2    0->2: flow=0/1
    1->2: flow=1/1    1->3: flow=0/1
    2->3: flow=1/2
  total_flow=1, total_cost=3
```

Update potentials: `pi = [0+0, 0+1, 0+2, 0+3] = [0, 1, 2, 3]`

### Iteration 2

Dijkstra finds next shortest path using reduced costs.
Edge `1->2` is saturated (residual=0), so it is skipped.

```
  Cheapest available path: 0->1->3   (original cost 1+3=4)
  dist = [0, 0, ?, 1]   (in reduced-cost space)
```

Augment along `0->1->3`, bottleneck = min(1,1) = 1:

```
  Flow state after augment:
    0->1: flow=2/2    0->2: flow=0/1
    1->2: flow=1/1    1->3: flow=1/1
    2->3: flow=1/2
  total_flow=2, total_cost=3+4=7
```

Update potentials: `pi = [0, 1, 2, 4]`

### Iteration 3

Edges `0->1`, `1->2`, `1->3` are saturated. Only path left: `0->2->3`.

```
  Path: 0->2->3   (original cost 2+1=3)
  Augment bottleneck = min(1,1) = 1
  total_flow=3, total_cost=7+3=10
```

### Result

```
  Maximum flow: 3
  Minimum cost: 10
```

The algorithm correctly selects paths in order of increasing cost.

## 7. Public API

From `pkg.generated.mbti`:

- `MinCostFlowPotentials::new(n)` — create a flow network with `n` vertices
- `add_edge(u, v, cap, cost)` — add a directed edge with capacity and cost
- `compute(source, sink)` — compute min-cost max-flow, returns `(flow, cost)`
- `compute_with_limit(source, sink, max_flow)` — same, but cap total flow

## 8. Example usage

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
test "min-cost flow picks cheaper path" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(4)
  // Cheap path
  mcf.add_edge(0, 1, 1L, 1L)
  mcf.add_edge(1, 3, 1L, 1L)
  // Expensive path
  mcf.add_edge(0, 2, 1L, 5L)
  mcf.add_edge(2, 3, 1L, 5L)
  let (flow, cost) = mcf.compute_with_limit(0, 3, 1L)
  inspect(flow, content="1")
  inspect(cost, content="2")
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

## 9. Complexity

Let `F` be the max flow value, `E` the number of edges, `V` the number of
vertices:

```
Dijkstra per path: O(E log V)
Total:             O(F * E log V)
```

This is much faster than SPFA for large graphs when all reduced costs are
non-negative after each potential update.

## 10. When can you use this version?

This implementation assumes **non-negative original edge costs**. With `pi = 0`
initially, all reduced costs equal the original costs and Dijkstra is safe
from the start.

If your graph has negative-cost edges, you must either:

- Run a Bellman-Ford pass to initialize `pi` before the first Dijkstra, or
- Use the SPFA-based MCMF package (`lib/mcmf`).

```
All costs >= 0  -> this package (Dijkstra + potentials)
Costs can be negative -> use lib/mcmf (SPFA)
```

## 11. Common pitfalls

- Forgetting reverse edges: the residual graph becomes incomplete.
- Overflow in `cost += flow * path_cost` for large flows with large costs.
- Using this package when original costs are negative (Dijkstra may give wrong
  distances).
- Not resetting `dist`/`prev_v`/`prev_e` arrays at the start of each Dijkstra
  call.
- Relaxing zero-capacity residual edges: always check `cap > flow` before
  relaxing.

## 12. Summary

Potentials + Dijkstra is the standard, fast MCMF implementation for graphs
with non-negative edge costs. It keeps reduced costs non-negative across
iterations, guarantees that each augmentation follows the cheapest residual
path, and produces the minimum-cost maximum flow.
