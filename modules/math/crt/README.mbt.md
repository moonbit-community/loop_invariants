# Chinese Remainder Theorem

## Overview

The **Chinese Remainder Theorem** (Sun Zi, ~3rd century CE) solves a
system of simultaneous congruences

```
x ≡ r₀ (mod m₀)
x ≡ r₁ (mod m₁)
...
x ≡ rₖ₋₁ (mod mₖ₋₁)
```

When the moduli are pairwise coprime, a **unique** solution exists in
`[0, M)` where `M = m₀ · m₁ · ... · mₖ₋₁`. For arbitrary positive moduli,
a solution exists iff every pair is *consistent*:
`gcd(mᵢ, mⱼ) ∣ rᵢ − rⱼ`. This package handles both cases.

| Operation | Time | Space |
|---|---|---|
| `merge(r1, m1, r2, m2)` | `O(log min(m1, m2))` | `O(1)` |
| `solve(residues, moduli)` | `O(k log M)` | `O(1)` |

---

## The algorithm (Garner's incremental form)

Maintain a running solution `(x, M)` of all congruences merged so far.
To merge in `(r_i, m_i)`:

1. Solve `m_i_inv = inverse(M, m_i)` via extended GCD (or detect that
   it does not exist and the system is inconsistent).
2. Compute the unique increment `t` in `[0, m_i)` with
   `x + t·M ≡ r_i (mod m_i)`.
3. Update `x ← x + t·M` and `M ← lcm(M, m_i)`.

For coprime moduli the LCM is just the product `M · m_i`; for the
general case we use the more careful `lcm = m_i · M / gcd`.

---

## The invariant

> After merging the first `j` congruences, `(x, M)` satisfies
> `0 ≤ x < M` and `x ≡ r_i (mod m_i)` for every `i < j`.

A `None` return means the next congruence is inconsistent with the
current `(x, M)`.

---

## API

```
pub fn merge(r1 : Int64, m1 : Int64, r2 : Int64, m2 : Int64)
  -> (Int64, Int64)?
pub fn solve(residues : Array[Int64], moduli : Array[Int64])
  -> (Int64, Int64)?
```

- `merge` returns `Some((r, m))` with `m = lcm(m1, m2)`, or `None` when
  inconsistent.
- `solve` returns `Some((x, M))` with `0 ≤ x < M = lcm(moduli)`, or
  `None` for an inconsistent / malformed input.

---

## Tests and examples

```mbt check
///|
test "crt classical sun zi" {
  // x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7) -> x = 23 mod 105.
  debug_inspect(
    @crt.solve([2L, 3L, 2L], [3L, 5L, 7L]),
    content="Some((23, 105))",
  )
}
```

```mbt check
///|
test "crt non-coprime moduli still merge" {
  // x ≡ 1 (mod 4), x ≡ 5 (mod 6) consistent (gcd=2 divides 4); answer 5 mod 12.
  debug_inspect(@crt.merge(1L, 4L, 5L, 6L), content="Some((5, 12))")
}
```

```mbt check
///|
test "crt detects inconsistency" {
  // gcd(4, 6) = 2 does not divide 2 − 1 = 1, so no solution.
  debug_inspect(@crt.merge(1L, 4L, 2L, 6L), content="None")
}
```

---

## Use cases

- **Big integer arithmetic** modulo several small primes
  (Montgomery / Barrett-free way to multiply 128-bit numbers).
- **Reconstruction in number-theoretic transforms** when working in
  multiple NTT-friendly primes.
- **Counting and parity arguments**: combining mod-`p` answers from a
  set of distinct small primes to recover a 64-bit answer.
- **Calendar arithmetic** — the original motivation: the 60-year Sexagenary
  Cycle in the Chinese calendar is `lcm(10, 12)`.

---

## Pitfalls

- **Overflow.** The internal product `m1 · k` (where `k < m2/gcd`) can
  overflow `Int64` once `lcm` exceeds `2^62`. For larger moduli use
  bignum arithmetic.
- **Non-positive moduli.** `solve` returns `None` if any modulus is
  `≤ 0`; `merge` assumes both are positive.
- **Empty input.** `solve` returns `None` for an empty list to avoid
  the ambiguity of "everything is a solution".
- **Mismatched arrays.** Returning `None` rather than asserting keeps
  the API total.

---

## Related concepts

```
Extended Euclidean   the inverse used inside every merge
Garner's algorithm   incremental CRT (this package)
Mixed-radix form     the basis Garner expands x in
Hensel lifting       p-adic analogue: lifting solutions mod p^k
```
