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
/// Normalize `x` into [0, m).
///
/// Reduces `x % m` and adds `m` if the result is negative, so the
/// return value always satisfies `0 <= result < m`.
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// Modular addition: returns `(a + b) mod m` in [0, m).
fn mod_add(a : Int64, b : Int64, m : Int64) -> Int64 {
  mod_norm(a + b, m)
}

///|
/// Modular subtraction: returns `(a - b) mod m` in [0, m).
fn mod_sub(a : Int64, b : Int64, m : Int64) -> Int64 {
  mod_norm(a - b, m)
}

///|
/// Modular multiplication: returns `(a * b) mod m` in [0, m).
fn mod_mul(a : Int64, b : Int64, m : Int64) -> Int64 {
  a * b % m
}

///|
/// Modular exponentiation: returns `base^exp mod m` using binary exponentiation.
///
/// The loop invariant maintained is: `result * (b^e) ≡ base^exp (mod m)`.
/// When `e` reaches zero the invariant reduces to `result ≡ base^exp (mod m)`.
fn pow_mod(base : Int64, exp : Int64, m : Int64) -> Int64 {
  let result = for result = 1L % m, b = mod_norm(base, m), e = exp; e > 0L; {
    let next_result = if (e & 1L) == 1L {
      mod_mul(result, b, m)
    } else {
      result
    }
    continue next_result, mod_mul(b, b, m), e / 2L
  } nobreak {
    result
  } where {
    proof_invariant: e >= 0L,
    proof_reasoning: (
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
/// Modular multiplicative inverse of `x` modulo a prime `m`.
///
/// Uses Fermat's little theorem: `x^{m-2} ≡ x^{-1} (mod m)` when `m` is prime.
/// The caller must ensure `x ≢ 0 (mod m)` and that `m` is prime.
fn inv_mod(x : Int64, m : Int64) -> Int64 {
  pow_mod(x, m - 2L, m)
}

///|
/// Find the shortest linear recurrence that generates `seq` modulo the prime `m`.
///
/// ## What this returns
///
/// A coefficient array `[c0, c1, ..., c_{L-1}]` of minimal length `L` such
/// that for every valid index `i >= L`:
///
/// ```
/// s[i] = c0*s[i-1] + c1*s[i-2] + ... + c_{L-1}*s[i-L]  (mod m)
/// ```
///
/// If `seq` is empty the return value is `[]`.
///
/// ## Requirements
///
/// - `m` must be a prime number (the algorithm requires modular inverses).
/// - For reliable recovery of a recurrence of true length `L`, supply at
///   least `2*L` terms.
///
/// ## How the algorithm works
///
/// The algorithm scans `seq` left to right and maintains two polynomials:
///
/// - `C` — the current shortest connection polynomial (represents the recurrence
///   found so far, stored with a leading 1 coefficient).
/// - `B` — a copy of `C` from the last time the recurrence length was increased.
///
/// At each position `i` the algorithm computes the **discrepancy**:
///
/// ```
/// d = s[i] - (c1*s[i-1] + ... + c_L*s[i-L])  (mod m)
/// ```
///
/// When `d == 0` the current recurrence already predicts `s[i]` correctly; the
/// algorithm just advances.  When `d != 0` a correction is applied:
///
/// ```
/// C_new(x) = C(x) - (d / last_d) * x^m_steps * B(x)
/// ```
///
/// This cancels the discrepancy at position `i` while preserving correctness
/// for all earlier positions.  If the correction forces `L` to grow (i.e.
/// `2*L <= i`), `B` is updated to the old `C` and `last_d` to `d`.
///
/// ## Complexity
///
/// - Time: O(n^2) where n = seq.length()
/// - Space: O(n)
///
/// ## Example: Fibonacci
///
/// ```mbt check
/// test "berlekamp_massey fibonacci" {
///   let m = 1000000007L
///   let seq : Array[Int64] = [0L, 1L, 1L, 2L, 3L, 5L, 8L]
///   let coeffs = @berlekamp_massey.berlekamp_massey(seq[:], m)
///   // s[i] = 1*s[i-1] + 1*s[i-2]
///   inspect(coeffs, content="[1, 1]")
/// }
/// ```
///
/// ## Example: geometric progression
///
/// ```mbt check
/// test "berlekamp_massey geometric" {
///   let m = 1000000007L
///   let seq : Array[Int64] = [1L, 2L, 4L, 8L, 16L]
///   let coeffs = @berlekamp_massey.berlekamp_massey(seq[:], m)
///   // s[i] = 2*s[i-1]
///   inspect(coeffs, content="[2]")
/// }
/// ```
pub fn berlekamp_massey(seq : ArrayView[Int64], m : Int64) -> Array[Int64] {
  let n = seq.length()
  if n == 0 {
    return []
  }
  let init_c : Array[Int64] = [1L]
  let init_b : Array[Int64] = [1L]
  let (c, l) = for i = 0, c = init_c, b = init_b, l = 0, m_steps = 1, last_disc = 1L; i <
                  n; {
    let max_j = if l < i { l } else { i }
    let d = for j = 0, d = 0L; j < max_j + 1; {
      continue j + 1, mod_add(d, mod_mul(c[j], seq[i - j], m), m)
    } nobreak {
      d
    }
    if d == 0L {
      continue i + 1, c, b, l, m_steps + 1, last_disc
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
      continue i + 1, c_next, c, i + 1 - l, 1, d
    } else {
      continue i + 1, c_next, b, l, m_steps + 1, last_disc
    }
  } nobreak {
    (c, l)
  }
  let result : Array[Int64] = [ for i in 1..<(l + 1) => mod_norm(-c[i], m) ]
  result
}

///|
test "mod_norm handles negative input" {
  inspect(mod_norm(-1L, 7L), content="6")
  inspect(mod_norm(-15L, 7L), content="6")
  inspect(mod_norm(15L, 7L), content="1")
}

///|
test "pow_mod handles edge exponents and signs" {
  inspect(pow_mod(5L, 0L, 7L), content="1")
  inspect(pow_mod(-2L, 4L, 7L), content="2")
  inspect(pow_mod(-2L, 5L, 7L), content="3")
}
