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
/// Normalize `x` into the range `[0, m)`.
///
/// The built-in `%` operator in MoonBit can return negative values when `x`
/// is negative.  This helper guarantees a non-negative remainder.
///
/// Parameters:
/// - `x` : the value to normalize (may be negative)
/// - `m` : the modulus (must be positive)
///
/// Returns `x mod m` in `[0, m)`.
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// Compute `(a * b) mod m`.
///
/// Both `a` and `b` are assumed to already be in `[0, m)`.  The product is
/// taken modulo `m` before returning so the result stays in range.
///
/// Parameters:
/// - `a` : first factor, in `[0, m)`
/// - `b` : second factor, in `[0, m)`
/// - `m` : the modulus (must be positive)
fn mod_mul(a : Int64, b : Int64, m : Int64) -> Int64 {
  a * b % m
}

///|
/// Compute `base^exp mod m` using binary (square-and-multiply) exponentiation.
///
/// The algorithm maintains the invariant `result * b^e == base^exp (mod m)`
/// at every step, where `e` starts at `exp` and is halved each iteration.
/// When `e` reaches 0 the invariant gives `result == base^exp (mod m)`.
///
/// Fermat's little theorem depends on this function: for a prime `p` and
/// `gcd(a, p) = 1` we have `a^(p-2) mod p == a^{-1} mod p`.
///
/// Parameters:
/// - `base` : the base (any `Int64`; normalized into `[0, m)` internally)
/// - `exp`  : the exponent (must be non-negative)
/// - `m`    : the modulus (must be positive)
///
/// Returns `base^exp mod m`.
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
      #|result * (b^e) equals base^exp modulo m. Each iteration processes
      #|one bit of e and preserves the invariant.
      #|TERMINATION:
      #|When e = 0, result holds base^exp mod m.
    ),
  }
}

///|
/// Compute the small binomial coefficient `C(n, k) mod p` using precomputed
/// factorial and inverse-factorial tables.
///
/// Both `n` and `k` must satisfy `0 <= k <= n < p`, so that the table
/// indices are valid.  If `k < 0` or `k > n` the function returns `0`
/// immediately (consistent with the combinatorial definition).
///
/// Parameters:
/// - `n`        : upper index (must be in `[0, p)`)
/// - `k`        : lower index (must be in `[0, n]`)
/// - `fact`     : precomputed factorial table, `fact[i] = i! mod p`
/// - `inv_fact` : precomputed inverse-factorial table, `inv_fact[i] = (i!)^{-1} mod p`
/// - `p`        : the prime modulus
///
/// Returns `C(n, k) mod p`.
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
/// Compute `C(n, k) mod p` for arbitrarily large `n` and `k` using
/// Lucas' theorem, where `p` is a prime.
///
/// # Overview
///
/// Direct factorial formulas fail for `n >= p` because `n! mod p = 0`.
/// Lucas' theorem avoids this by writing `n` and `k` in base `p` and
/// computing:
///
/// ```
/// C(n, k) mod p = product_i C(n_i, k_i) mod p
/// ```
///
/// where `n_i` and `k_i` are the `i`-th base-`p` digits of `n` and `k`
/// respectively.  If any digit satisfies `k_i > n_i` the product is 0.
///
/// # Algorithm
///
/// 1. Build factorial table `fact[0..p-1]` in O(p).
/// 2. Compute `inv_fact[p-1] = fact[p-1]^(p-2) mod p` via Fermat's
///    little theorem (one call to `pow_mod`).
/// 3. Fill `inv_fact` downward in O(p).
/// 4. Peel one base-`p` digit at a time from `n` and `k`, multiply
///    the corresponding small `C(n_i, k_i)` into the running product,
///    and divide both by `p`.  Stop when `k` reaches 0.
///
/// # Preconditions
///
/// - `p` must be a prime number.  Lucas' theorem is incorrect for
///   composite moduli.
/// - `p` must fit in `Int` (i.e. `p <= 2^31 - 1`) because factorial
///   tables of size `p` are allocated.
/// - `n` and `k` must be non-negative.
///
/// # Edge cases
///
/// - Returns `0` when `k > n` (no way to choose more items than exist).
/// - Returns `0` when `p <= 1` (not a valid prime).
///
/// # Complexity
///
/// - Time : O(p + log_p n)
/// - Space: O(p) for the two factorial tables
///
/// Parameters:
/// - `n` : total items (non-negative `Int64`)
/// - `k` : items to choose (non-negative `Int64`)
/// - `p` : prime modulus (must satisfy `2 <= p <= 2^31 - 1`)
///
/// Returns `C(n, k) mod p`.
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
    proof_invariant: kk >= 0L,
    proof_reasoning: (
      #|INVARIANT (Lucas digits):
      #|result equals the product of C(n_i, k_i) over processed base-p digits.
      #|Each iteration consumes one digit of n and k.
      #|TERMINATION:
      #|When kk = 0, all digits are processed and result is final.
    ),
  }
  result
}
