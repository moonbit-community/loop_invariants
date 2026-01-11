# Bridges and Articulation Points (Reference)

Find all bridges and articulation points in an undirected graph using a DFS
with discovery times and low-link values (Tarjan-style).

## What it demonstrates

- DFS tree edges vs. back edges
- Low-link computation for each vertex
- Bridge condition: `low[v] > disc[u]`
- Articulation point conditions for root and non-root vertices

## Pseudocode sketch

```mbt nocheck
let finder = BridgeFinder::new(n)
finder.add_edge(u, v)
finder.find()
let bridges = finder.get_bridges()
let cut_vertices = finder.get_articulation_points()
```

## Notes

- This package is a reference implementation; the core struct is private.
- See the tests in `lib/bridges/bridges.mbt` for concrete graph examples.
- Time complexity: `O(V + E)`.
