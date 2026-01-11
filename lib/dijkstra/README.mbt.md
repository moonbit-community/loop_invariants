# Dijkstra (Shortest Paths)

Compute shortest paths in a weighted graph with non-negative edge weights.
This package provides a simple adjacency-list graph and several helpers for
inspecting distances and paths.

## What it includes

- `Graph` and `Edge` types for weighted graphs
- `dijkstra` returning distances and parent pointers
- `reconstruct_path` and `shortest_distance` helpers
- `bidirectional_dijkstra` for faster point-to-point queries

## Example

```mbt check
///|
test "dijkstra example" {
  let g = @dijkstra.Graph::new(4)
  g.add_edge(0, 1, 1)
  g.add_edge(1, 2, 2)
  g.add_edge(0, 2, 4)
  g.add_edge(2, 3, 1)
  let res = @dijkstra.dijkstra(g, 0)
  inspect(res.dist, content="[0, 1, 3, 4]")
  let path = @dijkstra.reconstruct_path(res, 3)
  inspect(path, content="[0, 1, 2, 3]")
}
```

## Notes

- Requires non-negative edge weights for correctness.
- Time complexity: `O((V + E) log V)` with the binary heap.
