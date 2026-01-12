# Graph Algorithms

## Overview

This package provides reference implementations of fundamental graph algorithms
with detailed loop invariants and reasoning. It serves as an educational
resource for understanding algorithm correctness.

## Algorithms Covered

### 1. Topological Sort (Kahn's Algorithm)
```
Order vertices so all edges point forward.
Only works on DAGs (Directed Acyclic Graphs).

Algorithm:
1. Count in-degrees for all vertices
2. Add vertices with in-degree 0 to queue
3. Process queue: output vertex, decrement neighbors' in-degrees
4. Add newly zero-degree vertices to queue

Time: O(V + E)

     A → B → D
     ↓   ↓
     C → E

Topological order: A, B, C, D, E (or A, C, B, E, D, etc.)
```

### 2. Dijkstra's Shortest Paths
```
Find shortest paths from source to all vertices.
Requires non-negative edge weights.

Algorithm:
1. Initialize: dist[source] = 0, dist[others] = ∞
2. Use priority queue ordered by distance
3. Extract minimum, relax outgoing edges
4. Update distances and add to queue if improved

Time: O((V + E) log V) with binary heap

     A --1-- B --2-- D
     |       |
     3       1
     |       |
     C --1-- E

Shortest from A: A=0, B=1, C=3, E=2, D=3
```

### 3. Union-Find (Disjoint Set Union)
```
Maintain disjoint sets with efficient union and find.
Key optimizations: path compression + union by rank.

Operations:
- find(x): Return representative of x's set
- union(x, y): Merge sets containing x and y

Time: O(α(n)) ≈ O(1) per operation

     Initially: {0}, {1}, {2}, {3}, {4}
     union(0,1): {0,1}, {2}, {3}, {4}
     union(2,3): {0,1}, {2,3}, {4}
     union(0,2): {0,1,2,3}, {4}
     find(3) → representative of {0,1,2,3}
```

### 4. Bellman-Ford Shortest Paths
```
Find shortest paths with possibly negative edges.
Can detect negative cycles.

Algorithm:
1. Initialize: dist[source] = 0, dist[others] = ∞
2. Repeat V-1 times: relax all edges
3. One more pass to detect negative cycles

Time: O(V × E)

     A --(-1)-- B --(2)-- D
     |          |
    (4)        (3)
     |          |
     C --(5)--- E

Handles negative edges correctly!
```

### 5. Floyd-Warshall All-Pairs
```
Find shortest paths between ALL pairs of vertices.
Handles negative edges (but not negative cycles).

Algorithm:
1. Initialize dist[i][j] = weight(i,j) or ∞
2. For each intermediate vertex k:
   dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])

Time: O(V³)

The DP insight: gradually allow more intermediate vertices.
```

### 6. Kruskal's MST
```
Find minimum spanning tree using greedy edge selection.

Algorithm:
1. Sort edges by weight
2. For each edge (u,v) in order:
   If u and v are in different components:
     Add edge to MST
     Union u and v
3. Stop when MST has V-1 edges

Time: O(E log E)

     A --1-- B --4-- D
     |       |       |
     2       3       5
     |       |       |
     C --6-- E --7-- F

MST edges: AB(1), AC(2), BE(3), BD(4), DF(5)
Total weight: 15
```

## Key Invariants

### Dijkstra's Invariant
```
After processing vertex u:
  dist[u] = actual shortest path distance from source
  All vertices in "done" set have optimal distances

Why it works:
  When we extract minimum from queue, no shorter
  path can exist (requires negative edges to fail).
```

### Bellman-Ford Invariant
```
After k iterations:
  dist[v] ≤ length of shortest path using ≤ k edges

Why V-1 iterations suffice:
  Shortest path has at most V-1 edges (no cycles in path).
```

### Floyd-Warshall Invariant
```
After processing intermediate vertex k:
  dist[i][j] = shortest path from i to j
               using only vertices {0, 1, ..., k} as intermediates

Why it works:
  Either the optimal path uses k, or it doesn't.
  We check both possibilities.
```

### Union-Find Invariant
```
Each set forms a tree with representative at root.
Path compression: flatten tree during find.
Union by rank: attach shorter tree under taller.

Together: nearly constant time per operation.
```

## Usage Pattern

```mbt nocheck
// These are reference implementations - read the source!
// For callable APIs, use the dedicated packages:

// @dijkstra.dijkstra(...)
// @dijkstra.dijkstra_dense(...)
// @union_find.UnionFind::new(...)
// @challenge_toposort_kahn.topo_sort(...)
```

## Algorithm Selection Guide

| Problem | Algorithm | Time |
|---------|-----------|------|
| Shortest path, non-negative | Dijkstra | O((V+E) log V) |
| Shortest path, negative | Bellman-Ford | O(VE) |
| All-pairs shortest | Floyd-Warshall | O(V³) |
| Minimum spanning tree | Kruskal/Prim | O(E log V) |
| Topological order | Kahn's | O(V + E) |
| Connectivity | Union-Find | O(α(n)) per op |

## Implementation Notes

- All implementations include detailed invariants
- Read `lib/graph/graph.mbt` for annotated source
- Use challenge packages for production APIs
- Implementations are intentionally verbose for learning
