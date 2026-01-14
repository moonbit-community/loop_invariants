# Edmonds' Arborescence (Chu–Liu/Edmonds)

## Overview

**Edmonds' algorithm** finds the minimum-cost **arborescence** (directed spanning
tree) rooted at a given vertex. Every node except the root has exactly one
incoming edge, and all nodes are reachable from the root.

- **Time**: O(V × E) (simple implementation)
- **Space**: O(V + E)
- **Key Feature**: Handles cycles through contraction

## The Key Insight

```
Problem: Find minimum directed spanning tree from root r

Greedy attempt:
  For each node v ≠ r, pick cheapest incoming edge.

  If no cycle forms → Done! This is optimal.
  If cycle forms → Problem! Cycle has no connection to root.

Edmonds' insight: CONTRACT the cycle!
  - Merge cycle nodes into a single supernode
  - Adjust edge weights to "pay" for breaking the cycle
  - Recurse on smaller graph
  - Expand back to recover original edges

Weight adjustment for edge u → v entering cycle:
  w'(u → v) = w(u → v) - in_cost[v]

  This ensures choosing this edge "pays for" removing
  the edge we selected inside the cycle.
```

## Visual: Cycle Contraction

```
Original graph (root = 0):

    0
    │╲
   5│ ╲1
    │  ╲
    ▼   ▼
    2◄──1
      1   ╲2
           ▼
           3

Step 1: Pick cheapest incoming edge for each node
  1 ← 0 (cost 1)
  2 ← 1 (cost 1)
  3 ← 1 (cost 2)

Result: 0→1→2, 1→3 (no cycle, total = 4)

But consider this graph:

    0
    │
   5│
    ▼
    1◄──┐
    │   │
   1│   │2
    ▼   │
    2───┘

Min incoming edges:
  1 ← 2 (cost 2)  ← Cycle!
  2 ← 1 (cost 1)  ← Cycle!

Cycle {1, 2} detected with cost 3.

Contract cycle into supernode C:
  Edge 0→1 becomes 0→C with cost 5 - 2 = 3
  (Subtracting the in-edge cost we'd replace)

After contraction, pick 0→C (cost 3).
Total = 3 + 1 = 4 (0→1→2, keeping 1→2)
```

## The Algorithm

```
edmonds(n, edges, root):
  // Check reachability
  if not all nodes reachable from root:
    return None

  while true:
    // Step 1: Find min incoming edge for each node
    for each node v ≠ root:
      in_edge[v] = cheapest edge into v

    // Step 2: Check for cycles
    cycle = find_cycle(in_edge)

    if cycle is empty:
      // No cycle - we're done!
      return edges selected by in_edge

    // Step 3: Contract cycle
    // Create supernode for cycle
    // Adjust weights: w'(u→v) = w(u→v) - in_edge[v].cost
    // where v is in cycle

    // Recurse with contracted graph
    contract_and_recurse()
```

## Example Usage

```mbt check
///|
test "arborescence example" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1 },
    { from: 0, to: 2, weight: 5 },
    { from: 1, to: 2, weight: 1 },
    { from: 1, to: 3, weight: 2 },
    { from: 2, to: 3, weight: 1 },
  ]
  let res = @edmonds_arborescence.min_arborescence(4, edges[:], 0).unwrap()
  inspect(res.cost, content="3")
}
```

```mbt check
///|
test "arborescence with cycle resolution" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 10 },
    { from: 1, to: 2, weight: 1 },
    { from: 2, to: 1, weight: 1 },
    { from: 2, to: 3, weight: 5 },
  ]
  let res = @edmonds_arborescence.min_arborescence(4, edges[:], 0).unwrap()
  // Must break the 1↔2 cycle by using 0→1
  inspect(res.cost, content="16")
}
```

## Algorithm Walkthrough

```
Graph: 4 nodes, root = 0
Edges: 0→1(1), 0→2(5), 1→2(1), 1→3(2), 2→3(1)

    0
   /│
  1 5
 /  │
▼   ▼
1─1→2
│   │
2   1
│   │
▼   ▼
  3

Step 1: Find min incoming edge for each node ≠ 0
  Node 1: 0→1 (cost 1)
  Node 2: 1→2 (cost 1) vs 0→2 (cost 5) → pick 1→2
  Node 3: 1→3 (cost 2) vs 2→3 (cost 1) → pick 2→3

Step 2: Check for cycles
  Following in_edges: 1←0, 2←1, 3←2
  No cycle! (0 is root, terminates chain)

Step 3: Done!
  Arborescence: 0→1, 1→2, 2→3
  Total cost: 1 + 1 + 1 = 3 ✓
```

## Why Weight Adjustment Works

```
When we contract a cycle C with internal cost I:
  - We must keep exactly |C| - 1 edges from C
  - One edge into C must replace one cycle edge

For edge e: u → v where v ∈ C:
  Original cost to reach v from outside: w(e)
  But we "save" the in-cycle edge cost: in_cost[v]

  Net cost of using e: w(e) - in_cost[v]

After finding optimal arborescence in contracted graph:
  - Total cost = contracted_cost + cycle_internal_cost
  - The adjustment ensures this equals the true cost
```

## Common Applications

### 1. Network Design
```
Build minimum-cost broadcast network from a source.
All nodes must receive data from the source.
```

### 2. Dependency Resolution
```
Find cheapest way to satisfy all dependencies.
Root = main module, edges = import costs.
```

### 3. Control Flow Optimization
```
Optimize control flow graph with weighted edges.
Find minimum-cost dominator tree.
```

### 4. Phylogenetic Trees
```
Build evolutionary trees with minimum mutation cost.
Root = common ancestor.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Find min incoming edges | O(E) | Scan all edges |
| Cycle detection | O(V) | Follow parent pointers |
| Contraction per phase | O(E) | Rebuild edge list |
| Number of phases | O(V) | At most V contractions |
| **Total** | **O(V × E)** | Simple implementation |

## Faster Implementations

```
Gabow et al.: O(E + V log V)
  Uses Fibonacci heaps and sophisticated data structures.

For dense graphs (E ≈ V²):
  Simple O(VE) ≈ O(V³) may be acceptable.

For sparse graphs:
  Advanced implementations provide significant speedup.
```

## Arborescence vs MST

| Aspect | Arborescence | MST (Undirected) |
|--------|--------------|------------------|
| Graph type | Directed | Undirected |
| Root | Required | Not required |
| Edge direction | All away from root | No direction |
| Algorithm | Edmonds' O(VE) | Kruskal/Prim O(E log V) |

## When It Returns None

```
No arborescence exists when:
  1. Some vertex is unreachable from root
  2. Graph is disconnected (for directed reachability)

The algorithm first checks if all nodes are
reachable from the root using BFS/DFS.
```

## Implementation Notes

- First verify all vertices are reachable from root
- Track which edges are selected during contraction
- Uncontract carefully to recover original edge indices
- Handle self-loops (ignore them)
- Multiple edges between same pair: keep track of all

