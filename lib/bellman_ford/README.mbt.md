# Bellman-Ford Algorithm

## Overview

The **Bellman-Ford Algorithm** computes single-source shortest paths in graphs
with negative edge weights. Unlike Dijkstra's, it can detect negative cycles.

- **Time**: O(V × E)
- **Space**: O(V)

## When to Use Bellman-Ford

```
Dijkstra:      Positive weights only, O((V+E) log V)
Bellman-Ford:  Negative weights OK, detects negative cycles, O(V×E)

Use Bellman-Ford when:
✓ Graph has negative edge weights
✓ Need to detect negative cycles
✓ Graph is sparse (E ≈ V)
```

## The Key Insight

```
After k iterations of relaxing all edges:
  dist[v] = shortest path to v using at most k edges

Since shortest paths have at most V-1 edges (no cycles in simple paths),
V-1 iterations are sufficient to find all shortest paths.
```

## Algorithm Walkthrough

```
Graph:
    0 ─(4)→ 1 ─(3)→ 3
    │       ↑
   (2)    (-5)
    ↓       │
    2 ──────┘

Edges: (0,1,4), (0,2,2), (2,1,-5), (1,3,3)
Source: 0

Initial:   dist = [0, ∞, ∞, ∞]

Iteration 1 (relax all edges):
  (0,1,4): dist[1] = min(∞, 0+4) = 4
  (0,2,2): dist[2] = min(∞, 0+2) = 2
  (2,1,-5): dist[1] = min(4, 2+(-5)) = -3
  (1,3,3): dist[3] = min(∞, -3+3) = 0

  dist = [0, -3, 2, 0]

Iteration 2:
  (0,1,4): dist[1] = min(-3, 0+4) = -3 (no change)
  (0,2,2): dist[2] = min(2, 0+2) = 2 (no change)
  (2,1,-5): dist[1] = min(-3, 2+(-5)) = -3 (no change)
  (1,3,3): dist[3] = min(0, -3+3) = 0 (no change)

  No changes → early termination!

Final: dist = [0, -3, 2, 0]
```

## Visual: Edge Relaxation

```
Edge relaxation (u, v, w):
  if dist[u] + w < dist[v]:
    dist[v] = dist[u] + w

Before:          After:
  u ──(w)→ v       u ──(w)→ v
 [3]      [10]    [3]      [3+w]
                            (if 3+w < 10)

The triangle inequality:
  dist[v] ≤ dist[u] + w(u,v)

After V-1 iterations, all distances satisfy this.
```

## Negative Cycle Detection

```
After V-1 iterations, if any edge can still be relaxed,
there exists a negative cycle!

Why? A simple path has at most V-1 edges. If relaxation
is still possible, the path must use V+ edges → has a cycle.

Graph with negative cycle:
    0 ─(1)→ 1
    ↑       │
   (2)    (-4)
    │       ↓
    └────── 2

Cycle: 1 → 2 → 0 → 1
Weight: -4 + 2 + 1 = -1 (negative!)

Each traversal of cycle decreases dist → unbounded
```

## Example Usage

```mbt check
///|
test "bellman ford example" {
  let bf = @bellman_ford.BellmanFord::new(4)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(1, 2, 2L)
  bf.add_edge(0, 2, 5L)
  bf.add_edge(2, 3, 1L)
  let res = bf.compute(0)
  inspect(res.get_distance(3), content="Some(4)")
  inspect(res.has_negative_cycle(), content="false")
}
```

## SPFA: Queue-Based Optimization

```
SPFA (Shortest Path Faster Algorithm):
- Only relax edges from vertices whose distance changed
- Use a queue to track "active" vertices
- Average case: O(E), worst case: O(V×E)

Standard Bellman-Ford:
  For i = 1 to V-1:
    For each edge (u,v,w):
      relax(u, v, w)

SPFA:
  queue = [source]
  while queue not empty:
    u = dequeue()
    for each edge (u,v,w):
      if relax(u,v,w) and v not in queue:
        enqueue(v)
```

## Common Applications

### 1. Currency Arbitrage Detection
```
Problem: Find if profit exists from circular currency exchange

Model: Nodes = currencies, edges = exchange rates
       Edge weight = -log(rate) (to convert multiplication to addition)
       Negative cycle = arbitrage opportunity!
```

### 2. Routing with Negative Costs
```
Some network metrics can be negative (e.g., profit - cost).
Bellman-Ford handles this while Dijkstra cannot.
```

### 3. Difference Constraints
```
System of inequalities: x_j - x_i ≤ c_ij

Create graph with edge (i, j, c_ij).
If no negative cycle: solvable, distances give solution.
If negative cycle: no solution exists.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Initialization | O(V) |
| Main loop (V-1 iterations) | O(V × E) |
| Negative cycle check | O(E) |
| **Total** | **O(V × E)** |

## Bellman-Ford vs Other Algorithms

| Algorithm | Handles Negative? | Time | Use Case |
|-----------|-------------------|------|----------|
| **Bellman-Ford** | Yes + cycle detect | O(VE) | Negative weights |
| Dijkstra | No | O((V+E) log V) | Positive weights |
| Floyd-Warshall | Yes | O(V³) | All-pairs |
| SPFA | Yes | O(E) avg / O(VE) worst | Sparse graphs |

**Choose Bellman-Ford when**: You have negative edges or need cycle detection.

## Why V-1 Iterations?

```
Claim: Shortest path has at most V-1 edges (if no negative cycle).

Proof: A shortest path visits each vertex at most once.
       Otherwise, if vertex v appears twice, the cycle
       between occurrences must have non-negative weight
       (else we'd use fewer edges for shorter distance).
       So we can remove the cycle → at most V vertices
       → at most V-1 edges.

After iteration k:
  dist[v] = shortest path using ≤ k edges

After iteration V-1:
  All shortest paths are found!
```

## Implementation Notes

- Use large but not MAX_INT for infinity (avoid overflow)
- Track parent pointers to reconstruct paths
- Early termination: stop if no relaxation in an iteration
- For negative cycle path: run V more iterations, track vertices that change

