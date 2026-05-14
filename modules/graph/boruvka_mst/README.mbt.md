# Borůvka's Minimum Spanning Tree

## Overview

**Borůvka 1926** is the *original* minimum-spanning-tree algorithm,
predating Prim (1957) and Kruskal (1956) by three decades. Its key
property is that each connected component picks its cheapest outgoing
edge **independently** — making it the algorithm of choice for
**parallel** and **distributed** MST.

- **Time**: `O(m log n)` sequential
- **Space**: `O(n + m)`
- **Signatures**:
  - `mst(n, edges) -> Array[Int]` — selected edge indices
  - `mst_weight(n, edges) -> Int` — total weight

For disconnected inputs the result is a minimum spanning **forest**.

---

## The algorithm

```
while more than one component:
  for each component C, find cheapest edge (u, v, w) with u ∈ C, v ∉ C
  add every such edge to MST, merging components atomically
```

The key fact (the **cut property**): the cheapest edge crossing any
cut is in every MST. Each "cheapest outgoing edge per component" is
exactly such a crossing edge, so all chosen edges are MST edges.

Each phase merges every component with at least one other, so the
number of components at least halves per phase. With `n` initial
components, the algorithm finishes in `O(log n)` phases.

---

## The invariant

> After completing phase `k`, the chosen edges form a subgraph of
> some MST, and the number of components has at most halved since the
> start of phase `k`.

---

## Why parallel-friendly

Each component computes its cheapest outgoing edge **independently**.
This step parallelises trivially across `p` processors, scanning each
edge once per phase. PRAM and message-passing variants achieve:

| Model | Time |
|---|---|
| PRAM EREW | `O(log² n)` |
| Filter-Borůvka (Cycle Property) | `O(m α(m, n))` sequential |
| GPU Borůvka | `O(log n)` per phase on `p ≈ m` cores |

This is in stark contrast to Prim and Kruskal, which are inherently
sequential due to their global priority queue / sorted edge order.

---

## Reference implementation

```
pub fn mst(n : Int, edges : Array[(Int, Int, Int)]) -> Array[Int]
pub fn mst_weight(n : Int, edges : Array[(Int, Int, Int)]) -> Int
```

`edges[i] = (u, v, w)` is an undirected edge of weight `w`. The
function uses union-find with path compression and union-by-size.

Tie-breaking: when two edges share weight, the lower-indexed edge
wins (so the algorithm is deterministic).

---

## Tests and examples

```mbt check
///|
test "boruvka triangle" {
  // Triangle 0-1 (1), 1-2 (2), 0-2 (3). MST drops heaviest, total = 3.
  debug_inspect(
    @boruvka_mst.mst_weight(3, [(0, 1, 1), (1, 2, 2), (0, 2, 3)]),
    content="3",
  )
}
```

```mbt check
///|
test "boruvka 4-vertex example" {
  // CLRS example.
  let n = 4
  let edges = [(0, 1, 10), (0, 2, 6), (0, 3, 5), (1, 3, 15), (2, 3, 4)]
  // MST: 2-3 (4), 0-3 (5), 0-1 (10) -> weight 19
  debug_inspect(@boruvka_mst.mst_weight(n, edges), content="19")
}
```

```mbt check
///|
test "boruvka disconnected gives forest" {
  // Two components: {0,1} and {2,3}. MSF total = 1 + 3 = 4
  debug_inspect(@boruvka_mst.mst_weight(4, [(0, 1, 1), (2, 3, 3)]), content="4")
}
```

---

## Complexity

| Phase | Cost |
|---|---|
| Scan edges to find cheapest per component | `O(m)` |
| Add edges and merge | `O(m α(n))` |
| Total per phase | `O(m)` |
| Number of phases | `O(log n)` |
| **Total** | `O(m log n)` |

In practice the sequential constant factor is competitive with
Kruskal and Prim, and the algorithm is **embarrassingly parallel**
across phases.

---

## When to choose Borůvka

| Concern | Pick |
|---|---|
| Small dense graph, single core | Prim with binary heap |
| Sparse graph, single core | Kruskal with sorted edges |
| Parallel / distributed setting | **Borůvka** |
| Streaming / external memory | **Borůvka** (one pass per phase) |
| GPU implementation | **Borůvka** |

---

## Pitfalls

- **Tie-breaking determinism**. If two edges have the same weight,
  both could plausibly be the "cheapest outgoing edge" for two
  components, leading to a cycle. Fix by tie-breaking on a unique edge
  index (this package uses the input position).
- **Disconnected graphs**. The algorithm naturally produces a spanning
  forest; weight equals sum of MST weights per component.
- **Multigraphs**. Parallel edges are handled correctly — the lightest
  is picked.
- **Self-loops**. The implementation requires `u != v` for each edge.
  Filter self-loops out before calling.

---

## Related concepts

```
Borůvka MST (this)        O(m log n) parallel-friendly, 1926
Prim's algorithm          O(m + n log n) with Fibonacci heaps, 1957
Kruskal's algorithm       O(m log m) via sorted edges, 1956
Reverse-delete            O(m log² n), historical
Chazelle's MST            O(m α(m, n)) deterministic, 2000
Karger-Klein-Tarjan       O(m) expected, randomised, 1995
```
