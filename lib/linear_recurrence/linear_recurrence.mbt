// ============================================================================
// LINEAR RECURRENCE - Kitamasa (linear rec exponentiation)
// ============================================================================
//
// Given coefficients c[0..k-1] and initial values f[0..k-1], compute f(n):
//   f(n) = c0*f(n-1) + c1*f(n-2) + ... + c_{k-1}*f(n-k)  (mod M)
//
// This uses polynomial doubling (Kitamasa) with O(k^2 log n) time.
//
// TIME COMPLEXITY: O(k^2 log n)
// SPACE COMPLEXITY: O(k)

///|
/// Normalize `x` into the range `[0, m)`.
///
/// Returns `x mod m` as a non-negative value, correcting for MoonBit's
/// sign-preserving `%` operator on negative operands.
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// Compute `(a + b) mod m`, with result in `[0, m)`.
fn mod_add(a : Int64, b : Int64, m : Int64) -> Int64 {
  mod_norm(a + b, m)
}

///|
/// Compute `(a * b) mod m`.
///
/// Both operands are assumed to already be in `[0, m)` so the intermediate
/// product fits within an `Int64` for typical competitive-programming moduli
/// (m <= 10^9).
fn mod_mul(a : Int64, b : Int64, m : Int64) -> Int64 {
  a * b % m
}

///|
/// Compute `base^exp mod m` using binary (fast) exponentiation.
///
/// Handles `m = 1` correctly (result is 0) and normalises negative bases.
///
/// Loop invariant: `result * (b^e) == base^exp (mod m)` at every iteration.
/// Each step consumes one bit of `e`, updating `result` and squaring `b`.
/// When `e` reaches 0, `result` equals `base^exp mod m`.
fn pow_mod(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for e = exp, result = 1L % m, b = mod_norm(base, m); e > 0L; {
    let new_result = if (e & 1L) == 1L { mod_mul(result, b, m) } else { result }
    continue e / 2L, new_result, mod_mul(b, b, m)
  } nobreak {
    result
  } where {
    proof_invariant: e >= 0L,
    proof_reasoning: (
      #|INVARIANT (binary exponentiation):
      #|result * (b^e) equals base^exp modulo m. Each step consumes one bit
      #|of e, updating result and squaring b.
      #|TERMINATION:
      #|When e reaches 0, result is base^exp mod m.
    ),
  }
}

///|
/// Multiply two degree-(k-1) coefficient vectors `a` and `b`, then reduce
/// the degree-(2k-2) product modulo the characteristic polynomial of the
/// recurrence.
///
/// The characteristic polynomial is:
///
/// ```
/// P(x) = x^k - coeffs[0]*x^(k-1) - coeffs[1]*x^(k-2) - ... - coeffs[k-1]
/// ```
///
/// Reduction uses the identity `x^k = coeffs[0]*x^(k-1) + ... + coeffs[k-1]`
/// to fold high-degree terms back into degree 0..k-1.
///
/// The result has length `k` and represents the product polynomial mod `P(x)`
/// over `Z/mZ`.
///
/// Time complexity: O(k^2).
fn combine(
  a : Array[Int64],
  b : Array[Int64],
  coeffs : ArrayView[Int64],
  m : Int64,
) -> Array[Int64] {
  let k = coeffs.length()
  let tmp = Array::make(2 * k - 1, 0L)
  for i in 0..<k {
    for j in 0..<k {
      let idx = i + j
      tmp[idx] = mod_add(tmp[idx], mod_mul(a[i], b[j], m), m)
    }
  }
  let start_exclusive = 2 * k - 1
  for i in start_exclusive>..k {
    let val = tmp[i]
    if val != 0L {
      for j in 1..<(k + 1) {
        let idx = i - j
        tmp[idx] = mod_add(tmp[idx], mod_mul(val, coeffs[j - 1], m), m)
      }
    }
  }
  [|
    for i in 0..<k => tmp[i]
  |]
}

///|
/// Compute the n-th term of a linear recurrence modulo `m` using the
/// Kitamasa method.
///
/// The recurrence of order `k` is defined by:
///
/// ```
/// f(n) = coeffs[0]*f(n-1) + coeffs[1]*f(n-2) + ... + coeffs[k-1]*f(n-k)
/// ```
///
/// with `initial[i] = f(i)` for `i` in `0..<k`.
///
/// Parameters:
/// - `coeffs`  - recurrence coefficients `[c0, c1, ..., c_{k-1}]`, length k
/// - `initial` - initial values `[f(0), f(1), ..., f(k-1)]`, length k
/// - `n`       - the index to evaluate (0-based, non-negative)
/// - `m`       - positive modulus; all arithmetic is performed mod m
///
/// Returns `f(n) mod m`.
///
/// Constraints:
/// - `coeffs.length() == initial.length()` (both equal k)
/// - `m > 0`
/// - `n >= 0`
///
/// Time complexity: O(k^2 log n).
/// Space complexity: O(k).
///
/// Special cases:
/// - `k = 0`: returns 0.
/// - `n < k`: returns `initial[n] mod m` directly.
/// - `k = 1`: reduces to fast modular exponentiation in O(log n).
///
/// The algorithm represents `x^n mod P(x)` as a coefficient vector of
/// length k, where `P(x)` is the characteristic polynomial of the recurrence.
/// Binary exponentiation on these vectors drives the doubling:
///
/// Loop invariant: `res` encodes `x^(processed bits)` and `base` encodes
/// `x^(current power)`, both reduced modulo `P(x)`. When `e` reaches 0,
/// `res[i]` gives the coefficient of `f(i)` in the expansion of `f(n)`.
pub fn linear_recurrence_nth(
  coeffs : ArrayView[Int64],
  initial : ArrayView[Int64],
  n : Int64,
  m : Int64,
) -> Int64 {
  let k = coeffs.length()
  if k == 0 {
    return 0L
  }
  if n < k.to_int64() {
    return mod_norm(initial[n.to_int()], m)
  }
  if k == 1 {
    return mod_mul(initial[0], pow_mod(coeffs[0], n, m), m)
  }
  let init_res = Array::make(k, 0L)
  init_res[0] = 1L
  let init_base = Array::make(k, 0L)
  init_base[1] = 1L
  let (res, _) = for e = n, res = init_res, base = init_base; e > 0L; {
    let new_res = if (e & 1L) == 1L {
      combine(res, base, coeffs, m)
    } else {
      res
    }
    continue e / 2L, new_res, combine(base, base, coeffs, m)
  } nobreak {
    (res, base)
  } where {
    proof_invariant: e >= 0L,
    proof_reasoning: (
      #|INVARIANT (Kitamasa exponent):
      #|res encodes x^processed modulo the characteristic polynomial, base
      #|encodes x^current_power, and e tracks remaining exponent bits.
      #|TERMINATION:
      #|When e = 0, res encodes x^n modulo the recurrence.
    ),
  }
  let ans = for i in 0..<k; ans = 0L {
    continue mod_add(ans, mod_mul(res[i], initial[i], m), m)
  } nobreak {
    ans
  }
  ans
}
