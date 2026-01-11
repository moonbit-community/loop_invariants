# Minimum Spanning Tree (Reference)

Reference implementations of Kruskal's and Prim's algorithms for building a
minimum spanning tree in a weighted, connected, undirected graph.

## What it demonstrates

- Kruskal's algorithm with DSU
- Prim's algorithm with a priority queue
- Cut property and greedy choice reasoning

## Pseudocode sketch

```mbt nocheck
///|
let mst_weight = kruskal(n, edges)

///|
let mst_weight2 = prim(n, edges)
```

## Notes

- This package is a reference; the concrete types are private.
- For a public API, see `lib/challenge_mst_kruskal` and `lib/challenge_mst_prim`.
- Time complexity: Kruskal `O(E log E)`, Prim `O((V + E) log V)`.
