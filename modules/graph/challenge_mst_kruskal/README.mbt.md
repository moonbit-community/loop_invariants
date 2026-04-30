# Challenge: Minimum Spanning Tree (Kruskal)

A **minimum spanning tree (MST)** connects all vertices of a weighted, undirected
graph with the smallest possible total edge weight.

Kruskal's algorithm builds the MST by sorting edges and adding them if they do
not create a cycle.

This package provides:

```
mst_weight(n, edges) -> Int?
```

It returns `Some(total_weight)` if the graph is connected, otherwise `None`.

---

## Problem restatement (plain words)

You have `n` vertices (numbered `0..n-1`) and weighted edges.
Find the smallest total weight that still connects every vertex.

If the graph is disconnected, an MST does not exist.

---

## Key idea of Kruskal

1) **Sort edges by weight** (smallest first).
2) Start with an empty set of edges.
3) Scan edges in sorted order:
   - Add an edge if it **connects two different components**.
   - Skip it if it would create a cycle.
4) Stop when you have `n - 1` edges.

To check if two vertices are already connected, we use **DSU (Union-Find)**.

---

## Union-Find in one paragraph

A DSU maintains a set of disjoint components.

- `find(x)` returns the representative (root) of `x`'s component.
- `union(a, b)` merges two components if they are different.

If `find(a) == find(b)`, then `a` and `b` are already connected, and adding the
edge would form a cycle.

This implementation uses **union by size** (smaller tree attaches to larger).

---

## Worked example (step by step)

Graph with 4 vertices:

```
0 --(1)-- 1
| \       |
|  (4)    (3)
|    \    |
(2)   2 -- 3
     (5)
```

Edges list (u, v, w):

```
(0,1,1), (0,2,2), (1,3,3), (0,3,4), (2,3,5)
```

Sorted by weight:

```
(0,1,1), (0,2,2), (1,3,3), (0,3,4), (2,3,5)
```

Now pick edges in order:

- Add (0,1,1) -> connects 0 and 1
- Add (0,2,2) -> connects 2 into the component
- Add (1,3,3) -> connects 3 into the component

We already have `n - 1 = 3` edges, so we stop.

Total weight = `1 + 2 + 3 = 6`.

---

## Why sorting works

The MST must contain the **cheapest available edge** that connects two different
components (cut property). Sorting ensures we always consider cheapest edges
first, and DSU ensures we only take those that do not form a cycle.

---

## Reference implementation

```mbt nocheck
///| pub fn mst_weight(n : Int, edges : ArrayView[(Int, Int, Int)]) -> Int? { ... }
```

The implementation is in `challenge_mst_kruskal.mbt`.

---

## Tests and examples

### Example from the walkthrough

```mbt check
///|
test "kruskal basic" {
  let n = 4
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (0, 2, 2),
    (1, 3, 3),
    (0, 3, 4),
    (2, 3, 5),
  ]
  let ans = @challenge_mst_kruskal.mst_weight(n, edges)
  debug_inspect(ans, content="Some(6)")
}
```

### Disconnected graph

```mbt check
///|
test "kruskal disconnected" {
  let n = 4
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (2, 3, 1)]
  let ans = @challenge_mst_kruskal.mst_weight(n, edges)
  debug_inspect(ans, content="None")
}
```

### Multiple equal-weight edges

```mbt check
///|
test "kruskal equal weights" {
  let n = 3
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (0, 2, 1)]
  let ans = @challenge_mst_kruskal.mst_weight(n, edges)
  debug_inspect(ans, content="Some(2)")
}
```

### Single vertex

```mbt check
///|
test "kruskal single" {
  let n = 1
  let edges : Array[(Int, Int, Int)] = []
  let ans = @challenge_mst_kruskal.mst_weight(n, edges)
  debug_inspect(ans, content="Some(0)")
}
```

### Ignore invalid edges (out of range vertices)

```mbt check
///|
test "kruskal ignores invalid" {
  let n = 3
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 2),
    (1, 2, 1),
    (2, 3, 1),
    (-1, 2, 5),
  ]
  let ans = @challenge_mst_kruskal.mst_weight(n, edges)
  debug_inspect(ans, content="Some(3)")
}
```

---

## Complexity

Let `m = edges.length()` and `n = number of vertices`.

- Sorting edges: `O(m log m)`
- DSU operations: about `O(m log n)` with union by size
- Total: `O(m log m)` dominates

Memory usage is `O(n)` for DSU plus `O(m)` for edge sorting.

---

## Takeaways

- Kruskal builds an MST by **sorting edges** and **skipping cycles**.
- DSU makes cycle checks fast.
- If the graph is disconnected, no MST exists (`None`).
