# Pollard's Rho Factorization

## Overview

**Pollard's Rho** is a probabilistic algorithm for integer factorization. Combined
with **Miller-Rabin primality testing**, it can factor 64-bit integers very efficiently.

- **Time**: Expected O(n^(1/4)) for finding a factor
- **Space**: O(1) extra
- **Key Feature**: Fast factorization of large numbers

## The Key Insight

```
Problem: Factor a large number n

Trial division: Check all primes up to √n → O(√n) → too slow for large n

Pollard's Rho insight:
  - Generate a pseudorandom sequence: x_{i+1} = x_i² + c (mod n)
  - If n = p × q, the sequence "cycles" modulo p before cycling modulo n
  - Use cycle detection to find gcd(|x - y|, n) > 1

Expected time: O(√p) ≈ O(n^(1/4)) for smallest prime factor p
```

## Understanding the Birthday Paradox Connection

```
The algorithm exploits the birthday paradox:

In a group of √n random values, likely two are equal (mod √n).

If n = p × q with p ≈ √n:
  - Our sequence visits √p values before repeating (mod p)
  - √p ≈ n^(1/4)
  - When x_i ≡ x_j (mod p), we have gcd(|x_i - x_j|, n) divisible by p

This gives us a factor!
```

## The Pseudorandom Sequence

```
x_{i+1} = x_i² + c (mod n)

Example: n = 91 (= 7 × 13), c = 1, x_0 = 2

x_0 = 2
x_1 = 2² + 1 = 5
x_2 = 5² + 1 = 26
x_3 = 26² + 1 = 677 = 586 (mod 91)
x_4 = 586² + 1 = 343397 = 37 (mod 91)
...

The sequence eventually cycles, and the cycle has special structure
related to the factors of n.
```

## Floyd's Cycle Detection (Tortoise and Hare)

```
To detect the cycle without storing the sequence:

Tortoise: moves 1 step at a time (x)
Hare: moves 2 steps at a time (y)

x = f(x)        // tortoise: one step
y = f(f(y))     // hare: two steps

Eventually they meet: x_i = x_{2i} (mod p)
Then gcd(|x - y|, n) might give us a factor!

  ┌────────────────────┐
  │                    │
  ↓                    │
  ○ → ○ → ○ → ○ → ○ → ○
  ^         ^
  │         │
  x       y (moves faster)
```

## Algorithm Walkthrough

```
Factor n = 91 (= 7 × 13):

Choose c = 1, x = y = 2

Iteration 1:
  x = x² + 1 = 5
  y = (y² + 1)² + 1 = 5² + 1 = 26
  gcd(|5 - 26|, 91) = gcd(21, 91) = 7 ← Found a factor!

91 = 7 × 13

Let's verify:
  x_1 = 5, x_2 = 26
  5 mod 7 = 5
  26 mod 7 = 5
  5 ≡ 26 (mod 7) ✓
  So gcd(26-5, 91) = gcd(21, 91) = 7 ✓
```

## Miller-Rabin Primality Test

```
Before factoring, check if n is prime!

Miller-Rabin: Fast probabilistic primality test
  - Write n-1 = 2^s × d (d odd)
  - For witness a: compute a^d mod n
  - Square s times, looking for ±1 patterns

For 64-bit integers, testing specific witnesses is DETERMINISTIC:
  Witnesses: 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37

If n passes all these witnesses, n is definitely prime (for 64-bit n).
```

## Quick Start

```mbt check
///|
test "pollard rho quick start" {
  let factors = @pollard_rho.factorize_with_counts(8051L)
  inspect(factors, content="[(83, 1), (97, 1)]")
}
```

## More Examples

```mbt check
///|
test "pollard rho is_prime" {
  inspect(@pollard_rho.is_prime(2L), content="true")
  inspect(@pollard_rho.is_prime(97L), content="true")
  inspect(@pollard_rho.is_prime(221L), content="false")
}
```

```mbt check
///|
test "pollard rho large factor" {
  // Factor 1000003 × 1000033
  let n = 1000003L * 1000033L
  let factors = @pollard_rho.factorize_with_counts(n)
  inspect(factors, content="[(1000003, 1), (1000033, 1)]")
}
```

## The Complete Algorithm

```
factorize(n):
  if n <= 1: return []
  if is_prime(n): return [n]

  // Find a non-trivial factor
  d = pollard_rho(n)

  // Recursively factor both parts
  return factorize(d) + factorize(n/d)

pollard_rho(n):
  x = y = random start
  c = random constant

  while true:
    x = x² + c (mod n)
    y = (y² + c)² + c (mod n)   // two steps

    d = gcd(|x - y|, n)

    if 1 < d < n:
      return d  // found a factor!

    if d == n:
      // bad luck, restart with different c
      restart with new c
```

## Common Applications

### 1. Cryptography Analysis
```
Breaking RSA requires factoring n = p × q.
Pollard's Rho works when one factor is "small" (< 10^12).
```

### 2. Number Theory
```
Compute Euler's totient φ(n) = n × ∏(1 - 1/p).
Need prime factorization first.
```

### 3. Competitive Programming
```
Factor numbers up to 10^18 quickly.
Combined with primality test, very practical.
```

### 4. Discrete Logarithm
```
Pollard's Rho for discrete log uses similar ideas.
Find x such that g^x ≡ h (mod p).
```

## Complexity Analysis

| Operation | Expected Time |
|-----------|---------------|
| Miller-Rabin (64-bit) | O(log³ n) |
| Find one factor | O(n^(1/4)) |
| Complete factorization | O(n^(1/4) × k) for k factors |

## Pollard's Rho vs Other Methods

| Method | Time | Use Case |
|--------|------|----------|
| **Pollard's Rho** | O(n^(1/4)) | General factorization |
| Trial Division | O(√n) | Very small numbers |
| Quadratic Sieve | O(exp(√(ln n ln ln n))) | Large semiprimes |
| GNFS | O(exp(...)) | Very large numbers |

**Choose Pollard's Rho when**: Factoring numbers up to ~10^18 or when factors are moderate size.

## Factorization Tips

- The factor list is sorted and includes repeats (e.g. `12 -> [2, 2, 3]`)
- For `(prime, exponent)` pairs, use `factorize_with_counts`
- Input `n <= 1` returns an empty list
- For n = 1, returns empty (no prime factors)

## Implementation Notes

- Always test primality before trying to factor
- If gcd returns n, the sequence cycled badly; restart with different c
- Brent's improvement: vary the cycle detection for ~25% speedup
- Use Montgomery multiplication for faster modular arithmetic
- For 64-bit, use 128-bit intermediate values to avoid overflow

