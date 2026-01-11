# Graph Algorithms (Reference)

A curated set of graph algorithm examples with deep loop invariants. This
package is designed as a reference and learning resource rather than a
user-facing API.

## What it covers

- Topological sort (Kahn's algorithm)
- Dijkstra shortest paths
- Union-Find (DSU) with path compression
- Bellman-Ford shortest paths with negative edges
- Floyd-Warshall all-pairs shortest paths
- Kruskal minimum spanning tree

## How to use this package

- Read the commentary and invariants in `lib/graph/graph.mbt`.
- Use the challenge packages for callable APIs, e.g. `lib/challenge_dijkstra`.

## Notes

- Implementations are intentionally verbose and annotated for learning.
- Time complexity varies by algorithm; each section documents its own bounds.
