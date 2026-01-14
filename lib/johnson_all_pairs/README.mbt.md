# Johnson's All-Pairs Shortest Paths

## Overview

**Johnson's algorithm** computes shortest paths between **all pairs** of vertices
in a sparse directed graph with possibly **negative edge weights** (but no
negative cycles). Faster than Floyd-Warshall for sparse graphs.

- **Time**: O(V·E·log V + V·E) ≈ O(V·E·log V)
- **Space**: O(V²) for output, O(V + E) for computation
- **Key Feature**: Handles negative weights via reweighting

## The Key Insight

```
Problem: All-pairs shortest paths with negative weights

Floyd-Warshall: O(V³) - doesn't use sparsity
Dijkstra: O(V · (E + V log V)) - but needs non-negative weights!

Johnson's insight: REWEIGHT edges to make them non-negative!

Key observation:
  If we add a "potential" h(v) to each vertex, then:

  w'(u,v) = w(u,v) + h(u) - h(v)

  For any path from s to t:
  w'(path) = w(path) + h(s) - h(t)

  All paths s→t shift by the SAME amount!
  Shortest path is preserved!

Finding good potentials:
  Add super-source q connected to all vertices with weight 0.
  Run Bellman-Ford from q.
  h(v) = dist(q, v)

  Then w'(u,v) = w(u,v) + h(u) - h(v) ≥ 0
  (By triangle inequality from Bellman-Ford)
```

## Visual: Reweighting Process

```
Original graph (has negative edge):

    0 ──1──► 1
    │        │
    4       -2    ← Negative!
    │        │
    ▼        ▼
    2 ──1──► 3

Step 1: Add super-source q with 0-weight edges

    q ─0─► 0 ──1──► 1
    │      │        │
    0      4       -2
    │      │        │
    ▼      ▼        ▼
    ├─0──► 2 ──1──► 3

Step 2: Bellman-Ford from q
    h[0] = 0, h[1] = 1, h[2] = 0, h[3] = -1

Step 3: Reweight
    w'(0,1) = 1 + h[0] - h[1] = 1 + 0 - 1 = 0
    w'(0,2) = 4 + h[0] - h[2] = 4 + 0 - 0 = 4
    w'(1,3) = -2 + h[1] - h[3] = -2 + 1 - (-1) = 0
    w'(2,3) = 1 + h[2] - h[3] = 1 + 0 - (-1) = 2

All non-negative! Now run Dijkstra from each vertex.
```

## The Algorithm

```
johnson_all_pairs(n, edges):
  // Step 1: Add super-source q
  extended_edges = edges + [(q, v, 0) for each v]

  // Step 2: Bellman-Ford from q to get potentials h[]
  h = bellman_ford(n+1, extended_edges, q)
  if negative_cycle_detected:
    return None

  // Step 3: Reweight edges
  for each edge (u, v, w):
    w' = w + h[u] - h[v]  // Now w' >= 0

  // Step 4: Dijkstra from each vertex
  dist = new V×V matrix
  for each source s:
    d = dijkstra(reweighted_graph, s)
    for each target t:
      // Un-reweight: restore original distances
      dist[s][t] = d[t] - h[s] + h[t]

  return dist
```

## Example Usage

```mbt check
///|
test "johnson basic" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (0, 2, 4L),
    (1, 2, -2L),
    (2, 3, 2L),
    (1, 3, 5L),
  ]
  let dist = @johnson_all_pairs.johnson_all_pairs(4, edges[:]).unwrap()
  inspect(dist[0], content="[0, 1, -1, 1]")
}
```

```mbt check
///|
test "johnson negative cycle" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 2, -2L), (2, 1, -2L)]
  inspect(@johnson_all_pairs.johnson_all_pairs(3, edges[:]), content="None")
}
```

```mbt check
///|
test "johnson disconnected" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L)]
  let dist = @johnson_all_pairs.johnson_all_pairs(3, edges[:]).unwrap()
  inspect(dist[0][1], content="1")
  // dist[0][2] = INF (unreachable)
}
```

## Algorithm Walkthrough

