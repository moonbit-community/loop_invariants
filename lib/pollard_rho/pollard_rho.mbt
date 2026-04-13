// ============================================================================
// POLLARD RHO FACTORIZATION (64-bit)
// ============================================================================
//
// Implements Miller-Rabin primality test and Pollard's Rho to factor Int64
// values. Uses safe modular multiplication to avoid overflow.
//
// Deterministic bases for 64-bit integers are used in Miller-Rabin.

///|
/// Normalize `x` into the range [0, m) by removing the sign of the remainder.
///
/// The built-in `%` operator may return a negative result for negative
/// operands in MoonBit. This function ensures the result is always
/// non-negative, which is required before passing values to `add_mod` or
/// `mul_mod`.
///
/// Parameters:
/// - `x` : the value to normalize (may be negative).
/// - `m` : the modulus; must be positive.
///
/// Returns `x mod m` in [0, m).
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// Compute `(a + b) mod m` without intermediate overflow.
///
/// Ordinary addition `a + b` can overflow `Int64` when both operands are
/// near `m`. This function avoids overflow by using the identity:
///
/// ```
///   a + b - m  is equivalent to  a - (m - b)
/// ```
///
/// which stays within `Int64` range because `0 <= a < m` and `0 <= b < m`.
///
/// Preconditions: `0 <= a < m` and `0 <= b < m`.
fn add_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  if a >= m - b {
    a - (m - b)
  } else {
    a + b
  }
}

///|
/// Compute `(a * b) mod m` without intermediate overflow.
///
/// Multiplying two 64-bit values can overflow `Int64` when both operands
/// approach 2^62. This function implements the binary (Russian peasant)
/// method: repeatedly double `a` and halve `b`, accumulating into `res`
/// whenever the low bit of `b` is set. All additions are done through
/// `add_mod`, which avoids overflow.
///
/// Time complexity: O(log b).
///
/// Preconditions: `m > 0`.
fn mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  for res = 0L, x = mod_norm(a, m), y = mod_norm(b, m) {
    if y == 0L {
      break res
    } else {
      let next_res = if (y & 1L) == 1L { add_mod(res, x, m) } else { res }
      continue next_res, add_mod(x, x, m), y >> 1
    }
  }
}

///|
/// Compute `base^exp mod m` using fast binary exponentiation.
///
/// The loop invariant is:
///
/// ```
///   acc * b^e  ==  base^exp  (mod m)
/// ```
///
/// At each step either:
/// - `e` is odd: multiply `acc` by `b` and decrement `e`, or
/// - `e` is even: square `b` and halve `e`.
///
/// When `e` reaches 0, `acc` holds the result.
///
/// All intermediate multiplications are delegated to `mul_mod` to avoid
/// 64-bit overflow.
///
/// Time complexity: O(log exp).
///
/// Preconditions: `exp >= 0` and `m > 0`.
fn pow_mod(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for b = mod_norm(base, m), e = exp, acc = 1L % m {
    if e == 0L {
      break acc
    } else if (e & 1L) == 1L {
      continue b, e - 1L, mul_mod(acc, b, m)
    } else {
      continue mul_mod(b, b, m), e / 2L, acc
    }
  } where {
    proof_invariant: e >= 0L && acc >= 0L && acc < m,
    proof_reasoning: (
      #|INVARIANT (modular exponentiation):
      #|acc * b^e ≡ base^exp (mod m) is preserved at every step.
      #|MAINTENANCE:
      #|When e is odd, multiply acc by b and decrement e; when e is even,
      #|square b and halve e.
      #|TERMINATION:
      #|At e = 0, acc is base^exp mod m.
    ),
  }
}

///|
/// Compute `gcd(|a|, |b|)` using the Euclidean algorithm.
///
/// Negative inputs are handled by taking absolute values before the loop.
/// The loop maintains the invariant `gcd(x, y) = gcd(|a|, |b|)` and
/// terminates because `y` strictly decreases at each step.
///
/// Time complexity: O(log(min(|a|, |b|))).
fn gcd(a : Int64, b : Int64) -> Int64 {
  for x = (if a < 0L { -a } else { a }), y = (if b < 0L { -b } else { b }) {
    if y == 0L {
      break x
    } else {
      continue y, x % y
    }
  }
}

