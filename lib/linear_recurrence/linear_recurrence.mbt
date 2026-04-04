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
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
fn mod_add(a : Int64, b : Int64, m : Int64) -> Int64 {
  mod_norm(a + b, m)
}

///|
fn mod_mul(a : Int64, b : Int64, m : Int64) -> Int64 {
  a * b % m
}

///|
fn pow_mod(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for e = exp, result = 1L % m, b = mod_norm(base, m); e > 0L; {
    let new_result = if (e & 1L) == 1L { mod_mul(result, b, m) } else { result }
    continue e / 2L, new_result, mod_mul(b, b, m)
  } nobreak {
    result
  } where {
    invariant: e >= 0L,
    reasoning: (
      #|INVARIANT (binary exponentiation):
      #|result * (b^e) equals base^exp modulo m. Each step consumes one bit
      #|of e, updating result and squaring b.
      #|TERMINATION:
      #|When e reaches 0, result is base^exp mod m.
    ),
  }
}

///|
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
  let result = Array::make(k, 0L)
  for i in 0..<k {
    result[i] = tmp[i]
  }
  result
}

///|
/// Compute f(n) for the given recurrence and initial values.
/// `coeffs.length()` must match the number of initial terms.
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
    invariant: e >= 0L,
    reasoning: (
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
