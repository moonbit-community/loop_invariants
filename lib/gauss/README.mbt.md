# Gaussian Elimination (Reference)

Solve linear systems and compute ranks by row-reduction.

## What it demonstrates

- Pivot selection and row swapping
- Forward elimination and back substitution
- Handling singular systems

## Pseudocode sketch

```mbt nocheck
for col in 0..m-1:
  pick pivot row
  normalize pivot
  eliminate below/above
```

## Notes

- Time complexity: O(n^3)
- This package is a reference implementation with invariants
