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

## 2. Flow network diagram

The network below has 6 nodes: source `s` (node 0), sink `t` (node 5), and
four intermediate nodes A=1, B=2, C=3, D=4.  Numbers on edges are capacities.

```
                10          4
        s(0) --------> A(1) ----> t(5)
         |               |          ^
       10|             2 |          |
         |               v         |10
         v        6      B(2)       |
        C(3) --------> D(4) --------+
```

Edge list:

```
s -> A  cap 10
s -> C  cap 10
A -> t  cap  4
A -> B  cap  2
C -> D  cap  6
B -> t  cap 10
D -> t  cap 10
```

We want to know: how many units can flow from `s` to `t`?

Answer: **13** (limited by min-cut A->t + C->D = 4 + 9 at saturation).

## 3. Residual graph (the core concept)

For each edge `u -> v` with capacity `c` and current flow `f`:

- Residual capacity forward: `c - f` (how much more we can send)
- Residual capacity backward: `f` (how much we can cancel)

Example:

```
Edge: A -> B, capacity 10, flow 7
Residual forward:  3  (still room)
Residual backward: 7  (can undo)
```

The algorithm only travels through edges with **positive residual**.

### Residual graph visual

```
Original edge:   A --(cap 10, flow 7)--> B

Residual graph:
  A --(3)--> B    (can still send 3 forward)
  B --(7)--> A    (can cancel up to 7)
```

Every time we push flow along a path we simultaneously:
1. Decrease the forward residual on each edge by the pushed amount.
2. Increase the backward residual (reverse edge) by the same amount.

This is why Dinic stores a **reverse edge** for every forward edge.

## 4. Step-by-step Edmonds-Karp BFS augmentation

Edmonds-Karp is the simplest correct max-flow algorithm: it is Ford-Fulkerson
where the augmenting path is always chosen by BFS (shortest in hops).

Consider this 4-node graph:

```
        3          2
  s(0) ----> A(1) ----> t(3)
   \                    ^
  2 \                  / 4
     v                /
     B(2) -----------+
```

Edge capacities:

```
s -> A  cap 3
s -> B  cap 2
A -> t  cap 2
B -> t  cap 4
```

### Iteration 1

BFS from `s` finds shortest path `s -> A -> t` (2 hops).

```
Residual capacities before:
  s->A  3   s->B  2   A->t  2   B->t  4

BFS path: s -> A -> t
Bottleneck: min(3, 2) = 2
Push 2 units.

Residual capacities after:
  s->A  1   A->s  2   (forward reduced, backward created)
  A->t  0   t->A  2   (saturated)
  s->B  2   B->t  4   (unchanged)
```

### Iteration 2

BFS from `s` finds next shortest path.  `A->t` is now saturated (residual 0),
so `s -> A -> t` is blocked.  BFS finds `s -> B -> t` (2 hops).

```
BFS path: s -> B -> t
Bottleneck: min(2, 4) = 2
Push 2 units.

Residual capacities after:
  s->B  0   B->s  2
  B->t  2   t->B  2
```

### Iteration 3

BFS from `s` tries again.  `s->A` has residual 1, but `A->t` is 0 and there is
no other forward edge from A.  `s->B` is 0.  Sink `t` is unreachable.

BFS returns no path.  Algorithm halts.

**Total max flow = 2 + 2 = 4.**

This matches the min-cut `{s->A (3 total, 2 used), s->B (2 total, 2 used)}`
with capacity 5, but the actual bottleneck is A->t=2 + B->t used portion...
More precisely, the cut `S={s}`, `T={A,B,t}` has capacity `s->A + s->B = 3+2=5`,
while the cut `S={s,A,B}`, `T={t}` has capacity `A->t + B->t = 2+4=6`.
The tightest cut is `S={s,A}`, `T={B,t}` with `s->B + A->t = 2+2=4`. That is
the min cut, and it equals our max flow of 4.

## 5. Level graph (Dinic's BFS phase)

Dinic improves on Edmonds-Karp by building a **level graph** per phase and
finding a **blocking flow** (saturating all shortest paths at once) before the
next BFS.

We do BFS from the source and assign each vertex a **level**:

```
level[s] = 0
level[v] = level[u] + 1 for any edge u->v with residual > 0
```

Only edges that go **from level d to level d+1** are kept in the level graph.
This guarantees shortest augmenting paths are used in each phase.

Diagram:

```
Level 0:  s(0)
          |  \
          |   \
Level 1: A(1) B(2)
          |    |
Level 2:  t(3)
```

The DFS phase uses only downward edges (level[u]+1 == level[v]).

## 6. Blocking flow (DFS phase)

Within the level graph, DFS pushes flow until:

- All s-t paths are saturated, or
- The sink is unreachable

This is called a **blocking flow**.
Once we have a blocking flow, the shortest path length increases, and we build
another level graph.

The `iter[]` array ("current arc") remembers where DFS left off in each node's
adjacency list, avoiding rescanning dead-end edges.

## 7. Small worked example (Dinic)

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

Total flow after phase 1 = 5.

No more paths in level graph.  BFS again shows `t` unreachable.
So max flow = **5**.

### Cut check

The cut `{s,A,B} | {t}` has capacity `A->t + B->t = 2+3 = 5`, confirming
optimality.

## 8. Why it works (max-flow min-cut)

**Max-Flow Min-Cut Theorem**:

```
Maximum flow value = minimum cut capacity
```

A cut is a partition of vertices into `S` (containing source) and `T`
(containing sink).  Cut capacity is the sum of capacities of edges from `S`
to `T`.

Dinic stops when no s-t path exists in the residual graph.  At that point,
`S` is exactly the set reachable from `s`.  The edges from `S` to `T` are
fully saturated, so the flow equals the cut capacity, proving optimality.

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

## 9. Implementation details in this package

- Each edge stores a **reverse edge index** for O(1) residual updates.
- BFS builds a `level[]` array.
- DFS uses `iter[]` to avoid re-scanning dead ends (current-arc optimization).
- All capacities and flows are `Int64`.
- `FLOW_INF` is `Int64::max_value`, used as the initial "pushed" budget in DFS.
- `min_cut` runs one final BFS after `max_flow` to identify the source-side
  reachable set, then collects saturated crossing edges.

## 10. Example usage (internal)

This package does not export a public API.  The examples below mirror the tests
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

## 11. Common applications

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

Model: add super-source `s` with unit-capacity edges to every left node, and
super-sink `t` with unit-capacity edges from every right node.  Max flow =
maximum matching.

## 12. Complexity

```
General:        O(V^2 * E)
Unit capacity:  O(E * sqrt(V))
```

Why the improvement with unit capacity:

- Each BFS increases shortest path length.
- The number of phases is smaller when capacities are 1.
- After O(sqrt(V)) phases, all remaining paths are long and few remain.

## 13. Pitfalls and tips

- Forgetting to add reverse edges breaks the residual graph.
- Using a DFS without `iter[]` can cause large slowdowns.
- Undirected edges should be modeled as two directed edges with equal capacity,
  or use `add_undirected_edge` which sets both halves as forward edges.
- Large graphs may still need push-relabel for speed.

### Common beginner mistake

Forgetting reverse edges means you cannot "undo" flow.
Without reverse edges, the residual graph is incorrect and the algorithm may
report a sub-optimal flow.

## 14. Summary

Dinic's algorithm is the standard, reliable max-flow algorithm:

- Simple to implement
- Fast for most competitive programming inputs
- Works for matching, min-cut, and many modeling tasks
