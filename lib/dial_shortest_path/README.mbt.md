# Dial's Shortest Path Algorithm

## Overview

**Dial's Algorithm** is a specialized shortest path algorithm for graphs with
**small non-negative integer edge weights**. It replaces Dijkstra's priority
queue with an array of buckets, achieving O(E + CV) time where C is the
maximum edge weight.

- **Time**: O(E + C·V)
- **Space**: O(E + C·V)
- **Key Feature**: Faster than Dijkstra when C is small

## The Key Insight

```
Dijkstra's algorithm: O((V + E) log V) with priority queue
  - Priority queue is expensive for small weight range

Dial's insight: If edge weights are in {0, 1, 2, ..., C}:
  - Maximum shortest path ≤ C·(V-1)
  - Use C·V buckets instead of priority queue!
  - bucket[d] = list of vertices with distance exactly d
  - Scan buckets in order to process vertices by distance

No priority queue overhead → O(E + CV) total time!
```

## Visual: Bucket Structure

```
Graph:              Buckets after processing:
  0 --2-- 1         bucket[0]: [0]      ← start
  |       |         bucket[1]: []
  1       3         bucket[2]: [1, 2]   ← via edge 0→1, 0→2
  |       |         bucket[3]: []
  2 --1-- 3         bucket[4]: []
                    bucket[5]: [3]      ← via 1→3 or 2→3

Edge weights: 0→1:2, 0→2:1, 1→3:3, 2→3:1

Processing order: 0, then 1 and 2 (distance 2), then 3 (distance 5)
Wait - 2 has distance 1, not 2! Let me recalculate:

  dist[0] = 0
  Process 0: dist[1] = 2, dist[2] = 1
  bucket[1]: [2]
  bucket[2]: [1]

  Process 2 (dist=1): dist[3] = min(∞, 1+1) = 2
  bucket[2]: [1, 3]

  Process 1 (dist=2): dist[3] = min(2, 2+3) = 2 (no change)
  Process 3 (dist=2): done

Final: dist = [0, 2, 1, 2]
```

## Algorithm

```
dial_shortest_path(graph, source, max_weight):
  max_dist = max_weight * (n - 1)
  buckets = array of max_dist+1 empty lists
  dist = array of n infinities

  dist[source] = 0
  buckets[0].add(source)

  for d = 0 to max_dist:
    while buckets[d] is not empty:
      u = buckets[d].remove_any()

      if dist[u] < d:  // Already processed with shorter distance
        continue

      for each edge (u, v, w):
        new_dist = d + w
        if new_dist < dist[v]:
          dist[v] = new_dist
          buckets[new_dist].add(v)

  return dist
```

## Example Usage

```mbt check
///|
test "dial shortest path example" {
  let g = @dial_shortest_path.Graph::new(5, 3)
  g.add_edge(0, 1, 1)
  g.add_edge(0, 2, 2)
  g.add_edge(1, 2, 1)
  g.add_edge(1, 3, 3)
  g.add_edge(2, 3, 1)
  g.add_edge(3, 4, 0)
  let dist = @dial_shortest_path.dial_shortest_paths(g, 0)
  inspect(dist, content="[0, 1, 2, 3, 3]")
}
```

```mbt check
///|
test "dial shortest path undirected" {
  let g = @dial_shortest_path.Graph::new(4, 2)
  g.add_undirected_edge(0, 1, 1)
  g.add_undirected_edge(1, 2, 1)
  g.add_undirected_edge(2, 3, 2)
  let dist = @dial_shortest_path.dial_shortest_paths(g, 0)
  inspect(dist, content="[0, 1, 2, 4]")
}
```

## Algorithm Walkthrough

```
Graph: 5 nodes, max weight C=3
Edges: 0→1(1), 0→2(2), 1→2(1), 1→3(3), 2→3(1), 3→4(0)

Initialize:
  dist = [0, ∞, ∞, ∞, ∞]
  buckets[0] = [0]

d=0: Process vertex 0
  Edge 0→1(1): dist[1] = 1, add 1 to bucket[1]
  Edge 0→2(2): dist[2] = 2, add 2 to bucket[2]

d=1: Process vertex 1
  Edge 1→2(1): dist[2] = min(2, 1+1) = 2, no change
  Edge 1→3(3): dist[3] = 4, add 3 to bucket[4]

d=2: Process vertex 2
  Edge 2→3(1): dist[3] = min(4, 2+1) = 3, add 3 to bucket[3]

d=3: Process vertex 3
  Edge 3→4(0): dist[4] = 3, add 4 to bucket[3]
  Process vertex 4 (also in bucket[3])
  No outgoing edges from 4

Final: dist = [0, 1, 2, 3, 3]
```

## When to Use Dial's Algorithm

```
Use Dial's when:
  ✓ Edge weights are non-negative integers
  ✓ Maximum weight C is small (C = O(V) or less)
  ✓ You want O(E + CV) instead of O((V+E) log V)

Don't use when:
  ✗ Edge weights are large (C >> V)
  ✗ Edge weights are real numbers
  ✗ Edge weights can be negative
```

## Complexity Analysis

| Algorithm | Time | Space | Best For |
|-----------|------|-------|----------|
| Dial's | O(E + CV) | O(CV) | Small integer weights |
| Dijkstra (heap) | O((V+E) log V) | O(V) | General non-negative |
| Dijkstra (Fibonacci) | O(E + V log V) | O(V) | Dense graphs |
| 0-1 BFS | O(V + E) | O(V) | Weights in {0, 1} only |

## Comparison: Dial vs 0-1 BFS

```
0-1 BFS: Weights must be exactly 0 or 1
  Uses deque: push_front for 0, push_back for 1
  Time: O(V + E)

Dial's: Weights can be 0, 1, 2, ..., C
  Uses C buckets
  Time: O(E + CV)

When C = 1, Dial's degenerates to BFS!
When C = small constant, Dial's ≈ O(V + E)
```

## Common Applications

### 1. Road Networks with Speed Limits
```
Edge weight = travel time = distance / speed
Discretize to small integers for Dial's algorithm.
```

### 2. Grid Navigation
```
Moving to adjacent cell costs 1.
Moving diagonally costs 2.
Dial's with C=2 is efficient.
```

### 3. Game Pathfinding
```
Different terrain types have different costs.
If costs are small integers, Dial's is fast.
```

## Implementation Notes

- Circular buckets: Only need C+1 buckets with circular indexing
- Lazy deletion: Skip vertices that were already processed with shorter distance
- Handle duplicates: A vertex may appear in multiple buckets as distance improves
- Memory optimization: Use linked lists or deques for buckets

## Optimization: Circular Buckets

```
Instead of max_dist buckets, use only C+1 buckets with circular indexing:

bucket_index = distance mod (C + 1)

Works because:
- Current distance d is in bucket[d mod (C+1)]
- Next distances are d+1, d+2, ..., d+C
- These map to different buckets (no collision)
- When we advance to d+1, bucket[d mod (C+1)] is free

Space: O(V + C) instead of O(CV)
```

