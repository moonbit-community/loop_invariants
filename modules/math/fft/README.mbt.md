# FFT/NTT - Fast Polynomial Multiplication

## Overview

The **Fast Fourier Transform (FFT)** and **Number Theoretic Transform (NTT)**
enable O(n log n) polynomial multiplication by converting between coefficient
and point-value representations.

- **Time**: O(n log n)
- **Space**: O(n)
- **NTT modulus**: `998244353` (primitive root `3`)

## The Problem: Polynomial Multiplication

```
Multiply two polynomials:
  A(x) = 1 + 2x + 3x²
  B(x) = 4 + 5x

Naive O(n²): multiply each pair of coefficients
  = 4 + 5x + 8x + 10x² + 12x² + 15x³
  = 4 + 13x + 22x² + 15x³

FFT O(n log n): convert to point-values, multiply, convert back
```

## The Key Insight: Evaluate, Multiply, Interpolate

```
Coefficient form:    A = [a₀, a₁, ..., aₙ]     B = [b₀, b₁, ..., bₙ]
                              |                              |
                         FFT  |  O(n log n)           FFT  |  O(n log n)
                              v                              v
Point-value form:    A' = [A(ω⁰), A(ω¹), ...]   B' = [B(ω⁰), B(ω¹), ...]
                              |                              |
                      pointwise multiply: C'[k] = A'[k] * B'[k]
                              |
                              |  O(n) work
                              v
                         C' = [A(ω⁰)·B(ω⁰), A(ω¹)·B(ω¹), ...]
                              |
                       IFFT  |  O(n log n)
                              v
Coefficient form:    C = [c₀, c₁, ..., c₂ₙ]  (product polynomial)

Total cost: O(n log n) instead of O(n²)
```

## Roots of Unity

```
Complex roots of unity (FFT):
  ω = e^(2πi/n) = cos(2π/n) + i·sin(2π/n)

  ω⁸ = 1 for n=8: eight evenly spaced points on the unit circle

           ω¹
        ω²    ω⁰=1
      ω³          ω⁷
        ω⁴    ω⁶
           ω⁵

Key properties (enable the fast algorithm):
  ω^n = 1             (periodicity)
  ω^(n/2) = -1        (half-period negation)
  ω^k = -ω^(k+n/2)   (butterfly cancellation)
```

## Divide-and-Conquer: Even/Odd Index Splitting

The Cooley-Tukey algorithm splits a polynomial into its even- and odd-indexed
coefficients, evaluates each half recursively, then combines using the butterfly.

```
A(x) = a₀ + a₁x + a₂x² + a₃x³ + a₄x⁴ + a₅x⁵ + a₆x⁶ + a₇x⁷

        Split by index parity
       /                      \
A_even(x²) = a₀+a₂x²+a₄x⁴+a₆x⁶    A_odd(x²) = a₁+a₃x²+a₅x⁴+a₇x⁶

        Split again             Split again
       /        \              /        \
  ee-part   eo-part       oe-part   oo-part

... until size-1 leaves (trivially evaluated)

Combine step at each level (the "butterfly"):
  A(ω^k)      = A_even(ω^(2k)) + ω^k · A_odd(ω^(2k))
  A(ω^(k+n/2)) = A_even(ω^(2k)) - ω^k · A_odd(ω^(2k))

This reuses the same A_even and A_odd evaluations for two outputs,
halving the work at every level.
```

## The Butterfly Pattern

Each butterfly combines two values u and v with a twiddle factor ω^k:

```
    u ───────┬──────── u + ω^k · v
             |× ω^k
    v ───────┴──────── u - ω^k · v
```

A full 8-point NTT has 3 stages of 4 butterflies each (log₂(8) = 3):

```
Stage 1: pairs (length-2 groups)
  a₀ ─┬─── a₀+a₁         a₂ ─┬─── a₂+a₃         a₄ ─┬─── a₄+a₅         a₆ ─┬─── a₆+a₇
      ╳ ω⁰                    ╳ ω⁰                    ╳ ω⁰                    ╳ ω⁰
  a₁ ─┴─── a₀-a₁         a₃ ─┴─── a₂-a₃         a₅ ─┴─── a₄-a₅         a₇ ─┴─── a₆-a₇

Stage 2: length-4 groups (combine pairs from stage 1)
  [a₀+a₁]─┬──── [a₀+a₁]+ω⁰[a₂+a₃]    [a₄+a₅]─┬──── [a₄+a₅]+ω⁰[a₆+a₇]
           ╳ ω⁰/ω²                              ╳ ω⁰/ω²
  [a₂+a₃]─┴──── [a₀+a₁]-ω⁰[a₂+a₃]    [a₆+a₇]─┴──── [a₄+a₅]-ω⁰[a₆+a₇]
  (similarly for the -a₁, -a₃ halves with ω²)

Stage 3: full length-8 group (combine all)
  top half ─┬──── top + ω^k · bottom  (k = 0,1,2,3)
            ╳ ω⁰ ω¹ ω² ω³
  bot half ─┴──── top - ω^k · bottom
```

## Step 1: Bit-Reversal Permutation

Before the butterfly stages, indices are rearranged by reversing their bits.
This puts the correct subproblem elements adjacent in memory.

