# 2D Fenwick Tree (Reference)

Support point updates and 2D prefix/range sums in O(log^2 n) time.

## What it demonstrates

- Extending lowbit traversal to two dimensions
- Inclusion-exclusion for rectangle queries
- Careful index handling

## Pseudocode sketch

```mbt nocheck
update(x, y, delta):
  for i = x..: for j = y..: tree[i][j] += delta
prefix(x, y):
  for i = x..: for j = y..: sum += tree[i][j]
```

## Notes

- Time complexity: O(log^2 n)
- This package is a reference implementation with invariants
