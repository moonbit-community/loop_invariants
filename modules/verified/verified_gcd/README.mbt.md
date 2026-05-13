# Verified GCD

## Overview

Compute the greatest common divisor of two non-negative integers, with
proof annotations that make the invariants explicit. This package
provides two algorithms with identical contracts:

- `gcd_euclid(a, b)` -- classical Euclidean algorithm using `mod`.
- `gcd_binary(a, b)` -- binary (Stein) algorithm using only shifts,
  parity tests, and subtraction.

Both have signatures

```
pub fn gcd_euclid(a : Int, b : Int) -> Int
pub fn gcd_binary(a : Int, b : Int) -> Int
```

with the proof contract

```
proof_require: nonneg(a)
proof_require: nonneg(b)
proof_ensure : result => divides(result, a) && divides(result, b)
proof_ensure : result => result >= 0
```

- **Time**: `O(log min(a, b))` for both algorithms.
- **Space**: `O(1)` for both.

## What "verified" means here

A *verified* package puts the loop invariant on the same page as the
loop. The MoonBit annotations

- `proof_require:` -- precondition the caller must establish before the
  function may run;
- `proof_ensure:` -- postcondition the function guarantees on return;
- `proof_invariant:` -- a relation between the loop variables that is
  true at the start of every iteration;
- `proof_reasoning:` -- a structured argument that initialization,
  maintenance, and termination all hold.

For `gcd_euclid` the central invariant is

```
the set of common divisors of (x, y)
  ==
the set of common divisors of the original (a, b)
```

For `gcd_binary` the central invariants are that

- the abstract value `gcd(a, b)` of the original inputs equals
  `2^shift * gcd(x, y)` where `(x, y)` is the running state;
- inside the main loop `x` is odd, which makes `|x - y|` even and thus
  reducible by the inner halving loop.

Each invariant is paired with a `proof_reasoning` block that walks
through the three obligations explicitly.

## Theory

### Euclidean algorithm

The classical identity

```
  gcd(a, b)  ==  gcd(b, a mod b)         (when b > 0)
```

follows because every common divisor of `a` and `b` also divides
`a - q*b = a mod b`, and conversely every common divisor of `b` and
`a mod b` divides `q*b + (a mod b) = a`. Iterating until `b == 0`
yields `gcd(a, b) == gcd(g, 0) == g`.

**Termination** is by well-founded induction on `b`: each iteration
replaces `b` by `a mod b`, which lies in `[0, b)`. The strict decrease
means at most `O(log min(a, b))` iterations are needed; the Lamé bound
makes adjacent Fibonacci numbers the worst case.

### Binary (Stein) algorithm

Use three elementary facts about the GCD:

```
  gcd(2a, 2b)   ==  2 * gcd(a, b)           (both even)
  gcd(2a, b)    ==      gcd(a, b)           (b odd)
  gcd(a, b)     ==      gcd(a, b - a)       (any non-negative a, b)
```

The algorithm strips shared powers of two first (storing the count in
`shift`), then makes the smaller side reach zero by alternating "halve
while even" and "subtract smaller from larger" steps. The shared power
of two is reattached at the end via `result << shift`.

**Termination** is by strict decrease of `x + y`: every halving reduces
one of the two operands, and the subtractive step `(x, y) := (min,
|x - y|)` strictly shrinks the sum whenever both are positive.

## Worked example: `gcd(48, 18)`

### Euclidean trace

```
  step 1:  (a, b) = (48, 18)   -> (18, 48 mod 18) = (18, 12)
  step 2:  (a, b) = (18, 12)   -> (12, 18 mod 12) = (12, 6)
  step 3:  (a, b) = (12,  6)   -> ( 6, 12 mod  6) = ( 6, 0)
  step 4:  b == 0, return 6.
```

Four iterations.

### Binary trace

```
  start:   a = 48 = 0b110000,   b = 18 = 0b010010,  shift = 0
  phase 1: both even -> (24, 9),                    shift = 1
           a even, b odd -> exit phase 1.
  phase 2: a = 24 is even -> 12 -> 6 -> 3.          (a is now odd)
  phase 3: state (a, b) = (3, 9)
             b = 9 is odd already.
             a < b, replace b with b - a = 6.
           state (a, b) = (3, 6)
             halve b: (3, 3).
             b > 0, equal -> b - a = 0. state (3, 0).
             exit loop.
  phase 4: return 3 << 1 = 6.
```

