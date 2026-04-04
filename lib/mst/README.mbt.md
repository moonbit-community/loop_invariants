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

## 2. A weighted graph and its MST

The full graph has 5 vertices and 7 edges. Edge weights are shown on each edge.

```
Full weighted graph:

    0 ---5--- 1
    |  \      |
    3   4     4
    |     \   |
    2 ---2--- 3
          \
           6
            \
             4

Edges: (0,1,5), (0,2,3), (0,3,4), (1,3,4), (2,3,2)
       (0 and 1 also mapped as: see exact list below)
```

Let us use the same 5-vertex example that appears throughout this file:

```
Vertices: A=0, B=1, C=2, D=3

    A ---5--- B
    |  \      |
    3   4     4
    |    \    |
    C ---2--- D
```

Edge list (u, v, weight):

```
(A,B,5)  (A,C,3)  (A,D,4)  (B,D,4)  (C,D,2)
```

MST edges are marked with `*`:

```
MST (total weight = 9):

    A         B
    |         |
    3 *       4 *
    |         |
    C ---2*-- D
```

The MST picks (C,D,2), (A,C,3), (B,D,4) — total 9.
Edge (A,D,4) is skipped because A and D are already connected via A-C-D.
Edge (A,B,5) is skipped because all vertices are already spanned.

---

## 3. Two key theorems (why greedy works)

### Cut property

For any cut (partition of vertices into S and V-S),
the **lightest edge crossing the cut** is in *some* MST.

```
Cut: S = {A, C},  V-S = {B, D}

  S side            |  V-S side
                    |
   A ----3---- C    |    B ----4---- D
               |    |    |
               +--2-+----+  <- lightest crossing edge: (C,D,2)
                    |
  (A,D,4) and (A,B,5) also cross, but they are heavier.
```

If the lightest crossing edge were not in the MST, we could swap it in
(replacing a heavier crossing edge) and get a lighter tree — a
contradiction. Therefore the lightest crossing edge is always safe to add.

### Cycle property

In any cycle, the **heaviest edge** cannot be in *every* MST.

```
Cycle A -> D -> C -> A  (weights 4, 2, 3):

    A
   / \
  4   3
 /     \
D --2-- C

Heaviest edge: (A,D,4).  Removing it still leaves A and D connected
via A -> C -> D, so (A,D,4) cannot be in the unique MST.
```

So when Kruskal sees that an edge would close a cycle, it is safe to drop
that edge — it can never be the sole cheapest way to span those vertices.

---

## 4. Kruskal's algorithm (edge-centric)

**Idea**: sort edges by weight and add them if they do not form a cycle.

```
High-level steps:

  1. Sort all edges by weight (ascending).
  2. Initialise Union-Find: each vertex is its own component.
  3. For each edge in sorted order:
       if find(u) != find(v):   <- different components
           add edge to MST
           union(u, v)
       else:
           skip (would form a cycle)
  4. Stop when MST has V-1 edges (all vertices connected).
```

### Step-by-step walkthrough on the example

Sorted edge list (smallest weight first):

```
Step  Edge    Weight  Components before          Action
----  ------  ------  -------------------------  ------
  1   (C,D)     2     {A} {B} {C} {D}            ADD    -> {A} {B} {C,D}
  2   (A,C)     3     {A} {B} {C,D}              ADD    -> {A,C,D} {B}
  3   (A,D)     4     {A,C,D} {B}                SKIP   (A and D same component)
  4   (B,D)     4     {A,C,D} {B}                ADD    -> {A,B,C,D}
  5   (A,B)     5     {A,B,C,D}                  STOP   (3 edges chosen, done)
```

Union-Find state after each ADD:

```
After step 1 (C,D,2):
  parent: A->A  B->B  C->D  D->D    (C points to D)

After step 2 (A,C,3):
  find(A)=A, find(C)=D -> different; union A and D
  parent: A->A  B->B  C->D  D->A    (D points to A, path-compressed on next find)

After step 4 (B,D,4):
  find(B)=B, find(D)=A -> different; union B and A
  parent: A->A  B->A  C->D  D->A    (B points to A)
```

MST weight = 2 + 3 + 4 = **9**.

### Cut property justification at each step

```
Step 1: cut S={C}, V-S={A,B,D}
        lightest crossing edge: (C,D,2)  -> safe by cut property

Step 2: cut S={A}, V-S={B,C,D}   (C and D already merged)
        lightest crossing edge: (A,C,3)  -> safe by cut property

Step 4: cut S={B}, V-S={A,C,D}   (A, C, D already merged)
        lightest crossing edge: (B,D,4)  -> safe by cut property
```

