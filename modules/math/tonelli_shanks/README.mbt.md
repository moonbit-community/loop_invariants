# Tonelli-Shanks

## Overview

Compute modular square roots: given an odd prime `p` and an integer `n`,
find `r` such that

```
  r^2 ≡ n  (mod p)
```

or report that `n` is a quadratic non-residue modulo `p` (no solution
exists). This complements primality testing (`@pollard_rho`) by giving
you the inverse of squaring inside the prime field `Z/pZ`.

- **Time**: `O(log^2 p)`
- **Space**: `O(1)`
- **Signature**: `tonelli_shanks(n : Int64, p : Int64) -> Int64?`

## Where it sits in number theory

| Operation                | Available             |
|--------------------------|-----------------------|
| Primality of p           | `@pollard_rho.is_prime` |
| Factor p - 1             | local helper          |
| `a · b mod p`            | local `mul_mod` (no overflow) |
| `a^k mod p`              | local `mod_pow`       |
| **Square root mod p**    | **this package**      |
| Discrete log mod p       | not yet               |
| nth root mod p           | not yet               |

## Existence: Euler's criterion

For an odd prime `p` and `n` not divisible by `p`,

```
  n^((p-1)/2)  ≡  +1   (mod p)   iff n is a quadratic residue
              ≡  -1   (mod p)   iff n is a non-residue
```

The proof is a direct consequence of Fermat's little theorem
(`n^(p-1) ≡ 1`) and the fact that `x^2 = 1` has only two solutions
(`x = ±1`) in `(Z/pZ)*` for prime `p`. `tonelli_shanks` calls
`mod_pow(n, (p-1)/2, p)` first; if the result isn't `1`, it returns
`None` immediately.

## Easy case: `p ≡ 3 (mod 4)`

When `p ≡ 3 (mod 4)`, the closed form

```
  r  =  n^((p+1)/4) mod p
```

works, because

```
  r^2  =  n^((p+1)/2)
       =  n  ·  n^((p-1)/2)
       =  n  ·  1
       =  n   (mod p)
```

using Euler's criterion in the last step (assuming `n` is a residue).
The `p == 3 mod 4` branch is taken whenever the second-lowest bit of
`p` is set, which is roughly half of all odd primes.

## General case: `p ≡ 1 (mod 4)`

Write `p - 1 = q · 2^s` with `q` odd. The Tonelli-Shanks loop maintains
**three coupled invariants**:

```
(I1)  r^2  ≡  t · n  (mod p)
(I2)  ord(t)  |  2^m
(I3)  c  is a primitive 2^m-th root of unity mod p
```

Initial values:

```
  m  =  s
  c  =  z^q mod p     where z is any quadratic non-residue
  t  =  n^q mod p
  r  =  n^((q+1)/2) mod p
```

Sanity-check the initial state:

- `r^2 = n^(q+1) = n · n^q = n · t`, satisfying **(I1)**.
- `t^(2^m) = (n^q)^(2^s) = n^(q · 2^s) = n^(p-1) = 1`, so **(I2)** holds.
- `c = z^q` has order `2^s = 2^m` because `z` is a non-residue (a
  primitive `2^s`-th root of unity in `(Z/pZ)*`), satisfying **(I3)**.

### The reduction step

While `t ≠ 1`:

1. Find the smallest `i ∈ (0, m)` with `t^(2^i) ≡ 1`. Such an `i` exists
   because `(I2)` says `t^(2^m) = 1`; and `i ≥ 1` because `t ≠ 1`.
2. Let `b = c^(2^(m - i - 1)) mod p`. Then `b^2` has order exactly `2^i`,
   so `b^2` is a primitive `2^i`-th root of unity.
3. Update:

   ```
     m_new  =  i
     c_new  =  b^2
     t_new  =  t · b^2
     r_new  =  r · b
   ```

### Why the invariants are preserved

The crucial fact: at `m = i`, both `t` and `b^2` are primitive `2^i`-th
roots of unity, so

```
  t^(2^(i-1))  ≡  -1   and   b^(2^i)  ≡  -1
```

(this is the same observation as `(±1)^2 = 1` in the unique order-2
subgroup). Multiplying:

```
  (t · b^2)^(2^(i-1))  =  t^(2^(i-1)) · b^(2^i)  =  (-1) · (-1)  =  1
```

so `ord(t_new) | 2^(i-1)`, which trivially gives `ord(t_new) | 2^i`,
re-establishing **(I2)** with the smaller `m_new = i`. **(I3)** falls
out because `b^2` is a primitive `2^i`-th root of unity by
construction, and **(I1)** is preserved because

```
  r_new^2  =  (r · b)^2
           =  r^2 · b^2
           ≡  t · n · b^2          (by (I1))
           =  (t · b^2) · n
           =  t_new · n             (mod p)
```

### Termination

Each iteration strictly decreases `m` by at least one (`m_new = i < m`),
so the loop runs at most `s` times. When `t = 1`, invariant **(I1)**
yields `r^2 ≡ n (mod p)`, and the function returns `Some(r)`.

## Worked example: `tonelli_shanks(5, 41) = ?`

