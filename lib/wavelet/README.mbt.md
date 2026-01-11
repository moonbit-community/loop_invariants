# Wavelet Tree (Reference)

Wavelet tree supports order statistics and range counting queries over static
arrays.

## What it demonstrates

- Recursive partitioning by value range
- Prefix counts for navigation
- Queries like kth smallest and count <= x

## Pseudocode sketch

```mbt nocheck
build(node, lo, hi, values):
  split by mid, store prefix counts
```

## Notes

- Time complexity: O(log V) per query
- This package is a reference implementation with invariants
