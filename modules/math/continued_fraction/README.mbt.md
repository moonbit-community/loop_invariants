# Continued Fractions

## Overview

A rational number `p / q` has a unique finite **simple continued
fraction** representation

```
p / q = [a_0; a_1, a_2, ..., a_k]
      = a_0 + 1 / (a_1 + 1 / (a_2 + ...))
```

computed by the **Euclidean algorithm**:

```
a_i = floor(p_i / q_i)
(p_{i+1}, q_{i+1}) = (q_i, p_i - a_i * q_i)
```

stopping when `q_{i+1} = 0`. The first coefficient `a_0` may be
negative; every subsequent one is positive.

This package provides three operations:

| Function | Description |
|---|---|
| `to_cf(p, q)` | Euclidean expansion → `[a_0; a_1, ..., a_k]` |
| `from_cf(cf)` | Rebuild the fraction `(numerator, denominator)` |
| `convergents(cf)` | Sequence of best rational approximations `h_k / k_k` |

### Convergents

The *k*-th **convergent** `h_k / k_k` is defined by the two-term
recurrence

```
h_{-1} = 1,  h_0 = a_0
k_{-1} = 0,  k_0 = 1
h_n    = a_n h_{n-1} + h_{n-2}
k_n    = a_n k_{n-1} + k_{n-2}
```

The final convergent is `p / q` in lowest terms. Every earlier
convergent is a **best rational approximation**: no fraction with a
denominator at most `k_n` is closer to `p/q` than `h_n / k_n`.

### Complexity

| Operation | Time | Space |
|---|---|---|
| `to_cf(p, q)` | `O(log min(\|p\|, \|q\|))` | `O(log min(\|p\|, \|q\|))` |
| `from_cf(cf)` | `O(n)` | `O(1)` extra |
| `convergents(cf)` | `O(n)` | `O(n)` |

---

## The loop invariant

The key invariant maintained by `to_cf` at every step is:

> **Invariant**: `p / q = [a_0; a_1, ..., a_{i-1}, x_i / y_i]`,  
> where `(x_i, y_i)` is the current `(x, y)` pair and `y_i > 0`.

Initially `(x_0, y_0) = (p, q)` with `y_0 > 0` (enforced by sign
normalisation). Each step extracts `a_i = floor(x_i / y_i)` and
sets `(x_{i+1}, y_{i+1}) = (y_i, x_i - a_i y_i)`. Since `0 <= x_{i+1} < y_i`
(the Euclidean remainder), `y_{i+1} < y_i` and the sequence strictly
decreases until `y = 0`.

The `convergents` function dually maintains:

> **Invariant**: after producing the *n*-th convergent, the pair
> `(h_{n-1}, k_{n-1})` and `(h_n, k_n)` satisfy the **determinant
> identity** `h_n k_{n-1} - h_{n-1} k_n = (-1)^{n+1}`.

This identity guarantees that consecutive convergents are in lowest
terms and alternate above and below the target.

---

## API

```
pub fn to_cf(p : Int64, q : Int64) -> Array[Int64]
pub fn from_cf(cf : Array[Int64]) -> (Int64, Int64)
pub fn convergents(cf : Array[Int64]) -> Array[(Int64, Int64)]
```

- `to_cf` returns `[]` when `q == 0`.
- `from_cf` returns `(0, 0)` for an empty array.
- `convergents` returns `[]` for an empty array.

---

## Tests and examples

### Basic expansion

```mbt check
///|
test "7/3 and 22/7" {
  // 7/3 = 2 + 1/3 → [2; 3]
  debug_inspect(@continued_fraction.to_cf(7L, 3L), content="[2, 3]")
  // 22/7 = 3 + 1/7 → [3; 7]
  debug_inspect(@continued_fraction.to_cf(22L, 7L), content="[3, 7]")
}
```

### Euclid's classic: 415/93

```mbt check
///|
test "415/93 = [4; 2, 6, 7]" {
  debug_inspect(
    @continued_fraction.to_cf(415L, 93L),
    content="[4, 2, 6, 7]",
  )
}
```

### Round-trip (to_cf → from_cf)

```mbt check
///|
test "round trip 7/3" {
  let cf = @continued_fraction.to_cf(7L, 3L)
  debug_inspect(@continued_fraction.from_cf(cf), content="(7, 3)")
}
```

### Convergents of π — [3; 7, 15, 1, 292, ...]

The convergents recover the classical best-rational approximations of π:

```mbt check
///|
test "pi convergents" {
  let cf : Array[Int64] = [3L, 7L, 15L, 1L, 292L, 1L, 1L, 1L, 2L, 1L]
  let cv = @continued_fraction.convergents(cf)
  debug_inspect(cv[0], content="(3, 1)")
  debug_inspect(cv[1], content="(22, 7)")
  debug_inspect(cv[3], content="(355, 113)")
  debug_inspect(cv[4], content="(103993, 33102)")
}
```

### Negative input

```mbt check
///|
test "negative numerator" {
  // -7/3 = -3 + 2/3 = -3 + 1/(1 + 1/2) → [-3; 1, 2]
  debug_inspect(@continued_fraction.to_cf(-7L, 3L), content="[-3, 1, 2]")
  debug_inspect(
    @continued_fraction.from_cf([-3L, 1L, 2L]),
    content="(-7, 3)",
  )
}
```

---

## Where it sits

| Operation | Available |
|---|---|
| CF expansion `[a_0; a_1, ...]` of `p/q` | **this package** |
| Rebuild `p/q` from CF coefficients | **this package** |
| Convergent sequence `h_k/k_k` | **this package** |
| Extended GCD / Bézout coefficients | `@extended_gcd` |
| Best approximation with bounded denominator | `@stern_brocot` |
| Farey sequence | `@farey_sequence` |

---

## Pitfalls

- **`q == 0` is silently ignored.** `to_cf(p, 0L)` returns `[]`; the
  caller must check for this case if the input may be degenerate.
- **Overflow.** The `to_cf` coefficients and `convergents` numerators /
  denominators can grow as large as the Fibonacci sequence, reaching
  `Int64` overflow for very deep expansions. In practice this is safe
  well past `2^31` but fails for adversarial inputs near `2^62`.
- **Non-uniqueness of the last coefficient.** The Euclidean algorithm
  always terminates with the last coefficient ≥ 2 (for `q > 1`), giving
  the "short" form. The "long" form replaces the final `k` with
  `[k-1, 1]`; both represent the same rational. `from_cf` accepts both
  forms; `to_cf` always produces the short form.

---

## Related concepts

```
Euclidean algorithm      the same quotient sequence; gcd is the last remainder
Extended GCD / Bézout    Bézout coefficients equal CF convergent denominators
Farey sequence           consecutive Farey fractions are CF neighbours
Stern-Brocot tree        CF run-lengths encode L/R paths in the tree
Convergents              best rational approximations to a real number
Pell's equation          solutions are given by convergents of √d
```
