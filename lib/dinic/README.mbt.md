# Dinic's Algorithm (Maximum Flow)

## Overview

**Dinic's Algorithm** computes the maximum flow in a directed graph using
level graphs and blocking flows. It improves upon Ford-Fulkerson and
Edmonds-Karp by finding multiple augmenting paths in a single DFS pass.

- **Time**: O(V^2 x E) general, O(E x sqrt(V)) for unit-capacity graphs
- **Space**: O(V + E)

## The Max Flow Problem

Given a directed graph where each edge has a capacity, find the maximum
amount of flow that can be sent from a source vertex `s` to a sink vertex `t`
without exceeding any edge capacity.

```
Flow network with capacities:

        3           2
   S ──────► A ──────► T
   │          \         ▲
 2 │         1 \      3 │
   │             ▼       │
   └──────► B ──────────┘
        2

Edges: S→A(3), S→B(2), A→B(1), A→T(2), B→T(3)

Maximum flow = 5
  Path S→A→T:   2 units  (A→T saturated)
  Path S→A→B→T: 1 unit   (A→B saturated, S→A residual = 0)
  Path S→B→T:   2 units  (S→B saturated)
```

## Flow Network with Flow Values

After computing max flow, each edge shows `flow/capacity`:

```
        2/3         2/2
   S ──────► A ──────► T
   │          \         ▲
 2/2│        1/1\     3/3│
   │               ▼     │
   └──────► B ──────────┘
        2/2

Total flow out of S: 2 + 2 = 4   (but includes A→B→T path)
Total flow into T:  2 + 3 = 5
Max flow = 5
```

## The Key Insight: Layered Graph

Dinic builds a **level graph** using BFS, then finds a **blocking flow**
using DFS. After each blocking flow the distance from S to T strictly
increases, so at most O(V) BFS phases are needed.

```
BFS assigns a level to every reachable vertex:

    Level 0    Level 1    Level 2    Level 3
       │           │          │          │
       S ─────────► A ────────► C ───────► T
       │            │                     ▲
       │            └────────► B ─────────┘
       │                       ▲
       └───────────────────────┘

Rules for the level graph:
  - Only edges that go from level i to level i+1 are kept.
  - Edges between the same level or going backwards are ignored.
  - This guarantees every path in the level graph is a shortest path.
```

## Algorithm Walkthrough (Step by Step)

```
Input graph:
  S →(3)→ A →(2)→ T
  S →(2)→ B →(3)→ T
  A →(1)→ B

────────────────────────────────────────
Phase 1 — BFS level assignment:
────────────────────────────────────────

  Vertex:  S   A   B   T
  Level:   0   1   1   2

  Level graph (only forward edges kept):

    Level 0    Level 1    Level 2
       S ──(3)──► A ──(2)──► T
       └──(2)──► B ──(3)──► T
       (edge A→B is between the same level, so it is dropped)

  DFS blocking flow:
    Attempt S→A→T: push min(3,2) = 2
      A→T is now saturated.
    Attempt S→A→(dead end): iter[A] advanced past T.
    Attempt S→B→T: push min(2,3) = 2
      S→B is now saturated.
    No more paths. Blocking flow = 4.

────────────────────────────────────────
Phase 2 — BFS on residual graph:
────────────────────────────────────────

  Residual capacities after phase 1:
    S→A: 3-2=1,  A→T: 2-2=0 (saturated),
    A→B: 1-0=1,  S→B: 2-2=0 (saturated),
    B→T: 3-2=1
    Back edges: A→S:2, T→A:2, B→S:2, T→B:2

  BFS from S (only positive residual capacity):
    S→A (cap 1): level[A] = 1
    A→B (cap 1): level[B] = 2
    B→T (cap 1): level[T] = 3

  Vertex:  S   A   B   T
  Level:   0   1   2   3

  Level graph:
    Level 0    Level 1    Level 2    Level 3
       S ──(1)──► A ──(1)──► B ──(1)──► T

  DFS blocking flow:
    Attempt S→A→B→T: push min(1,1,1) = 1
      All three edges saturated.
    No more paths. Blocking flow = 1.

────────────────────────────────────────
Phase 3 — BFS on residual graph:
────────────────────────────────────────

  S→A: 1-1=0 (saturated). BFS cannot reach T.
  Algorithm terminates.

Maximum flow = 4 + 1 = 5
```

## Blocking Flow Detail

A blocking flow saturates at least one edge on **every** S-T path in the
level graph, making the level graph "blocked".

