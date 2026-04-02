# Challenge: SCC (Tarjan)

This package implements **Tarjan's algorithm** for strongly connected
components (SCCs) in a directed graph.

Tarjan runs in **one DFS pass** and assigns component ids as SCCs are completed.

This package provides:

- `scc_tarjan(n, edges)` returning an array `comp` of length `n` where
  `comp[v]` is the component id of node `v`.

---

## Core idea: index, lowlink, and a stack

Each node has:

- `index[v]`: DFS discovery time
- `low[v]`: smallest index reachable from `v` using DFS edges and back edges

During DFS, all active nodes are stored on a stack.

When `low[v] == index[v]`, node `v` is the **root of an SCC**. We pop nodes off
stack until `v` to form one component.

---

## Visual intuition

Example graph:

```
0 -> 1 -> 2
^         |
|         v
+---------+

3 -> 4
```

SCCs:

- `{0,1,2}` is one SCC
- `{4}` and `{3}` are individual SCCs

Tarjan will discover `{0,1,2}` together because their lowlinks collapse to the
same root.

---

## API summary

- Time: `O(n + m)` where `m` is the number of edges
- Space: `O(n + m)` for adjacency lists and recursion stacks

---

## Example 1: One cycle plus a chain

```mbt check
///|
test "scc tarjan cycle" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
  let comp = @challenge_scc_tarjan.scc_tarjan(5, edges[:])
  inspect(comp[0] == comp[1] && comp[1] == comp[2], content="true")
  inspect(comp[3] != comp[4], content="true")
}
```

---

## Example 2: DAG (no cycles)

```mbt check
///|
test "scc tarjan dag" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let comp = @challenge_scc_tarjan.scc_tarjan(4, edges[:])
  inspect(comp, content="[3, 2, 1, 0]")
}
```

Each node becomes its own SCC. The ids reflect the order SCCs are completed.

---

## Example 3: All nodes isolated

```mbt check
///|
test "scc tarjan isolated" {
  let edges : Array[(Int, Int)] = []
  let comp = @challenge_scc_tarjan.scc_tarjan(2, edges[:])
  inspect(comp[0] != comp[1], content="true")
}
```

---

## When to use this algorithm

Use Tarjan when you need:

- SCC decomposition in a **single DFS pass**
- linear time complexity
- compact memory usage

Kosaraju is simpler to explain, while Tarjan is more efficient in practice.

---

## Reference implementation

```mbt nocheck
///| pub fn scc_tarjan(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]
```
