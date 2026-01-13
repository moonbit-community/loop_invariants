// ============================================================================
// BERLEKAMP–MASSEY - Minimal linear recurrence over a prime modulus
// ============================================================================
//
// Given a sequence s[0..n-1], Berlekamp–Massey finds the shortest linear
// recurrence of the form:
//   s[i] = c0*s[i-1] + c1*s[i-2] + ... + c_{L-1}*s[i-L]  (mod M)
//
// This implementation assumes M is prime so modular inverses exist.
//
// TIME COMPLEXITY: O(n^2)
// SPACE COMPLEXITY: O(n)

///|
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let mut v = x % m
  if v < 0L {
    v = v + m
  }
  v
}

///|
fn mod_add(a : Int64, b : Int64, m : Int64) -> Int64 {
  mod_norm(a + b, m)
}

///|
fn mod_sub(a : Int64, b : Int64, m : Int64) -> Int64 {
  mod_norm(a - b, m)
}

///|
fn mod_mul(a : Int64, b : Int64, m : Int64) -> Int64 {
  a * b % m
}

///|
fn pow_mod(base : Int64, exp : Int64, m : Int64) -> Int64 {
  let mut result = 1L % m
  let mut b = mod_norm(base, m)
  let mut e = exp
  for ; e > 0L; {
    if (e & 1L) == 1L {
      result = mod_mul(result, b, m)
    }
    b = mod_mul(b, b, m)
    e = e / 2L
  } where {
    invariant: e >= 0L,
    reasoning: (
      #|INVARIANT (binary exponentiation):
      #|result * (b^e) equals base^exp modulo m. Each iteration consumes the
      #|lowest bit of e, updating result when the bit is 1 and squaring b.
      #|TERMINATION:
      #|When e reaches 0, result holds base^exp mod m.
    ),
  }
  result
}

///|
fn inv_mod(x : Int64, m : Int64) -> Int64 {
  pow_mod(x, m - 2L, m)
}

///|
/// Compute minimal recurrence coefficients for the sequence.
/// Returns coefficients [c0, c1, ..., c_{L-1}].
/// M must be prime for inverses to exist.
pub fn berlekamp_massey(seq : ArrayView[Int64], m : Int64) -> Array[Int64] {
  let n = seq.length()
  if n == 0 {
    return []
  }
  let mut c : Array[Int64] = [1L]
  let mut b : Array[Int64] = [1L]
  let mut l = 0
  let mut m_steps = 1
  let mut last_disc = 1L
  for i in 0..<n {
    let mut d = 0L
    let max_j = if l < i { l } else { i }
    for j in 0..<(max_j + 1) {
      d = mod_add(d, mod_mul(c[j], seq[i - j], m), m)
    }
    if d == 0L {
      m_steps = m_steps + 1
      continue
    }
    let coef = mod_mul(d, inv_mod(last_disc, m), m)
    let c_next = c.copy()
    let needed = b.length() + m_steps - c_next.length()
    if needed > 0 {
      for _ in 0..<needed {
        c_next.push(0L)
      }
    }
    for j in 0..<b.length() {
      let idx = j + m_steps
      c_next[idx] = mod_sub(c_next[idx], mod_mul(coef, b[j], m), m)
    }
    if 2 * l <= i {
      l = i + 1 - l
      b = c
      last_disc = d
      m_steps = 1
    } else {
      m_steps = m_steps + 1
    }
    c = c_next
  }
  let result : Array[Int64] = []
  for i in 1..<(l + 1) {
    result.push(mod_norm(-c[i], m))
  }
  result
}