///|
/// Perform a single Miller-Rabin witness check for base `a`.
///
/// Given the factorization `n - 1 = d * 2^s` with `d` odd, a prime `n`
/// satisfies: either
///
/// ```
///   a^d == 1  (mod n)
/// ```
///
/// or there exists some `r` in [0, s) such that
///
/// ```
///   a^(d * 2^r) == n - 1  (mod n).
/// ```
///
/// If neither condition holds, `n` is definitely composite and the function
/// returns `false`. Otherwise it returns `true` (the base passes).
///
/// Parameters:
/// - `n` : the number under test; must be odd and >= 3.
/// - `a` : the witness base; must satisfy `1 < a < n - 1`.
/// - `d` : odd part of `n - 1`.
/// - `s` : exponent of 2 in `n - 1 = d * 2^s`.
fn miller_test(n : Int64, a : Int64, d : Int64, s : Int) -> Bool {
  let x = pow_mod(a, d, n)
  if x == 1L || x == n - 1L {
    return true
  }
  for r = 1, x = x {
    if r >= s {
      break false
    } else {
      let x = mul_mod(x, x, n)
      if x == n - 1L {
        break true
      } else {
        continue r + 1, x
      }
    }
  } where {
    proof_invariant: r >= 1 && r <= s,
    proof_reasoning: (
      #|INVARIANT (Miller-Rabin squaring):
      #|x equals a^(d * 2^r) mod n after r squarings.
      #|MAINTENANCE:
      #|Square x to advance to the next power of two.
      #|TERMINATION:
      #|If x hits n-1, the base passes; otherwise composite is detected.
    ),
  }
}

///|
/// Test whether `n` is prime using a deterministic Miller-Rabin test.
///
/// For 64-bit integers, testing against the 12 fixed bases
/// `{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}` is provably sufficient:
/// there are no pseudoprimes below 3.3 * 10^24 for this witness set, so
/// the result is deterministic for all `Int64` values.
///
/// The algorithm:
/// 1. Reject `n < 2` immediately.
/// 2. Accept or reject small values that appear directly in the base list.
/// 3. Write `n - 1 = d * 2^s` with `d` odd.
/// 4. For each base `a`, run `miller_test(n, a, d, s)`.
///
/// Time complexity: O(log^3 n) (12 bases, each taking O(log^2 n) via
/// `pow_mod` and `mul_mod`).
///
/// Parameters:
/// - `n` : the 64-bit integer to test; may be any value including negative.
///
/// Returns `true` if and only if `n` is prime.
pub fn is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  let bases : Array[Int64] = [
    2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L,
  ]
  for p in bases {
    if n == p {
      return true
    }
    if n % p == 0L {
      return false
    }
  }
  let (d, s) = for d = n - 1L, s = 0 {
    if d % 2L != 0L {
      break (d, s)
    } else {
      continue d / 2L, s + 1
    }
  } where {
    proof_invariant: d >= 1L && s >= 0 && d * (1L << s) == n - 1L,
    proof_reasoning: (
      #|INVARIANT (factor n-1):
      #|d * 2^s = n-1 is preserved while d is even.
      #|MAINTENANCE:
      #|Halve d and increment s.
      #|TERMINATION:
      #|d becomes odd, giving the decomposition needed for Miller-Rabin.
    ),
  }
  for a in bases {
    if a % n == 0L {
      continue
    }
    if !miller_test(n, a, d, s) {
      return false
    }
  }
  true
}

///|
/// Find a non-trivial factor of the composite number `n` using Pollard's Rho.
///
/// The algorithm generates a pseudo-random sequence using the quadratic map
/// `f(x) = x^2 + c  (mod n)` and applies Floyd's tortoise-and-hare cycle
/// detection. When the tortoise and hare meet modulo a hidden prime factor
/// `p` of `n`, the gcd of their difference with `n` reveals `p`.
///
/// Because the state space modulo `p` is much smaller than modulo `n`,
/// a collision modulo `p` is expected after O(sqrt(p)) steps. Since `p`
/// divides `n` and `p <= sqrt(n)`, this is at most O(n^(1/4)) steps.
///
/// If a constant `c` causes a degenerate cycle where gcd returns `n`,
/// the next constant from `[1, 3, 5, 7, 11, 13, 17]` is tried.
///
/// Special case: if `n` is even, 2 is returned immediately.
///
/// Preconditions: `n > 1` and `n` is composite (callers should verify
/// primality with `is_prime` before calling this function).
///
/// Returns a non-trivial divisor `d` with `1 < d < n`, or `n` itself as a
/// fallback if all constants are exhausted (should not occur for valid
/// 64-bit composite inputs).
fn pollard_rho(n : Int64) -> Int64 {
  if (n & 1L) == 0L {
    return 2L
  }
  let constants : Array[Int64] = [1L, 3L, 5L, 7L, 11L, 13L, 17L]
  for idx in 0..<constants.length() {
    let c = constants[idx]
    let d = for x = 2L, y = 2L, d = 1L {
      if d != 1L {
        break d
      } else {
        let x = (mul_mod(x, x, n) + c) % n
        let y = (mul_mod(y, y, n) + c) % n
        let y = (mul_mod(y, y, n) + c) % n
        let diff = if x > y { x - y } else { y - x }
        continue x, y, gcd(diff, n)
      }
    }
    if d != n {
      return d
    }
  } where {
    proof_invariant: idx >= 0 && idx <= constants.length(),
    proof_reasoning: (
      #|INVARIANT (rho attempts):
      #|All constants in constants[0..idx) have been tried without success.
      #|MAINTENANCE:
      #|Run a rho iteration with constant c until a nontrivial factor is found.
      #|TERMINATION:
      #|At idx = len, either a factor is found or n is returned as fallback.
    ),
  }
  n
}

