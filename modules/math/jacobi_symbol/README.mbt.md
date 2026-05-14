# Jacobi Symbol

## Overview

The **Jacobi symbol** `(a / n)` generalises the Legendre symbol from
prime moduli to odd composite moduli, taking values in `{-1, 0, +1}`.
It can be computed in `O(log n)` arithmetic operations **without
factoring `n`**, using a Euclidean-style algorithm based on quadratic
reciprocity.

- **Time**: `O(log² n)` bit operations
- **Space**: `O(1)`
- **Signature**: `jacobi(a : Int64, n : Int64) -> Int`

`n` must be an odd positive integer. The result is `0`, `+1`, or `-1`.

This is the building block for the **Solovay-Strassen primality
test**, which checks whether `a^((n-1)/2) ≡ (a / n) (mod n)` for
several random `a`.

---

## Definition

For an odd prime `p`:

```
(a / p) =  0     if p | a
        = +1    if a is a quadratic residue mod p
        = -1    if a is a quadratic non-residue mod p
```

For an odd positive composite `n = p₁^e₁ · p₂^e₂ · ... · pₖ^eₖ`:

```
(a / n) = (a / p₁)^e₁ · (a / p₂)^e₂ · ... · (a / pₖ)^eₖ
```

Crucially: when `n` is composite, `(a / n) = +1` does **not** imply
`a` is a QR mod `n`. The symbol only tells you the product is `+1`.
However `(a / n) = -1` **does** imply `a` is not a QR.

---

## How to compute it without factoring

The Jacobi symbol obeys four useful rules:

1. **Periodicity**: `(a / n) = ((a mod n) / n)`.
2. **2-supplement**: `(2 / n) = +1` if `n ≡ ±1 (mod 8)`; `-1` if `n ≡ ±3 (mod 8)`.
3. **Multiplicativity**: `(ab / n) = (a / n) · (b / n)`.
4. **Quadratic reciprocity**: for odd `a, n > 0`,
   `(a / n) = (n / a) · (-1)^((a-1)(n-1)/4)`.

Combining them gives an Euclidean-style recursion that *swaps* the
arguments at each step. The algorithm halts when the upper argument
becomes 0 or 1, and runs in `O(log n)` steps.

---

## The invariant

> Throughout the algorithm, the running result `s` and the current
> arguments `(a', n')` satisfy `s · (a' / n') = (a₀ / n₀)`,
> where `(a₀, n₀)` are the original inputs.

When `a' = 0`, the symbol is `0` if `n' > 1` else `1`.

---

## Reference implementation

```
pub fn jacobi(a : Int64, n : Int64) -> Int
```

Returns `0` if `n` is not a positive odd integer.

---

## Tests and examples

```mbt check
///|
test "jacobi prime modulus" {
  // 7 has QRs {1, 2, 4} and non-QRs {3, 5, 6}.
  debug_inspect(@jacobi_symbol.jacobi(2L, 7L), content="1")
  debug_inspect(@jacobi_symbol.jacobi(3L, 7L), content="-1")
}
```

```mbt check
///|
test "jacobi composite modulus" {
  // (7 / 15) = (7/3)·(7/5) = (1/3)·(2/5) = 1·(-1) = -1
  debug_inspect(@jacobi_symbol.jacobi(7L, 15L), content="-1")
}
```

```mbt check
///|
test "jacobi gcd > 1 gives 0" {
  debug_inspect(@jacobi_symbol.jacobi(6L, 15L), content="0")
}
```

```mbt check
///|
test "jacobi negative numerator" {
  // (-1 / n) = +1 iff n ≡ 1 mod 4
  debug_inspect(@jacobi_symbol.jacobi(-1L, 5L), content="1")
  debug_inspect(@jacobi_symbol.jacobi(-1L, 7L), content="-1")
}
```

---

## Complexity

| Phase | Cost |
|---|---|
| Each step removes a factor of 2 or swaps + reduces | `O(log min(a, n))` total steps |
| Each step's arithmetic (mod, divide-by-2) | `O(log n)` bit operations |
| Total | `O(log² n)` |

This matches the cost of the binary GCD algorithm, which performs the
same "remove-2s then swap" pattern.

---

## Use cases

- **Solovay-Strassen primality test**: pick random `a`, check
  `a^((n-1)/2) ≡ (a / n) (mod n)`. If unequal for any `a`, `n` is
  composite.
- **Tonelli-Shanks square root**: requires `(a / p) = +1` to know a
  square root exists.
- **Quadratic-residuosity cryptography**: GM encryption and similar
  protocols.
- **Sum-of-two-squares decomposition**: `p` is a sum of two squares
  iff `p = 2` or `p ≡ 1 (mod 4)`, equivalently `(-1 / p) = +1`.

---

## Pitfalls

- **`n` even**. The Jacobi symbol is only defined for odd `n`. This
  package returns `0` if you pass an even `n` (or non-positive).
- **`a = 0`**. `(0 / n) = 0` for any `n`. The implementation handles
  this.
- **Numerator larger than denominator**. The implementation reduces
  `a mod n` up front, so any `Int64 a` works.
- **Overflow**. Internal arithmetic uses Int64; for cryptographic-size
  moduli use bignum types.

---

## Related concepts

```
Jacobi symbol (this)        generalised Legendre; O(log n) without factoring
Legendre symbol             Jacobi specialised to prime n
Kronecker symbol            further generalisation to any non-zero n
Quadratic reciprocity       the law that powers the algorithm
Solovay-Strassen            primality via random Jacobi-symbol checks
Tonelli-Shanks              square root mod p, uses Jacobi as a witness
```
