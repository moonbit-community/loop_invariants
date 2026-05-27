// ============================================================================
// LAGRANGE INTERPOLATION
// ============================================================================
//
// PROBLEM
//
// Given `n + 1` points `(x_0, y_0), ..., (x_n, y_n)` with **distinct**
// `x_i`, find the unique polynomial `P` of degree `<= n` with
// `P(x_i) = y_i` for every `i`. Evaluate `P` at an arbitrary `x`.
//
// LAGRANGE'S FORMULA
//
//   P(x) = sum_{i=0..n}  y_i * L_i(x)
//   L_i(x) = prod_{j != i}  (x - x_j) / (x_i - x_j)
//
// Each basis polynomial `L_i` satisfies `L_i(x_j) = [i == j]` so the
// formula is correct by construction; uniqueness follows from the fact
// that a non-zero polynomial of degree `<= n` has at most `n` roots.
//
// COMPLEXITY (this implementation)
//
//   evaluate(points, x)   : O(n^2)
//   eval_mod(points, x, p) : O(n^2) using a small extended-gcd mod inverse
//
// FASTER VARIANTS (not implemented here)
//
//   - When the `x_i` are equally-spaced integers, can be done in O(n).
//   - With repeated evaluation and Newton-form polynomials, can amortise
//     to O(n) per new query.
//   - Multipoint evaluation runs in O(n log^2 n) via subproduct trees.
//
// THE INVARIANT (modular evaluator)
//
//   "After completing iteration i, `acc = sum_{k=0..i} y_k * L_k(x) mod p`
//    and inv_self_i = inverse of (x_i - x_j_seen) products mod p."

///|
/// Evaluate the Lagrange interpolation polynomial at `x` using `Double`
/// arithmetic. Requires that every `points[i].0` is distinct.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Interpolating (0, 0), (1, 1), (2, 4), (3, 9) -> P(x) = x^2.
///   let pts = [(0.0, 0.0), (1.0, 1.0), (2.0, 4.0), (3.0, 9.0)]
///   @debug.assert_eq(@lagrange_interpolation.evaluate(pts, 4.0), 16.0)
/// }
/// ```
pub fn evaluate(points : Array[(Double, Double)], x : Double) -> Double {
  let n = points.length()
  let mut result = 0.0
  for i in 0..<n {
    let xi = points[i].0
    let yi = points[i].1
    let mut term = yi
    for j in 0..<n {
      if i == j {
        continue
      }
      let xj = points[j].0
      term = term * (x - xj) / (xi - xj)
    }
    result = result + term
  }
  result
}

///|
fn safe_mod(a : Int64, p : Int64) -> Int64 {
  let r = a % p
  if r < 0L {
    r + p
  } else {
    r
  }
}

///|
fn mod_pow(base : Int64, exp : Int64, p : Int64) -> Int64 {
  let mut b = safe_mod(base, p)
  let mut e = exp
  let mut r = 1L
  while e > 0L {
    if e.land(1L) == 1L {
      r = r * b % p
    }
    b = b * b % p
    e = e / 2L
  }
  r
}

///|
fn mod_inv(a : Int64, p : Int64) -> Int64 {
  // Fermat's little theorem: a^(p-2) mod p, valid when p is prime.
  mod_pow(a, p - 2L, p)
}

///|
/// Evaluate the interpolation polynomial at `x` modulo a **prime** `p`.
/// `x_i` values are interpreted modulo `p` and must be pairwise distinct
/// mod `p`. Time `O(n^2)`. Uses Fermat's little theorem for inversion,
/// so `p` must be prime and not divide any `(x_i - x_j)`.
///
/// Returns the value of `P(x) mod p` in `[0, p)`.
pub fn eval_mod(points : Array[(Int64, Int64)], x : Int64, p : Int64) -> Int64 {
  let n = points.length()
  if n == 0 {
    return 0L
  }
  let mut result = 0L
  for i in 0..<n {
    let xi = safe_mod(points[i].0, p)
    let yi = safe_mod(points[i].1, p)
    let mut num = yi
    let mut den = 1L
    for j in 0..<n {
      if i == j {
        continue
      }
      let xj = safe_mod(points[j].0, p)
      num = num * safe_mod(x - xj, p) % p
      den = den * safe_mod(xi - xj, p) % p
    }
    result = safe_mod(result + num * mod_inv(den, p), p)
  }
  result
}

///|
test "lagrange_double polynomial recovery" {
  // P(x) = x^2 from (0,0), (1,1), (2,4), (3,9).
  let pts = [(0.0, 0.0), (1.0, 1.0), (2.0, 4.0), (3.0, 9.0)]
  @debug.assert_eq(evaluate(pts, 4.0), 16.0)
  @debug.assert_eq(evaluate(pts, 5.0), 25.0)
}

///|
test "lagrange_double passes through given points" {
  // For each interpolation node, P(x_i) = y_i exactly.
  let pts = [(0.5, 1.0), (1.5, 3.0), (2.5, 7.0)]
  for p in pts {
    let v = evaluate(pts, p.0)
    // Within floating tolerance.
    let diff = if v - p.1 < 0.0 { p.1 - v } else { v - p.1 }
    @debug.assert_eq(diff < 1.0e-9, true)
  }
}

///|
test "lagrange_double linear" {
  // 2 points -> linear polynomial.
  let pts = [(0.0, 5.0), (10.0, 25.0)]
  @debug.assert_eq(evaluate(pts, 0.0), 5.0)
  @debug.assert_eq(evaluate(pts, 10.0), 25.0)
  @debug.assert_eq(evaluate(pts, 5.0), 15.0)
}

///|
test "lagrange_mod polynomial recovery" {
  // P(x) = x^2 (mod 1000000007).
  let p = 1000000007L
  let pts = [(0L, 0L), (1L, 1L), (2L, 4L), (3L, 9L)]
  // P(4) = 16 mod p.
  @debug.assert_eq(eval_mod(pts, 4L, p), 16L)
  // P(100) = 10000.
  @debug.assert_eq(eval_mod(pts, 100L, p), 10000L)
  // P(-1 mod p) = 1.
  @debug.assert_eq(eval_mod(pts, p - 1L, p), 1L)
}

///|
test "lagrange_mod cubic" {
  // P(x) = x^3 + 2*x + 5 at x=0,1,2,3 mod 97.
  // Values: 5, 8, 17, 38.
  let p = 97L
  let pts = [(0L, 5L), (1L, 8L), (2L, 17L), (3L, 38L)]
  // P(4) = 64 + 8 + 5 = 77.
  @debug.assert_eq(eval_mod(pts, 4L, p), 77L)
  // P(5) = 125 + 10 + 5 = 140 mod 97 = 43.
  @debug.assert_eq(eval_mod(pts, 5L, p), 43L)
}

///|
test "lagrange_mod recovers given points" {
  let p = 1000000007L
  let pts = [(3L, 42L), (7L, 100L), (11L, 999L), (13L, 5L)]
  for q in pts {
    @debug.assert_eq(eval_mod(pts, q.0, p), safe_mod(q.1, p))
  }
}

///|
test "lagrange_mod empty input" {
  @debug.assert_eq(eval_mod([], 5L, 7L), 0L)
}