///|
/// Recursively collect prime factors of `n` into `factors`.
///
/// The recursion proceeds as follows:
/// - If `n == 1`, there is nothing to do.
/// - If `n` is prime (`is_prime` returns true), push `n` directly.
/// - Otherwise, find a non-trivial divisor `d` via `pollard_rho` and
///   recurse on both `d` and `n / d`.
///
/// Because each recursive call receives a strictly smaller number, and
/// `is_prime` terminates the recursion for all primes, the recursion
/// always terminates.
///
/// Parameters:
/// - `n`       : the integer to factor; must be >= 1.
/// - `factors` : accumulator array; prime factors are appended in the order
///               they are discovered (unsorted).
fn factor_rec(n : Int64, factors : Array[Int64]) -> Unit {
  if n == 1L {
    return
  }
  if is_prime(n) {
    factors.push(n)
    return
  }
  let d = pollard_rho(n)
  if d == n {
    factors.push(n)
    return
  }
  factor_rec(d, factors)
  factor_rec(n / d, factors)
}

///|
/// Factorize `n` into its prime factors, returned in sorted ascending order
/// with repetitions.
///
/// Example:
/// ```
/// factorize(360L) // => [2L, 2L, 2L, 3L, 3L, 5L]
/// factorize(97L)  // => [97L]
/// factorize(1L)   // => []
/// ```
///
/// The algorithm:
/// 1. Return an empty array for `n <= 1`.
/// 2. Call `factor_rec` to recursively collect all prime factors.
/// 3. Sort the result in ascending order.
///
/// Expected time complexity: O(n^(1/4) * k * log n) where `k` is the
/// number of distinct prime factors (at most 15 for 64-bit integers, since
/// 2 * 3 * 5 * ... * 47 < 2^63).
///
/// Parameters:
/// - `n` : the 64-bit integer to factor; values <= 1 return an empty array.
///
/// Returns a sorted `Array[Int64]` of prime factors with repetitions.
pub fn factorize(n : Int64) -> Array[Int64] {
  let factors : Array[Int64] = []
  if n <= 1L {
    return factors
  }
  factor_rec(n, factors)
  factors.sort()
  factors
}

///|
/// Factorize `n` and return the result as `(prime, exponent)` pairs.
///
/// Each pair `(p, e)` indicates that `p^e` divides `n` exactly, and `p`
/// is prime. The pairs are sorted in ascending order of `p`.
///
/// Example:
/// ```
/// factorize_with_counts(360L) // => [(2L, 3), (3L, 2), (5L, 1)]
/// factorize_with_counts(97L)  // => [(97L, 1)]
/// factorize_with_counts(1L)   // => []
/// ```
///
/// This is a convenience wrapper over `factorize`: it calls `factorize` to
/// get the sorted prime list, then runs-length-encodes consecutive equal
/// primes into `(prime, count)` pairs.
///
/// Parameters:
/// - `n` : the 64-bit integer to factor; values <= 1 return an empty array.
///
/// Returns an `Array[(Int64, Int)]` of `(prime, exponent)` pairs sorted by
/// prime in ascending order.
pub fn factorize_with_counts(n : Int64) -> Array[(Int64, Int)] {
  let factors = factorize(n)
  let result : Array[(Int64, Int)] = []
  for i = 0 {
    if i >= factors.length() {
      break result
    } else {
      let p = factors[i]
      let (next_i, cnt) = for i = i + 1, cnt = 1 {
        if i >= factors.length() || factors[i] != p {
          break (i, cnt)
        } else {
          continue i + 1, cnt + 1
        }
      }
      result.push((p, cnt))
      continue next_i
    }
  }
}
