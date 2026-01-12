# Bipartite Matching (Reference)

Compute a maximum matching in a bipartite graph. This implementation uses a
layered BFS + DFS approach (Hopcroft-Karp).

## What it demonstrates

- BFS layering from unmatched left nodes
- DFS to find vertex-disjoint augmenting paths
- Repeating until no augmenting path exists

## Pseudocode sketch

```mbt nocheck
while bfs_level_graph():
  for u in left:
    if dfs_augment(u): matching++
```

## Example

```mbt check
///|
test "bipartite matching example" {
  let edges : Array[(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
  let matching = @bipartite_matching.max_matching(2, 2, edges[:])
  inspect(matching, content="[(0, 0), (1, 1)]")
  inspect(matching.length(), content="2")
}
```

## Notes

- Time complexity: O(E * sqrt(V))
- This package is a reference implementation with invariants
