# Linear Diophantine Equation — ax + by = c

## Overview

A **linear Diophantine equation** over the integers is an equation of the form

```
a · x + b · y = c
```

where `a, b, c ∈ ℤ` are given and integer solutions `(x, y)` are sought.

**Existence (Bezout's theorem):** Integer solutions exist if and only if
`gcd(a, b) | c`. When `g = gcd(a, b)` and a particular solution `(x₀, y₀)` is
known, the complete solution set is the coset

```
x = x₀ + (b/g) · t
y = y₀ − (a/g) · t       t ∈ ℤ
```

because the added term `(b/g · a − a/g · b) = 0` leaves the equation unchanged.

| Operation | Time | Space |
|---|---|---|
| `solve(a, b, c)` | `O(log min(\|a\|, \|b\|))` | `O(1)` |
| `solve_min_x(a, b, c)` | `O(log min(\|a\|, \|b\|))` | `O(1)` |

---

## API

```
pub struct DiophantineResult {
  solution : (Int64, Int64)?
  period   : (Int64, Int64)
}

pub fn solve(a : Int64, b : Int64, c : Int64) -> DiophantineResult
pub fn solve_min_x(a : Int64, b : Int64, c : Int64) -> DiophantineResult
```

- `solve` returns a `DiophantineResult` where `solution` is `Some((x₀, y₀))`
  when solutions exist and `None` otherwise. `period` is the step `(b/g, -a/g)`
  that generates the full family; it is `(0, 0)` when no solution exists.
- `solve_min_x` is identical to `solve` but normalises the returned `x₀` to
  the smallest non-negative value in `[0, |b/g|)`.

Both functions handle negative and zero coefficients correctly.

---

## The invariant

The internal extended Euclidean algorithm maintains the invariant:

```
old_r = a · old_s + b · old_t
r     = a · s     + b · t
```

at every iteration. Each step is one Euclidean reduction that preserves
the invariant. When `r = 0`, `old_r = gcd(|a|, |b|)` and `(old_s, old_t)` is
a Bezout pair.

---

## Tests and examples

```mbt check
///|
test "solve basic" {
  // 3 x + 6 y = 9 has infinitely many solutions; one particular one satisfies the equation.
  let r = @linear_diophantine.solve(3L, 6L, 9L)
  match r.solution {
    Some((x, y)) => debug_inspect(3L * x + 6L * y, content="9")
    None => abort("expected a solution")
  }
}
```

```mbt check
///|
test "solve no solution" {
  // gcd(4, 6) = 2 does not divide 7.
  let r = @linear_diophantine.solve(4L, 6L, 7L)
  debug_inspect(r.solution, content="None")
}
```

```mbt check
///|
test "solve_min_x normalised" {
  // 7 x + 5 y = 1; smallest non-negative x is in [0, 5).
  let r = @linear_diophantine.solve_min_x(7L, 5L, 1L)
  match r.solution {
    Some((x, y)) => {
      debug_inspect(7L * x + 5L * y, content="1")
      debug_inspect(x >= 0L && x < 5L, content="true")
    }
    None => abort("expected a solution")
  }
}
```

---

## Use cases

- **Modular arithmetic** — finding when two periodic events coincide.
- **Coin problem (Frobenius / Chicken McNugget)** — representability by two
  coprime denominators.
- **CRT / key scheduling** — computing offsets for combined congruences.
- **2-D grid alignment** — integer steps along two lattice directions.

---

## Pitfalls

- **Overflow.** Internal products can overflow `Int64` near `2^63`; use
  bignum arithmetic for cryptographic-size inputs.
- **Non-unique particular solution.** `solve` returns one particular `(x₀, y₀)`;
  the normalised variant `solve_min_x` picks the canonical representative with
  the smallest non-negative `x`.
- **`period = (0, 0)` when no solution exists.** Always check `solution` before
  inspecting `period`.

---

## Related concepts

```
Bezout's identity      existence and form of the general solution
Extended Euclidean     algorithm used internally to find (x₀, y₀)
Chinese Remainder      system of congruences; reduces to Diophantine pairs
Modular inverse        special case ax ≡ 1 (mod m)
```
