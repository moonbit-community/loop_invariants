# Wilson's Theorem Primality

## Overview

**Wilson's theorem** (1770) gives a striking characterisation of
primality: an integer `n >= 2` is prime if and only if

```
(n - 1)!  ≡  -1   (mod n)
```

This package exposes:

- `is_prime(n) -> Bool` — Wilson's theorem primality test
- `wilson_quotient(p) -> Int64?` — `((p-1)! + 1) / p` mod `p` for prime `p`

Wilson is **not a practical primality test** — it costs `O(n)` modular
multiplications and is wildly outperformed by Miller-Rabin and
Solovay-Strassen. It is included here for its theoretical elegance,
and because it is the simplest deterministic if-and-only-if primality
test in elementary number theory.

- **Time**: `O(n)`
- **Space**: `O(1)`

---

## Why the theorem works

For a prime `p`, every non-zero residue mod `p` has a unique inverse.
The only self-inverses are `±1`, because `x² ≡ 1` mod `p` implies
`(x-1)(x+1) ≡ 0`, and `Z_p` has no zero divisors.

So in the product `1 · 2 · 3 · ... · (p-1) (mod p)`, every element
`x ∈ [2, p-2]` pairs up with its (distinct) inverse, and each pair
contributes `1`. What's left is `1 · (p-1) ≡ -1`.

Conversely, if `n > 4` is composite, then `n` has a factor `d` with
`2 ≤ d ≤ n/2`, and `d` and `n/d` both appear distinctly in `(n-1)!`,
so `n | (n-1)!`. The edge case is `n = 4`, where `(4-1)! = 6 ≡ 2 mod
4`, which is neither `0` nor `-1`, so the test correctly returns
`false`.

---

## The invariant

The implementation maintains a running product `prod` through the loop
`k = 2, 3, ..., n-1`, with the invariant

> **After processing `k`, `prod ≡ k! mod n`.**

The function returns true iff `prod` equals `n - 1` (i.e., `-1 mod n`)
at the end of the loop.

There's one practical optimisation: once `prod` hits `0`, it stays `0`
forever, so we can bail out early — every composite `n > 4` triggers
this short-circuit before the loop finishes.

---

## Reference implementation

```
pub fn is_prime(n : Int64) -> Bool
pub fn wilson_quotient(p : Int64) -> Int64?
```

---

## Wilson primes

A **Wilson prime** is a prime `p` for which

```
(p - 1)! ≡ -1 (mod p²)
```

equivalently, the Wilson quotient is divisible by `p`. The only known
Wilson primes are `5`, `13`, and `563`. No further example is known
below `2 · 10¹³` — but it is conjectured that infinitely many exist.

```mbt check
///|
test "wilson primes 5 and 13" {
  debug_inspect(@wilson_primality.wilson_quotient(5L), content="Some(0)")
  debug_inspect(@wilson_primality.wilson_quotient(13L), content="Some(0)")
}
```

---

## Tests and examples

```mbt check
///|
test "wilson basic" {
  debug_inspect(@wilson_primality.is_prime(7L), content="true")
  debug_inspect(@wilson_primality.is_prime(15L), content="false")
}
```

```mbt check
///|
test "wilson all primes below 30" {
  let primes_below_30 = [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L]
  for p in primes_below_30 {
    debug_inspect(@wilson_primality.is_prime(p), content="true")
  }
}
```

```mbt check
///|
test "wilson edge case 4" {
  debug_inspect(@wilson_primality.is_prime(4L), content="false")
}
```

---

## Practical comparison

| Test | Time per query | Deterministic | Notes |
|---|---|---|---|
| **Wilson (this)** | `O(n)` | yes | Only practical for tiny n |
| Trial division | `O(√n)` | yes | Fine up to ~10¹² |
| AKS | `O(log⁶ n)` polynomial | yes | Theoretical, slow in practice |
| Miller-Rabin | `O(k log³ n)` | no (with k bases) | Standard for cryptography |
| Solovay-Strassen | `O(k log³ n)` | no | Historical, slightly weaker than MR |

---

## Pitfalls

- **Overflow**. `(n-1)!` mod `n` is computed using Int64 modular
  arithmetic, which is safe as long as `n² < 2⁶³` — i.e. `n < ~3 · 10⁹`.
  For `n > 2³¹` use 128-bit modular multiplication or Montgomery
  reduction.
- **Wilson quotient overflow**. `wilson_quotient` works modulo `p²`,
  so it requires `p² < 2⁶³`, i.e. `p < 3 · 10⁹`. (The third known
  Wilson prime, `563`, is well within range.)
- **Don't use this for cryptography**. `O(n)` is infeasible for
  cryptographic-size primes (~2⁵¹² and up). Use Miller-Rabin.

---

## Related concepts

```
Wilson's theorem (this)     iff primality via (n-1)!
Fermat's little theorem     a^(p-1) ≡ 1 (mod p) for gcd(a, p) = 1
Euler's theorem             a^phi(n) ≡ 1 (mod n) for gcd(a, n) = 1
Miller-Rabin                deterministic with known witnesses for n < ~3 · 10^24
Solovay-Strassen            Jacobi-symbol-based probabilistic primality
AKS                         deterministic poly-time primality (Agrawal-Kayal-Saxena 2002)
```
