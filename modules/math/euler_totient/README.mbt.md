# Euler's Totient Function

## Overview

Euler's **totient function** `phi(n)` counts the integers in `[1, n]`
that are coprime to `n`. It satisfies:

```
phi(1)         = 1
phi(p)         = p - 1                       for prime p
phi(p^k)       = p^k - p^{k-1} = p^{k-1}(p-1)
phi(m·n)       = phi(m)·phi(n)               if gcd(m, n) = 1
phi(n)         = n · prod_{p | n} (1 - 1/p)
```

| Operation | Time | Space |
|---|---|---|
| `phi(n)` (single value) | `O(sqrt(n))` | `O(1)` |
| `sieve(n)` (all up to n) | `O(n)` | `O(n)` |

`phi` underpins Euler's theorem: when `gcd(a, n) = 1`,
`a^{phi(n)} ≡ 1 (mod n)`. This is the basis of RSA.

---

## Algorithms

**Single value** (`phi`). Trial-divide `n`, and for every distinct prime
factor `p` apply `result -= result / p`. Strips factor 2 first so the
inner loop only inspects odd candidates.

**Bulk computation** (`sieve`). Linear sieve: for each composite
`k = p · i` where `p` is `k`'s smallest prime factor,

- if `p | i`, then `phi(k) = phi(i) · p`,
- otherwise `phi(k) = phi(i) · (p - 1)`.

Each composite is hit exactly once, giving `O(n)` time.

---

## The invariant

`phi`: at every iteration of the trial-division loop, after processing
all prime factors up to (but not including) `p`,

> `result == n_original · prod_{q prime, q | n_original, q < p} (1 − 1/q)`

When `p²  > m` and `m > 1`, `m` itself is the final prime factor and one
last multiplication finishes the job.

---

## API

```
pub fn phi(n : Int64) -> Int64
pub fn sieve(n : Int) -> Array[Int64]
```

- `phi(n)` returns `0` for `n ≤ 0`.
- `sieve(n)` returns an empty array for `n < 0`, a length-1 array
  `[0]` for `n = 0`, and otherwise an array of length `n + 1` with
  `result[k] = phi(k)` for `1 ≤ k ≤ n`. `result[0]` is `0` by
  convention.

---

## Tests and examples

```mbt check
///|
test "phi small" {
  // phi(12) counts {1, 5, 7, 11} = 4.
  debug_inspect(@euler_totient.phi(12L), content="4")
}
```

```mbt check
///|
test "phi prime" {
  debug_inspect(@euler_totient.phi(101L), content="100")
}
```

```mbt check
///|
test "sieve up to 10" {
  let t = @euler_totient.sieve(10)
  debug_inspect(t[10], content="4")
  debug_inspect(t[7], content="6")
}
```

---

## Use cases

- **RSA key generation**: `d = e^{-1} mod phi(n)`.
- **Euler's theorem / Fermat's little theorem** (special case): used in
  modular exponent reduction.
- **Counting Farey fractions**: `|Farey_n| = 1 + sum_{k=1..n} phi(k)`.
- **Number-theoretic generating functions**: many Dirichlet convolutions
  involve `phi`.

---

## Pitfalls

- **Overflow.** `phi(p²)` for `p` near `2^31.5` already approaches
  `Int64` limits. For larger `n` use bignum arithmetic.
- **`n ≤ 0`** returns `0`, a convention; the totient is only defined
  for `n ≥ 1`.
- **`sieve(n)` allocates O(n) memory.** Avoid for `n > 10^7` unless you
  have the RAM.

---

## Related concepts

```
Euler's theorem      a^{phi(n)} ≡ 1 (mod n) when gcd(a, n) = 1
Mobius function      sum_{d | n} mu(d) = [n = 1]; pair with phi via convolution
Carmichael function  lambda(n) | phi(n), the actual order of (Z/nZ)*
Jordan totient       generalisation J_k(n) counting k-tuples coprime to n
```
