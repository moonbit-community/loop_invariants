# Maximum Flow (Dinic's Algorithm)

## Overview

**Maximum Flow** finds the maximum amount that can flow from source to sink
through a network with edge capacities. This implementation uses **Dinic's algorithm**.

- **Time**: O(V²E) general, O(E√V) for unit capacity/bipartite
- **Space**: O(V + E)

## The Problem

```
Given a directed graph with edge capacities:

        10          10
    s ───────> A ───────> t
    │         ↑│         ↑
  10│       2 ││9        │10
    │         │↓         │
    └───────> B ───────>─┘
        10          10

Find: Maximum flow from s to t
Answer: 19 (bottleneck limits flow)
```

## How Dinic's Algorithm Works

### Step 1: Build Level Graph (BFS)

Assign levels to vertices by distance from source:

```
Level 0:  s
Level 1:  A, B
Level 2:  t

Level graph only uses edges going to next level.
This ensures we find shortest augmenting paths first.
```

### Step 2: Find Blocking Flow (DFS)

Repeatedly find augmenting paths in the level graph:

```
Phase 1:
  Path s→A→t: push 10
  Path s→B→t: push 10
  Total flow: 20? No, let's be more careful...

Actually:
  s→A: capacity 10, s→B: capacity 10
  A→t: capacity 10, B→t: capacity 10

  But there might be bottlenecks...
```

### Step 3: Repeat

Rebuild level graph and repeat until no path exists.

## Visual Walkthrough

```
Initial:
         10          10
    s ────────> A ────────> t
    │          ↑│          ↑
  10│        2 ││9         │10
    │          │↓          │
    └────────> B ─────────>┘
         10          10

After Phase 1 (level graph with paths s→A→t, s→B→t):
  Push 10 through s→A→t
  Push 9 through s→B→A→t (using A→B backward = 2, limited by B→A)

Wait, let me recalculate...

Simpler example:
         1
    s ────────> A
    │          ↓
    │1         │1
    │          ↓
    └────────> B ────────> t
                    1

Phase 1: BFS finds level 0=s, level 1=A,B, level 2=t
  DFS: s→A→t? No edge A→t
  DFS: s→B→t? Push 1
  Flow = 1

Phase 2: BFS from residual graph
  s→A still has capacity 1
  A→B has capacity 1 (in level graph)
  B→t saturated, but B→s has residual 1 (reverse)
  No path to t in level graph
  Done! Max flow = 1
```

## Residual Graph

For each edge, track residual capacity:

```
Original edge: u → v with capacity c, flow f
  Residual u → v: c - f  (remaining capacity)
  Residual v → u: f      (can "undo" flow)

Example:
  Edge A→B capacity 10, flow 7
  Residual A→B: 3 (can push 3 more)
  Residual B→A: 7 (can cancel 7 units)
```

## Why It Works: Max-Flow Min-Cut Theorem

**Theorem**: Maximum flow = Minimum cut capacity

```
A cut separates source from sink:

    s ─── A               Cut edges: s→B, A→t
    │     │               Capacity: 10 + 10 = 20
    B ─── t

The algorithm terminates when no augmenting path exists,
which happens exactly when flow equals minimum cut.
```

## Common Applications

### 1. Bipartite Matching

```
Workers: {A, B, C}    Jobs: {1, 2, 3}
Edges show which worker can do which job

        A ─── 1
       /│     │\
Source  │     │  Sink
       \│     │/
        B ─── 2
       /      │
      C ───── 3

Max flow = Maximum matching
```

### 2. Image Segmentation

```
Pixels connected to source = foreground
Pixels connected to sink = background
Edge weights = similarity between pixels

Min cut separates foreground from background!
```

### 3. Network Reliability

```
Given network with link capacities,
max flow = maximum bandwidth between two nodes
min cut = bottleneck links to target
```

### 4. Project Selection

```
Projects with dependencies and profits:
- Connect profitable projects to source
- Connect costly projects to sink
- Add dependency edges

Max flow helps find optimal project set
```

## Complexity Analysis

| Graph Type | Time Complexity | Example |
|------------|-----------------|---------|
| General | O(V²E) | Dense graphs |
| Unit capacity | O(E√V) | Unweighted |
| Bipartite | O(E√V) | Matching |
| Unit network | O(E√E) | Special structure |

### Why O(V²E)?

```
- At most O(V) phases (shortest path increases each phase)
- Each phase: O(VE) for blocking flow
- Total: O(V²E)

For unit capacity:
- At most O(√V) phases
- Total: O(E√V)
```

## Algorithm Comparison

| Algorithm | Time | Best For |
|-----------|------|----------|
| **Dinic** | O(V²E) | General, bipartite |
| Ford-Fulkerson | O(E × maxflow) | Small flows |
| Edmonds-Karp | O(VE²) | BFS-based |
| Push-Relabel | O(V²E) or O(V³) | Dense graphs |
| HLPP | O(V²√E) | Very large graphs |

## Min-Cut Extraction

After computing max flow, find min cut:

```
1. Run BFS on residual graph from source
2. Mark all reachable vertices
3. Cut edges go from reachable to unreachable

       s ─(10)─> A ─(0)─> t    (saturated)
       │         ↑
      (5)       (5)
       ↓         │
       B ─(10)─> C

Reachable from s: {s, B, C}
Cut edges: A→t (saturated)
Cut capacity = max flow
```

## Implementation Tips

- Store edges with reverse pointers for O(1) residual updates
- Use `iter` array for dead-end pruning in DFS (Dinic optimization)
- Level graph prevents infinite loops
- Handle parallel edges by summing capacities

