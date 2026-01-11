# Implicit Treap (Reference)

Sequence data structure using a treap where position is determined by subtree
sizes rather than explicit keys.

## What it demonstrates

- Split by index rather than key
- Range operations by splitting into three parts
- Maintaining subtree sizes

## Pseudocode sketch

```mbt nocheck
split_by_index(root, k) -> (left, right)
merge(left, right) -> root
```

## Notes

- Expected time: O(log n) per operation
- This package is a reference implementation with invariants