Both algorithms agree: `gcd(48, 18) == 6`.

## Reference implementation

```
pub fn gcd_euclid(a : Int, b : Int) -> Int
pub fn gcd_binary(a : Int, b : Int) -> Int
```

## Tests and examples

### Small cases

```mbt check
///|
test "gcd small cases" {
  debug_inspect(@verified_gcd.gcd_euclid(0, 0), content="0")
  debug_inspect(@verified_gcd.gcd_euclid(0, 5), content="5")
  debug_inspect(@verified_gcd.gcd_euclid(12, 18), content="6")
  debug_inspect(@verified_gcd.gcd_euclid(17, 31), content="1")
}
```

### Both algorithms agree

```mbt check
///|
test "gcd euclid and binary agree" {
  debug_inspect(@verified_gcd.gcd_binary(48, 18), content="6")
  debug_inspect(@verified_gcd.gcd_binary(100, 75), content="25")
  debug_inspect(@verified_gcd.gcd_binary(17, 31), content="1")
}
```

### Powers of two stress the binary algorithm

```mbt check
///|
test "gcd powers of two" {
  // gcd(1024, 768) = gcd(2^10, 2^8 * 3) = 2^8 = 256.
  debug_inspect(@verified_gcd.gcd_binary(1024, 768), content="256")
  debug_inspect(@verified_gcd.gcd_euclid(1024, 768), content="256")
}
```

### Fibonacci pairs are the Euclidean worst case

```mbt check
///|
test "gcd fibonacci worst case" {
  // Adjacent Fibonacci numbers are always coprime and need the maximum
  // number of Euclidean steps for inputs of their magnitude.
  // F(19) = 4181, F(20) = 6765.
  debug_inspect(@verified_gcd.gcd_euclid(6765, 4181), content="1")
  debug_inspect(@verified_gcd.gcd_binary(6765, 4181), content="1")
}
```

## Complexity

| Algorithm    | Time              | Space | Notes                                         |
|--------------|-------------------|-------|-----------------------------------------------|
| Euclidean    | `O(log min(a,b))` | `O(1)`| Lamé bound, one `mod` per step               |
| Binary/Stein | `O(log min(a,b))` | `O(1)`| Only shifts, parity, subtraction              |

The two algorithms have the same asymptotic complexity, but on hardware
without a fast integer divider (or for arbitrary-precision integers
where division is much costlier than subtraction and shifts) the binary
algorithm typically wins by a small constant factor. On modern CPUs with
a single-cycle 64-bit divider the Euclidean version is usually faster
because it makes fewer iterations and the inner step is one instruction.

## Common applications

- **Reducing fractions**: divide numerator and denominator by their
  gcd.
- **Modular inverses**: extended Euclidean variants (not in this
  package) recover Bezout coefficients giving `gcd(a, m) = 1 ->
  a^{-1} mod m`.
- **Lattice/cryptography preprocessing**: gcd computations form the
  innermost step of LLL-style basis reduction and of various number-
  theoretic algorithms.
- **CRT setup**: deciding coprimality of moduli before applying the
  Chinese Remainder Theorem.

## Common pitfalls

- **Negative inputs**: this package's contract requires `a, b >= 0`.
  For signed inputs take absolute values first.
- **Both arguments zero**: `gcd(0, 0)` is defined here as `0`, matching
  the convention used by most algebra textbooks (it is the additive
  identity of the gcd monoid).
- **Overflow on `a - b`**: not a concern here since the binary
  algorithm always subtracts the smaller from the larger.
- **Mistaking "even" for `% 2 == 0`**: the binary algorithm tests
  parity with `(x & 1) == 0`. On non-negative `Int` these are
  equivalent.

## Related concepts

```
Euclidean algorithm         gcd via successive remainders
Extended Euclidean          additionally returns Bezout coefficients
Binary/Stein GCD            shift-and-subtract variant, no division
Lehmer's GCD                multi-word speedup using leading digits
Half-GCD / GMP gcd          recursive, sub-quadratic for big integers
Lamé's theorem              proves the O(log) bound is tight at Fibonacci pairs
```
