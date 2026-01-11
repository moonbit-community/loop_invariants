# FFT / NTT (Reference)

Fast polynomial multiplication using the Fast Fourier Transform or Number
Theoretic Transform.

## What it demonstrates

- Cooley-Tukey iterative FFT
- Bit-reversal permutation
- Modular NTT for integer convolution

## Pseudocode sketch

```mbt nocheck
bit_reverse_permute(a)
for len = 2; len <= n; len *= 2:
  apply roots of unity for each block
```

## Notes

- Time complexity: O(n log n)
- This package is a reference implementation with invariants
