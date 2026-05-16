# Miller-Rabin Primality Test

## Overview

The **Miller-Rabin primality test** decides whether a positive integer
`n` is prime by inspecting the structure of `(Z/nZ)*` under
exponentiation. With the right small witness set, it is **deterministic**
for every `Int64` in `O(log³ n)` bit operations.

| Operation | Time | Space |
|---|---|---|
| `is_prime(n)` (12 fixed bases) | `O(log³ n)` bit operations | `O(1)` |

This package uses the witness set
`{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}`, proven to be
deterministic for all `n < 3.3 · 10²⁴` (Sorenson & Webster 2017) —
which covers the entire `Int64` range.

---

## The mathematics

Write `n - 1 = 2^s · d` with `d` odd. For any prime `n` and any
`a` not divisible by `n`, **one** of these must hold:

```
a^d ≡ 1  (mod n)
a^(2^r · d) ≡ -1  (mod n)   for some 0 ≤ r < s
```

If neither holds, `n` is composite and `a` is a **witness** for that
fact. Rabin proved that for any composite `n` and a random
`a ∈ [2, n-2]`, the probability that `a` fails to witness is at most
`1/4`. With a clever choice of *fixed* small primes as witnesses, the
test becomes deterministic up to a known bound — see Sorenson &
Webster (2017).

---

## The invariant

In the squaring loop, after the initial exponentiation `x = a^d mod n`:

> At every iteration with counter `r`, `x ≡ a^(2^r · d)  (mod n)`.

We exit early when `x == n - 1` (witness passed) or when `x == 1` after
`r > 0` (a *nontrivial* square root of 1 — witness fails). Exhausting
the `s` squarings without seeing `n - 1` also means the witness fails.

---

## API

```
pub fn is_prime(n : Int64) -> Bool
```

Returns `true` iff `n` is prime. Handles `n ≤ 1` and negative inputs
(returning `false`).

---

## Tests and examples

```mbt check
///|
test "is_prime small primes" {
  debug_inspect(@miller_rabin.is_prime(2L), content="true")
  debug_inspect(@miller_rabin.is_prime(97L), content="true")
}
```

```mbt check
///|
test "is_prime small composites" {
  debug_inspect(@miller_rabin.is_prime(1L), content="false")
  debug_inspect(@miller_rabin.is_prime(91L), content="false")
}
```

```mbt check
///|
test "is_prime Carmichael number" {
  // Carmichael numbers fool Fermat -- not Miller-Rabin.
  debug_inspect(@miller_rabin.is_prime(561L), content="false")
}
```

```mbt check
///|
test "is_prime competitive-programming primes" {
  debug_inspect(@miller_rabin.is_prime(998244353L), content="true")
  debug_inspect(@miller_rabin.is_prime(1000000007L), content="true")
}
```

---

## Use cases

- **Cryptography**: probabilistic large-prime generation (e.g. RSA,
  Diffie-Hellman).
- **Competitive programming**: testing primality of intermediate values
  inside number-theoretic algorithms (Pollard rho, factorization).
- **Building block** for Solovay-Strassen and AKS sanity checks.

---

## Pitfalls

- **Negative or zero inputs**. We return `false` — primality is defined
  only for `n ≥ 2`.
- **Bigger than Int64**. The deterministic witness set covers all 64-bit
  integers, but for `n > Int64.max_value` (e.g. RSA-size moduli) you
  need bignum modular arithmetic.
- **Modular multiplication overflow**. `a · b mod n` with `a, b ~ 2^62`
  overflows naively. We use binary "Russian-peasant" multiplication to
  stay inside `Int64`.

---

## Related concepts

```
Fermat's little theorem   the weaker test that Carmichael numbers fool
Solovay-Strassen          Jacobi-symbol-based probabilistic test
AKS                       polynomial-time *deterministic* primality
Pollard rho / p-1         integer factorization (uses primality as a check)
```
