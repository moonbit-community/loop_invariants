# Min-Cost Max-Flow (Johnson Potentials)

## Overview

This implementation of **Min-Cost Max-Flow** uses successive shortest
augmenting paths with **Johnson potentials**. Potentials reweight edges
to eliminate negative reduced costs, allowing Dijkstra for each augmentation.

- **Time**: O(F · E log V) where F is max flow
- **Space**: O(V + E)
- **Key Feature**: Efficient for graphs with non-negative original costs

## The Key Insight

```
Problem: Find maximum flow with minimum total cost

Min-cost max-flow approach:
  1. Find shortest path (by cost) from s to t in residual graph
  2. Augment flow along this path
  3. Repeat until no path exists

Challenge: Residual graph has negative-cost edges!
  Forward edge: cost c
  Reverse edge: cost -c (to "undo" the cost)

Johnson potentials solution:
  Use reduced costs: reduced_cost(u,v) = cost(u,v) + π[u] - π[v]
  With correct potentials, all reduced costs are non-negative!
  → Can use Dijkstra instead of Bellman-Ford!
```

## Visual: Residual Graph and Potentials

```
Original edge:          Residual edges after flow f:
  u ──c,cap──► v           u ──c,cap-f──► v    (remaining capacity)
                           u ◄──-c,f───── v    (reverse, negative cost!)

With potentials π:
  reduced_cost(u,v) = c + π[u] - π[v]

If we maintain: π[v] = shortest path cost from s to v
Then: reduced_cost ≥ 0 for all edges (triangle inequality)

After each augmentation:
  Update potentials: π[v] += dist[v] (from last Dijkstra)
  This maintains the non-negativity invariant!
```

## Algorithm

```
min_cost_max_flow(graph, source, sink):
  total_flow = 0
  total_cost = 0
  potential = array of 0s

  while true:
    // Find shortest path using reduced costs
    (dist, parent) = dijkstra_with_potentials(graph, source, potential)

    if dist[sink] == ∞:
      break  // No more augmenting paths

    // Update potentials
    for v in vertices:
      if dist[v] < ∞:
        potential[v] += dist[v]

    // Find bottleneck capacity
    path = reconstruct_path(parent, source, sink)
    min_cap = min capacity along path

    // Augment flow
    for each edge (u, v) in path:
      edge.flow += min_cap
      reverse_edge.flow -= min_cap

    total_flow += min_cap
    total_cost += min_cap * (potential[sink] - potential[source])

  return (total_flow, total_cost)
```

## Example Usage

```mbt check
///|
test "min-cost flow with potentials" {
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

## Algorithm Walkthrough

```
Graph:
  0 ──(cap=2,cost=1)──► 1 ──(cap=1,cost=3)──► 3
  │                     │                     ▲
  └──(cap=1,cost=2)──►  2 ──(cap=2,cost=1)──┘
        also: 1 ──(cap=1,cost=1)──► 2

Initial potentials: [0, 0, 0, 0]

Iteration 1:
  Dijkstra with reduced costs:
    0→1: cost 1, 0→2: cost 2
    1→2: cost 1, 1→3: cost 3
    2→3: cost 1
  Shortest path: 0→1→2→3 (cost 3)
  Bottleneck: min(2, 1, 2) = 1
  Augment 1 unit, total_cost = 3
  Update potentials: [0, 1, 2, 3]

Iteration 2:
  Residual graph has reverse edges with reduced cost 0
  New shortest path: 0→1→3 (reduced cost = 1+3+0-1 = 3? Let me recalculate)

  Actually with updated potentials:
    0→1: reduced = 1 + 0 - 1 = 0
    1→3: reduced = 3 + 1 - 3 = 1
  Path 0→1→3: reduced cost 1, real cost = 1 + 3 = 4
  Bottleneck: min(1, 1) = 1
  Augment 1 unit, total_cost = 3 + 4 = 7

Iteration 3:
  Path 0→2→3: reduced cost = (2+0-2) + (1+2-3) = 0 + 0 = 0
  Real cost = 2 + 1 = 3
  Bottleneck: min(1, 1) = 1
  Augment 1 unit, total_cost = 7 + 3 = 10

Total: flow = 3, cost = 10 ✓
```

## Why Johnson Potentials Work

```
Key invariant: After each iteration:
  potential[v] = cost of shortest path from source to v

This guarantees:
  reduced_cost(u,v) = cost(u,v) + π[u] - π[v] ≥ 0

Proof: Triangle inequality on shortest paths
  π[v] ≤ π[u] + cost(u,v)
  → cost(u,v) + π[u] - π[v] ≥ 0 ✓

Why update π[v] += dist[v]?
  - dist[v] is the shortest reduced-cost distance
  - New potential π'[v] = π[v] + dist[v]
  - This equals the true shortest path cost from source
```

## Common Applications

### 1. Assignment Problem
```
Assign n workers to n jobs minimizing total cost.
Model as bipartite graph with unit capacities.
```

### 2. Transportation Problem
```
Ship goods from suppliers to consumers.
Minimize shipping cost while meeting demand.
```

### 3. Network Design
```
Install network links with capacity and cost.
Find cheapest way to meet bandwidth requirements.
```

### 4. Matching with Costs
```
Bipartite matching where edges have costs.
Find maximum matching with minimum total cost.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Single Dijkstra | O(E log V) |
| Number of augmentations | O(F) or O(VE) |
| **Total** | **O(F · E log V)** or **O(VE² log V)** |

For unit capacities: O(min(V,E) · E log V)

## Min-Cost Flow vs Other Flow Algorithms

| Algorithm | Finds | Time |
|-----------|-------|------|
| Ford-Fulkerson | Max flow | O(E · max_flow) |
| Edmonds-Karp | Max flow | O(VE²) |
| Dinic | Max flow | O(V²E) |
| Push-Relabel | Max flow | O(V²E) |
| **MCMF (potentials)** | **Min-cost max-flow** | **O(F·E log V)** |
| MCMF (SPFA) | Min-cost max-flow | O(F·VE) |

## SPFA vs Dijkstra with Potentials

```
SPFA (Bellman-Ford variant):
  - Handles negative edges directly
  - O(VE) per iteration
  - Simpler to implement

Dijkstra with potentials:
  - Requires potential maintenance
  - O(E log V) per iteration
  - Faster for large graphs

Choose potentials when:
  - Graph is large
  - Many augmentations expected
  - Need speed over simplicity
```

## Implementation Notes

- Initialize potentials to 0 (or run Bellman-Ford once if negative costs exist)
- Update potentials after each shortest path computation
- Store both forward and reverse edges in adjacency list
- Track residual capacity = capacity - flow
- Real cost = reduced cost + π[sink] - π[source]

