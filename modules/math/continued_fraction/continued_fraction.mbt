// ============================================================================
// CONTINUED FRACTIONS for rationals  -  Euclidean expansion + convergents
// ============================================================================
//
// A rational number `p / q` has a unique finite **simple continued
// fraction** representation
//
//   p / q = [a_0; a_1, a_2, ..., a_k]
//         = a_0 + 1 / (a_1 + 1 / (a_2 + ...))
//
// computed by the Euclidean algorithm:
//
//   a_i = floor(p_i / q_i)
//   (p_{i+1}, q_{i+1}) = (q_i, p_i - a_i * q_i)
//
// stopping when `q_{i+1} = 0`.
//
// THE CONVERGENTS
//
// The k-th **convergent** is `h_k / k_k` where
//
//   h_{-1} = 1, h_0 = a_0
//   k_{-1} = 0, k_0 = 1
//   h_n    = a_n h_{n-1} + h_{n-2}
//   k_n    = a_n k_{n-1} + k_{n-2}
//
// The convergents are the **best rational approximations** of `p/q`
// with denominators at most `k_n`.
//
// COMPLEXITY
//
//   to_cf(p, q)          : O(log min(|p|, |q|))   -- Euclidean
//   convergents(cf)       : O(n)
//   from_cf(cf)           : O(n)
//
// THE INVARIANT
//
//   "After yielding the i-th coefficient, (p_i, q_i) satisfies
//    p / q = [a_0; ...; a_i] applied to (p_i, q_i) -- equivalently,
//    p k_i + (-1)^i p_i = q h_i and similar identities (Bezout-style)."

///|
/// Expand `p / q` into its continued-fraction coefficients. The first
/// coefficient may be negative; subsequent coefficients are positive.
/// Returns `[]` when `q == 0`. By convention the expansion uses the
/// shorter form where the last coefficient is not `1` (except for the
/// trivial case `p/q = 1`).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 7/3 = 2 + 1/3 -> [2; 3]
///   @debug.assert_eq(@continued_fraction.to_cf(7L, 3L), [2L, 3L])
/// }
/// ```
pub fn to_cf(p : Int64, q : Int64) -> Array[Int64] {
  if q == 0L {
    return []
  }
  let mut x = p
  let mut y = q
  // Make denominator positive: cf(-p, q) = -cf(p, q) at position 0 only.
  if y < 0L {
    x = -x
    y = -y
  }
  let res : Array[Int64] = []
  while y != 0L {
    let a = floor_div(x, y)
    res.push(a)
    let nx = y
    let ny = x - a * y
    x = nx
    y = ny
  }
  res
}

///|
fn floor_div(a : Int64, b : Int64) -> Int64 {
  let q = a / b
  let r = a % b
  if r != 0L && (r < 0L) != (b < 0L) {
    q - 1L
  } else {
    q
  }
}

///|
/// Reconstruct `(numerator, denominator)` from a CF coefficient list.
/// The returned fraction is in lowest terms (because consecutive
/// convergents satisfy `h_n k_{n-1} - k_n h_{n-1} = (-1)^n`).
pub fn from_cf(cf : Array[Int64]) -> (Int64, Int64) {
  let n = cf.length()
  if n == 0 {
    return (0L, 0L)
  }
  // Evaluate from the right: x = a_i + 1/x.
  let mut num = cf[n - 1]
  let mut den = 1L
  let mut i = n - 2
  while i >= 0 {
    // x = a_i + 1 / (num/den) = (a_i * num + den) / num
    let new_num = cf[i] * num + den
    let new_den = num
    num = new_num
    den = new_den
    i = i - 1
  }
  (num, den)
}

