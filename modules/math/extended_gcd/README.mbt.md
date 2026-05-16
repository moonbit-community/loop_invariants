# Extended Euclidean Algorithm

## Overview

The **extended Euclidean algorithm** computes `(g, x, y)` such that

```
a · x + b · y = g = gcd(a, b)
```

This is **Bezout's identity**: every greatest common divisor of two
integers is an integer linear combination of them. It is the foundation
of:

- **Modular inverse**: when `gcd(a, m) = 1`, the equation
  `a · x ≡ 1 (mod m)` is solved by the Bezout coefficient.
- **Linear Diophantine equations** `ax + by = c`: solvable iff `g | c`.
- **Chinese Remainder Theorem** reconstructions, **RSA**, and many
  cryptographic primitives.

| Operation | Time | Space |
|---|---|---|
| `bezout(a, b)` | `O(log min(\|a\|, \|b\|))` | `O(1)` |
| `gcd(a, b)`    | `O(log min(\|a\|, \|b\|))` | `O(1)` |
| `mod_inverse(a, m)` | `O(log m)` | `O(1)` |

---

## API

```
pub fn bezout(a : Int64, b : Int64) -> (Int64, Int64, Int64)
pub fn gcd(a : Int64, b : Int64) -> Int64
pub fn mod_inverse(a : Int64, m : Int64) -> Int64?
```

- `bezout` returns `(g, x, y)` with `a·x + b·y == g` and `g >= 0`.
- `gcd` returns the non-negative gcd; matches the `g` from `bezout`.
- `mod_inverse` returns `Some(x)` with `0 <= x < m` and `a·x ≡ 1 (mod m)`,
  or `None` if `gcd(a, m) != 1` or `m <= 0`.

---

## The invariant

The iterative form maintains two pairs `(old_r, old_s)` and `(r, s)`
such that, **at every iteration**,

```
old_r = |a| · old_s + |b| · old_t
r     = |a| · s     + |b| · t
```

for some implicit `old_t, t` recovered at the end. Each step is one
Euclidean reduction, which preserves the invariant. The loop halts when
`r = 0`, at which point `old_r = gcd(|a|, |b|)` and `old_s` is the
coefficient of `|a|`.

---

## Tests and examples

```mbt check
///|
test "bezout basic" {
  let (g, x, y) = @extended_gcd.bezout(30L, 18L)
  debug_inspect(g, content="6")
  debug_inspect(30L * x + 18L * y, content="6")
}
```

```mbt check
///|
test "mod inverse small" {
  // 3 · 5 ≡ 1 (mod 7)
  debug_inspect(@extended_gcd.mod_inverse(3L, 7L), content="Some(5)")
}
```

```mbt check
///|
test "mod inverse none when not coprime" {
  // gcd(4, 6) = 2 ≠ 1, no inverse.
  debug_inspect(@extended_gcd.mod_inverse(4L, 6L), content="None")
}
```

---

## Use cases

- **RSA key generation** — finding `d` from `e` and `phi(n)`.
- **CRT reconstruction** — pairwise inverses to combine residues.
- **Solving `ax ≡ b (mod m)`** — divide through by `g = gcd(a, m)` if
  `g | b`, then multiply by `mod_inverse(a/g, m/g)`.
- **Continued fractions / rational approximation** — the same sequence
  of quotients gives the best rational approximations.

---

## Pitfalls

- **Overflow.** Internal products `q · r` and `q · s` can overflow
  `Int64` for adversarial inputs; in practice this is safe well past
  `2^31` but not at full `2^63`. For cryptographic-size inputs use
  bignum arithmetic.
- **Non-canonical Bezout pair.** The coefficients `(x, y)` are *one*
  Bezout pair; they are not unique. Adding any multiple of
  `(b/g, -a/g)` gives another valid pair.
- **`m <= 0` in `mod_inverse`.** The function returns `None` rather
  than raising; check the result before using it.

---

## Related concepts

```
Bezout's identity     existence of (x, y) with ax + by = gcd
Modular inverse       a^{-1} mod m via the same coefficients
CRT                   reconstructs a number from coprime residues
Continued fractions   same quotient sequence; same recurrence
Binary GCD            faster on hardware without divide; same result
```
