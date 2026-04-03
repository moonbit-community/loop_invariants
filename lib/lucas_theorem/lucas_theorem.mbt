// ============================================================================
// LUCAS THEOREM - nCk mod prime for large n
// ============================================================================
//
// Lucas theorem splits n and k in base p and computes:
//   C(n, k) = Π C(n_i, k_i) (mod p), where n_i, k_i are digits in base p.
//
// This implementation precomputes factorials modulo p (p must fit in Int).
//
// TIME COMPLEXITY: O(p + log_p n)
// SPACE COMPLEXITY: O(p)

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
      #|result * (b^e) equals base^exp modulo m. Each iteration processes
      #|one bit of e and preserves the invariant.
      #|TERMINATION:
      #|When e = 0, result holds base^exp mod m.
    ),
  }
}

///|
fn nck_small(
  n : Int64,
  k : Int64,
  fact : Array[Int64],
  inv_fact : Array[Int64],
  p : Int64,
) -> Int64 {
  if k < 0L || k > n {
    return 0L
  }
  let ni = n.to_int()
  let ki = k.to_int()
  mod_mul(fact[ni], mod_mul(inv_fact[ki], inv_fact[ni - ki], p), p)
}

///|
/// Compute C(n, k) mod prime p using Lucas theorem.
/// `p` must fit in Int so factorial tables can be built.
pub fn nck_mod_prime_lucas(n : Int64, k : Int64, p : Int64) -> Int64 {
  if k < 0L || k > n {
    return 0L
  }
  let prime = p.to_int()
  if prime <= 1 {
    return 0L
  }
  let fact = Array::make(prime, 1L)
  for i in 1..<prime {
    fact[i] = mod_mul(fact[i - 1], i.to_int64(), p)
  }
  let inv_fact = Array::make(prime, 1L)
  inv_fact[prime - 1] = pow_mod(fact[prime - 1], p - 2L, p)
  let start_exclusive = prime - 1
  for i in start_exclusive>..0 {
    inv_fact[i] = mod_mul(inv_fact[i + 1], (i + 1).to_int64(), p)
  }
  let result = for nn = n, kk = k, result = 1L; kk > 0L; {
    let ni = nn % p
    let ki = kk % p
    if ki > ni {
      break 0L
    }
    continue nn / p,
      kk / p,
      mod_mul(result, nck_small(ni, ki, fact, inv_fact, p), p)
  } nobreak {
    result
  } where {
    invariant: kk >= 0L,
    reasoning: (
      #|INVARIANT (Lucas digits):
      #|result equals the product of C(n_i, k_i) over processed base-p digits.
      #|Each iteration consumes one digit of n and k.
      #|TERMINATION:
      #|When kk = 0, all digits are processed and result is final.
    ),
  }
  result
}
