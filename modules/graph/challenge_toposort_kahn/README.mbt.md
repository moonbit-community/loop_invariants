# Challenge: Topological Sort (Kahn's Algorithm)

A **topological order** of a directed graph is an ordering of vertices such that
for every edge `u -> v`, `u` appears before `v`.

This is only possible if the graph is a **DAG** (directed acyclic graph).

This package provides:

- `topo_sort(n, edges)` returning `Some(order)` or `None` if there is a cycle
- `is_topo(order, n, edges)` to validate an ordering

---

## Core idea: Kahn's algorithm

Kahn's algorithm uses **indegrees** (number of incoming edges):

1. Compute indegree for every node.
2. Put all nodes with indegree `0` into a queue.
3. Repeatedly pop from the queue:
   - append node to the answer
   - remove its outgoing edges (decrement indegrees)
   - any neighbor that drops to indegree `0` goes into the queue

If you process all nodes, the graph is a DAG and the order is valid. If not,
there is a cycle.

---

## Visual intuition

Graph:

```
0 -> 2 -> 3
 \        ^
  \-> 1 --|
```

Indegrees:

```
0:0  1:1  2:1  3:2
```

Queue starts with `[0]`.

- Pop `0`, add to order.
- Remove edges `0->1` and `0->2`.
- Now indegrees become:

```
1:0  2:0  3:2
```

Queue now `[1,2]`. Continue until all nodes are processed.

---

## API summary

- Time: `O(n + m)` where `m` is the number of edges
- Space: `O(n + m)`

---

## Example 1: DAG

```mbt check
///|
test "toposort kahn basic" {
  let n = 4
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let order_opt = @challenge_toposort_kahn.topo_sort(n, edges)
  guard order_opt is Some(order) else { fail("expected order") }
  inspect(@challenge_toposort_kahn.is_topo(order, n, edges), content="true")
}
```

---

## Example 2: Cycle

```mbt check
///|
test "toposort kahn cycle" {
  let n = 3
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  let order_opt = @challenge_toposort_kahn.topo_sort(n, edges)
  debug_inspect(order_opt, content="None")
}
```

---

## Example 3: Validate a manual order

```mbt check
///|
test "toposort check" {
  let n = 3
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (0, 2)]
  let order : Array[Int] = [0, 2, 1]
  inspect(@challenge_toposort_kahn.is_topo(order, n, edges), content="true")
}
```

---

## When to use this algorithm

Use Kahn's algorithm when you need:

- a topological order of a DAG
- cycle detection in directed graphs
- a simple, iterative approach

If you want a DFS-based approach, use topological sort via DFS instead.

---

## Reference implementation

```mbt nocheck
///| pub fn topo_sort(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]?

///| pub fn is_topo(order : Array[Int], n : Int, edges : ArrayView[(Int, Int)]) -> Bool
```
