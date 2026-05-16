// ============================================================================
// MILLER-RABIN PRIMALITY TEST  -  Miller 1976, Rabin 1980
// ============================================================================
//
// PROBLEM
//
// Decide whether a positive integer `n` is prime, in time `O(log n)`
// per witness, using **probabilistic** evidence that can be made
// deterministic by choosing the right fixed set of witnesses.
//
// THE KEY IDENTITY
//
// Write `n - 1 = 2^s * d` with `d` odd. For a prime `n` and any
// `a` with `1 <= a <= n-1` not divisible by `n`, one of these holds:
//
//   a^d ≡ 1 (mod n)
//   a^(2^r * d) ≡ -1 (mod n)   for some 0 <= r < s
//
// If *neither* holds, `n` is composite and `a` is a **witness** for
// compositeness. A randomly chosen `a` in `[2, n-2]` is a witness with
// probability at least `3/4` for composite `n` (Rabin's theorem).
//
// DETERMINISTIC WITNESSES (used here)
//
// For inputs that fit in `Int64`, a small fixed set of bases makes the
// test deterministic. The set `{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}`
// is sufficient for **all** `n < 3.3 * 10^24` (Sorenson & Webster 2017),
// which covers every `Int64`.
//
// COMPLEXITY
//
//   Time : O(k log^3 n) bit operations where k = number of witnesses
//          (12 for the deterministic set), modular exponentiations are
//          the dominant cost
//   Space: O(1)
//
// THE INVARIANT
//
// Inside `is_strong_probable_prime`, after computing `x = a^d mod n`
// and entering the squaring loop with counter `r`:
//
//   "x ≡ a^(2^r * d)  (mod n) at every iteration."
//
// We stop early if `x == n - 1` (witness `a` failed), or if `x == 1`
// and `r > 0` (a nontrivial square root of 1 -- `a` succeeded), or if
// we exhaust all `s` squarings (`a` succeeded).

///|
/// Compute `(base^exp) mod m` using square-and-multiply, with all
/// multiplications kept in Int64 via reduction. `m` must be positive.
fn mod_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
  if m == 1L {
    return 0L
  }
  let mut b = base % m
  if b < 0L {
    b = b + m
  }
  let mut e = exp
  let mut r = 1L
  while e > 0L {
    if e.land(1L) == 1L {
      r = mod_mul(r, b, m)
    }
    b = mod_mul(b, b, m)
    e = e / 2L
  }
  r
}

///|
/// Compute `(a * b) mod m` without overflow.
///
/// We need this because `a, b < m` can have up to 62 bits each, and the
/// product can overflow Int64. We use the standard binary-decomposition
/// "Russian peasant" multiplication: `m fits in Int64`, so each addition
/// is one modular reduction.
fn mod_mul(a : Int64, b : Int64, m : Int64) -> Int64 {
  let mut x = a % m
  if x < 0L {
    x = x + m
  }
  let mut y = b % m
  if y < 0L {
    y = y + m
  }
  let mut r = 0L
  while y > 0L {
    if y.land(1L) == 1L {
      r = r + x
      if r >= m {
        r = r - m
      }
    }
    x = x + x
    if x >= m {
      x = x - m
    }
    y = y / 2L
  }
  r
}

///|
/// Strong-probable-prime test for the single base `a`. Returns true if
/// `n` passes the test (could be prime), false if `a` proves `n` is
/// composite. Requires `n > 2` and `n` odd, and `2 <= a <= n - 2`.
fn is_strong_probable_prime(n : Int64, a : Int64) -> Bool {
  // Factor n - 1 = 2^s * d with d odd.
  let mut d = n - 1L
  let mut s = 0
  while d.land(1L) == 0L {
    d = d / 2L
    s = s + 1
  }
  let mut x = mod_pow(a, d, n)
  if x == 1L || x == n - 1L {
    return true
  }
  let mut r = 1
  while r < s {
    x = mod_mul(x, x, n)
    if x == n - 1L {
      return true
    }
    if x == 1L {
      // Nontrivial sqrt(1) found -- composite.
      return false
    }
    r = r + 1
  }
  false
}

