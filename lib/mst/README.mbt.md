# Minimum Spanning Tree (MST)

## Overview

A **Minimum Spanning Tree** connects all vertices in a weighted graph with
minimum total edge weight, using exactly V-1 edges.

- **Kruskal's Time**: O(E log E)
- **Prim's Time**: O((V + E) log V)
- **Space**: O(V + E)

## The Problem

```
Graph:
    A ──5── B
    |\     /|
    3 \   / 4
    |  \ /  |
    C ──2── D

Edges: (A,B,5), (A,C,3), (A,D,4), (B,D,4), (C,D,2)

Goal: Connect all vertices with minimum total weight

MST (total weight = 9):
    A       B
    |       |
    3       4
    |       |
    C ──2── D
```

## The Cut Property

```
Key Theorem: For any cut dividing vertices into S and V-S,
the minimum weight edge crossing the cut is in some MST.

        Cut
          |
    A  B  |  C  D
    ●──●  |  ●──●
       ╲  |  ╱
        ╲ | ╱
         min edge → in MST!

Why? If min edge not in MST, we can add it (creates cycle),
then remove a heavier edge from the cycle that also crosses
the cut. Result: valid spanning tree with lower weight.
Contradiction!
```

## Kruskal's Algorithm

### Idea: Greedy by Edge Weight

```
1. Sort all edges by weight
2. For each edge (u, v, w) in sorted order:
   - If u and v are in different components:
     - Add edge to MST
     - Union their components
3. Stop when MST has V-1 edges
```

### Walkthrough

```
Edges sorted: (C,D,2), (A,C,3), (A,D,4), (B,D,4), (A,B,5)

Initial components: {A}, {B}, {C}, {D}

(C,D,2): C and D different → add to MST
         Components: {A}, {B}, {C,D}
         MST edges: [(C,D)]

(A,C,3): A and C different → add to MST
         Components: {A,C,D}, {B}
         MST edges: [(C,D), (A,C)]

(A,D,4): A and D same → skip (would create cycle)

(B,D,4): B and D different → add to MST
         Components: {A,B,C,D}
         MST edges: [(C,D), (A,C), (B,D)]

3 edges = V-1 → done!
MST weight = 2 + 3 + 4 = 9
```

## Prim's Algorithm

### Idea: Grow Tree from Vertex

```
1. Start with any vertex in MST
2. Repeat V-1 times:
   - Find minimum weight edge from MST to non-MST vertex
   - Add that vertex and edge to MST
3. Result: MST with V-1 edges
```

### Walkthrough

```
Start from A:
  MST = {A}

Step 1: Edges from A: (A,B,5), (A,C,3), (A,D,4)
        Min = (A,C,3) → add C
        MST = {A,C}, edges: [(A,C)]

Step 2: Edges from {A,C}: (A,B,5), (A,D,4), (C,D,2)
        Min = (C,D,2) → add D
        MST = {A,C,D}, edges: [(A,C), (C,D)]

Step 3: Edges from {A,C,D}: (A,B,5), (B,D,4)
        Min = (B,D,4) → add B
        MST = {A,B,C,D}, edges: [(A,C), (C,D), (B,D)]

Done! MST weight = 3 + 2 + 4 = 9
```

## Visual Comparison

```
Kruskal's (edge-centric):        Prim's (vertex-centric):

1. Sort edges globally          1. Start from vertex
   ↓                               ↓
2. Process edges in order       2. Find min edge to outside
   ↓                               ↓
3. Use Union-Find for cycles    3. Use priority queue
   ↓                               ↓
4. Stop at V-1 edges            4. Stop at V-1 edges

Better for:                     Better for:
- Sparse graphs (E ≈ V)         - Dense graphs (E ≈ V²)
- Distributed computing         - When starting vertex matters
```

## Example Usage

```mbt check
///|
test "mst concept" {
  // Kruskal's: Sort edges, greedily add if no cycle
  // Prim's: Grow tree by adding minimum outgoing edge

  // Both produce MST with same total weight
  // MST has exactly V-1 edges

  inspect(true, content="true")
}
```

## Common Applications

### 1. Network Design
```
Problem: Connect cities with minimum cable length
Vertices = cities, edges = possible connections
MST = cheapest way to connect all cities
```

### 2. Clustering
```
Single-linkage clustering:
1. Build MST of data points
2. Remove k-1 heaviest edges
3. Result: k clusters

The MST captures minimum-distance connections.
```

### 3. Approximation Algorithms
```
MST-based 2-approximation for Traveling Salesman:
1. Compute MST
2. Double all edges (Eulerian graph)
3. Find Euler tour
4. Shortcut repeated vertices
Result: Tour ≤ 2 × optimal
```

### 4. Image Segmentation
```
Pixels = vertices, edge weight = color difference
Heavy MST edges indicate object boundaries.
```

## Complexity Analysis

| Algorithm | Sort/PQ | Union-Find | Total |
|-----------|---------|------------|-------|
| Kruskal's | O(E log E) | O(E α(V)) | O(E log E) |
| Prim's (binary heap) | O((V+E) log V) | - | O((V+E) log V) |
| Prim's (Fibonacci heap) | O(E + V log V) | - | O(E + V log V) |

## Kruskal vs Prim

| Aspect | Kruskal | Prim |
|--------|---------|------|
| Approach | Edge-centric | Vertex-centric |
| Data structure | Union-Find | Priority Queue |
| Better for | Sparse graphs | Dense graphs |
| Parallelizable | Yes (edge batching) | Less easily |
| Online | No (needs all edges) | Yes (can add edges) |

**Choose Kruskal when**: Graph is sparse or edges arrive in batches.
**Choose Prim when**: Graph is dense or starting vertex matters.

## Why Does Greedy Work?

```
Both algorithms exploit the cut property:

Kruskal's: Each edge added crosses a cut (between components)
           It's the minimum such edge (sorted order)
           → In some MST by cut property

Prim's:    Each edge added crosses the cut (MST vs non-MST)
           It's the minimum such edge (priority queue)
           → In some MST by cut property

Greedy choice is always safe!
```

## Implementation Notes

- Kruskal: Use Union-Find with path compression + rank
- Prim: Use binary heap or Fibonacci heap
- Handle disconnected graphs (forest of MSTs)
- For maximum spanning tree: negate weights or reverse comparisons
- Multiple MSTs possible if equal-weight edges exist