```
Index:       0   1   2   3   4   5   6   7
Binary:    000 001 010 011 100 101 110 111
Reversed:  000 100 010 110 001 101 011 111
New index:   0   4   2   6   1   5   3   7

a = [a₀, a₁, a₂, a₃, a₄, a₅, a₆, a₇]
  → [a₀, a₄, a₂, a₆, a₁, a₅, a₃, a₇]
      └─even─even   └─even─odd   (interleaving undone)
```

## Number Theoretic Transform (NTT)

For integer results without floating-point error, NTT uses modular arithmetic:

```
NTT uses primitive roots modulo a prime p of the form p = k · 2^m + 1.
This guarantees 2^m-th roots of unity exist modulo p.

Common NTT-friendly primes:
  998244353 = 119 · 2²³ + 1    primitive root g = 3
  167772161 = 5 · 2²⁵ + 1      primitive root g = 3

Root of unity for a transform of size n (a power of 2):
  ω = g^((p-1)/n) mod p

For n=4, p=998244353:
  ω = 3^(998244352/4) mod 998244353
    = 3^249561088 mod 998244353
    = 911660635

All butterfly arithmetic is done mod p, so no floating-point rounding occurs.
```

## Full Walkthrough: (1 + 2x) × (3 + 4x)

```
1. Output length = 2+2-1 = 3; pad to next power of 2: n = 4
   A = [1, 2, 0, 0]
   B = [3, 4, 0, 0]

2. Bit-reversal (2 bits): (0,1,2,3) → (0,2,1,3)
   A = [1, 0, 2, 0]
   B = [3, 0, 4, 0]

3. NTT transform (2 stages):
   Stage 1 (len=2):
     Butterfly [1,0]:  [1+0,  1-0]  = [1, 1]
     Butterfly [2,0]:  [2+0,  2-0]  = [2, 2]
     Butterfly [3,0]:  [3+0,  3-0]  = [3, 3]
     Butterfly [4,0]:  [4+0,  4-0]  = [4, 4]
   Stage 2 (len=4): combine with roots ω⁰, ω¹

4. Pointwise multiply: C'[k] = A'[k] * B'[k]  (mod 998244353)

5. Inverse NTT + divide by 4:
   C = [3, 10, 8, 0]

6. Trim to length 3: [3, 10, 8]

Result: 3 + 10x + 8x²  (correct: 1·3=3, 1·4+2·3=10, 2·4=8)
```

## Why O(n log n)?

```
Recurrence: T(n) = 2·T(n/2) + O(n)

Recursion tree (n=8):
Level 0:  [a₀,a₁,a₂,a₃,a₄,a₅,a₆,a₇]       n=8 butterflies  (8 work)
Level 1:  [a₀,a₂,a₄,a₆] [a₁,a₃,a₅,a₇]    2 × n/2           (8 work)
Level 2:  [a₀,a₄][a₂,a₆] [a₁,a₅][a₃,a₇]  4 × n/4           (8 work)
Level 3:  single elements                   n × 1             (8 work)

log₂(n) levels, each doing O(n) butterfly work → O(n log n) total.
```

## API

```
ntt_convolution(a, b)
  - Multiplies two integer polynomials modulo 998244353
  - Returns coefficients of the product; length = a.len + b.len - 1
  - Input: ArrayView[Int64]  Output: Array[Int64]
```

## Example Usage

```mbt check
///|
test "ntt convolution example" {
  let a : Array[Int64] = [1L, 2L]
  let b : Array[Int64] = [3L, 4L]
  let c = @fft.ntt_convolution(a, b)
  inspect(c, content="[3, 10, 8]")
}
```

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
Treat digits as polynomial coefficients, multiply with FFT, handle carries.
Time: O(n log n) vs O(n²) naive.
```

### 2. String Matching with Wildcards
```
Encode pattern and text as polynomials.
Convolution finds positions where the pattern matches.
Time: O(n log n).
```

### 3. Counting Pairs by Sum
```
Count pairs (i,j) where a[i] + b[j] = k:
Create polynomials from the value sets; coefficient of x^k in the product
equals the count of such pairs.
```

### 4. Polynomial Division/Modulo
```
A(x) / B(x) and A(x) mod B(x):
Use Newton's method with FFT for O(n log n) division.
```

## Complexity

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

**Choose NTT when**: you need exact integer results and n is large.
**Choose FFT when**: floating-point precision is acceptable.

## Common Pitfalls

- **Modulo wrap**: NTT results are modulo `998244353`.
- **Output length**: the product has `a.len + b.len - 1` terms.
- **Power-of-two padding**: the internal array must be a power of two; `ntt_convolution` handles this automatically.
- **Negative coefficients**: normalize into `[0, mod)` before comparison.

## Edge Cases

```
If either input polynomial is empty, the product is empty [].
If one polynomial is a constant c, the output is c times every coefficient of the other.
```

## Implementation Notes

- Array size must be a power of 2; pad with zeros to reach the next power.
- Bit-reversal is computed iteratively in O(n).
- For the inverse, roots are replaced by their modular inverses and the result is divided by n.
- NTT eliminates floating-point errors entirely; all arithmetic is in Z/pZ.
- Use 64-bit integers to avoid overflow in intermediate products (mod p < 2^30, product < 2^60 < 2^63).
