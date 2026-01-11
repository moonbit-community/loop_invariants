# AVL Tree (Reference)

Self-balancing binary search tree that maintains height balance via rotations.

## What it demonstrates

- Height tracking and balance factors
- Single and double rotations
- Insert/delete with rebalancing

## Pseudocode sketch

```mbt nocheck
insert(node, key):
  bst insert
  update height
  rotate if balance out of range
```

## Notes

- Time complexity: O(log n) per operation
- This package is a reference implementation with invariants