```
Graph: 4 nodes
Edges: 0→1(1), 0→2(4), 1→2(-2), 2→3(2), 1→3(5)

    0 ──1──► 1
    │       /│
    4    -2  5
    │   /    │
    ▼  ▼     ▼
    2 ──2──► 3

Step 1: Add super-source q
  q→0(0), q→1(0), q→2(0), q→3(0)

Step 2: Bellman-Ford from q
  Initial: h = [0, 0, 0, 0]

  Relax edges:
    0→1: h[1] = min(0, 0+1) = 0
    0→2: h[2] = min(0, 0+4) = 0
    1→2: h[2] = min(0, 0-2) = -2
    2→3: h[3] = min(0, -2+2) = 0
    1→3: h[3] = min(0, 0+5) = 0

  Final: h = [0, 0, -2, 0]

Step 3: Reweight edges
  0→1: 1 + 0 - 0 = 1
  0→2: 4 + 0 - (-2) = 6
  1→2: -2 + 0 - (-2) = 0
  2→3: 2 + (-2) - 0 = 0
  1→3: 5 + 0 - 0 = 5

  All ≥ 0 ✓

Step 4: Dijkstra from each source

  From 0: d' = [0, 1, 1, 1]
  Un-reweight: dist[0][v] = d'[v] - h[0] + h[v]
    dist[0][0] = 0 - 0 + 0 = 0
    dist[0][1] = 1 - 0 + 0 = 1
    dist[0][2] = 1 - 0 + (-2) = -1
    dist[0][3] = 1 - 0 + 0 = 1

Result: dist[0] = [0, 1, -1, 1] ✓
```

## Why Reweighting Preserves Shortest Paths

```
Claim: Shortest paths are the same after reweighting.

For any path P = v₀ → v₁ → ... → vₖ:

Original cost:
  w(P) = Σᵢ w(vᵢ, vᵢ₊₁)

Reweighted cost:
  w'(P) = Σᵢ [w(vᵢ, vᵢ₊₁) + h(vᵢ) - h(vᵢ₊₁)]
        = Σᵢ w(vᵢ, vᵢ₊₁) + Σᵢ [h(vᵢ) - h(vᵢ₊₁)]
        = w(P) + h(v₀) - h(vₖ)  // Telescoping sum!

All paths from v₀ to vₖ change by same constant!
So relative ordering is preserved.
```

## Why w'(u,v) ≥ 0

```
After Bellman-Ford: h[v] = shortest path from q to v

Triangle inequality:
  h[v] ≤ h[u] + w(u,v)

Rearranging:
  w(u,v) + h[u] - h[v] ≥ 0
  w'(u,v) ≥ 0 ✓

This is exactly the reweighted edge!
Bellman-Ford guarantees this property.
```

## Common Applications

### 1. Sparse Graphs with Negative Weights
```
When E << V² and negative weights exist.
Faster than Floyd-Warshall's O(V³).
```

### 2. Network Analysis
```
Finding shortest paths between all node pairs.
Detecting negative cycles (arbitrage opportunities).
```

### 3. Preprocessing for Path Queries
```
Build distance matrix once, answer queries in O(1).
Trade space for query time.
```

### 4. Transportation Networks
```
Travel times with variable conditions.
Some routes may have "negative" time (shortcuts).
```

## Complexity Analysis

| Phase | Time | Notes |
|-------|------|-------|
| Bellman-Ford | O(V·E) | Single source, V-1 iterations |
| Reweight | O(E) | Visit each edge once |
| Dijkstra × V | O(V·(E + V log V)) | With binary heap |
| **Total** | **O(V·E + V²·log V)** | For sparse graphs |

## Johnson's vs Floyd-Warshall

| Aspect | Johnson's | Floyd-Warshall |
|--------|-----------|----------------|
| Time | O(V·E·log V) | O(V³) |
| Space (working) | O(V + E) | O(V²) |
| Negative weights | Yes | Yes |
| Negative cycles | Detected | Detected |
| Best for | Sparse graphs | Dense graphs |

**Choose Johnson's when**: E << V² (sparse)
**Choose Floyd-Warshall when**: E ≈ V² (dense)

## Negative Cycle Detection

```
Bellman-Ford detects negative cycles:
  After V-1 iterations, run one more.
  If any distance decreases → negative cycle exists.

When negative cycle detected:
  - No meaningful shortest paths exist
  - Algorithm returns None
  - The cycle can be extracted from Bellman-Ford
```

## Implementation Notes

- Use a sentinel value (e.g., INF/2) for unreachable pairs
- Be careful with overflow when adding potentials
- Store h[] values for un-reweighting after Dijkstra
- Can output actual paths by tracking predecessors
- Super-source q doesn't need to be added explicitly

