# Challenge: DFS Subtree Sizes

Compute subtree sizes in a rooted tree with a single DFS pass.

## What you learn

- Post-order accumulation of child sizes
- Parent tracking to avoid revisiting nodes
- Simple tree DP pattern

## Pseudocode sketch

```mbt nocheck
size[u] = 1
for v in adj[u]:
  if v != parent:
    dfs(v)
    size[u] += size[v]
```

## Notes

- Time complexity: O(n)
- Space complexity: O(n)