---

## 5. Prim's algorithm (vertex-centric)

**Idea**: grow a tree from a start vertex, always taking the cheapest edge
from the current tree to any outside vertex.

```
High-level steps:

  1. Pick any start vertex (e.g. A). Set min_edge[A]=0, all others = INF.
  2. Repeat V times:
       u = vertex not yet in MST with smallest min_edge[u]
       Add u (and its connecting edge) to the MST
       For each neighbor v of u:
           if v not in MST and weight(u,v) < min_edge[v]:
               min_edge[v] = weight(u,v)
```

### Step-by-step walkthrough on the same graph

```
Start: in_mst={},  min_edge=[A:0, B:INF, C:INF, D:INF]

Iter 1: pick A (min_edge=0, no real edge — just the seed)
        in_mst={A}
        relax neighbors:
          B: min_edge[B] = min(INF, 5) = 5
          C: min_edge[C] = min(INF, 3) = 3
          D: min_edge[D] = min(INF, 4) = 4
        min_edge=[A:0, B:5, C:3, D:4]

Iter 2: pick C (min_edge=3, cheapest outside vertex)
        in_mst={A, C},  add edge (A,C,3)
        relax neighbors of C:
          D: min_edge[D] = min(4, 2) = 2  <- improved!
        min_edge=[A:0, B:5, C:3, D:2]

Iter 3: pick D (min_edge=2, cheapest outside vertex)
        in_mst={A, C, D},  add edge (C,D,2)
        relax neighbors of D:
          B: min_edge[B] = min(5, 4) = 4  <- improved!
        min_edge=[A:0, B:4, C:3, D:2]

Iter 4: pick B (min_edge=4)
        in_mst={A, B, C, D},  add edge (B,D,4)
        No more vertices outside.

MST edges: (A,C,3), (C,D,2), (B,D,4)
Total weight: 3 + 2 + 4 = 9
```

The cut property holds at every step: when we add vertex `u`, the edge
`(u, min_edge[u])` is the lightest edge crossing the cut `(in_mst, V-in_mst)`.

---

## 6. Another example: multiple MSTs

Square with equal weights:

```
  A ----1---- B
  |           |
  1           1
  |           |
  C ----1---- D
```

Any 3 edges form an MST. There are **four** different MSTs here.
So MST is not always unique.

---

## 7. Disconnected graphs

If the graph is disconnected, there is **no single MST**.
Instead you get a **minimum spanning forest** (one tree per component).

```
Component 1: A --1-- B
Component 2: C --2-- D
```

There is no way to connect all 4 vertices, so a full MST does not exist.

---

## 8. Kruskal vs Prim comparison

```
                Kruskal (edge-driven)     Prim (vertex-driven)
                ----------------------    --------------------
Data structure  Union-Find (DSU)          min_edge array / heap
Input form      Edge list                 Adjacency list/matrix
Iteration unit  Edge                      Vertex
Cycle check     find(u) != find(v)        in_mst[] flag
Best for        Sparse graphs             Dense graphs
Time (sparse)   O(E log E)                O((V+E) log V)
Time (dense)    O(E log E)                O(V^2) with simple scan
```

---

## 9. Conceptual MoonBit-style pseudocode

These are **illustrations** (not part of the public API).

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
Cities   = vertices
Road cost = edge weight
MST      = cheapest network connecting all cities
```

### Clustering (single linkage)

```
Build MST of all data points.
Remove the (k-1) largest edges.
Remaining components = k clusters.
```

### TSP approximation

```
MST gives a 2-approximation for the metric Travelling Salesman Problem.
Double the MST edges, find an Eulerian circuit, then shortcut.
```

---

## 12. Complexity summary

```
Algorithm            Time               Space
-------------------  -----------------  -------
Kruskal              O(E log E)         O(V + E)
Prim (binary heap)   O((V+E) log V)     O(V + E)
Prim (O(V^2) scan)   O(V^2)             O(V)
```

Kruskal's O(E log E) dominates for sparse graphs; Prim's O(V^2) scan is
simpler and faster when E approaches V^2.

---

## 13. Summary

- MST connects all vertices with minimum total weight.
- Kruskal = sort edges, add if no cycle (Union-Find detects cycles).
- Prim = grow tree vertex by vertex, always pick the cheapest crossing edge.
- Both rely on the **cut property**: the lightest edge crossing any cut is
  always safe to include in an MST.
- If the graph is disconnected, neither algorithm can produce a full MST.
