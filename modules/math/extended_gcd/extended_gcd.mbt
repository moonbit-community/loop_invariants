// ============================================================================
// EXTENDED EUCLIDEAN ALGORITHM
// ============================================================================
//
// PROBLEM
//
// Given two integers `a, b` (not both zero), find integers `g, x, y`
// such that
//
//   a * x + b * y = g  =  gcd(a, b)
//
// This is **Bezout's identity**: `gcd(a, b)` is always representable as
// an integer linear combination of `a` and `b`, and the algorithm gives
// one such pair `(x, y)`.
//
// USE
//
//   - Modular inverse: when `gcd(a, m) = 1`, the equation
//     `a * x ≡ 1 (mod m)` is solved by the `x` returned for `(a, m)`.
//   - Linear Diophantine equations `ax + by = c`: a solution exists iff
//     `g | c`, and any such solution can be derived from Bezout's pair.
//   - RSA, CRT, and many cryptographic primitives.
//
// ITERATIVE FORM (used here)
//
// Maintain four numbers `(old_r, r, old_s, s)` with the invariant
//
//     a * old_s + b * (?)  = old_r     -- but we drop the second
//     a * s     + b * (?)  = r            coefficient; we recover it at
//                                         the end from old_y = (g - a*x) / b.
//
// Each step does one Euclidean reduction: `(old_r, r) <- (r, old_r - q*r)`,
// and the same on `(old_s, s)`. This preserves the invariant and runs in
// `O(log min(|a|, |b|))` iterations.
//
// COMPLEXITY
//
//   Time : O(log min(|a|, |b|)) iterations, each O(1) arithmetic ops
//   Space: O(1)
//
// THE INVARIANT
//
//   "At every iteration, `old_r = a * old_s + b * old_t` and
//    `r = a * s + b * t` hold, where `t = (old_r - a*old_s) / b` (or 0
//    when `b = 0`). When `r` becomes 0, `old_r = gcd(|a|, |b|)`."

///|
/// Bezout's identity for `(a, b)`: returns `(g, x, y)` with
/// `a * x + b * y == g` and `g == gcd(|a|, |b|) >= 0`.
///
/// When `a = b = 0`, returns `(0, 0, 0)`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let (g, x, y) = @extended_gcd.bezout(30L, 18L)
///   @debug.assert_eq(g, 6L)
///   @debug.assert_eq(30L * x + 18L * y, 6L)
/// }
/// ```
pub fn bezout(a : Int64, b : Int64) -> (Int64, Int64, Int64) {
  if a == 0L && b == 0L {
    return (0L, 0L, 0L)
  }
  // Track sign so the returned g is non-negative while the coefficients
  // refer to the original a, b.
  let sign_a = if a < 0L { -1L } else { 1L }
  let mut old_r = if a < 0L { -a } else { a }
  let mut r = if b < 0L { -b } else { b }
  let mut old_s = 1L
  let mut s = 0L
  while r != 0L {
    let q = old_r / r
    let new_r = old_r - q * r
    old_r = r
    r = new_r
    let new_s = old_s - q * s
    old_s = s
    s = new_s
  }
  // Now old_r = gcd(|a|, |b|), and (old_s) is the Bezout coefficient
  // for |a|. Recover y from g - |a| * x.
  let g = old_r
  let x = old_s * sign_a
  // y * b = g - a * x. Use original b to compute; b may be 0.
  let y = if b == 0L { 0L } else { (g - a * x) / b }
  (g, x, y)
}

