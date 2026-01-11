# Mo's Algorithm (Reference, Extended)

Extended Mo's algorithm variants, including tree queries and additional
window-maintenance patterns.

## What it demonstrates

- Alternate query ordering strategies
- Tree flattening for Mo on trees
- Complexity trade-offs

## Pseudocode sketch

```mbt nocheck
sort queries
for q in queries:
  move window to q
  answer from current state
```

## Notes

- Time complexity depends on add/remove cost
- This package is a reference implementation with invariants
