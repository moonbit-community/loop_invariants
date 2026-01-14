# Lucas Theorem

## Overview

**Lucas' Theorem** computes binomial coefficients modulo a prime p:

```
C(n, k) mod p
```

It works for very large n and k by decomposing them into base-p digits.

- **Time**: O(p + log_p n)
- **Space**: O(p)
- **Key Feature**: Handle huge n and k when p is small

## The Key Insight

```
Problem: Compute C(n, k) mod p for large n

Direct computation: Need to handle factorials of huge numbers!

Lucas' insight: Decompose n and k into base-p digits!

n = n₀ + n₁·p + n₂·p² + ...
k = k₀ + k₁·p + k₂·p² + ...

Then:
C(n, k) ≡ C(n₀, k₀) · C(n₁, k₁) · C(n₂, k₂) · ... (mod p)

Each C(nᵢ, kᵢ) is small (nᵢ, kᵢ < p), so easy to compute!
```

## Visual: Digit Decomposition

```
Example: C(12, 5) mod 3

12 in base 3: 12 = 1·9 + 1·3 + 0 = (1, 1, 0)₃
 5 in base 3:  5 = 0·9 + 1·3 + 2 = (0, 1, 2)₃

Lucas' theorem:
C(12, 5) mod 3 = C(1, 0) · C(1, 1) · C(0, 2) mod 3

Wait, C(0, 2) = 0 (can't choose 2 from 0!)
So C(12, 5) mod 3 = 0

Verify: C(12, 5) = 792 = 264 × 3, so 792 mod 3 = 0 ✓
```

## The Formula

```
Lucas' Theorem:
For prime p, write n and k in base p:
  n = Σ nᵢ · pⁱ
  k = Σ kᵢ · pⁱ

Then:
  C(n, k) ≡ Π C(nᵢ, kᵢ) (mod p)

Key property:
  If any kᵢ > nᵢ, then C(nᵢ, kᵢ) = 0
  So the entire product is 0!
```

## Example Usage

```mbt check
///|
test "lucas theorem quick start" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(10L, 3L, 7L), content="1")
}
```

```mbt check
///|
test "lucas theorem small cases" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(5L, 2L, 5L), content="0")
  inspect(@lucas_theorem.nck_mod_prime_lucas(1000L, 500L, 2L), content="0")
}
```

## Algorithm

```
lucas(n, k, p):
  if k > n: return 0

  result = 1
  while n > 0 or k > 0:
    ni = n mod p
    ki = k mod p

    if ki > ni:
      return 0  // C(ni, ki) = 0

    result = result * C(ni, ki) mod p
    n = n / p
    k = k / p

  return result

// Precompute small binomial coefficients
// C[i][j] = C(i, j) for 0 ≤ i, j < p
precompute_binomials(p):
  C = 2D array of size p × p
  for i = 0 to p-1:
    C[i][0] = 1
    for j = 1 to i:
      C[i][j] = (C[i-1][j-1] + C[i-1][j]) mod p
  return C
```

## Algorithm Walkthrough

```
Compute C(10, 3) mod 7

10 in base 7: 10 = 1·7 + 3 = (1, 3)₇
 3 in base 7:  3 = 0·7 + 3 = (0, 3)₇

Lucas' theorem:
C(10, 3) mod 7 = C(1, 0) · C(3, 3) mod 7
               = 1 · 1 mod 7
               = 1 ✓

Verify: C(10, 3) = 120 = 17·7 + 1, so 120 mod 7 = 1 ✓
```

## Why It Works

```
The key is Fermat's Little Theorem and properties of (1+x)^p mod p.

For prime p:
  (1 + x)^p ≡ 1 + x^p (mod p)

This means:
  (1 + x)^n = (1 + x)^(n₀ + n₁·p + n₂·p² + ...)
            = (1 + x)^n₀ · ((1 + x)^p)^n₁ · ...
            ≡ (1 + x)^n₀ · (1 + x^p)^n₁ · ... (mod p)

Comparing coefficients of x^k gives Lucas' theorem!
```

## Common Applications

### 1. Competitive Programming
```
Many counting problems require C(n, k) mod p.
Lucas handles cases where n is very large.
```

### 2. Number Theory
```
Study divisibility of binomial coefficients.
Kummer's theorem extends Lucas' ideas.
```

### 3. Combinatorics
```
Count combinations modulo a prime.
Lattice path counting, ballot problems.
```

### 4. Cryptography
```
Some cryptographic protocols use modular binomials.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Precompute binomials | O(p²) | Pascal's triangle mod p |
| Single Lucas query | O(log_p n) | Process each digit |
| Space | O(p²) or O(p) | Store small binomials |

## When C(n,k) mod p = 0

```
By Lucas' theorem:
C(n, k) ≡ 0 (mod p) iff some digit kᵢ > nᵢ

Example: C(1000, 500) mod 2
1000 in binary: 1111101000
 500 in binary: 0111110100

Compare digit by digit:
  Position 0: 0 vs 0 ✓
  Position 1: 0 vs 0 ✓
  Position 2: 0 vs 1 ✗ (k's bit > n's bit!)

So C(1000, 500) mod 2 = 0

This relates to Kummer's theorem:
  The power of p dividing C(n,k) equals the number
  of "carries" when adding k and n-k in base p.
```

## Lucas vs Direct Computation

```
Direct: Compute n! / (k! · (n-k)!) mod p
  - Need modular inverse
  - O(n) for factorial computation
  - Fails for n ≥ p (n! ≡ 0 mod p)

Lucas: Decompose into small binomials
  - O(log_p n) digits to process
  - Each digit binomial is easy
  - Works for arbitrary large n!

Use Lucas when: n is large, p is small prime
Use direct when: n < p
```

## Implementation Notes

- Precompute C(i,j) for i,j < p using Pascal's triangle
- Process digits of n and k from least significant
- Short-circuit if any kᵢ > nᵢ
- Handle k > n case (return 0)

## Generalizations

```
Lucas works for prime p.

For prime powers p^k:
  Use generalized Lucas (more complex)

For composite moduli:
  Use Chinese Remainder Theorem
  Decompose m = p₁^k₁ · p₂^k₂ · ...
  Compute C(n,k) mod each prime power
  Combine with CRT
```

