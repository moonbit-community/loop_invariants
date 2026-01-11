# Fenwick Tree (Binary Indexed Tree) (Reference)

Efficient point updates and prefix/range sums in logarithmic time using
bitwise index jumps.

## What it demonstrates

- Lowbit-based index traversal
- Prefix sum queries and point updates
- Variants: range add / range sum

## Pseudocode sketch

```mbt nocheck
update(i, delta):
  while i <= n: tree[i] += delta; i += lowbit(i)

prefix_sum(i):
  while i > 0: sum += tree[i]; i -= lowbit(i)
```

## Notes

- Time complexity: O(log n) per update/query
- This package is a reference implementation with invariants
- For a smaller API, see `lib/challenge_persistent_fenwick` or `lib/challenge_fenwick_2d`
