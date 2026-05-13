# Lucas-Lehmer Primality Test

## Overview

A *specialised* primality test for Mersenne numbers `M_p = 2^p - 1`.
Where general-purpose tests like Miller-Rabin must work over all
integers, Lucas-Lehmer exploits the algebraic structure of Mersenne
numbers to give a **deterministic, polynomial-time, single-witness**
primality test for this one family.

- **Time**: O(p · log² M_p) — i.e. `O(p³)` Int ops with overflow-safe `mul_mod`
- **Space**: O(1)
- **Signatures**:
  - `is_mersenne_prime(p : Int) -> Bool`
  - `mersenne_prime_exponents_up_to(n : Int) -> Array[Int]`

This is the algorithm GIMPS uses (in many-digit precision) to discover
the world's largest primes. As of 2024 it has produced the 52 largest
known primes, all of which are Mersenne primes.

---

## The recurrence

Let `M_p = 2^p - 1`. Define

```
s_0  =  4
s_i  =  (s_{i-1}² - 2)  mod  M_p     for i ≥ 1
```

Then:

> `M_p` is prime if and only if `s_{p-2} ≡ 0 (mod M_p)`.

That's the entire algorithm. Five lines of code give you a
deterministic primality test for numbers with billions of digits.

---

## Worked example: `p = 5`, `M_p = 31`

```
s_0  =  4
s_1  =  (4² - 2) mod 31   =   14
s_2  =  (14² - 2) mod 31  =   (196 - 2) mod 31  =  194 mod 31  =  8
s_3  =  (8²  - 2) mod 31  =   62 mod 31         =  0           ✓
```

`s_{p-2} = s_3 = 0`, so `M_5 = 31` is prime.

---

## A counterexample: `p = 11`, `M_p = 2047`

`2047 = 23 · 89`. Lucas-Lehmer must catch this:

```
s_0 = 4,  s_1 = 14,  s_2 = 194,   s_3 = 788,   s_4 = 701,
s_5 = 119, s_6 = 1877, s_7 = 240, s_8 = 282,  s_9 = 1736
```

`s_{p-2} = s_9 = 1736 ≠ 0`, so the test correctly reports composite.

Note that `p = 11` is prime, but the Mersenne number `M_11` is not.
Lucas-Lehmer never relies on `p` being prime — it works directly on
`M_p`.

---

## Why it works (one-line sketch)

Define `omega = 2 + sqrt(3)` and `omega' = 2 - sqrt(3)` in the ring
`Z[sqrt(3)]`. Then by induction

```
s_i  =  omega^{2^i} + omega'^{2^i}
```

so `s_{p-2} ≡ 0 (mod M_p)` becomes a statement about the order of
`omega` in `(Z[sqrt(3)] / M_p)*`. By a Fermat-style argument
(Bruce 1993, J. Recreational Math), that order is exactly `2^p`
when `M_p` is prime, and strictly less otherwise — which translates
to the `s_{p-2} = 0` condition.

---

## Range and overflow

For `Int64` arithmetic we need `M_p < 2^63`, i.e. `p ≤ 62`. Going
beyond requires arbitrary-precision integers. This package defensively
returns `false` for `p > 62`. The known Mersenne-prime exponents
within `Int64` range are

```
2, 3, 5, 7, 13, 17, 19, 31
```

(The next is `p = 61`, which fits too. After that the exponents jump
to 89, 107, ..., needing bignums.)

---

## Tests and examples

```mbt check
///|
test "lucas-lehmer M5 prime" {
  debug_inspect(@lucas_lehmer.is_mersenne_prime(5), content="true")
}
```

```mbt check
///|
test "lucas-lehmer M11 composite" {
  // 2047 = 23 * 89 -- a prime exponent with a non-prime Mersenne.
  debug_inspect(@lucas_lehmer.is_mersenne_prime(11), content="false")
}
```

```mbt check
///|
test "lucas-lehmer composite exponent" {
  // For composite p (like 4), M_p is automatically composite.
  debug_inspect(@lucas_lehmer.is_mersenne_prime(4), content="false")
}
```

```mbt check
///|
test "lucas-lehmer first eight exponents" {
  // OEIS A000043 starts 2, 3, 5, 7, 13, 17, 19, 31, ...
  debug_inspect(
    @lucas_lehmer.mersenne_prime_exponents_up_to(32),
    content="[2, 3, 5, 7, 13, 17, 19, 31]",
  )
}
```

---

## Complexity

| Operation | Time | Space |
|---|---|---|
| `is_mersenne_prime(p)` | `O(p · log² M_p) = O(p³)` Int ops | O(1) |
| `mersenne_prime_exponents_up_to(n)` | sum of above for p ≤ n | O(n) output |

A specialised modular reduction `x mod (2^p - 1)` shifts the high `p`
bits down to the low end and adds — much faster than general
`mul_mod`. We don't bother here since within `Int64` the cubic factor
is small. For multi-thousand-digit Mersenne numbers (GIMPS scale),
specialised bignum + FFT multiplication is essential.

---

## When to reach for it

- **Confirming a specific Mersenne candidate is prime**: this is *the*
  test. Probabilistic tests like Miller-Rabin can tell you it's
  probably prime, but Lucas-Lehmer gives a deterministic certificate.
- **Hunting for the next world-record prime**: GIMPS distributes
  Lucas-Lehmer tests across volunteer machines. Each test is
  embarrassingly parallel-friendly.
- **As a teaching example for algebraic primality tests**: the proof
  uses a quadratic field extension and Fermat's little theorem in a
  surprisingly tangible way.

---

## Related concepts

```
Lucas-Lehmer (this)           specialised to M_p = 2^p - 1
Lucas-Lehmer-Riesel           generalises to N = k * 2^n - 1
Pepin's test                  Fermat primes F_n = 2^{2^n} + 1
Pocklington-Lehmer            general primality with partial factorisation
AKS                           polynomial-time deterministic, no factorisation
Miller-Rabin                  randomised, works for any N
```
