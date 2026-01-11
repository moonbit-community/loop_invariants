# Treap (Reference)

Randomized balanced BST using heap priorities plus BST ordering on keys.

## What it demonstrates

- Split/merge operations
- Insert/delete using randomized priorities
- Expected O(log n) height

## Pseudocode sketch

```mbt nocheck
split(root, key) -> (l, r)
merge(l, r) -> root
```

## Notes

- Expected time: O(log n) per operation
- This package is a reference implementation with invariants
