# Skip List (Reference)

Probabilistic ordered set/map with layered forward pointers and expected
logarithmic operations.

## What it demonstrates

- Random level assignment
- Search by dropping levels
- Insert/delete with level updates

## Pseudocode sketch

```mbt nocheck
search(key):
  move right while next.key < key
  drop level and continue
```

## Notes

- Expected time: O(log n) per operation
- This package is a reference implementation with invariants
