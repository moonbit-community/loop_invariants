# Segment Tree (Reference)

Balanced tree over array intervals supporting fast range queries and updates.

## What it demonstrates

- Building a tree over ranges
- Querying segments that intersect a range
- Variants: sum, min/max, lazy propagation, 2D tree

## Pseudocode sketch

```mbt nocheck
build(node, l, r)
query(node, l, r, ql, qr)
update(node, l, r, idx, value)
```

## Notes

- Time complexity: O(log n) per query/update
- This package is a reference implementation with invariants
- For challenge-style APIs, see `lib/challenge_persistent_segment_tree_*`
