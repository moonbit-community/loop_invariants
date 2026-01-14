# Yen's K Shortest Paths Algorithm

## Overview

**Yen's algorithm** finds the **k shortest simple (loopless) paths** from a
source to a target in a weighted directed graph.

- **Time**: O(k · n · (m + n log n))
- **Space**: O(k · n)
- **Key Feature**: Finds multiple alternative shortest paths

## The Key Insight

```
Problem: Find not just THE shortest path, but the k shortest paths

Naive: Enumerate all paths and sort → Exponential!

Yen's insight: Build paths incrementally using "spur" deviations

Given the i-th shortest path Pᵢ:
  For each node v on Pᵢ:
    1. Keep the prefix (root path) from source to v
    2. Block edges that would recreate paths P₁...Pᵢ with same prefix
    3. Find shortest "spur" path from v to target
    4. Combine prefix + spur as a candidate for (i+1)-th path

The best candidate becomes the (i+1)-th shortest path!
```

## Visual: Spur Path Generation

```
Graph:
  0 ──1──► 1 ──1──► 3
  │        │
  3        1
  │        │
  ▼        ▼
  2 ──────2──────► 3

1st shortest path: 0 → 1 → 3 (cost 2)

Generate candidates for 2nd path:
  Spur at 0: Block edge 0→1, find path 0→2→3 (cost 5)
  Spur at 1: Keep 0→1, block 1→3, find 0→1→2→3 (cost 4)

Candidates: [0→2→3 (5), 0→1→2→3 (4)]
2nd shortest: 0→1→2→3 (cost 4)

Generate candidates for 3rd path:
  From 2nd path (0→1→2→3):
    Spur at 0: ... (already have 0→2→3 in candidates)
    Spur at 1: ...
    Spur at 2: Keep 0→1→2, find path to 3 (already at 3)

3rd shortest: 0→2→3 (cost 5)
```

## Algorithm

```
yen_k_shortest(graph, source, target, k):
  // Find first shortest path
  path1 = dijkstra(graph, source, target)
  if path1 is None: return []

  paths = [path1]
  candidates = min-heap

  for i = 1 to k-1:
    prev_path = paths[i-1]

    // Try each node as a spur point
    for j = 0 to len(prev_path) - 2:
      spur_node = prev_path[j]
      root_path = prev_path[0..j]

      // Temporarily modify graph
      for each path P in paths:
        if P[0..j] == root_path:
          block edge P[j] → P[j+1]

      // Block nodes in root path (ensure loopless)
      for node in root_path[0..j-1]:
        block node

      // Find spur path
      spur = dijkstra(modified_graph, spur_node, target)

      if spur exists:
        candidate = root_path + spur
        add candidate to candidates

      // Restore graph

    // Get next shortest path
    if candidates is empty: break
    paths.append(candidates.pop_min())

  return paths
```

## Example Usage

```mbt check
///|
test "yen k shortest paths" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 3, 1L),
    (0, 2, 3L),
    (2, 3, 2L),
    (1, 2, 1L),
  ]
  let paths = @k_shortest_paths_yen.yen_k_shortest_paths(4, edges[:], 0, 3, 3)
  inspect(paths[0].cost, content="2")
  inspect(paths[1].cost, content="4")
  inspect(paths[2].cost, content="5")
}
```

## Algorithm Walkthrough

```
Graph: 4 nodes
Edges: 0→1(1), 1→3(1), 0→2(3), 2→3(2), 1→2(1)

Find 3 shortest paths from 0 to 3:

Step 1: First shortest path (Dijkstra)
  Path: 0 → 1 → 3, Cost: 2

Step 2: Generate candidates from path 0→1→3
  Spur at node 0:
    Block edge 0→1 (used by path 1)
    Find path 0→...→3 without 0→1
    Path: 0 → 2 → 3, Cost: 5
    Candidate: [0→2→3, cost 5]

  Spur at node 1:
    Root: 0 → 1, Block nodes: {0}
    Block edge 1→3 (used by path 1)
    Find path 1→...→3 without 1→3, avoiding node 0
    Path: 1 → 2 → 3, Cost: 3
    Candidate: [0→1→2→3, cost 4]

  Candidates heap: [(0→1→2→3, 4), (0→2→3, 5)]

Step 3: Second shortest = 0→1→2→3 (cost 4)

Step 4: Generate candidates from path 0→1→2→3
  Spur at node 0: Already have 0→2→3
  Spur at node 1:
    Block 1→2 (used), 1→3 already blocked from before
    No valid spur
  Spur at node 2:
    Block 2→3, no other path to 3
    No valid spur

Step 5: Third shortest = 0→2→3 (cost 5)

Result: [(0→1→3, 2), (0→1→2→3, 4), (0→2→3, 5)]
```

## Why Block Edges and Nodes?

```
Block edges with same root path:
  - Prevents finding the same path again
  - Each path P₁...Pᵢ that shares root[0..j] blocks its next edge

Block nodes in root path:
  - Ensures paths are SIMPLE (no repeated vertices)
  - Spur path can't go through nodes already in prefix

Example:
  Path 1: A → B → C → D
  Spur at B with root A → B:
    Block A (in root path)
    Block edge B → C (from path 1)
    Find path B → ... → D not using A or edge B→C
```

## Common Applications

### 1. Route Planning
```
Find alternative routes for navigation.
"Show me 3 different ways to get there."
```

### 2. Network Routing
```
Backup paths for network traffic.
If primary path fails, use 2nd or 3rd shortest.
```

### 3. Transportation
```
Multiple travel options for passengers.
Different tradeoffs (cost, time, transfers).
```

### 4. Game AI
```
NPC pathfinding with variety.
Avoid predictable movement patterns.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| First Dijkstra | O(m + n log n) |
| Each spur search | O(m + n log n) |
| Number of spurs | O(k · n) |
| **Total** | **O(k · n · (m + n log n))** |

## Yen's vs Other K-Shortest Algorithms

| Algorithm | Paths | Time |
|-----------|-------|------|
| Yen's | Simple (loopless) | O(kn(m + n log n)) |
| Eppstein's | May have cycles | O(m + n log n + k) |
| Lazy Yen | Simple (optimized) | Often faster |

**Choose Yen's when**: You need simple paths (no repeated vertices).

## Optimizations

```
1. Lazy candidate generation:
   Don't generate all spur paths immediately.
   Generate on demand when popping from heap.

2. Edge blocking with sets:
   Use hash sets for O(1) edge lookup.

3. Graph restoration:
   Use undo stack instead of copying graph.

4. Bidirectional Dijkstra:
   For each spur search, use bidirectional search.
```

## Implementation Notes

- Store paths as node lists, not edge lists
- Use priority queue for candidates (avoid duplicates)
- Handle case where fewer than k paths exist
- Edges must have non-negative weights (for Dijkstra)
- Block nodes and edges carefully, restore after each spur

## Limitations

```
- Only works for simple (loopless) paths
- Requires non-negative edge weights
- Can be slow for large k or dense graphs
- Memory grows with k (store all paths)

For paths with cycles, consider Eppstein's algorithm.
```