```
Level graph before blocking flow:

   S ──(3)──► A ──(2)──► T
   │                      ▲
   └──(2)──► B ──(3)──────┘

DFS with current-arc optimization (iter[] tracks progress):

  Step 1: DFS from S, iter[S]=0 → try edge S→A
    DFS from A, iter[A]=0 → try edge A→T
      Reached T! push = min(3, 2) = 2
    A→T flow: 0→2 (saturated, cap=2)
    S→A flow: 0→2 (remaining cap=1)
    Blocking flow so far: 2

  Step 2: DFS from S, iter[S]=0 → try edge S→A again
    DFS from A, iter[A]=0 → try edge A→T (saturated, skip)
    iter[A] advanced to 1 (no more edges from A in level graph)
    Dead end at A. Return 0.
    iter[S] advanced to 1 → try edge S→B

  Step 3: DFS from S, iter[S]=1 → try edge S→B
    DFS from B, iter[B]=0 → try edge B→T
      Reached T! push = min(2, 3) = 2
    B→T flow: 0→2
    S→B flow: 0→2 (saturated)
    Blocking flow so far: 2+2 = 4

  Step 4: DFS from S, iter[S]=1 → try edge S→B (saturated, skip)
    iter[S] advanced to 2 (no more edges)
    DFS returns 0. Phase complete.

Total blocking flow: 4
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

```mbt check
///|
test "dinic no path" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5), (2, 3, 7)]
  let flow = @dinic.max_flow(4, edges[:], 0, 3)
  inspect(flow, content="0")
}
```

Using the `Dinic` struct directly for more control:

```mbt check
///|
test "dinic struct usage" {
  let d = @dinic.Dinic::new(4)
  d.add_edge(0, 1, 10)
  d.add_edge(0, 2, 10)
  d.add_edge(1, 3, 10)
  d.add_edge(2, 3, 10)
  let flow = d.max_flow(0, 3)
  inspect(flow, content="20")
  // Reuse the struct with a reset
  d.reset()
  let flow2 = d.max_flow(0, 3)
  inspect(flow2, content="20")
}
```

Min-cut from max-flow:

```mbt check
///|
test "dinic min cut example" {
  //   0 --3--> 1 --2--> 3
  //        \         /
  //         2       3
  //          \     /
  //           --> 2
  let d = @dinic.Dinic::new(4)
  d.add_edge(0, 1, 3)
  d.add_edge(0, 2, 2)
  d.add_edge(1, 3, 2)
  d.add_edge(2, 3, 3)
  let flow = d.max_flow(0, 3)
  inspect(flow, content="4")
  let source_side = d.min_cut_source_side(0)
  // Source (0) is always on source side
  inspect(source_side.contains(0), content="true")
  // Sink (3) is always on sink side
  inspect(source_side.contains(3), content="false")
}
```

## The Pseudocode

```
def dinic(graph, s, t):
    max_flow = 0

    loop:
        # Phase: build level graph using BFS
        level = [-1] * n
        level[s] = 0
        queue = [s]
        while queue not empty:
            u = queue.dequeue()
            for each edge (u, v) with residual capacity > 0:
                if level[v] == -1:
                    level[v] = level[u] + 1
                    queue.enqueue(v)

        if level[t] == -1:
            break  # Sink unreachable — done

        # Phase: find blocking flow using DFS with current-arc optimization
        iter = [0] * n  # current edge pointer per vertex
        while True:
            f = dfs(s, t, infinity)
            if f == 0:
                break
            max_flow += f

    return max_flow

def dfs(u, t, pushed):
    if u == t: return pushed
    while iter[u] < len(adj[u]):
        e = adj[u][iter[u]]
        if level[e.to] == level[u]+1 and e.residual > 0:
            d = dfs(e.to, t, min(pushed, e.residual))
            if d > 0:
                e.flow += d
                reverse(e).flow -= d
                return d
        iter[u] += 1
    return 0
```

## Residual Graph and Min Cut

```
After Dinic terminates, the residual graph reveals the min cut:

  Original edges with flow/capacity:

    S ──(2/3)──► A ──(2/2)──► T
    │             │             ▲
    │            (1/1)          │
    │             ▼             │
    └──(2/2)──► B ──(3/3)──────┘

  S-side (reachable from S in residual graph): {S}
    S→A has residual 1 but A→T is saturated (residual 0), so A is NOT
    reachable beyond; however A itself is reachable.
    Let's trace: S→A (residual 1), A→B (residual 0, saturated),
    so B is unreachable. A is reachable.
    A→T (residual 0, saturated): T unreachable.

  S-side = {S, A}   T-side = {B, T}

  Min-cut edges (S-side → T-side, saturated):
    A→T: capacity 2   (saturated)
    S→B: capacity 2   (saturated)

  Min-cut capacity = 2 + 2 = 4 = Max flow  (Max-flow Min-cut theorem)
```

## Common Applications

### 1. Network Bandwidth
```
Maximize data throughput from a server to clients.
Edges represent network links; capacities represent bandwidth limits.
```

### 2. Bipartite Matching
```
Add a super-source S connected to all left vertices (cap 1),
and a super-sink T connected from all right vertices (cap 1).
All bipartite edges get capacity 1.
Max flow = maximum matching size.
```

### 3. Project Selection
```
Each project has a profit; each resource has a cost.
Projects depend on resources. Model as min-cut:
  Source → project node (profit)
  Resource node → sink  (cost)
  Project → resource    (infinity, for dependency)
Max profit = total profit - min cut.
```

### 4. Image Segmentation
```
Pixels are nodes; neighboring pixel pairs are edges with
weights based on color similarity.
Min cut separates foreground from background with minimum boundary cost.
```

## Complexity Analysis

| Graph Type      | Time Complexity |
|-----------------|-----------------|
| General         | O(V^2 * E)      |
| Unit capacity   | O(E * sqrt(V))  |
| Bipartite match | O(E * sqrt(V))  |

| Algorithm      | Time           | Best For                    |
|----------------|----------------|-----------------------------|
| Dinic          | O(V^2 * E)     | General, simple to implement|
| Ford-Fulkerson | O(E * maxflow) | Very small capacities       |
| Edmonds-Karp   | O(V * E^2)     | Dense graphs, simple code   |
| Push-Relabel   | O(V^2 * E)     | Very dense graphs           |
| HLPP           | O(V^2 * sqrt(E))| Fastest known in practice  |

## Implementation Notes

- Use an adjacency list with each edge storing the index of its reverse edge.
- The "current-arc" optimization (`iter[]`) avoids re-examining dead edges
  within a single blocking-flow phase, giving O(VE) per phase.
- Reset `iter[]` at the start of each BFS phase, not between DFS calls.
- Reverse edges start with capacity 0; negative flow on them represents
  flow cancellation (equivalent to residual capacity on the reverse direction).
- `DINIC_INF` is used as the initial `pushed` argument to DFS; it must be
  larger than any possible flow value.