///|
/// Deterministic Miller-Rabin primality test for any `n : Int64`.
///
/// Returns `true` iff `n` is prime. Uses the witness set
/// `{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}`, which is
/// deterministic for `n < 3.3e24` (in particular for all `Int64`).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@miller_rabin.is_prime(998244353L), true)
///   @debug.assert_eq(@miller_rabin.is_prime(10L * 10L), false)
/// }
/// ```
pub fn is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  // Trial-divide by the witness primes -- this also handles n == p.
  for p in [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L] {
    if n == p {
      return true
    }
    if n % p == 0L {
      return false
    }
  }
  // Now n is odd and > 37.
  for a in [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L] {
    if !is_strong_probable_prime(n, a) {
      return false
    }
  }
  true
}

///|
test "miller_rabin small numbers" {
  // 0, 1 are not prime.
  @debug.assert_eq(is_prime(0L), false)
  @debug.assert_eq(is_prime(1L), false)
  // Negatives are not prime.
  @debug.assert_eq(is_prime(-5L), false)
  @debug.assert_eq(is_prime(-100L), false)
}

///|
test "miller_rabin first primes" {
  let small_primes = [
    2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L, 41L, 43L, 47L, 53L, 59L,
    61L, 67L, 71L, 73L, 79L, 83L, 89L, 97L,
  ]
  for p in small_primes {
    @debug.assert_eq(is_prime(p), true)
  }
}

///|
test "miller_rabin small composites" {
  let composites = [
    4L, 6L, 8L, 9L, 10L, 12L, 15L, 21L, 25L, 27L, 33L, 49L, 51L, 91L,
  ]
  for c in composites {
    @debug.assert_eq(is_prime(c), false)
  }
}

///|
test "miller_rabin agrees with trial division" {
  fn slow_is_prime(n : Int64) -> Bool {
    if n < 2L {
      return false
    }
    let mut p = 2L
    while p * p <= n {
      if n % p == 0L {
        return false
      }
      p = p + 1L
    }
    true
  }

  for n in 0L..<1000L {
    @debug.assert_eq(is_prime(n), slow_is_prime(n))
  }
}

///|
test "miller_rabin Carmichael numbers" {
  // Carmichael numbers fool Fermat's test but never Miller-Rabin.
  // 561 = 3 * 11 * 17, 1105 = 5 * 13 * 17, 1729 = 7 * 13 * 19.
  @debug.assert_eq(is_prime(561L), false)
  @debug.assert_eq(is_prime(1105L), false)
  @debug.assert_eq(is_prime(1729L), false)
  @debug.assert_eq(is_prime(2465L), false)
  @debug.assert_eq(is_prime(2821L), false)
  @debug.assert_eq(is_prime(6601L), false)
  // The smallest absolute pseudoprime to all bases up to 100 -- 41041.
  @debug.assert_eq(is_prime(41041L), false)
}

///|
test "miller_rabin large primes" {
  // Mersenne primes and other well-known primes.
  @debug.assert_eq(is_prime(8191L), true) // 2^13 - 1
  @debug.assert_eq(is_prime(131071L), true) // 2^17 - 1
  @debug.assert_eq(is_prime(524287L), true) // 2^19 - 1
  // Competitive-programming primes.
  @debug.assert_eq(is_prime(998244353L), true)
  @debug.assert_eq(is_prime(1000000007L), true)
  @debug.assert_eq(is_prime(1000000009L), true)
}

///|
test "miller_rabin near-large composites" {
  // Twin-prime composites and products of large primes.
  @debug.assert_eq(is_prime(998244353L * 2L), false)
  // 1000000007 * 1000000007 = 10^18 + ... a 64-bit safe composite.
  let large_composite = 1000000007L * 100003L
  @debug.assert_eq(is_prime(large_composite), false)
}

///|
test "miller_rabin near 2^62" {
  // Just under 2^62: 4611686018427387847 is prime (Mersenne neighborhood).
  @debug.assert_eq(is_prime(4611686018427387847L), true)
  // Even number must be composite.
  @debug.assert_eq(is_prime(4611686018427387846L), false)
}
