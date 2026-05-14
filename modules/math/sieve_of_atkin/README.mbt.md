# Sieve of Atkin

## Overview

A modern `O(N / log log N)` prime sieve based on a quadratic-form
recipe modulo 60. Slightly faster than the classical Eratosthenes
sieve (`O(N log log N)`), though with a larger constant factor — the
crossover is somewhere around `N = 10^9` in optimised
implementations.

- **Time**: `O(N / log log N)`
- **Space**: `O(N)` sieve bitmap
- **Signatures**:
  - `primes_up_to(n) -> Array[Int]`
  - `is_prime_atkin(n) -> Bool`

Atkin & Bernstein (2003) showed that the parity of the number of
representations of `n` as a quadratic form (specific to `n mod 12`)
characterises primality, modulo a squarefree filter. The algorithm
toggles a sieve bit per representation, then removes squares of
primes.

---

## The recipe

A number `n > 5` is prime iff it is squarefree AND:

| `n mod 12` | Quadratic form | Sign convention |
|---|---|---|
| 1 or 5 | `n = 4x² + y²`, `x, y > 0` | always |
| 7 | `n = 3x² + y²`, `x, y > 0` | always |
| 11 | `n = 3x² - y²`, `x > y > 0` | always |

For each form, count the number of `(x, y)` representations of `n`.
If that count is **odd**, `n` is a candidate prime. After all
toggling, we clear `r²`, `2r²`, `3r²`, ... for every candidate `r` —
those have odd representation but are not squarefree.

The remaining `true` bits are exactly the primes `> 3` up to `N`. We
add 2 and 3 directly (they are not produced by the forms).

---

## The loop invariants

| After phase | Meaning |
|---|---|
| Three quadratic-form loops complete | `sieve[n] = true` iff `n ∈ [5, N]` has an *odd* number of representations by its form |
| Square-clearing pass complete | `sieve[n] = true` iff `n` is prime AND `n > 3` |

Both invariants are stated as `proof_invariant` blocks on the respective loops.

---

## Why is it faster than Eratosthenes?

Eratosthenes does `O(N · ∑_{p ≤ √N} 1/p) = O(N log log N)` operations
because it crosses out every multiple of every prime. Atkin
*toggles* once per `(x, y)` pair, of which there are only
`O(N / log log N)` such pairs across the three forms. The
square-clearing pass adds another `O(N / log² N)` — also subdominant.

In practice, Atkin's constant factor is larger than Eratosthenes's
because of the modular tests; the asymptotic win is small unless `N`
is in the billions.

---

## Tests and examples

```mbt check
///|
test "atkin first primes" {
  debug_inspect(
    @sieve_of_atkin.primes_up_to(20),
    content="[2, 3, 5, 7, 11, 13, 17, 19]",
  )
}
```

```mbt check
///|
test "atkin pi 1000" {
  // π(1000) = 168.
  debug_inspect(@sieve_of_atkin.primes_up_to(1000).length(), content="168")
}
```

```mbt check
///|
test "atkin is_prime helper" {
  debug_inspect(@sieve_of_atkin.is_prime_atkin(91), content="false")
  debug_inspect(@sieve_of_atkin.is_prime_atkin(97), content="true")
}
```

```mbt check
///|
test "atkin tiny inputs" {
  debug_inspect(@sieve_of_atkin.primes_up_to(1), content="[]")
  debug_inspect(@sieve_of_atkin.primes_up_to(2), content="[2]")
}
```

---

## Complexity

| Phase | Time |
|------|------|
| Three quadratic-form loops | `O(N / log log N)` (Atkin-Bernstein analysis) |
| Square-clearing | `O(N / log² N)` |
| Collect output | `O(π(N)) = O(N / log N)` |
| Total | **`O(N / log log N)`** |

Space is dominated by the sieve bitmap: `N + 1` bytes (or 1 bit per
position with appropriate packing).

---

## When to reach for it

- **Generating many primes for offline use**: when you want a list
  of all primes up to a large `N` for use as a precomputed table.
- **Asymptotic enthusiasts**: it's the asymptotically fastest known
  sieve.
- **Anything that uses `mod 12` or `mod 60` structure**: the
  quadratic-forms approach generalises to specific residue classes.

For **single-shot primality testing of large `n`** (no need for the
full sieve), prefer `@pollard_rho.is_prime` (Miller-Rabin); it's
`O(log² n)` per test instead of `O(n)` upfront cost.

---

## Common pitfalls

- **`is_prime_atkin` sieves up to `n` itself**. This is wasteful for
  single-shot tests on large `n` — see the note above.
- **`Int` overflow**. For `n ≈ 2³⁰` (about 10⁹), the sieve bitmap
  takes ~1 GB. Beyond that you need either streaming versions or
  segmented sieves.
- **The mod-12 vs mod-60 trade-off**. The textbook Atkin uses
  `mod 60` for slightly tighter inner loops; this implementation
  uses `mod 12` (the simpler form) at a small constant-factor cost.

---

## Related concepts

```
Sieve of Atkin (this)        O(N / log log N), quadratic-form recipe
Sieve of Eratosthenes        O(N log log N), the classic
Sieve of Sundaram            O(N log N), avoids 2-multiples
Linear sieve (Euler sieve)   O(N), uses smallest prime factor table
Segmented sieve              O(N / log log N) with O(√N) memory; for huge N
Miller-Rabin                 fast probabilistic primality testing
Pollard rho                  factorisation, complements primality testing
```