///|
/// Greatest common divisor of `|a|` and `|b|`; non-negative.
pub fn gcd(a : Int64, b : Int64) -> Int64 {
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
/// Modular multiplicative inverse: returns `Some(x)` with
/// `a * x ≡ 1 (mod m)` and `0 <= x < m`, or `None` if no inverse exists
/// (i.e. `gcd(a, m) != 1` or `m <= 0`).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 3 * 5 = 15 ≡ 1 (mod 7)
///   @debug.assert_eq(@extended_gcd.mod_inverse(3L, 7L), Some(5L))
/// }
/// ```
pub fn mod_inverse(a : Int64, m : Int64) -> Int64? {
  if m <= 0L {
    return None
  }
  let (g, x, _) = bezout(a, m)
  if g != 1L {
    return None
  }
  let mut r = x % m
  if r < 0L {
    r = r + m
  }
  Some(r)
}

///|
test "bezout small" {
  // gcd(30, 18) = 6, and 30*(-1) + 18*2 = 6.
  let (g, x, y) = bezout(30L, 18L)
  @debug.assert_eq(g, 6L)
  @debug.assert_eq(30L * x + 18L * y, 6L)
}

///|
test "bezout coprime" {
  // gcd(35, 12) = 1.
  let (g, x, y) = bezout(35L, 12L)
  @debug.assert_eq(g, 1L)
  @debug.assert_eq(35L * x + 12L * y, 1L)
}

///|
test "bezout with zero" {
  // gcd(a, 0) = a (for a > 0); x = 1, y = 0.
  let (g, x, y) = bezout(7L, 0L)
  @debug.assert_eq(g, 7L)
  @debug.assert_eq(x, 1L)
  @debug.assert_eq(y, 0L)
  // gcd(0, b) = b (for b > 0); x = 0, y = 1.
  let (g2, x2, y2) = bezout(0L, 9L)
  @debug.assert_eq(g2, 9L)
  @debug.assert_eq(x2, 0L)
  @debug.assert_eq(y2, 1L)
}

///|
test "bezout both zero" {
  let (g, x, y) = bezout(0L, 0L)
  @debug.assert_eq(g, 0L)
  @debug.assert_eq(x, 0L)
  @debug.assert_eq(y, 0L)
}

///|
test "bezout negative inputs" {
  // gcd is non-negative regardless of input signs.
  let (g, x, y) = bezout(-30L, 18L)
  @debug.assert_eq(g, 6L)
  @debug.assert_eq(-30L * x + 18L * y, 6L)
  let (g2, x2, y2) = bezout(30L, -18L)
  @debug.assert_eq(g2, 6L)
  @debug.assert_eq(30L * x2 + -18L * y2, 6L)
  let (g3, x3, y3) = bezout(-30L, -18L)
  @debug.assert_eq(g3, 6L)
  @debug.assert_eq(-30L * x3 + -18L * y3, 6L)
}

///|
test "gcd matches bezout" {
  for a in [-50L, -7L, 0L, 1L, 12L, 35L, 1000L] {
    for b in [-9L, 0L, 4L, 18L, 25L, 100L] {
      let (g, _, _) = bezout(a, b)
      @debug.assert_eq(gcd(a, b), g)
    }
  }
}

///|
test "mod inverse small prime" {
  // mod 7: inverses are 1->1, 2->4, 3->5, 4->2, 5->3, 6->6.
  @debug.assert_eq(mod_inverse(1L, 7L), Some(1L))
  @debug.assert_eq(mod_inverse(2L, 7L), Some(4L))
  @debug.assert_eq(mod_inverse(3L, 7L), Some(5L))
  @debug.assert_eq(mod_inverse(4L, 7L), Some(2L))
  @debug.assert_eq(mod_inverse(5L, 7L), Some(3L))
  @debug.assert_eq(mod_inverse(6L, 7L), Some(6L))
}

///|
test "mod inverse missing when not coprime" {
  // 4 has no inverse mod 6 because gcd(4, 6) = 2.
  @debug.assert_eq(mod_inverse(4L, 6L), None)
  // 3 has no inverse mod 9.
  @debug.assert_eq(mod_inverse(3L, 9L), None)
}

///|
test "mod inverse roundtrip" {
  // a * inv(a) ≡ 1 (mod m) for every coprime pair.
  let m = 97L
  for a in 1L..<m {
    match mod_inverse(a, m) {
      Some(inv) => {
        let prod = a * inv % m
        @debug.assert_eq(prod, 1L)
      }
      None => @debug.assert_eq(true, false) // 97 prime, all should invert
    }
  }
}

///|
test "mod inverse handles negative a" {
  // mod_inverse should treat a modulo m. -3 mod 7 = 4, inverse is 2.
  @debug.assert_eq(mod_inverse(-3L, 7L), Some(2L))
}

///|
test "mod inverse invalid modulus" {
  @debug.assert_eq(mod_inverse(3L, 0L), None)
  @debug.assert_eq(mod_inverse(3L, -7L), None)
}
