# Linear Recurrence (Kitamasa Method)

## Overview

This package computes the **n-th term** of a linear recurrence in **O(k² log n)**
time using the Kitamasa method (polynomial doubling). It's faster than matrix
exponentiation for computing a single term.

```
f(n) = c₀·f(n-1) + c₁·f(n-2) + ... + c_{k-1}·f(n-k)  (mod M)
```

- **Time**: O(k² log n)
- **Space**: O(k)
- **Key Feature**: No matrix multiplication needed

## The Key Insight

```
Matrix exponentiation approach:
  [f(n)  ]   [c₀ c₁ ... c_{k-1}]^n   [f(k-1)]
  [f(n-1)] = [1  0  ...    0   ]   · [f(k-2)]
  [  ⋮   ]   [⋮        ⋱      ]     [  ⋮   ]
  [f(n-k+1)] [0  0  ... 1  0   ]     [f(0)  ]

Time: O(k³ log n) for matrix exponentiation

Kitamasa insight:
  We don't need the full matrix, just how to express f(n) in terms
  of f(0), f(1), ..., f(k-1)!

  f(n) = a₀·f(0) + a₁·f(1) + ... + a_{k-1}·f(k-1)

  Find coefficients [a₀, a₁, ..., a_{k-1}] directly!
  Time: O(k² log n)
```

## Visual: Polynomial Representation

```
Recurrence: f(n) = f(n-1) + f(n-2)  (Fibonacci, k=2)
Initial: f(0) = 0, f(1) = 1

Express f(n) as: a₀·f(0) + a₁·f(1)

f(0) = 1·f(0) + 0·f(1)  →  [1, 0]
f(1) = 0·f(0) + 1·f(1)  →  [0, 1]
f(2) = 1·f(0) + 1·f(1)  →  [1, 1]  (using recurrence)
f(3) = 1·f(1) + 1·f(2) = f(1) + f(0) + f(1) = f(0) + 2·f(1)  →  [1, 2]
f(4) = f(2) + f(3) = 2·f(0) + 3·f(1)  →  [2, 3]
...

Key: We're tracking coefficients, not computing values directly!
```

## Algorithm: Polynomial Doubling

```
Key operations on coefficient vectors [a₀, ..., a_{k-1}]:

1. DOUBLE: Compute coefficients for f(2n) from coefficients for f(n)
   - Multiply polynomial by itself
   - Reduce modulo the characteristic polynomial

2. INCREMENT: Compute coefficients for f(n+1) from f(n)
   - Shift polynomial
   - Reduce modulo the characteristic polynomial

Using binary representation of n:
  n = 13 = 1101₂

  Start: f(1) = [0, 1]
  Double: f(2)
  Double: f(4)
  Double + Inc: f(9)   (bit 3 = 1)
  Double: f(18)... wait, let's do this right

  Actually process bits from high to low:
  n = 13 = 1101₂

  Start with f(1)
  For each bit after the leading 1:
    - Always double (square the polynomial)
    - If bit is 1, also increment (shift polynomial)
```

## Example Usage

```mbt check
///|
test "linear recurrence fibonacci" {
  let m = 1000000007L
  let coeffs : Array[Int64] = [1L, 1L] // f(n) = 1*f(n-1) + 1*f(n-2)
  let initial : Array[Int64] = [0L, 1L] // f(0)=0, f(1)=1
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 7L, m),
    content="13",
  )
}
```

```mbt check
///|
test "linear recurrence geometric" {
  let m = 1000000007L
  let coeffs : Array[Int64] = [2L] // f(n) = 2*f(n-1)
  let initial : Array[Int64] = [1L] // f(0) = 1
  // f(n) = 2^n, so f(5) = 32
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 5L, m),
    content="32",
  )
}
```

## More Examples

```mbt check
///|
test "tribonacci sequence" {
  let m = 1000000007L
  // f(n) = f(n-1) + f(n-2) + f(n-3)
  let coeffs : Array[Int64] = [1L, 1L, 1L]
  let initial : Array[Int64] = [0L, 0L, 1L] // f(0)=0, f(1)=0, f(2)=1
  // f(3)=1, f(4)=2, f(5)=4, f(6)=7, f(7)=13
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 7L, m),
    content="13",
  )
}
```

## Algorithm Walkthrough

```
Fibonacci: f(n) = f(n-1) + f(n-2)
Compute f(7):

Characteristic polynomial: x² - x - 1 = 0
  (or equivalently: x² = x + 1)

Binary of 7 = 111₂

Step 1: Start with x¹ (represents f(1))
  coeffs = [0, 1]  meaning 0·f(0) + 1·f(1)

Step 2: Process bit 1 (second bit of 111):
  Double: x² = x + 1, so coeffs = [1, 1]  (represents f(2))
  Bit is 1, so increment: x³ = x² + x = (x+1) + x = 2x + 1
    coeffs = [1, 2]  (represents f(3))

Step 3: Process bit 2 (third bit of 111):
  Double: x⁶ = (x³)² = (2x+1)² = 4x² + 4x + 1
    Reduce: x² = x + 1, so 4x² = 4x + 4
    x⁶ = 4x + 4 + 4x + 1 = 8x + 5
    coeffs = [5, 8]  (represents f(6))
  Bit is 1, so increment: x⁷ = x · x⁶ = x(8x + 5) = 8x² + 5x
    Reduce: x² = x + 1, so 8x² = 8x + 8
    x⁷ = 8x + 8 + 5x = 13x + 8
    coeffs = [8, 13]  (represents f(7))

Final: f(7) = 8·f(0) + 13·f(1) = 8·0 + 13·1 = 13 ✓
```

## Why O(k² log n)?

```
Operations:
  - Double: Polynomial squaring + reduction = O(k²)
  - Increment: Polynomial shift + reduction = O(k)

Number of operations: O(log n) bits to process

Total: O(k² log n)

Compare to matrix exponentiation:
  - Matrix multiply: O(k³)
  - Number of multiplies: O(log n)
  - Total: O(k³ log n)

Kitamasa saves a factor of k!
```

## Common Applications

### 1. Fibonacci-like Sequences
```
Any linear recurrence: f(n) = c₀f(n-1) + c₁f(n-2) + ...
Compute f(10^18) in milliseconds.
```

### 2. Counting Problems
```
Many counting problems reduce to linear recurrences.
E.g., count tilings, paths, arrangements.
```

### 3. Polynomial Hash Computation
```
Compute x^n mod P(x) for polynomial hashing.
```

### 4. Sequence Generation
```
Generate pseudorandom numbers following a linear recurrence.
```

## Complexity Analysis

| Method | Time | Space |
|--------|------|-------|
| Naive iteration | O(n) | O(k) |
| Matrix exponentiation | O(k³ log n) | O(k²) |
| **Kitamasa** | **O(k² log n)** | **O(k)** |

## Kitamasa vs Matrix Exponentiation

```
Kitamasa advantages:
  - Faster by factor of k
  - Less memory (O(k) vs O(k²))
  - Simpler implementation

Matrix advantages:
  - Gives full state vector, not just f(n)
  - Easier to extend to matrix recurrences

Choose Kitamasa when:
  - You only need f(n), not the full state
  - k is large (saves factor of k)
```

## Implementation Notes

- `coeffs` and `initial` must have the same length k
- Work in modular arithmetic to avoid overflow
- Binary exponentiation on the coefficient vector
- Polynomial multiplication and reduction are the core operations

