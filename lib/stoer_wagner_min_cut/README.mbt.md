# Stoer-Wagner Global Minimum Cut

## Overview

**Stoer-Wagner** finds the **global minimum cut** of an undirected weighted graph:
the minimum total weight of edges to remove to disconnect the graph into two
non-empty parts. Unlike s-t min cut, no source/sink is specified.

- **Time**: O(V³) or O(V·E + V² log V) with heaps
- **Space**: O(V²)
- **Key Feature**: Finds minimum cut without specifying terminals

## The Key Insight

```
Problem: Find minimum cut separating ANY two vertices

Naive: Try all O(V²) pairs as s-t cuts → Too slow!

Stoer-Wagner insight:
  One clever "phase" identifies a valid cut candidate.
  Phase finds vertices s and t where cut({t}, V-{t})
  has the same weight as min s-t cut!

Maximum Adjacency Search:
  Greedily grow a set A by always adding the vertex
  most strongly connected to A.

  Last vertex added = t
  Second-to-last = s

  Theorem: The cut isolating t equals the min s-t cut!

After each phase:
  Record cut weight, then CONTRACT s and t.
  Repeat until only 1 vertex remains.
  Return minimum cut found across all phases.
```

## Visual: Maximum Adjacency Search

```
Graph:
    1
  ┌───┐
  │   │
 2│   │2
  │   │
  A───B───C
    2   1

Start: A = {A}, candidates = {B, C}

Step 1: Which vertex has max weight to A?
  w(A, B) = 2
  w(A, C) = 0 (no direct edge)
  Add B: A = {A, B}

Step 2: Which vertex has max weight to A?
  w(A∪B, C) = 2 + 1 = 3
  Add C: A = {A, B, C}

Order: A, B, C
s = B (second to last)
t = C (last)

Cut weight for {C}: edges from C to rest
  = edge(B,C) + edge(A,C) = 1 + 0 = 1?

Wait, let me reconsider the graph...

Actually w[t] tracks total weight to current A.
When t is added, w[t] = cut({t}, rest).
```

## The Algorithm

```
stoer_wagner(n, edges):
  // Build adjacency matrix
  adj = n×n matrix of edge weights

  best_cut = infinity
  best_partition = None

  // V-1 phases (contracting one vertex each time)
  for phase in 1..n-1:
    // Maximum Adjacency Search
    A = {arbitrary start vertex}
    w = [0] * n  // weight to set A

    for i in 1..n-|contracted|:
      // Find vertex with max weight to A
      z = vertex not in A with maximum w[z]

      if i == n-|contracted| - 1:
        s = z  // second to last
      if i == n-|contracted|:
        t = z  // last vertex
        // Cut weight = w[t]
        if w[t] < best_cut:
          best_cut = w[t]
          best_partition = current_side(t)

      // Add z to A, update weights
      A.add(z)
      for each neighbor u of z:
        if u not in A:
          w[u] += adj[z][u]

    // Contract s and t
    merge(s, t)  // combine edges

  return best_cut, best_partition
```

## Example Usage

```mbt check
///|
test "stoer wagner cycle" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 1L),
    (2, 3, 1L),
    (3, 0, 1L),
  ]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(4, edges[:]).unwrap()
  inspect(result.weight, content="2")
}
```

```mbt check
///|
test "stoer wagner disconnected" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(3, edges[:]).unwrap()
  inspect(result.weight, content="0")
}
```

```mbt check
///|
test "stoer wagner weighted" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 5L),
    (1, 2, 3L),
    (0, 2, 2L),
  ]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(3, edges[:]).unwrap()
  inspect(result.weight, content="5")
}
```

## Algorithm Walkthrough

```
Graph: 4-cycle with unit weights
  0 ─1─ 1
  │     │
  1     1
  │     │
  3 ─1─ 2

Phase 1: Maximum Adjacency Search
  Start: A = {0}, w = [0, 1, 0, 1]

  Add max(w): vertex 1 or 3 (both have w=1)
  Say we pick 1: A = {0, 1}, w = [0, -, 1, 1]

  Add max(w): vertex 2 or 3 (both have w=1)
  Say we pick 2: A = {0, 1, 2}, w = [0, -, -, 2]

  Add last: vertex 3, w[3] = 2

  s = 2, t = 3
  Cut {3} from rest has weight 2.

  Contract 2 and 3 into supernode [2,3].

Phase 2: Graph now has 3 nodes: 0, 1, [2,3]
  Edge weights: 0-1: 1, 1-[2,3]: 1, 0-[2,3]: 1

  Start: A = {0}, w = [0, 1, 1]
  Add 1: A = {0, 1}, w = [0, -, 2]
  Add [2,3]: cut weight = 2

  s = 1, t = [2,3], cut = 2
  Contract into [1,2,3].

Phase 3: Graph has 2 nodes: 0, [1,2,3]
  Edge weight: 0-[1,2,3] = 1 + 1 = 2

  Cut weight = 2

Minimum across all phases: 2

The global min cut separates graph into two pairs.
```

## Why It Works

```
Key Theorem:
  After Maximum Adjacency Search, let s,t be the last two vertices.
  Then: cut({t}, V-{t}) equals the minimum s-t cut.

Intuition:
  t is the vertex "most attached" to everything else.
  The cut separating just t is as small as any s-t cut.

Proof idea:
  Consider any s-t cut. The weight crossing the cut
  is at least the weight we accumulated for t,
  because we always chose vertices with maximum connection.

By trying all pairs (implicitly via contraction):
  We eventually find the global minimum cut pair.
```

## Common Applications

### 1. Network Reliability
```
Find weakest link in network.
Minimum edges to disconnect any part.
```

### 2. Image Segmentation
```
Graph cuts for foreground/background separation.
Each pixel = vertex, similarity = edge weight.
```

### 3. Clustering
```
Minimum cut gives natural cluster boundary.
Low-weight cut = weak connection between groups.
```

### 4. VLSI Design
```
Partition circuits to minimize cross-chip wires.
Edge weights = wire costs.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| One phase | O(V²) | V iterations, V updates each |
| Number of phases | O(V) | Contract one vertex each |
| **Total (simple)** | **O(V³)** | Dense representation |
| **Total (with heap)** | **O(VE + V² log V)** | Sparse optimization |

## Stoer-Wagner vs Other Min Cut Algorithms

| Algorithm | Type | Time | Notes |
|-----------|------|------|-------|
| Stoer-Wagner | Global | O(V³) | Deterministic |
| Karger's | Global | O(E) per trial | Randomized, Monte Carlo |
| Max-flow based | s-t cut | O(V²E) | Need source/sink |

**Choose Stoer-Wagner when**:
- You need the global minimum cut (no specified terminals)
- Deterministic result required
- Graph is not too large

## Contraction Details

```
Contracting s and t into supernode st:
  1. Combine vertices: st represents both s and t
  2. Merge edges: adj[st][v] = adj[s][v] + adj[t][v]
  3. Handle self-loop: remove edge between s and t
  4. Update bookkeeping for partition tracking

After contraction:
  Graph has one fewer vertex
  Any cut in contracted graph corresponds to
  a valid cut in original graph
```

## Implementation Notes

- Use adjacency matrix for dense graphs
- Track which original vertices each supernode contains
- Initialize with all edge weights, not just connected vertices
- Handle disconnected graphs (cut weight = 0)
- Returns one side of the cut as vertex list

## Edge Cases

```
n <= 1: Return None (no cut possible)
No edges: Cut weight = 0, any partition works
Disconnected: Some phase will have cut weight 0
All same weight: Multiple minimum cuts may exist
```