///|
/// Compute the sequence of convergents h_k / k_k of a CF expansion.
/// Returns an array of `(h_k, k_k)` pairs, one per coefficient.
pub fn convergents(cf : Array[Int64]) -> Array[(Int64, Int64)] {
  let n = cf.length()
  let res : Array[(Int64, Int64)] = []
  if n == 0 {
    return res
  }
  // h_{-2} = 0, h_{-1} = 1; k_{-2} = 1, k_{-1} = 0.
  let mut h_prev2 = 0L
  let mut h_prev1 = 1L
  let mut k_prev2 = 1L
  let mut k_prev1 = 0L
  for i in 0..<n {
    let h = cf[i] * h_prev1 + h_prev2
    let k = cf[i] * k_prev1 + k_prev2
    res.push((h, k))
    h_prev2 = h_prev1
    h_prev1 = h
    k_prev2 = k_prev1
    k_prev1 = k
  }
  res
}

///|
/// Greatest common divisor (helper for normalising returns).
fn gcd(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }
  while y != 0L {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
test "cf small examples" {
  // 7/3 = [2; 3]
  @debug.assert_eq(to_cf(7L, 3L), [2L, 3L])
  // 22/7 = [3; 7]
  @debug.assert_eq(to_cf(22L, 7L), [3L, 7L])
  // 1/1 = [1]
  @debug.assert_eq(to_cf(1L, 1L), [1L])
  // 0/1 = [0]
  @debug.assert_eq(to_cf(0L, 1L), [0L])
}

///|
test "cf 415/93 (Euclid example)" {
  // 415/93 = [4; 2, 6, 7]
  @debug.assert_eq(to_cf(415L, 93L), [4L, 2L, 6L, 7L])
}

///|
test "cf round trip" {
  // For many (p, q) pairs, to_cf -> from_cf should recover p/q in
  // lowest terms.
  for p in 1L..<100L {
    for q in 1L..<100L {
      let cf = to_cf(p, q)
      let (n, d) = from_cf(cf)
      let g = gcd(p, q)
      @debug.assert_eq((n, d), (p / g, q / g))
    }
  }
}

///|
test "convergents of pi via [3; 7, 15, 1, 292, ...]" {
  let cf : Array[Int64] = [3L, 7L, 15L, 1L, 292L, 1L, 1L, 1L, 2L, 1L]
  let cv = convergents(cf)
  // Classical pi approximations.
  @debug.assert_eq(cv[0], (3L, 1L))
  @debug.assert_eq(cv[1], (22L, 7L))
  @debug.assert_eq(cv[2], (333L, 106L))
  @debug.assert_eq(cv[3], (355L, 113L))
  @debug.assert_eq(cv[4], (103993L, 33102L))
}

///|
test "convergents alternate sides of target" {
  // For p/q = 415/93, even-index convergents should be less than p/q,
  // odd-index greater (or equal at the last).
  let cf = to_cf(415L, 93L)
  let cv = convergents(cf)
  let target_n = 415L
  let target_d = 93L
  for i in 0..<cv.length() {
    let (h, k) = cv[i]
    // Sign of (h * target_d - target_n * k) alternates.
    let diff = h * target_d - target_n * k
    if i % 2 == 0 && i < cv.length() - 1 {
      @debug.assert_eq(diff <= 0L, true)
    }
    if i % 2 == 1 && i < cv.length() - 1 {
      @debug.assert_eq(diff >= 0L, true)
    }
  }
  // Final convergent equals the target.
  let (h, k) = cv[cv.length() - 1]
  @debug.assert_eq(h, target_n / gcd(target_n, target_d))
  @debug.assert_eq(k, target_d / gcd(target_n, target_d))
}

///|
test "cf negatives" {
  // -7 / 3 = -3 + 2/3 = -3 + 1/(3/2) = -3 + 1/(1 + 1/2) -> [-3; 1, 2]
  @debug.assert_eq(to_cf(-7L, 3L), [-3L, 1L, 2L])
  let (n, d) = from_cf([-3L, 1L, 2L])
  @debug.assert_eq(n, -7L)
  @debug.assert_eq(d, 3L)
}

///|
test "cf empty when denom zero" {
  @debug.assert_eq(to_cf(5L, 0L), [])
  @debug.assert_eq(convergents([]), [])
}
