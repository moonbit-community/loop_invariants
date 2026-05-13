# Cipolla's Algorithm

## Overview

Modular square root via a quadratic field extension. Solves
`r² ≡ n (mod p)` for an odd prime `p`, returning `None` when `n` is a
quadratic non-residue.

- **Time**: O(log² p)
- **Space**: O(1)
- **Signature**: `cipolla_sqrt(n : Int64, p : Int64) -> Int64?`

Cipolla (1907) takes a different route than `@tonelli_shanks`:
**no case split on `p mod 4`**. Both algorithms are asymptotically
the same; Cipolla's elegance is in the proof rather than the
runtime.

---

## The idea

Pick `a ∈ F_p` such that `w = a² - n` is a **quadratic non-residue**
mod `p`. Then `w` has no square root in `F_p` — so we embed everything
in the quadratic extension

```
F_p[omega]   where   omega² = w
```

Inside this larger field, `omega` plays the role of an "imaginary
unit." The element `a + omega` lives in `F_p[omega]` but not in `F_p`.
Compute its `(p+1)/2`-th power:

```
r  =  (a + omega) ^ ((p + 1) / 2)        in F_p[omega]
```

**Magic**: `r` always lies inside `F_p` (its `omega`-component is
zero), and `r² ≡ n (mod p)`.

---

## Why it works (one-line proof)

The Frobenius automorphism `x → x^p` in `F_{p²}` fixes every element
of `F_p` and sends `omega → -omega`. So

```
(a + omega) ^ p   =   a - omega.
```

Therefore

```
(a + omega) ^ (p + 1)   =   (a + omega)(a - omega)   =   a² - omega²
                        =   a² - w   =   a² - (a² - n)   =   n.
```

Taking the principal square root in the cyclic group `F_{p²}*`:

```
((a + omega)^((p+1)/2))²   =   n.
```

One checks that the resulting element is in `F_p` (the
`omega`-component vanishes because the group order forces it). That
element is the requested `r`.

---

## Finding the non-residue `a`

Exactly half of the values in `F_p* \ {0}` are quadratic residues, so
a linear search starting at `a = 0` finds a good candidate within a
constant number of iterations in expectation. A short-circuit handles
the degenerate case where `a² - n = 0`: then `a` *itself* is a square
root, and we return it directly.

---

## Compared with Tonelli-Shanks

| | `@tonelli_shanks` | `@cipolla` |
|---|---|---|
| Case split on `p mod 4` | Yes (closed form for `p ≡ 3 mod 4`, loop for `p ≡ 1 mod 4`) | No |
| Auxiliary parameter | A non-residue `z` | A value `a` with `a² - n` non-residual |
| Main work | Tonelli-Shanks main loop | One `quad_pow` in F_p[omega] |
| Asymptotic cost | O(log² p) | O(log² p) |
| Constant factor | Smaller for `p ≡ 3 mod 4` | Slightly larger (extension-field multiplication) |

Both are appropriate for cryptographic-scale primes (`p ~ 2^256`); the
choice often comes down to taste.

---

## Tests and examples

```mbt check
///|
test "cipolla classical 41 mod 113" {
  let r = @cipolla.cipolla_sqrt(41L, 113L).unwrap()
  debug_inspect(r * r % 113L, content="41")
}
```

```mbt check
///|
test "cipolla works for p mod 4 == 1" {
  // 1009 is prime, 1009 mod 4 = 1 -- the "hard" case for Tonelli.
  let r = @cipolla.cipolla_sqrt(7L, 1009L).unwrap()
  debug_inspect(r * r % 1009L, content="7")
}
```

```mbt check
///|
test "cipolla non-residue" {
  // 2 is not a QR mod 3.
  debug_inspect(@cipolla.cipolla_sqrt(2L, 3L), content="None")
}
```

```mbt check
///|
test "cipolla agrees with brute force" {
  // For every QR n mod 17, r*r mod 17 == n.
  for n in 1L..<17L {
    match @cipolla.cipolla_sqrt(n, 17L) {
      Some(r) => debug_inspect(r * r % 17L == n, content="true")
      None => ()
    }
  }
}
```

---

## Complexity

| Step                                  | Cost      |
|---------------------------------------|-----------|
| Euler's criterion (`mod_pow`)         | O(log p)  |
| Non-residue search                    | O(1) avg  |
| Quadratic-extension exponentiation    | O(log p) F_p[omega] mults |
| Each F_p[omega] mult                  | O(log² p) Int ops via `mul_mod` |

Total: **O(log² p)** time, **O(1)** space.

---

## Common pitfalls

- **Composite p**: behaviour is undefined. Use `@pollard_rho` to
  factor first, then apply Cipolla per prime factor and recombine
  with CRT.
- **The two roots**: every QR has two square roots `r` and `p - r`.
  This function returns one of them; compute the other as `p - r`.
- **Overflow**: all multiplications go through `mul_mod`
  (Russian peasant), so the algorithm stays in `Int64` even for
  `p` near `2^62`.

---

## Related concepts

```
Cipolla (this)              modular sqrt via F_p[omega], no case split
Tonelli-Shanks              modular sqrt via 2-power torsion loop
Adleman-Manders-Miller      modular n-th root, generalises both
Schoof's algorithm          point counting on elliptic curves over F_p
Hensel lifting              modular sqrt mod p^k from sqrt mod p
```
