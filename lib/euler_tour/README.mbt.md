# Euler Tour (Reference)

Traverse a tree to record entry/exit times and a linearized order of nodes.

## What it demonstrates

- DFS entry/exit timestamps
- Flattening a subtree into a range
- Using an explicit stack to avoid recursion

## Pseudocode sketch

```mbt nocheck
dfs(u, parent):
  tin[u] = timer++
  for v in adj[u]: dfs(v, u)
  tout[u] = timer
```

## Notes

- Time complexity: O(n)
- This package is a reference implementation with invariants
