# Sqrt Decomposition (Reference, Extended)

An extended sqrt-decomposition toolkit with detailed invariants and multiple
query/update patterns.

## What it demonstrates

- Block sizing and index mapping
- Partial-block handling
- Mo-style window movement and updates

## Pseudocode sketch

```mbt nocheck
block = i / block_size
for each query:
  answer using partial blocks + full blocks
```

## Notes

- Time complexity: typically O(sqrt(n)) per query
- This package is a reference implementation with invariants
