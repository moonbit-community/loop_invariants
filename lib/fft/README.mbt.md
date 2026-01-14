# FFT/NTT - Fast Polynomial Multiplication

## Overview

The **Fast Fourier Transform (FFT)** and **Number Theoretic Transform (NTT)**
enable O(n log n) polynomial multiplication by converting between coefficient
and point-value representations.

- **Time**: O(n log n)
- **Space**: O(n)

## Core Idea

- Convert coefficients to **point-value form** using roots of unity.
- Multiply values **pointwise**, then inverse transform.
- Bit-reversal + butterfly steps implement the transform in O(n log n).

## The Problem

```
Multiply two polynomials:
  A(x) = 1 + 2x + 3x²
  B(x) = 4 + 5x

Naive: O(n²) - multiply each pair of coefficients
  = 4 + 5x + 8x + 10x² + 12x² + 15x³
  = 4 + 13x + 22x² + 15x³

FFT: O(n log n) - convert, multiply pointwise, convert back
```

## The Key Insight

```
Coefficient form:    [1, 2, 3]     Multiply: O(n²)
                         ↓ FFT O(n log n)
Point-value form:    [A(ω⁰), A(ω¹), A(ω²), ...]
                         ↓ Multiply: O(n)
Point-value product: [A(ω⁰)·B(ω⁰), A(ω¹)·B(ω¹), ...]
                         ↓ Inverse FFT O(n log n)
Coefficient form:    Product polynomial!

Total: O(n log n) instead of O(n²)
```

## Roots of Unity

```
Complex roots of unity (FFT):
  ω = e^(2πi/n) = cos(2π/n) + i·sin(2π/n)

  ω⁸ = 1 for n=8:
       ω¹
    ω²   ω⁰=1
  ω³       ω⁷
    ω⁴   ω⁶
       ω⁵

Key properties:
  ω^n = 1
  ω^(n/2) = -1
  ω^k = -ω^(k+n/2)  ← Enables butterfly!
```

## Cooley-Tukey Algorithm

### Step 1: Bit-Reversal Permutation

```
Index:       0   1   2   3   4   5   6   7
Binary:    000 001 010 011 100 101 110 111
Reversed:  000 100 010 110 001 101 011 111
New Index:   0   4   2   6   1   5   3   7

a = [a₀, a₁, a₂, a₃, a₄, a₅, a₆, a₇]
  → [a₀, a₄, a₂, a₆, a₁, a₅, a₃, a₇]
```

### Step 2: Butterfly Operations

```
Stage 1 (pairs):
[a₀, a₄] → [a₀+a₄, a₀-a₄]     using ω⁰=1
[a₂, a₆] → [a₂+a₆, a₂-a₆]     using ω⁰=1
[a₁, a₅] → [a₁+a₅, a₁-a₅]     using ω⁰=1
[a₃, a₇] → [a₃+a₇, a₃-a₇]     using ω⁰=1

Stage 2 (groups of 4):
[a₀+a₄, a₂+a₆] → combine with ω⁰, ω²
[a₀-a₄, a₂-a₆] → combine with ω⁰, ω²
...

Stage 3 (groups of 8):
Combine all using ω⁰, ω¹, ω², ω³

The "butterfly" pattern:
    u ─────┬───── u + ω·v
           ╳
    v ─────┴───── u - ω·v
```

## Number Theoretic Transform (NTT)

For integer results without floating-point error, use modular arithmetic:

```
NTT uses primitive roots modulo prime p:
  p = k · 2^m + 1  (allows 2^m-th roots of unity)

Common NTT primes:
  998244353 = 119 · 2²³ + 1    primitive root g = 3
  167772161 = 5 · 2²⁵ + 1      primitive root g = 3

Root of unity:
  ω = g^((p-1)/n) mod p

Example for n=4, p=998244353:
  ω = 3^(998244352/4) mod p
    = 3^249561088 mod 998244353
```

## Algorithm Walkthrough

```
Multiply A(x) = 1 + 2x and B(x) = 3 + 4x using NTT:

1. Pad to power of 2: n = 4
   A = [1, 2, 0, 0]
   B = [3, 4, 0, 0]

2. Bit-reverse: (0,1,2,3) → (0,2,1,3)
   A = [1, 0, 2, 0]
   B = [3, 0, 4, 0]

3. NTT transform (butterflies):
   Stage 1 (len=2):
     [1,0] → [1, 1]
     [2,0] → [2, 2]
   Stage 2 (len=4):
     Combine with ω⁰, ω¹, ω², ω³

   After NTT:
   A' = [3, -1+2i, -1, -1-2i]  (conceptually)
   B' = [7, -1+4i, -1, -1-4i]  (in modular form)

4. Point-wise multiply:
   C' = A' ⊙ B'

5. Inverse NTT:
   C = [3, 10, 8, 0]

Result: 3 + 10x + 8x²
```

## Example Usage

```mbt check
///|
test "polynomial multiplication concept" {
  // (1 + 2x) × (3 + 4x) = 3 + 10x + 8x²
  //
  // Using FFT/NTT:
  // 1. Transform both polynomials to point-value form
  // 2. Multiply corresponding points
  // 3. Transform back to coefficient form
  //
  // This achieves O(n log n) instead of O(n²)

  inspect(1 * 3, content="3") // constant term
  inspect(1 * 4 + 2 * 3, content="10") // x coefficient
  inspect(2 * 4, content="8") // x² coefficient
}
```

## Common Applications

### 1. Large Integer Multiplication
```
Multiply two n-digit numbers:
- Treat digits as polynomial coefficients
- Multiply polynomials using FFT
- Handle carries
- Time: O(n log n) vs O(n²) naive
```

### 2. String Matching with Wildcards
```
Pattern P with wildcards in text T:
- Encode as polynomials
- Convolution finds matching positions
- Time: O(n log n)
```

### 3. Convolution Problems
```
Count pairs (i,j) where a[i] + b[j] = k:
- Create polynomials from arrays
- Coefficient of x^k in product = count
```

### 4. Polynomial Division/Modulo
```
A(x) / B(x) and A(x) mod B(x):
- Use Newton's method with FFT
- Time: O(n log n)
```

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| FFT/NTT | O(n log n) | O(n) |
| Polynomial multiply | O(n log n) | O(n) |
| Convolution | O(n log n) | O(n) |

## FFT vs Other Methods

| Method | Time | Precision | Use Case |
|--------|------|-----------|----------|
| **NTT** | O(n log n) | Exact (mod p) | Integer results |
| **FFT** | O(n log n) | ~15 digits | Floating-point OK |
| Karatsuba | O(n^1.58) | Exact | Moderate n |
| Naive | O(n²) | Exact | Small n |

**Choose NTT when**: You need exact integer results and n is large.
**Choose FFT when**: Floating-point precision is acceptable.

## Why O(n log n)?

```
Recurrence: T(n) = 2·T(n/2) + O(n)

At each level:
- log n levels (halving each time)
- O(n) work per level (n/2 butterflies)

Total: O(n) × O(log n) = O(n log n)

Tree structure:
Level 0: n butterflies, ω^(n/1) roots
Level 1: n/2 butterflies each × 2 groups
Level 2: n/4 butterflies each × 4 groups
...
Level log n: 1 butterfly each × n groups
```

## Implementation Notes

- Array size must be power of 2 (pad with zeros)
- Bit-reversal can be computed iteratively
- For inverse, use ω^(-1) = ω^(n-1) and divide by n
- NTT avoids floating-point errors
- Watch for integer overflow in NTT (use 64-bit)