`41 - 1 = 40 = 5 · 2^3`, so `q = 5, s = 3`. Find a non-residue: try
`z = 2`. `2^20 mod 41`: `2^5 = 32`, `2^10 = 1024 mod 41 = 40 = -1`,
`2^20 = 1`. So 2 is a residue. Try `z = 3`: `3^20 mod 41`. `3^4 = 81
= -1 mod 41`. `3^20 = (3^4)^5 = (-1)^5 = -1`. So `z = 3` works.

Initialize:

```
m = 3
c = 3^5 mod 41
  = 243 mod 41
  = 243 - 5·41 = 38
t = 5^5 mod 41
  = 3125 mod 41
  = 3125 - 76·41 = 3125 - 3116 = 9
r = 5^3 mod 41
  = 125 mod 41 = 2
```

Iteration 1: `t = 9, m = 3`.
- `t^2 = 81 = -1 mod 41 = 40`. Not 1.
- `t^4 = 1`. So `i = 2`.
- `b = c^(2^(m - i - 1)) = c^(2^0) = c = 38`.
- `b^2 = 38^2 = 1444 mod 41`. `1444 - 35·41 = 1444 - 1435 = 9`. So `b^2 = 9`.
- New state: `m = 2, c = 9, t = 9 · 9 = 81 = -1 mod 41 = 40, r = 2 · 38 = 76 mod 41 = 35`.

Iteration 2: `t = 40, m = 2`.
- `t^2 = 1600 mod 41 = 1600 - 39·41 = 1600 - 1599 = 1`. So `i = 1`.
- `b = c^(2^(m - i - 1)) = c^(2^0) = c = 9`.
- `b^2 = 81 mod 41 = 40`.
- New state: `m = 1, c = 40, t = 40 · 40 mod 41 = 1, r = 35 · 9 mod 41 = 315 mod 41 = 315 - 7·41 = 28`.

Iteration 3: `t = 1`. Return `r = 28`.

Check: `28^2 = 784 mod 41 = 784 - 19·41 = 784 - 779 = 5`. ✓

## Reference implementation

```
pub fn tonelli_shanks(n : Int64, p : Int64) -> Int64?
```

## Tests and examples

### Round-trip a residue

```mbt check
///|
test "tonelli round-trip" {
  let r = @tonelli_shanks.tonelli_shanks(41L, 113L).unwrap()
  // Either root squares back to 41 mod 113.
  debug_inspect(r * r % 113L, content="41")
}
```

### Non-residue returns None

```mbt check
///|
test "tonelli non-residue" {
  // 2 is not a quadratic residue mod 3.
  debug_inspect(@tonelli_shanks.tonelli_shanks(2L, 3L), content="None")
}
```

### Closed-form branch (`p ≡ 3 (mod 4)`)

```mbt check
///|
test "tonelli p == 3 mod 4 branch" {
  // p = 7 satisfies 7 mod 4 = 3, so the closed form is taken.
  let r = @tonelli_shanks.tonelli_shanks(2L, 7L).unwrap()
  debug_inspect(r * r % 7L, content="2")
}
```

### General-loop branch (`p ≡ 1 (mod 4)`)

```mbt check
///|
test "tonelli p == 1 mod 4 branch" {
  // 1009 is prime; 1009 mod 4 = 1, so the main loop runs.
  let r = @tonelli_shanks.tonelli_shanks(7L, 1009L).unwrap()
  debug_inspect(r * r % 1009L, content="7")
}
```

## Common applications

- **Elliptic curve point decompression**: recovering `y` from `x` on a
  curve `y^2 = x^3 + a·x + b` over `F_p` requires a square root of the
  RHS modulo `p`.
- **Quadratic equations modulo p**: complete the square and apply
  Tonelli-Shanks to the discriminant.
- **Cipolla's algorithm comparison**: an alternative `O(log^2 p)` method
  that works without the case split on `p mod 4`; comparable constants.
- **Composite moduli**: factor `m = p_1 · p_2 · ...` first (via
  `@pollard_rho`), apply Tonelli-Shanks per prime power, and reassemble
  with CRT (`@math.chinese_remainder` -- see the `math/math` package).

## Common pitfalls

- **Composite `p`**: this function assumes `p` is prime. Behaviour on
  composites is undefined; in particular Euler's criterion does not
  fully characterise quadratic residues there.
- **Negative or large `n`**: `n` is normalised to `[0, p)` internally,
  so passing `-3` or `p + 7` works fine.
- **The two roots**: every QR has two square roots, `r` and `p - r`.
  `tonelli_shanks` returns one of them (whichever falls out of the
  algorithm); compute the other as `p - r` if you need both.
- **Overflow**: all multiplications go through `mul_mod` (Russian
  peasant) so the computation stays within `Int64` even for `p` near
  `2^62`.

## Related concepts

```
Euler's criterion          n^((p-1)/2) gives the Legendre symbol
Quadratic residue          n with x^2 ≡ n mod p solvable
Tonelli-Shanks (this)      sqrt mod p, general case
Cipolla                    sqrt mod p via field extension, no case split
Hensel lifting             root mod p^k from root mod p
Chinese remainder theorem  sqrt mod composite via per-prime sqrt
```
