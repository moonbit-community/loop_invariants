# Challenge: SCC (Kosaraju)

This package implements **Kosaraju's algorithm** to compute **strongly
connected components (SCCs)** in a directed graph.

An SCC is a maximal set of nodes where every node can reach every other node in
the set.

This package provides:

- `scc_kosaraju(n, edges)` returning an array `comp` of length `n` where
  `comp[v]` is the component id of node `v`.

---

## Core idea (two DFS passes)

Kosaraju's algorithm uses two passes:

1. **DFS on the original graph**, recording nodes in finishing order.
2. **DFS on the reversed graph**, visiting nodes in reverse finishing order.
   Each DFS tree in this pass is one SCC.

Why it works: The reverse finishing order ensures we always start from a node in
an SCC with no outgoing edge to an unvisited SCC in the reversed graph.

---

## Visual intuition

Example graph:

```
0 <-> 1 -> 2 <-> 3
```

- `{0,1}` is one SCC
- `{2,3}` is another SCC

The algorithm discovers these by finishing order in the first pass, then
collecting SCCs in the second pass.

---

## API summary

- Time: `O(n + m)` where `m` is the number of edges
- Space: `O(n + m)` for adjacency lists and recursion stacks

---

## Example 1: Two SCCs

```mbt check
///|
test "scc kosaraju basic" {
  let n = 4
  let edges = [(0, 1), (1, 0), (1, 2), (2, 3), (3, 2)]
  let comp = @challenge_scc_kosaraju.scc_kosaraju(n, edges[:])
  inspect(comp, content="[0, 0, 1, 1]")
}
```

Component ids depend on traversal order, but nodes in the same SCC always share
an id.

---

## Example 2: Single SCC

```mbt check
///|
test "scc kosaraju single" {
  let n = 3
  let edges = [(0, 1), (1, 2), (2, 0)]
  let comp = @challenge_scc_kosaraju.scc_kosaraju(n, edges[:])
  inspect(comp, content="[0, 0, 0]")
}
```

---

## Example 3: No cycles

```mbt check
///|
test "scc kosaraju dag" {
  let n = 4
  let edges = [(0, 1), (1, 2), (2, 3)]
  let comp = @challenge_scc_kosaraju.scc_kosaraju(n, edges[:])
  inspect(comp, content="[0, 1, 2, 3]")
}
```

In a DAG, every node is its own SCC. The ids here reflect finishing order.

---

## When to use this algorithm

Use Kosaraju when you need:

- SCC decomposition
- linear time complexity
- a simple, well-known approach

If you need SCCs plus extra metadata or online updates, consider other
algorithms (e.g., Tarjan for one-pass SCC).

---

## Reference implementation

```mbt
///| pub fn scc_kosaraju(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]
```
