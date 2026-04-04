# Minimum Spanning Tree (MST)

This package is a **tutorial** package (no exported functions). It explains
minimum spanning trees and two classic algorithms: **Kruskal** and **Prim**.

An MST connects all vertices of a weighted, undirected graph with the smallest
possible total edge weight.

---

## 1. What is a spanning tree?

A **spanning tree** of a graph:

- includes **all vertices**,
- is **connected**,
- has **no cycles**,
- therefore uses exactly **V - 1 edges**.

If edges have weights, a **minimum** spanning tree is the spanning tree with
the smallest total weight.

---

## 2. A tiny example by hand

Graph:

```
    A --5-- B
    | \     |
    3  4    4
    |    \  |
    C --2-- D
```

Edges:

```
(A,B,5), (A,C,3), (A,D,4), (B,D,4), (C,D,2)
```

One MST is:

```
    A      B
    |      |
    3      4
    |      |
    C --2-- D
```

Total weight = 3 + 2 + 4 = 9.

There might be other MSTs if there are ties.

---

## 3. Two key theorems (why greedy works)

### Cut property

For any cut (partition of vertices into S and V-S),
the **lightest edge crossing the cut** is in *some* MST.

```
Cut line:

  S side      |     V-S side
  A   B       |     C   D
  o---o       |     o---o
     \        |        /
      \_______|_______/
        lightest edge

If the lightest edge were not in the MST, you could swap it in and get a
lighter tree, which is impossible.
```

### Cycle property

In any cycle, the **heaviest edge** cannot be in *every* MST.

So when Kruskal sees a cycle, it is safe to drop the heaviest edge.

---

## 4. Kruskal's algorithm (edge‑centric)

**Idea**: sort edges by weight and add them if they do not form a cycle.

### Steps

```
1. Sort edges by weight
2. Use Union-Find to track components
3. For each edge in order:
     if it connects two different components, add it
4. Stop after V-1 edges
```

### Walkthrough on the example

Edges sorted:

```
(C,D,2), (A,C,3), (A,D,4), (B,D,4), (A,B,5)
```

Process:

```
Add (C,D,2) -> components: {C,D}, {A}, {B}
Add (A,C,3) -> components: {A,C,D}, {B}
Skip (A,D,4) -> would create cycle
Add (B,D,4) -> components: {A,B,C,D}
Stop (3 edges)
```

MST weight = 2 + 3 + 4 = 9.

---

## 5. Prim's algorithm (vertex‑centric)

**Idea**: grow a tree from a start vertex, always taking the cheapest edge
from the tree to an outside vertex.

### Steps

```
1. Pick any start vertex
2. Repeatedly add the cheapest edge connecting tree to outside
3. Stop after V-1 edges
```

### Walkthrough on the same graph

Start at A:

```
Step 1: edges from A: (A,B,5), (A,C,3), (A,D,4)
        pick (A,C,3)
Tree = {A,C}

Step 2: edges crossing tree:
        (A,B,5), (A,D,4), (C,D,2)
        pick (C,D,2)
Tree = {A,C,D}

Step 3: edges crossing tree:
        (A,B,5), (B,D,4)
        pick (B,D,4)
Tree = {A,B,C,D}
```

Total weight = 9.

---

## 6. Another example: multiple MSTs

Square with equal weights:

```
  A ----1---- B
  |          |
  1          1
  |          |
  C ----1---- D
```

Any 3 edges form an MST. There are **four** different MSTs here.
So MST is not always unique.

---

## 7. Disconnected graphs

If the graph is disconnected, there is **no single MST**.
Instead you get a **minimum spanning forest** (one tree per component).

Example:

```
Component 1: A --1-- B
Component 2: C --2-- D
```

There is no way to connect all 4 vertices, so MST does not exist.

---

## 8. ASCII diagram: Kruskal vs Prim

```
Kruskal (edge-driven)          Prim (vertex-driven)
---------------------------------------------------
Sort all edges                Start from one vertex
Pick smallest edge            Pick cheapest outgoing edge
Skip if cycle                 Expand tree by one vertex
Repeat until V-1 edges        Repeat until V-1 edges
```

Kruskal is usually better for **sparse** graphs.
Prim is usually better for **dense** graphs.

---

## 9. Conceptual MoonBit-style pseudocode

These are **illustrations** (not part of public API).

### Kruskal

```mbt nocheck
///|
struct Edge {
  u : Int
  v : Int
  w : Int
}

///|
fn kruskal(n : Int, edges : Array[Edge]) -> (Array[Edge], Int) {
  edges.sort_by((a, b) => a.w - b.w)
  let uf = UF::new(n)
  let mst : Array[Edge] = []
  let total = for e in edges; total = 0 {
    if uf.union(e.u, e.v) {
      mst.push(e)
      let next_total = total + e.w
      if mst.length() == n - 1 {
        break next_total
      }
      continue next_total
    }
    continue total
  } nobreak {
    total
  }
  (mst, total)
}
```

### Prim (priority queue version)

```mbt nocheck
///|
fn prim(n : Int, adj : Array[Array[(Int, Int)]]) -> Int {
  let in_tree = Array::make(n, false)
  let pq = MinHeap::new() // (weight, vertex)
  pq.push((0, 0))
  let total = for _ in 0..<n; total = 0 {
    let (w, v) = pq.pop_min()
    if in_tree[v] { continue total }
    in_tree[v] = true
    for (to, w2) in adj[v] {
      if !(in_tree[to]) {
        pq.push((w2, to))
      }
    }
    continue total + w
  } nobreak {
    total
  }
  total
}
```

---

## 10. Beginner-friendly checklist (how to solve an MST problem)

1. **Check if the graph is connected**. If not, MST does not exist.
2. **Pick the algorithm**:
   - Sparse graph or edge list? -> Kruskal.
   - Dense graph or adjacency matrix? -> Prim.
3. **Compute total weight** or return the edges.
4. **Confirm** the tree has exactly V-1 edges.

---

## 11. Common applications

### Network design

```
Cities = vertices
Cable cost = edge weight
MST = cheapest way to connect all cities
```

### Clustering (single linkage)

```
Build MST of all points.
Remove the (k-1) largest edges.
Remaining components = k clusters.
```

### TSP approximation

```
MST gives a 2-approximation for the metric TSP.
```

---

## 12. Complexity summary

```
Kruskal: O(E log E) + near-linear Union-Find
Prim (binary heap): O((V + E) log V)
Prim (O(V^2) version): good when V is small or dense graph
```

---

## 13. Summary

- MST connects all vertices with minimum total weight.
- Kruskal = sort edges, add if no cycle.
- Prim = grow tree, add cheapest outgoing edge.
- Both rely on the **cut property**, which makes the greedy choice safe.
