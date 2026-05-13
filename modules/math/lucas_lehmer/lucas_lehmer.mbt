// ============================================================================
// LUCAS-LEHMER - Specialised primality test for Mersenne numbers M_p = 2^p - 1
// ============================================================================
//
// THEOREM (Lucas 1878, Lehmer 1930)
//
// Let p be an odd prime. Define the sequence
//
//     s_0 = 4
//     s_i = (s_{i-1}^2 - 2)  mod  M_p     (for i >= 1)
//
// where M_p = 2^p - 1. Then M_p is prime if and only if s_{p-2} ≡ 0
// (mod M_p).
//
// EXAMPLE
//
// For p = 5:  M_5 = 31.  The sequence:
//   s_0 = 4
//   s_1 = 14         (16 - 2 = 14)
//   s_2 = 8          (196 - 2 = 194; 194 mod 31 = 194 - 6*31 = 8)
//   s_3 = 0          (64 - 2 = 62; 62 mod 31 = 0)
// s_{p-2} = s_3 = 0, so M_5 = 31 is prime.
//
// For p = 11: M_11 = 2047 = 23 * 89, NOT prime.
//   s_0 = 4, s_1 = 14, s_2 = 194, s_3 = 788, s_4 = 701, s_5 = 119,
//   s_6 = 1877, s_7 = 240, s_8 = 282, s_9 = 1736  (not zero)
// so M_11 is composite.
//
// PROOF SKETCH (Lehmer / Bruce '93)
//
// Define omega = 2 + sqrt(3) and omega' = 2 - sqrt(3) in Z[sqrt(3)].
// Then s_i = omega^{2^i} + omega'^{2^i}, and s_{p-2} ≡ 0 (mod M_p)
// is equivalent to omega^{(M_p+1)/2} ≡ -omega'^{(M_p+1)/2} in
// Z[sqrt(3)]/M_p. By a Fermat-style argument in that ring, this
// happens precisely when M_p is prime.
//
// TIME COMPLEXITY  : O(p) iterations, each O(log^2 M_p)
//                    via overflow-safe mul_mod -> O(p^3) overall
// SPACE COMPLEXITY : O(1)

///|
/// Normalise `x` to `[0, m)`.
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// `(a + b) mod m` without overflow when `0 <= a, b < m`.
fn add_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  if a >= m - b {
    a - (m - b)
  } else {
    a + b
  }
}

///|
/// `(a * b) mod m` via Russian-peasant doubling. Stays in Int64 even
/// for `m` near 2^62.
fn mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  for res = 0L, x = mod_norm(a, m), y = mod_norm(b, m) {
    if y == 0L {
      break res
    } else {
      let next_res = if (y & 1L) == 1L { add_mod(res, x, m) } else { res }
      continue next_res, add_mod(x, x, m), y >> 1
    }
  } where {
    proof_invariant: y >= 0L,
    proof_invariant: m > 0L,
    proof_reasoning: (
      #|INVARIANT (Russian peasant):
      #|res ≡ a * (b - y) (mod m); x ≡ a * 2^k (mod m).
      #|At y = 0 the invariant collapses to res ≡ a * b (mod m).
      #|TERMINATION: y right-shifts each iteration.
    ),
  }
}

///|
/// Test whether the Mersenne number `M_p = 2^p - 1` is prime, using
/// the Lucas-Lehmer recurrence.
///
/// ## Parameters
///
/// - `p` : the Mersenne exponent. Must satisfy `2 <= p <= 62` so that
///         `M_p` fits in `Int64`. For `p > 62`, callers need
///         arbitrary-precision arithmetic.
///
/// ## Returns
///
/// `true` iff `M_p` is a Mersenne prime.
///
/// ## Edge cases
///
/// - `p = 2`: `M_2 = 3`, a prime. We special-case this because the
///   Lucas-Lehmer sequence indexing starts at `s_{p-2}`, which is
///   `s_0 = 4`, not zero.
/// - `p < 2`: returns `false` (no valid Mersenne exponent).
/// - `p` composite (e.g. `p = 4, 6, 9`): `M_p` is automatically
///   composite (`M_{ab}` is divisible by `M_a` and `M_b`), and
///   Lucas-Lehmer correctly reports this. We do not pre-screen `p`;
///   the algorithm just runs to completion.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // The first few Mersenne primes are at p = 2, 3, 5, 7, 13, 17.
///   assert_eq(@lucas_lehmer.is_mersenne_prime(3), true) // M_3 = 7
///   assert_eq(@lucas_lehmer.is_mersenne_prime(5), true) // M_5 = 31
///   assert_eq(@lucas_lehmer.is_mersenne_prime(11), false) // M_11 = 23*89
/// }
/// ```
pub fn is_mersenne_prime(p : Int) -> Bool {
  if p < 2 {
    return false
  }
  if p == 2 {
    return true
  }
  if p > 62 {
    // M_p would overflow Int64; reject rather than silently wrap.
    return false
  }
  // M_p = 2^p - 1.
  let mp : Int64 = (1L << p) - 1L
  // Lucas-Lehmer recurrence: p - 2 iterations starting from s_0 = 4.
  for s = 4L, i = 0; i < p - 2; {
    let sq = mul_mod(s, s, mp)
    let next_s = if sq >= 2L { sq - 2L } else { sq + mp - 2L }
    continue next_s, i + 1
  } nobreak {
    s == 0L
  } where {
    proof_invariant: i >= 0 && i <= p - 2,
    proof_invariant: s >= 0L && s < mp,
    proof_reasoning: (
      #|INVARIANT (Lucas-Lehmer recurrence):
      #|After i iterations, `s` equals the i-th term of the canonical
      #|Lucas-Lehmer sequence reduced modulo M_p:
      #|  s_0 = 4
      #|  s_i = (s_{i-1}^2 - 2)  mod  M_p
      #|
      #|MAINTENANCE:
      #|Square s via overflow-safe mul_mod, subtract 2 (with wraparound
      #|via "+ mp" when the raw difference would be negative).
      #|
      #|TERMINATION:
      #|i increments by 1 each iteration, bounded by p - 2.
      #|
      #|POSTCONDITION:
      #|s == s_{p-2}; by Lucas-Lehmer's theorem this is 0 iff M_p is
      #|prime.
    ),
  }
}

