# Matrix Exponentiation (Reference)

Fast exponentiation of matrices to compute linear recurrences and path counts.

## What it demonstrates

- Binary exponentiation (square-and-multiply)
- Matrix multiplication loops with invariants
- Using powers for linear recurrences

## Pseudocode sketch

```mbt nocheck
while exp > 0:
  if exp odd: result = result * base
  base = base * base
  exp >>= 1
```

## Notes

- Time complexity: O(n^3 log exp) for n x n matrices
- This package is a reference implementation with invariants
