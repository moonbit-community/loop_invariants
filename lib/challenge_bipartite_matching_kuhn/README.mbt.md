# Challenge: Bipartite Matching (Kuhn)

DFS-based augmenting path algorithm for maximum bipartite matching.

## Core Idea

Repeatedly try to find an augmenting path from each left node using DFS.
When a free right node is found (or can be freed), we augment the matching.

Time complexity is O(VE) in the worst case but often fast in practice for
small or sparse graphs.

## Example

```mbt check
///|
test "bipartite matching example" {
  let edges : Array[(Int, Int)] = [(0, 0), (0, 1), (1, 1), (2, 2)]
  let adj = @challenge_bipartite_matching_kuhn.build_adj(3, 3, edges[:])
  let m = @challenge_bipartite_matching_kuhn.max_matching(adj, 3)
  inspect(m, content="3")
}
```

## Another Example

```mbt check
///|
test "bipartite matching empty" {
  let edges : Array[(Int, Int)] = []
  let adj = @challenge_bipartite_matching_kuhn.build_adj(2, 2, edges[:])
  let m = @challenge_bipartite_matching_kuhn.max_matching(adj, 2)
  inspect(m, content="0")
}
```

## Notes

- Left size must be provided to `max_matching`.
- The adjacency list is from left nodes to right nodes.
