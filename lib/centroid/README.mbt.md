# Centroid Decomposition (Reference)

Divide a tree by repeatedly removing centroids, yielding a centroid tree of
logarithmic depth.

## What it demonstrates

- Subtree size computation
- Finding a centroid in O(size)
- Recursive decomposition of remaining subtrees

## Pseudocode sketch

```mbt nocheck
centroid = find_centroid(root)
mark centroid removed
for each subtree: decompose(subtree)
```

## Notes

- Time complexity: O(n log n)
- This package is a reference implementation with invariants
