# Möbius Function

## Overview

The **Möbius function** `mu(n)` is defined by:

```
mu(1) = 1
mu(n) = 0       if any prime divides n more than once
mu(n) = (-1)^k  if n = p_1 · p_2 · ... · p_k (k distinct primes)
```

It is the Dirichlet-convolution inverse of the constant-1 function:
`sum_{d | n} mu(d) = [n == 1]`. From this comes **Möbius inversion**:

```
g(n) = sum_{d | n} f(d)   <=>   f(n) = sum_{d | n} mu(d) · g(n / d)
```

a standard technique for converting between divisor-sum forms and their
"squarefree-only" cousins.

| Operation | Time | Space |
|---|---|---|
| `mu(n)` (single value) | `O(sqrt(n))` | `O(1)` |
| `sieve(n)` (all up to n) | `O(n)` | `O(n)` |

---

## Algorithms

**Single value** (`mu`). Trial-divide `n`. If any prime appears twice we
return `0` immediately; otherwise count the distinct prime factors and
return `(-1)^count`.

**Bulk** (`sieve`). Linear sieve: for each composite `k = p · i` where
`p` is the smallest prime factor of `k`,

- if `p | i`, then `p^2 | k`, so `mu(k) = 0`,
- otherwise `mu(k) = -mu(i)`.

---

## The invariant

`mu`: at every iteration of the trial-division loop, after processing
all primes up to (but not including) `p`,

> `sign == (-1)^{(distinct primes of n_original seen)}`
> and `m` equals `n_original` with those primes removed exactly once.

If any prime is found to divide `m` *twice*, we abort with `0`.

---

## API

```
pub fn mu(n : Int64) -> Int
pub fn sieve(n : Int) -> Array[Int]
```

- `mu(n)` returns `0` for `n ≤ 0`.
- `sieve(n)` returns `[]` for `n < 0`, `[0]` for `n = 0`, and otherwise
  an array of length `n + 1` with `result[k] = mu(k)` for `1 ≤ k ≤ n`.

---

## Tests and examples

```mbt check
///|
test "mu squarefree" {
  // 30 = 2·3·5, three distinct primes -> (-1)^3 = -1.
  debug_inspect(@mobius.mu(30L), content="-1")
}
```

```mbt check
///|
test "mu non-squarefree" {
  // 12 = 2²·3 contains 4 -> 0.
  debug_inspect(@mobius.mu(12L), content="0")
}
```

```mbt check
///|
test "mu unit" {
  debug_inspect(@mobius.mu(1L), content="1")
}
```

```mbt check
///|
test "sieve small" {
  let m = @mobius.sieve(10)
  // mu(6) = 1
  debug_inspect(m[6], content="1")
}
```

---

## Use cases

- **Counting squarefree numbers** in an interval (use partial sums of
  `mu^2`).
- **Inverting divisor sums** that show up in number-theoretic identities
  (e.g. `phi = mu * Id` under Dirichlet convolution).
- **Mertens function** `M(n) = sum_{k=1..n} mu(k)`, related to the
  Riemann hypothesis.
- **Inclusion-exclusion** over divisors of a fixed integer, often
  shorter than explicit subset enumeration.

---

## Pitfalls

- **Sign of zero/negative input.** We return `0` rather than raising;
  the function is only defined for positive `n`.
- **`sieve(n)` memory.** Allocates `O(n)` ints; budget RAM if `n` is in
  the tens of millions.

---

## Related concepts

```
Möbius inversion           the duality used throughout this package
Dirichlet convolution      mu is the convolution inverse of 1
Euler's totient            phi = mu * Id (in the Dirichlet sense)
Mertens function           M(n) = sum mu(k); cumulative sums of mu
Liouville function         lambda(n) = (-1)^Omega(n), a related sign
```
