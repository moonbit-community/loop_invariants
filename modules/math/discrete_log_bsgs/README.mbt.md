# Discrete Log (Baby-Step Giant-Step)

## Overview

Given a prime modulus `p`, a base `a`, and a target `b`, compute the
smallest non-negative `x` satisfying

```
  a^x ≡ b  (mod p)
```

or report that no such `x` exists. The discrete log is the inverse of
modular exponentiation in the multiplicative group `(Z/pZ)*`, and it is
believed to be hard in general (this hardness underpins Diffie-Hellman
and ElGamal). BSGS is a deterministic time-memory trade-off that solves
the problem in `O(sqrt(p))` operations and `O(sqrt(p))` memory.

- **Time**: `O(sqrt(p) · log p)`
- **Space**: `O(sqrt(p))`
- **Signature**: `discrete_log_bsgs(a : Int64, b : Int64, p : Int64) -> Int64?`

## Where it sits in number theory

| Operation                | Available                  |
|--------------------------|----------------------------|
| Primality of `p`         | `@pollard_rho.is_prime`    |
| `a · b mod p`            | local `mul_mod` (no overflow) |
| `a^k mod p`              | local `mod_pow`            |
| Square root mod `p`      | `@tonelli_shanks.tonelli_shanks` |
| **Discrete log mod `p`** | **this package**           |
| Order of `a` mod `p`     | not yet                    |
| n-th root mod `p`        | not yet                    |

## Algorithm

Let `m = ceil(sqrt(p))`. Every `x` in `[0, p)` can be written uniquely
as

```
  x = i · m - j     with   1 <= i <= m   and   0 <= j < m
```

(the value `x = 0` is handled separately by the short-circuit on
`b ≡ 1`). Rewriting the congruence:

```
  a^(i·m - j)        ≡ b         (mod p)
  (a^m)^i            ≡ b · a^j   (mod p)
```

So the right-hand side depends only on `j` (the "baby step") and the
left-hand side only on `i` (the "giant step"). BSGS tabulates one side
and walks the other:

```
1.  Build a hash table  T  with
      T[ b · a^j mod p ] = j      for j = 0, 1, ..., m-1.
2.  Compute  step = a^m mod p.
3.  For i = 1, 2, ..., m:
      if (step^i mod p) ∈ T, with value j:
        return  i · m - j.
4.  Return None.
```

The search space `[0, m·m)` covers `[0, p)` because `m·m >= p` by
construction.

### Loop invariants

```
(BABY)  After j iterations:
        - cur ≡ b · a^j  (mod p)
        - every residue (b · a^k mod p) for k in [0, j) is present in T
          mapped to some k' in [0, j) with k' >= k and the same residue.

(GIANT) Before iteration i:
        - cur ≡ (a^m)^i  (mod p)
        - for every i' in [1, i), no j in [0, m) satisfied
          a^(i'·m - j) ≡ b  (mod p), so all candidates x' in
          ((i'-1)·m, i'·m] have been ruled out.
```

The baby-step table is built *biased toward larger `j`*: each
overwrite stores a larger exponent for the same residue. That keeps
`x = i·m - j` minimal once the first hit lands.

## Worked example: `discrete_log_bsgs(2, 22, 29)`

`p = 29`, `a = 2`, `b = 22`. Compute `m = ceil(sqrt(29)) = 6`.

### Baby steps

For `j = 0, 1, ..., 5`, record `(22 · 2^j mod 29, j)`:

| j | `22 · 2^j mod 29` |
|---|-------------------|
| 0 | 22                |
| 1 | 44 → 15           |
| 2 | 30 → 1            |
| 3 | 2                 |
| 4 | 4                 |
| 5 | 8                 |

Table `T = { 22:0, 15:1, 1:2, 2:3, 4:4, 8:5 }`.

### Giant steps

`step = 2^6 mod 29 = 64 - 2·29 = 6`. Now walk `i`:

| i | `step^i mod 29` | in T? |
|---|-----------------|-------|
| 1 | 6               | no    |
| 2 | 36 → 7          | no    |
| 3 | 42 → 13         | no    |
| 4 | 78 → 20         | no    |
| 5 | 120 → 4         | yes, j = 4 |

Hit at `i = 5, j = 4` → `x = 5·6 - 4 = 26`.

Check: `2^26 mod 29`. `2^5 = 32 ≡ 3`, `2^10 ≡ 9`, `2^20 ≡ 81 ≡ 23`,
`2^26 = 2^20 · 2^6 ≡ 23 · 6 = 138 ≡ 138 - 4·29 = 22`. ✓

(Note: `2^9 mod 29 = 19`, *not* 22. Read carefully — small mental
arithmetic with discrete logs is famously slippery.)

## Reference implementation

```
pub fn discrete_log_bsgs(a : Int64, b : Int64, p : Int64) -> Int64?
```

## Tests and examples

### Round-trip with a primitive root