///|
/// Convenience: list the first few Mersenne primes up to exponent `n`.
/// Returns the exponents `p` (not the primes themselves) such that
/// `M_p = 2^p - 1` is prime.
///
/// Useful for quickly populating a known-good list and for verifying
/// the algorithm against the OEIS sequence A000043.
pub fn mersenne_prime_exponents_up_to(n : Int) -> Array[Int] {
  let result : Array[Int] = []
  for p in 2..<=n {
    if is_mersenne_prime(p) {
      result.push(p)
    }
  } where {
    proof_invariant: p >= 2 && p <= n + 1,
    proof_reasoning: (
      #|INVARIANT (Mersenne-prime enumeration):
      #|For every value tested in [2, p), the exponent has been
      #|classified and pushed to result iff M_q is prime.
      #|MAINTENANCE: one Lucas-Lehmer test per p.
      #|TERMINATION: p advances by 1 and is bounded by n.
    ),
  }
  result
}

///|
test "lucas-lehmer small known cases" {
  // M_2 = 3, prime.
  @debug.assert_eq(is_mersenne_prime(2), true)
  // M_3 = 7, prime.
  @debug.assert_eq(is_mersenne_prime(3), true)
  // M_5 = 31, prime.
  @debug.assert_eq(is_mersenne_prime(5), true)
  // M_7 = 127, prime.
  @debug.assert_eq(is_mersenne_prime(7), true)
  // M_11 = 2047 = 23 * 89, COMPOSITE.
  @debug.assert_eq(is_mersenne_prime(11), false)
  // M_13 = 8191, prime.
  @debug.assert_eq(is_mersenne_prime(13), true)
  // M_17 = 131071, prime.
  @debug.assert_eq(is_mersenne_prime(17), true)
  // M_19 = 524287, prime.
  @debug.assert_eq(is_mersenne_prime(19), true)
}

///|
test "lucas-lehmer rejects composite exponents" {
  // For composite p, M_p is also composite. Verify a few.
  @debug.assert_eq(is_mersenne_prime(4), false) // M_4 = 15 = 3 * 5
  @debug.assert_eq(is_mersenne_prime(6), false) // M_6 = 63 = 7 * 9
  @debug.assert_eq(is_mersenne_prime(8), false) // M_8 = 255 = 3 * 85
  @debug.assert_eq(is_mersenne_prime(9), false) // M_9 = 511 = 7 * 73
}

///|
test "lucas-lehmer prime exponent but composite M_p" {
  // Some prime p have COMPOSITE M_p. The first few are p = 11, 23, 29.
  @debug.assert_eq(is_mersenne_prime(11), false) // M_11 = 23 * 89
  @debug.assert_eq(is_mersenne_prime(23), false) // M_23 = 47 * 178481
  @debug.assert_eq(is_mersenne_prime(29), false) // M_29 = 233 * 1103 * 2089
}

///|
test "lucas-lehmer enumeration matches OEIS A000043" {
  // The Mersenne-prime exponents up to 32 are 2, 3, 5, 7, 13, 17, 19, 31.
  // (Source: OEIS A000043.)
  @debug.assert_eq(mersenne_prime_exponents_up_to(32), [
    2, 3, 5, 7, 13, 17, 19, 31,
  ])
}

///|
test "lucas-lehmer edge cases" {
  @debug.assert_eq(is_mersenne_prime(0), false)
  @debug.assert_eq(is_mersenne_prime(1), false)
  @debug.assert_eq(is_mersenne_prime(-5), false)
  // p > 62 overflows Int64; the function returns false defensively.
  @debug.assert_eq(is_mersenne_prime(63), false)
}

///|
test "lucas-lehmer larger range" {
  // Up to p = 32 the Mersenne primes are at p in {2, 3, 5, 7, 13, 17,
  // 19, 31}. Counting them must give 8.
  let exps = mersenne_prime_exponents_up_to(32)
  @debug.assert_eq(exps.length(), 8)
}
