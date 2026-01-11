# Sqrt Decomposition (Reference)

Divide an array into blocks of size sqrt(n) to trade off update/query time.

## What it demonstrates

- Block aggregates for range queries
- Rebuilding a single block after an update
- Handling partial vs. full blocks

## Pseudocode sketch

```mbt nocheck
for i in l..r:
  if i at block boundary and full block fits: use block sum
  else: use element
```

## Notes

- Time complexity: O(sqrt(n)) per query/update
- This package is a reference implementation with invariants
