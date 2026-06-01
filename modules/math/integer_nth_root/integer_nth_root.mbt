// ============================================================================
// INTEGER n-th ROOT  -  Newton's method on integers
// ============================================================================
//
// PROBLEM
//
// Given non-negative integer `x` and positive integer `n`, return
//
//   r = floor(x^{1/n})
//
// the largest integer such that `r^n <= x < (r+1)^n`. The classical
// use case `n = 2` is **integer square root**; for `n = 3` it is
// `icbrt`; and the general routine is useful in primality testing
// (testing whether `x` is a perfect power).
//
// NEWTON'S METHOD ON INTEGERS
//
//   x_{k+1} = ((n - 1) x_k + (x / x_k^{n-1})) / n
//
// converges from above to the true `n`-th root. Standard fix-ups
// handle the cases `n = 1`, `x = 0`, and the small-root regime where
// the Newton update would oscillate.
//
// COMPLEXITY
//
//   Time : O(log log x)  arithmetic operations (Newton's quadratic
//          convergence). Each op is O(n) bignum-style ints, but we
//          stay in Int64.
//   Space: O(1)
//
// THE INVARIANT
//
//   "At every step of the Newton iteration, x_k * is an upper bound
//    for the true n-th root, and x_{k+1} <= x_k while x_{k+1}^n >= x
//    is still possible. The loop exits when x_{k+1} >= x_k."

///|
fn ipow(b : Int64, e : Int) -> Int64 {
  let mut r = 1L
  let mut bb = b
  let mut ee = e
  while ee > 0 {
    if (ee & 1) == 1 {
      r = r * bb
    }
    bb = bb * bb
    ee = ee >> 1
  }
  r
}

///|
/// Floor of the integer n-th root.
///
/// Requires `n >= 1`. Returns `0` for `x < 0` or `n < 1`. Saturates
/// at the largest `Int64` value if intermediate overflow would happen.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@integer_nth_root.nth_root(1000000L, 3), 100L)
/// }
/// ```
pub fn nth_root(x : Int64, n : Int) -> Int64 {
  if x < 0L || n < 1 {
    return 0L
  }
  if n == 1 || x == 0L || x == 1L {
    return x
  }
  // Initial guess: 2^ceil(log2(x) / n) is comfortably above the root.
  let mut r = 1L
  while ipow_safe(r, n) < x && r <= 1000000000L {
    r = r * 2L
  }
  // Cap r to avoid Int64.max accidents.
  if r > 2147483647L {
    r = 2147483647L
  }
  // Newton iterate.
  let mut prev = r
  let mut iter = 0
  while iter < 100 {
    let nm1 = (n - 1).to_int64()
    let pn1 = ipow_safe(r, n - 1)
    if pn1 == 0L {
      break
    }
    let next = (nm1 * r + x / pn1) / n.to_int64()
    if next >= r {
      // Done; converged from above.
      break
    }
    prev = r
    r = next
    iter = iter + 1
  }
  let _ = prev
  // Floor adjustment in case Newton overshot slightly: walk down/up.
  while r > 0L && ipow_safe(r, n) > x {
    r = r - 1L
  }
  while ipow_safe(r + 1L, n) <= x {
    r = r + 1L
  }
  r
}

///|
/// Safe `b^e` that saturates at `Int64.max_value` on overflow.
fn ipow_safe(b : Int64, e : Int) -> Int64 {
  let max = 9223372036854775807L
  if b == 0L {
    return if e == 0 { 1L } else { 0L }
  }
  if b == 1L {
    return 1L
  }
  let mut r = 1L
  let mut bb = b
  let mut ee = e
  while ee > 0 {
    if (ee & 1) == 1 {
      // r = r * bb with overflow check.
      if bb > max / r {
        return max
      }
      r = r * bb
    }
    ee = ee >> 1
    if ee > 0 {
      if bb > max / bb {
        bb = max
      } else {
        bb = bb * bb
      }
    }
  }
  let _ = ipow
  r
}

