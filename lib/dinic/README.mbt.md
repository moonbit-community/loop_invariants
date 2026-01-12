# Dinic's Algorithm (Maximum Flow)

## Overview

**Dinic's Algorithm** computes the maximum flow in a directed graph using
level graphs and blocking flows. It improves upon Ford-Fulkerson by finding
multiple augmenting paths efficiently.

- **Time**: O(V² × E) general, O(E × √V) for unit graphs
- **Space**: O(V + E)

## The Max Flow Problem

```
Find maximum flow from source s to sink t
respecting edge capacities.

Graph with capacities:
    ┌──3──→ B ──2──┐
    │       ↓      ↓
    S ──2──→ C ──3──→ T
    │       ↑      ↑
    └──3──→ D ──4──┘

Maximum flow = 5
  Path S→B→T: 2 units
  Path S→D→T: 3 units
```

## The Key Insight

```
Build level graph using BFS from source.
Then find blocking flow using DFS.
Repeat until no path to sink exists.

Level Graph: Only edges going from level i to level i+1

Original:                Level Graph (iteration 1):
    B                         B (level 1)
   ↗ ↘                       ↗ ↘
  S → C → T      →         S → C → T
   ↘ ↗                       ↘
    D                         D (level 1)

Level ensures we only use shortest paths!
```

## Algorithm Walkthrough

```
Graph:
  S →(3)→ A →(2)→ T
  S →(2)→ B →(3)→ T
  A →(1)→ B

Iteration 1:
  BFS levels: S=0, A=1, B=1, T=2

  DFS blocking flow:
    S→A→T: push 2 (limited by A→T)
    S→B→T: push 2 (limited by S→B)

  Total pushed: 4

Iteration 2:
  BFS from S with residual capacities:
    S→A: 1 remaining
    A→B: 1 remaining
    B→T: 1 remaining

  Levels: S=0, A=1, B=2, T=3

  DFS blocking flow:
    S→A→B→T: push 1

  Total pushed: 1

Iteration 3:
  BFS cannot reach T → done!

Maximum flow = 4 + 1 = 5
```

## Visual: Level Graph Construction

```
BFS assigns levels based on shortest path from source:

        level 0    level 1    level 2    level 3
           │          │          │          │
           S ────────→ A ─┬─────→ C ───────→ T
           │          │  │       ↑          ↑
           │          │  └──────→ B ────────┘
           │          ↓          │
           └─────────→ D ────────┘

Only edges going forward (from level i to i+1) are kept.
This prevents cycles and ensures shortest paths.
```

## Blocking Flow

```
A blocking flow saturates at least one edge on every
s-t path in the level graph.

Level graph:
  S →(3)→ A →(2)→ T
    └(2)→ B →(3)→┘

DFS from S:
  1. Try S→A→T: flow = min(3, 2) = 2
     A→T saturated, backtrack to S
  2. Try S→B→T: flow = min(2, 3) = 2
     S→B saturated, done

Blocking flow total: 4

After this, we rebuild the level graph with residuals.
```

## Example Usage

```mbt check
///|
test "dinic max flow example" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 3),
    (0, 2, 2),
    (1, 2, 1),
    (1, 3, 2),
    (2, 3, 4),
  ]
  let flow = @dinic.max_flow(4, edges[:], 0, 3)
  inspect(flow, content="5")
}
```

## The Algorithm

```
def dinic(graph, s, t):
    max_flow = 0

    while True:
        # Build level graph using BFS
        level = [-1] * n
        level[s] = 0
        queue = [s]

        while queue:
            u = queue.pop(0)
            for v in neighbors(u):
                if capacity[u][v] > 0 and level[v] < 0:
                    level[v] = level[u] + 1
                    queue.append(v)

        if level[t] < 0:
            break  # No path to sink

        # Find blocking flow using DFS
        while True:
            flow = dfs(s, t, infinity, level)
            if flow == 0:
                break
            max_flow += flow

    return max_flow
```

## Common Applications

### 1. Network Bandwidth
```
Maximize data flow from server to clients.
Edges = links, capacities = bandwidth.
```

### 2. Bipartite Matching
```
Add source connected to left side,
sink connected to right side.
Max flow = maximum matching size.
```

### 3. Project Selection
```
Select projects with dependencies.
Model as min-cut to maximize profit.
```

### 4. Image Segmentation
```
Pixels are nodes, adjacencies are edges.
Min-cut separates foreground from background.
```

## Why O(V² E)?

```
Key insight: Each BFS phase increases the shortest
s-t path length by at least 1.

- Maximum phases: O(V) (path length ≤ V)
- Work per phase: O(VE) for blocking flow
- Total: O(V² E)

For unit capacity graphs (like bipartite matching):
- Phases: O(√V)
- Total: O(E √V)
```

## Complexity Analysis

| Graph Type | Time Complexity |
|------------|-----------------|
| General | O(V² E) |
| Unit capacity | O(E √V) |
| Unit network | O(E √V) |

## Max Flow Algorithms Comparison

| Algorithm | Time | Best For |
|-----------|------|----------|
| **Dinic** | O(V²E) | General, elegant |
| Ford-Fulkerson | O(E × max_flow) | Small capacities |
| Edmonds-Karp | O(VE²) | Dense graphs |
| Push-Relabel | O(V²E) or O(V³) | Very dense graphs |
| HLPP | O(V² √E) | Fastest in practice |

**Choose Dinic when**: You want a good balance of simplicity and efficiency.

## Min-Cut from Max-Flow

```
After Dinic terminates:
- S-side: nodes reachable from s in residual graph
- T-side: all other nodes
- Min-cut edges: saturated edges from S-side to T-side

    S ───(0/3)──→ A ───(2/2)──→ T
      \                        ↗
       (2/2)──→ B ──(2/3)────┘

Saturated edges crossing cut: S→B, A→T
Min-cut capacity = 2 + 2 = 4 = Max flow
```

## Implementation Notes

- Use adjacency list with reverse edge pointers
- Store edge indices, not endpoints, for residual updates
- Use "current arc" optimization: skip saturated edges in DFS
- Reset current arc array at start of each BFS phase
- Handle multiple edges between same nodes by summing capacities

