# Maximum Flow (Dinic's Algorithm)

## 1. Problem statement

You have a directed graph where each edge has a **capacity**.
Find the maximum amount of flow that can go from a **source** `s` to a **sink** `t`.

Rules:

- Flow on an edge cannot exceed its capacity.
- For every vertex except `s` and `t`, inflow = outflow.

### Tiny mental model

Think of edges as **pipes** with maximum water capacity.
We want to push as much water as possible from `s` to `t`.

## 2. Why this is hard

A naive approach repeatedly finds any augmenting path and pushes flow.
This can take a very long time depending on the path choices.

Dinic's algorithm makes it fast by:

1. Building a **level graph** with BFS
2. Finding a **blocking flow** in that level graph with DFS

## 3. Residual graph (the core concept)

For each edge `u -> v` with capacity `c` and current flow `f`:

- Residual capacity forward: `c - f` (how much more we can send)
- Residual capacity backward: `f` (how much we can cancel)

Example:

```
Edge: A -> B, capacity 10, flow 7
Residual forward: 3
Residual backward: 7
```

The algorithm only travels through edges with **positive residual**.

### Residual graph visual

```
Original edge:  A --(cap 10)--> B
Current flow:   f = 7

Residual graph:
  A --(3)--> B    (can still send 3 forward)
  B --(7)--> A    (can cancel up to 7)
```

## 4. Level graph (BFS phase)

We do BFS from the source and assign each vertex a level:

```
level[s] = 0
level[v] = level[u] + 1 for any edge u->v with residual > 0
```

Only edges that go **from level d to level d+1** are kept in the level graph.
This guarantees shortest augmenting paths are used in each phase.

This also prevents DFS from wandering sideways or backward in the same phase.

Diagram:

```
Level 0: s
Level 1: A, B
Level 2: t

Only edges that go down one level are allowed in the DFS phase.
```

## 5. Blocking flow (DFS phase)

Within the level graph, DFS pushes flow until:

- All s-t paths are saturated, or
- The sink is unreachable

This is called a **blocking flow**.
Once we have a blocking flow, the shortest path length increases, and we build
another level graph.

### Intuition

Think of each BFS phase as "all shortest paths right now".
DFS tries to saturate all of them, so the next phase must use longer paths.

## 6. Small worked example

Graph:

```
    s
   / \
  3   2
 /     \
A ---1--- B
 \     /
  2   3
   \ /
    t
```

Edge list:

```
s->A (3)
s->B (2)
A->B (1)
A->t (2)
B->t (3)
```

### Phase 1 (BFS levels)

```
level[s]=0
level[A]=1, level[B]=1
level[t]=2 (reachable from both A and B)
```

### Blocking flow

- Path s->A->t, push 2 (A->t saturates)
- Path s->B->t, push 2 (s->B saturates)
- Path s->A->B->t, push 1 (A->B saturates)

Total flow = 5

No more paths in level graph. BFS again shows `t` unreachable.
So max flow = 5.

### Cut check

The cut separating `s` from `t` has capacity 5, so the flow is optimal.

## 7. Why it works (max-flow min-cut)

**Max-Flow Min-Cut Theorem**:

```
Maximum flow value = minimum cut capacity
```

A cut is a partition of vertices into `S` (reachable from source) and `T`.
Cut capacity is the sum of capacities of edges from `S` to `T`.

Dinic stops when no s-t path exists in the residual graph. At that point,
`S` is exactly the set reachable from `s`. The edges from `S` to `T` are
fully saturated, so the flow equals the cut capacity, which proves optimality.

### Simple cut example

```
s -> A (3)
s -> B (2)
A -> t (2)
B -> t (3)

Cut S = {s, A}, T = {B, t}
Edges from S to T: s->B (2), A->t (2) -> cut capacity = 4
Maximum flow cannot exceed 4 (min-cut)
```

## 8. Implementation details in this package

- Each edge stores a **reverse edge index** for O(1) residual updates.
- BFS builds a `level[]` array.
- DFS uses `iter[]` to avoid re-scanning dead ends (Dinic optimization).
- All capacities and flows are `Int64`.

## 9. Example usage (internal)

This package does not export a public API. The examples below mirror the tests
inside `lib/max_flow/max_flow.mbt`, so they are `mbt nocheck`.

```mbt nocheck
///|
test "basic max flow" {
  let mf = MaxFlow::new(4)
  mf.add_edge(0, 1, 3L)
  mf.add_edge(0, 2, 2L)
  mf.add_edge(1, 3, 2L)
  mf.add_edge(2, 3, 3L)
  inspect(mf.max_flow(0, 3), content="4")
}
```

### Example: flow on a small network (diagram)

```
s --3--> A --2--> t
 \       |
  \--2-->B --3--> t

Max flow = 5
```

```mbt nocheck
///|
test "bipartite matching" {
  // Left: 1,2,3  Right: 4,5,6
  let mf = MaxFlow::new(8)
  mf.add_edge(0, 1, 1L)
  mf.add_edge(0, 2, 1L)
  mf.add_edge(0, 3, 1L)
  mf.add_edge(1, 4, 1L)
  mf.add_edge(1, 5, 1L)
  mf.add_edge(2, 5, 1L)
  mf.add_edge(2, 6, 1L)
  mf.add_edge(3, 4, 1L)
  mf.add_edge(4, 7, 1L)
  mf.add_edge(5, 7, 1L)
  mf.add_edge(6, 7, 1L)
  inspect(mf.max_flow(0, 7), content="3")
}
```

## 10. Common applications

- **Bipartite matching** (unit capacities)
- **Project selection** with profits and dependencies
- **Image segmentation** (min-cut)
- **Bandwidth / throughput analysis** in networks

### Another classic: bipartite matching

```
Left:  L1 L2 L3
Right: R1 R2 R3

Edges:
L1 -> R1, R2
L2 -> R2, R3
L3 -> R1

Max matching size = max flow
```

## 11. Complexity

```
General:        O(V^2 * E)
Unit capacity:  O(E * sqrt(V))
```

Why the improvement with unit capacity:

- Each BFS increases shortest path length
- The number of phases is smaller when capacities are 1

## 12. Pitfalls and tips

- Forgetting to add reverse edges breaks the residual graph.
- Using a DFS without iter[] can cause large slowdowns.
- Undirected edges should be modeled as two directed edges.
- Large graphs may still need push-relabel for speed.

### Common beginner mistake

Forgetting reverse edges means you cannot "undo" flow.
Without reverse edges, the residual graph is incorrect and the algorithm fails.

## 13. Summary

Dinic's algorithm is the standard, reliable max-flow algorithm:

- Simple to implement
- Fast for most competitive programming inputs
- Works for matching, min-cut, and many modeling tasks