///|
/// `true` iff `x` is a perfect `n`-th power.
pub fn is_perfect_nth_power(x : Int64, n : Int) -> Bool {
  if x < 0L || n < 1 {
    return false
  }
  let r = nth_root(x, n)
  ipow_safe(r, n) == x
}

///|
/// Integer square root: floor(sqrt(x)).
pub fn isqrt(x : Int64) -> Int64 {
  nth_root(x, 2)
}

///|
/// Integer cube root: floor(cbrt(x)).
pub fn icbrt(x : Int64) -> Int64 {
  nth_root(x, 3)
}

///|
test "isqrt small" {
  @debug.assert_eq(isqrt(0L), 0L)
  @debug.assert_eq(isqrt(1L), 1L)
  @debug.assert_eq(isqrt(2L), 1L)
  @debug.assert_eq(isqrt(3L), 1L)
  @debug.assert_eq(isqrt(4L), 2L)
  @debug.assert_eq(isqrt(8L), 2L)
  @debug.assert_eq(isqrt(9L), 3L)
  @debug.assert_eq(isqrt(15L), 3L)
  @debug.assert_eq(isqrt(16L), 4L)
}

///|
test "isqrt large" {
  @debug.assert_eq(isqrt(100L), 10L)
  @debug.assert_eq(isqrt(99L), 9L)
  @debug.assert_eq(isqrt(10000L), 100L)
  @debug.assert_eq(isqrt(1000000000000L), 1000000L)
}

///|
test "icbrt small" {
  @debug.assert_eq(icbrt(0L), 0L)
  @debug.assert_eq(icbrt(7L), 1L)
  @debug.assert_eq(icbrt(8L), 2L)
  @debug.assert_eq(icbrt(26L), 2L)
  @debug.assert_eq(icbrt(27L), 3L)
  @debug.assert_eq(icbrt(63L), 3L)
  @debug.assert_eq(icbrt(64L), 4L)
}

///|
test "icbrt large" {
  @debug.assert_eq(icbrt(1000L), 10L)
  @debug.assert_eq(icbrt(1000000L), 100L)
  @debug.assert_eq(icbrt(1000000000L), 1000L)
}

///|
test "nth_root general" {
  // 2^10 = 1024.
  @debug.assert_eq(nth_root(1024L, 10), 2L)
  // 3^7 = 2187.
  @debug.assert_eq(nth_root(2187L, 7), 3L)
  // 5^5 = 3125 -> floor.
  @debug.assert_eq(nth_root(3124L, 5), 4L)
  @debug.assert_eq(nth_root(3125L, 5), 5L)
}

///|
test "nth_root edge cases" {
  @debug.assert_eq(nth_root(0L, 2), 0L)
  @debug.assert_eq(nth_root(1L, 100), 1L)
  @debug.assert_eq(nth_root(-5L, 2), 0L)
  @debug.assert_eq(nth_root(100L, 1), 100L)
  @debug.assert_eq(nth_root(50L, 0), 0L)
}

///|
test "perfect powers" {
  @debug.assert_eq(is_perfect_nth_power(1024L, 10), true)
  @debug.assert_eq(is_perfect_nth_power(1024L, 11), false)
  @debug.assert_eq(is_perfect_nth_power(0L, 5), true)
  @debug.assert_eq(is_perfect_nth_power(1L, 5), true)
  @debug.assert_eq(is_perfect_nth_power(8L, 3), true)
  @debug.assert_eq(is_perfect_nth_power(9L, 2), true)
  @debug.assert_eq(is_perfect_nth_power(10L, 2), false)
}

///|
test "nth_root brute force agreement" {
  for n in 1..<=6 {
    for x in 0L..<200L {
      let r = nth_root(x, n)
      // r^n <= x < (r+1)^n
      @debug.assert_eq(ipow_safe(r, n) <= x, true)
      @debug.assert_eq(ipow_safe(r + 1L, n) > x, true)
    }
  }
}
