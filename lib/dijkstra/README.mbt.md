# Dijkstra's Shortest Path Algorithm

## Overview

**Dijkstra's algorithm** finds the shortest paths from a source vertex to all
other vertices in a weighted graph with **non-negative edge weights**.

- **Time**: O((V + E) log V) with binary heap
- **Space**: O(V + E)

## The Algorithm Visualized

Find shortest paths from vertex 0:

```
Graph:
        1
    0 -----> 1
    |        |
  4 |        | 2
    v        v
    2 <----- 3
        1

Initial state:
  dist = [0, INF, INF, INF]
  Process vertex 0 (dist=0)

Step 1: Process neighbors of 0
  - Edge 0->1 (weight 1): dist[1] = min(INF, 0+1) = 1
  - Edge 0->2 (weight 4): dist[2] = min(INF, 0+4) = 4
  dist = [0, 1, 4, INF]

Step 2: Process vertex 1 (smallest unvisited, dist=1)
  - Edge 1->3 (weight 2): dist[3] = min(INF, 1+2) = 3
  dist = [0, 1, 4, 3]

Step 3: Process vertex 3 (dist=3)
  - Edge 3->2 (weight 1): dist[2] = min(4, 3+1) = 4 (no change)
  dist = [0, 1, 4, 3]

Step 4: Process vertex 2 (dist=4)
  - No outgoing edges
  dist = [0, 1, 4, 3]

Final: Shortest distances from 0 are [0, 1, 4, 3]
```

## Why It Works: The Greedy Choice

Dijkstra's key insight: **when we extract the minimum, that distance is final**.

```
Priority Queue State:
  Initially: [(0, dist=0)]

  Extract min (0, d=0), add neighbors:
    Queue: [(1, d=1), (2, d=4)]

  Extract min (1, d=1) <- This is FINAL!
    Why? Any other path to 1 goes through
    vertices with dist >= 1, plus edge weight > 0.
    So 1 is the shortest possible.
```

This only works with **non-negative weights**!

## Use Cases

### 1. Basic Shortest Paths

```mbt check
///|
test "basic shortest paths" {
  let g = @dijkstra.Graph::new(4)
  g.add_edge(0, 1, 1)
  g.add_edge(1, 2, 2)
  g.add_edge(0, 2, 4)
  g.add_edge(2, 3, 1)
  let res = @dijkstra.dijkstra(g, 0)

  // Distances from source 0
  inspect(res.dist[0], content="0") // Source
  inspect(res.dist[1], content="1") // 0 -> 1
  inspect(res.dist[2], content="3") // 0 -> 1 -> 2
  inspect(res.dist[3], content="4") // 0 -> 1 -> 2 -> 3
}
```

### 2. Path Reconstruction

```mbt check
///|
test "path reconstruction" {
  let g = @dijkstra.Graph::new(4)
  g.add_edge(0, 1, 1)
  g.add_edge(1, 2, 2)
  g.add_edge(0, 2, 4)
  g.add_edge(2, 3, 1)
  let res = @dijkstra.dijkstra(g, 0)
  let path = @dijkstra.reconstruct_path(res, 3)
  inspect(path, content="[0, 1, 2, 3]") // Actual path
}
```

### 3. Single Pair Query

```mbt check
///|
test "single pair distance" {
  let g = @dijkstra.Graph::new(4)
  g.add_edge(0, 1, 1)
  g.add_edge(1, 2, 2)
  g.add_edge(0, 2, 4)
  g.add_edge(2, 3, 1)
  let dist = @dijkstra.shortest_distance(g, 0, 3)
  inspect(dist, content="Some(4)")
  let no_path = @dijkstra.shortest_distance(g, 3, 0) // No path back
  inspect(no_path, content="None")
}
```

## Common Applications

1. **GPS Navigation**: Find shortest route between locations
2. **Network Routing**: Route packets through networks (OSPF)
3. **Social Networks**: Degrees of separation
4. **Games**: AI pathfinding (A* is Dijkstra with heuristics)
5. **Robot Motion**: Plan shortest collision-free paths

## Algorithm Comparison

| Algorithm      | Weights     | Time          | Use Case |
|----------------|-------------|---------------|----------|
| **Dijkstra**   | Non-negative| O((V+E)log V) | General shortest paths |
| BFS            | Unweighted  | O(V + E)      | Hop count |
| Bellman-Ford   | Any         | O(V * E)      | Negative weights |
| Floyd-Warshall | Any         | O(V³)         | All pairs |
| A*             | Non-negative| O((V+E)log V) | With heuristic |

## Why Non-Negative Weights?

With negative weights, the greedy choice fails:

```
     -5
0 -----> 1
|        ^
| 1      | 1
v        |
2 ------>+

Dijkstra processes 2 first (dist=1), but
the actual shortest to 1 is 0 -> 1 = -5, not 0 -> 2 -> 1 = 2!
```

For negative weights, use **Bellman-Ford** instead.

## Priority Queue Insight

The algorithm's efficiency comes from the priority queue:

```
Naive approach:  For each vertex, scan all vertices for minimum
                 O(V) per extraction × V extractions = O(V²)

With heap:       Extract min in O(log V)
                 O(log V) per extraction × V extractions = O(V log V)
                 Plus O(E log V) for decrease-key operations
                 Total: O((V + E) log V)
```

## Bidirectional Dijkstra

For point-to-point queries, search from both ends:

```
Source -> ... -> Target
   |               |
   v               v
Forward search   Backward search
   |               |
   +----> Meet <---+

Roughly 2× faster in practice!
```

The module includes `bidirectional_dijkstra(forward_graph, backward_graph, src, dst)`
for faster single-pair queries on large graphs. It requires separate forward and
backward graph representations.

## Implementation Notes

- Uses min-heap (priority queue) for efficient minimum extraction
- Distances initialized to "infinity" (large value)
- Parent pointers enable path reconstruction
- Early termination possible for single-target queries
