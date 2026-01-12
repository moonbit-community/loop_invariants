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

## Example

```mbt check
///|
test "bridges example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let bridges = @bridges.find_bridges(4, edges[:])
  inspect(bridges, content="[(1, 3)]")
  let cuts = @bridges.articulation_points(4, edges[:])
  inspect(cuts, content="[1]")
}
```

## Notes

- This package is a reference implementation with a small public wrapper.
- See the tests in `lib/bridges/bridges.mbt` for concrete graph examples.
- Time complexity: `O(V + E)`.