```mbt check
///|
test "bsgs round-trip primitive root mod 29" {
  // 2 is a primitive root mod 29. Pick x = 9 and round-trip it.
  // 2^9 mod 29 = 512 mod 29 = 19.
  let x = @discrete_log_bsgs.discrete_log_bsgs(2L, 19L, 29L).unwrap()
  debug_inspect(x, content="9")
}
```

### The trickier example from the worked trace

```mbt check
///|
test "bsgs 2 raised to what is 22 mod 29" {
  // 2^26 = 22 mod 29 (see README for the trace).
  let x = @discrete_log_bsgs.discrete_log_bsgs(2L, 22L, 29L).unwrap()
  debug_inspect(x, content="26")
}
```

### `b = 1` is always solved by `x = 0`

```mbt check
///|
test "bsgs b equals one" {
  let x = @discrete_log_bsgs.discrete_log_bsgs(5L, 1L, 17L).unwrap()
  debug_inspect(x, content="0")
}
```

### No solution exists when `b` is outside the subgroup of `a`

```mbt check
///|
test "bsgs no solution" {
  // 4 has order 5 mod 11; its subgroup is {1, 4, 5, 9, 3}. 2 is not in
  // it, so there is no x with 4^x = 2 (mod 11).
  debug_inspect(
    @discrete_log_bsgs.discrete_log_bsgs(4L, 2L, 11L),
    content="None",
  )
}
```

## Complexity analysis

Let `m = ceil(sqrt(p))`. The baby-step loop runs `m` iterations, each
doing one `mul_mod` (cost `O(log p)` via Russian peasant) and one hash
insertion (`O(1)` amortised). The giant-step loop runs at most `m`
iterations, each doing one `mul_mod` and one hash lookup. Total time:

```
  O(m · log p)  =  O(sqrt(p) · log p)
```

Memory is dominated by the table, which holds at most `m` entries each
of size `O(1)`: `O(sqrt(p))`.

### Trade-off with Pollard rho for discrete logs

| Algorithm    | Time              | Space          | Comments              |
|--------------|-------------------|----------------|-----------------------|
| Trial        | `O(p)`            | `O(1)`         | unusable beyond ~10^9 |
| BSGS (this)  | `O(sqrt(p) log p)` | `O(sqrt(p))`  | deterministic         |
| Pollard rho  | `O(sqrt(p))`      | `O(1)`         | randomised, often faster in practice |

For very large `p` (cryptographic sizes), BSGS becomes memory-bound and
Pollard rho or index calculus wins. For `p` up to ~`10^{12}` BSGS is
typically simplest and fastest.

## Common applications

- **Diffie-Hellman**: a passive adversary who recovers Alice's secret
  `a` from `g^a mod p` is computing a discrete log. BSGS is the
  baseline attack used to calibrate group sizes.
- **ElGamal encryption / signatures**: same hardness assumption as
  Diffie-Hellman; the BSGS attack is the floor.
- **Order computation**: combining BSGS with Pohlig-Hellman gives the
  order of a group element mod a smooth `p - 1`.
- **CTF / Olympiad problems**: many number-theory puzzles reduce to a
  small discrete-log query (e.g. "find `x` such that `g^x` matches a
  given target"). BSGS handles them in milliseconds for `p` up to a
  few billion.
- **Elliptic-curve point counting** (educational): scalar-multiplication
  inverses on small curves can be cracked with BSGS, demonstrating why
  ECC needs large groups.

## Common pitfalls

- **Composite `p`**: BSGS requires the *cyclic group* structure of
  `(Z/pZ)*`. For composite `p`, the multiplicative group is not cyclic
  in general, and BSGS may miss solutions or report spurious ones.
  Always verify the returned witness with a fresh `mod_pow`.
- **Smallest `x`**: BSGS as written here returns the smallest
  non-negative `x` in `[0, p)`, but the "smallest `x` such that
  `a^x = b`" *globally* is bounded by `ord(a)`. For a primitive root
  the two coincide; for non-primitive `a` they may not.
- **Overflow**: `i · m` can be as large as `p`, but `m * m <= p + 2m`
  fits comfortably in `Int64` for any `p < 2^62`. All other arithmetic
  goes through `mul_mod`.
- **`a = 0`**: special-cased. `0^0` is conventionally `1` (so `b = 1`
  short-circuits to `x = 0`); `0^x = 0` for `x >= 1`, giving the
  unique witness `x = 1` when `b = 0`.
- **Memory ceiling**: at `p ≈ 2^{40}` the baby table contains `2^{20}`
  entries (~1 M Int64 keys), which is fine; at `p ≈ 2^{60}` it would
  need `2^{30}` entries (gigabytes). Switch to Pollard rho beyond
  ~`2^{50}`.

## Related concepts

```
Fermat's little theorem    a^(p-1) ≡ 1 (mod p) bounds the period
Order of an element        smallest k > 0 with a^k ≡ 1
Pohlig-Hellman             reduces log mod p to log mod each prime power factor of p - 1
Pollard rho for logs       randomised O(sqrt(p)) time, O(1) space
Index calculus             sub-exponential time over F_p, large constants
Shanks (1971)              the original baby-step giant-step paper for orders
```
