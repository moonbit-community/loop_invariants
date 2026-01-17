# Challenge: Minimum Spanning Tree (Prim, O(n^2))

Prim's algorithm grows a minimum spanning tree (MST) **one vertex at a time**.
It is especially simple for dense graphs when using the `O(n^2)` version.

This package provides:

- `build_adj(n, edges)` to build an undirected adjacency list
- `mst_weight(adj)` to compute MST total weight (or `None` if disconnected)

---

## Problem restatement (plain words)

Given a connected, weighted, undirected graph with `n` vertices, find the
minimum total weight of edges that connects all vertices.

If the graph is disconnected, an MST does not exist.

---

## Prim's algorithm (idea)

Start from any vertex (we use `0`), then repeatedly add the **cheapest edge
that reaches a new vertex**.

We maintain:

- `in_mst[v]` : whether vertex `v` is already in the tree
- `min_edge[v]` : the cheapest edge that can connect `v` to the current tree

At each step:

1) Pick the vertex `v` (not in MST) with the smallest `min_edge[v]`.
2) Add it to the tree and add its cost to the total.
3) Update `min_edge` for its neighbors.

This version uses a simple `O(n)` scan to pick the next vertex, giving `O(n^2)`
for the whole algorithm.

---

## Visual intuition

Think of the MST as a growing "blob":

```
Tree (T):    O---O
Frontier:    |  / \
            O  O   O
```

Prim always adds the **lightest edge** from the blob to a new vertex.

---

## Worked example (step by step)

Graph with 4 vertices:

```
0 --(1)-- 1
| \       |
|  (4)    (2)
|    \    |
(3)   2 -- 3
     (5)
```

Edges:

```
(0,1,1), (0,2,3), (0,3,4), (1,3,2), (2,3,5)
```

Start with vertex 0:

- `min_edge` = [0, 1, 3, 4]

Step 1: pick vertex 1 (cost 1)

- total = 1
- update neighbors: `min_edge[3]` becomes 2 (edge 1-3)

Step 2: pick vertex 3 (cost 2)

- total = 3
- update neighbors: `min_edge[2]` stays 3 (edge 0-2 is still cheaper)

Step 3: pick vertex 2 (cost 3)

- total = 6
- all vertices added

MST total weight = 6.

---

## Reference implementation

```mbt
///| pub fn build_adj(n : Int, edges : ArrayView[(Int, Int, Int)]) -> Array[Array[(Int, Int)]]

///| pub fn mst_weight(adj : Array[Array[(Int, Int)]]) -> Int?
```

---

## Tests and examples

### Basic example

```mbt check
///|
test "mst prim example" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (2, 3, 3),
    (0, 3, 10),
  ]
  let adj = @challenge_mst_prim.build_adj(4, edges[:])
  let total = @challenge_mst_prim.mst_weight(adj)
  inspect(total, content="Some(6)")
}
```

### Example from the walkthrough

```mbt check
///|
test "mst prim walkthrough" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (0, 2, 3),
    (0, 3, 4),
    (1, 3, 2),
    (2, 3, 5),
  ]
  let adj = @challenge_mst_prim.build_adj(4, edges[:])
  let total = @challenge_mst_prim.mst_weight(adj)
  inspect(total, content="Some(6)")
}
```

### Disconnected graph

```mbt check
///|
test "mst prim disconnected" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1)]
  let adj = @challenge_mst_prim.build_adj(3, edges[:])
  let total = @challenge_mst_prim.mst_weight(adj)
  inspect(total, content="None")
}
```

### Negative edge weights

```mbt check
///|
test "mst prim negative" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, -2), (1, 2, 3), (0, 2, 1)]
  let adj = @challenge_mst_prim.build_adj(3, edges[:])
  let total = @challenge_mst_prim.mst_weight(adj)
  inspect(total, content="Some(-1)")
}
```

### Ignore invalid edges (out of range vertices)

```mbt check
///|
test "mst prim ignores invalid" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 2),
    (1, 2, 1),
    (-1, 2, 5),
    (2, 3, 1),
  ]
  let adj = @challenge_mst_prim.build_adj(3, edges[:])
  let total = @challenge_mst_prim.mst_weight(adj)
  inspect(total, content="Some(3)")
}
```

---

## Complexity

Let `n = number of vertices`, `m = number of edges`.

- Building adjacency list: `O(m)`
- Prim (O(n^2) version): `O(n^2)`
- Total: `O(n^2 + m)`

This is good for dense graphs. For sparse graphs, a heap-based version can
reduce the time to `O(m log n)`.

---

## Takeaways

- Prim grows the MST from a starting vertex by always adding the cheapest edge
  to a new vertex.
- `min_edge` stores the current best way to reach each vertex.
- If the graph is disconnected, you cannot form a spanning tree (`None`).
