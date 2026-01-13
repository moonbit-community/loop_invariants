# Challenge: DFS Subtree Sizes

Compute subtree sizes in a rooted tree with a single DFS pass.

## What you learn

- Post-order accumulation of child sizes
- Parent tracking to avoid revisiting nodes
- Simple tree DP pattern

## Core Idea

Run a DFS from the root. Each node starts with size 1 (itself), then adds the
sizes of all child subtrees. Parent tracking prevents cycling in the undirected
adjacency list.

## Pseudocode sketch

```mbt nocheck
size[u] = 1
for v in adj[u]:
  if v != parent:
    dfs(v)
    size[u] += size[v]
```

## Example

```mbt check
///|
test "dfs subtree basic" {
  let adj : Array[Array[Int]] = [[1, 2], [0], [0, 3], [2]]
  let size = @challenge_dfs_subtree.subtree_sizes(adj, 0)
  inspect(size, content="[4, 1, 2, 1]")
}
```

## Another Example

```mbt check
///|
test "dfs subtree chain" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [1]]
  let size = @challenge_dfs_subtree.subtree_sizes(adj, 1)
  inspect(size, content="[1, 3, 1]")
}
```

## Notes

- Time complexity: O(n)
- Space complexity: O(n)
