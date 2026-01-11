# Mo's Algorithm (Reference)

Offline range query processing by sorting queries into blocks and moving a
window incrementally.

## What it demonstrates

- Block ordering for queries
- Maintaining a mutable window
- Add/remove operations with invariants

## Pseudocode sketch

```mbt nocheck
sort queries by (block(l), r)
move current window to each query
```

## Notes

- Time complexity: O((n + q) * sqrt(n)) for typical problems
- This package is a reference implementation with invariants
