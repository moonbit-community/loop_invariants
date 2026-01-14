# Fast Walsh-Hadamard Transform (FWHT)

## Overview

The **Fast Walsh-Hadamard Transform** computes the XOR convolution of two
sequences in O(n log n) time. It's the XOR analog of FFT for polynomial
multiplication.

- **Time**: O(n log n)
- **Space**: O(n)
- **Key Feature**: XOR convolution without modular arithmetic complexity

## The Key Insight

```
Problem: Compute XOR convolution of two arrays a and b

c[k] = Σ a[i] · b[j]  where i XOR j = k

Naive: O(n²) - try all pairs (i, j)

FWHT insight: Transform to frequency domain where XOR becomes pointwise multiply!

a  →  FWHT  →  A
b  →  FWHT  →  B
                    → C = A ⊙ B (pointwise)
c  ←  IFWHT ←  C

Just like FFT turns regular convolution into pointwise multiplication,
FWHT turns XOR convolution into pointwise multiplication!
```

## Visual: The Butterfly Operation

```
FWHT uses a simple butterfly at each level:

  a ──┬──(+)──► a + b
      │
  b ──┼──(-)──► a - b
      │
      └────────────

Level 0 (size 1): No operation needed
Level 1 (size 2): Apply butterfly to pairs
Level 2 (size 4): Apply butterfly to size-2 groups
...

Example for n=4:

Input: [1, 2, 3, 4]

Level 1 (stride 1):
  [1,2] → [1+2, 1-2] = [3, -1]
  [3,4] → [3+4, 3-4] = [7, -1]
  Result: [3, -1, 7, -1]

Level 2 (stride 2):
  [3, 7] → [3+7, 3-7] = [10, -4]
  [-1,-1] → [-1+(-1), -1-(-1)] = [-2, 0]
  Result: [10, -2, -4, 0]

FWHT([1,2,3,4]) = [10, -2, -4, 0]
```

## Why FWHT Works for XOR

```
Key property: The Walsh-Hadamard matrix H satisfies:

H[i][j] = (-1)^popcount(i AND j)

This means: H[i][j] · H[i][k] = H[i][j XOR k]

When we transform a and b:
  A[i] = Σ_j H[i][j] · a[j]
  B[i] = Σ_k H[i][k] · b[k]

Product in frequency domain:
  C[i] = A[i] · B[i] = Σ_{j,k} H[i][j] · H[i][k] · a[j] · b[k]
       = Σ_{j,k} H[i][j XOR k] · a[j] · b[k]

Inverse transform recovers c where c[m] = Σ_{j XOR k = m} a[j] · b[k]

This is exactly XOR convolution!
```

## Algorithm

```
fwht(a, inverse):
  n = length(a)  // Must be power of 2

  for len = 1; len < n; len *= 2:
    for i = 0; i < n; i += 2 * len:
      for j = 0; j < len; j++:
        u = a[i + j]
        v = a[i + j + len]
        a[i + j] = u + v
        a[i + j + len] = u - v

  if inverse:
    for i = 0 to n-1:
      a[i] /= n
```

## Example Usage

```mbt check
///|
test "fwht xor roundtrip" {
  let a : Array[Int64] = [1L, 2L, 3L, 4L]
  let t = @fwht.fwht_xor(a[:], false)
  let inv = @fwht.fwht_xor(t[:], true)
  inspect(inv, content="[1, 2, 3, 4]")
}
```

```mbt check
///|
test "fwht xor convolution" {
  let a : Array[Int64] = [1L, 2L, 3L, 4L]
  let b : Array[Int64] = [5L, 6L, 7L, 8L]
  let c = @fwht.xor_convolution(a[:], b[:])
  inspect(c, content="[70, 68, 62, 60]")
}
```

## XOR Convolution Walkthrough

```
a = [1, 2, 3, 4], b = [5, 6, 7, 8]

XOR convolution c[k] = Σ a[i]·b[j] where i XOR j = k

c[0] = a[0]·b[0] + a[1]·b[1] + a[2]·b[2] + a[3]·b[3]
     = 1·5 + 2·6 + 3·7 + 4·8 = 5 + 12 + 21 + 32 = 70

c[1] = a[0]·b[1] + a[1]·b[0] + a[2]·b[3] + a[3]·b[2]
     = 1·6 + 2·5 + 3·8 + 4·7 = 6 + 10 + 24 + 28 = 68

c[2] = a[0]·b[2] + a[1]·b[3] + a[2]·b[0] + a[3]·b[1]
     = 1·7 + 2·8 + 3·5 + 4·6 = 7 + 16 + 15 + 24 = 62

c[3] = a[0]·b[3] + a[1]·b[2] + a[2]·b[1] + a[3]·b[0]
     = 1·8 + 2·7 + 3·6 + 4·5 = 8 + 14 + 18 + 20 = 60

Result: [70, 68, 62, 60] ✓
```

## Common Applications

### 1. Subset Sum Problems
```
Count ways to partition elements where XOR of parts satisfies constraints.
```

### 2. Bitmask DP Acceleration
```
Some bitmask DP recurrences involve XOR operations.
FWHT can speed up the transition.
```

### 3. Error-Correcting Codes
```
Walsh-Hadamard codes use this transform.
Fast encoding and decoding.
```

### 4. Signal Processing
```
Walsh functions form an orthogonal basis.
Alternative to Fourier basis for discrete signals.
```

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| FWHT | O(n log n) | O(n) |
| Inverse FWHT | O(n log n) | O(n) |
| XOR Convolution | O(n log n) | O(n) |

## FWHT vs FFT

| Transform | Convolution Type | Ring |
|-----------|-----------------|------|
| FFT | Regular (addition) | Polynomial |
| FWHT | XOR convolution | Boolean/XOR |
| NTT | Regular (mod prime) | Integers mod p |

**Choose FWHT when**: Your problem involves XOR operations on indices or bitmasks.

## Other Walsh-Hadamard Variants

```
AND convolution: c[k] = Σ a[i]·b[j] where i AND j = k
  Butterfly: (a, b) → (a + b, b)

OR convolution: c[k] = Σ a[i]·b[j] where i OR j = k
  Butterfly: (a, b) → (a, a + b)

XOR convolution (this package): c[k] = Σ a[i]·b[j] where i XOR j = k
  Butterfly: (a, b) → (a + b, a - b)
```

## Implementation Notes

- Array length must be a power of 2 (pad with zeros if needed)
- Inverse transform divides by n
- For modular arithmetic, ensure division is valid
- In-place algorithm modifies the input array

