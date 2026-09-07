// ============================================================================
// BINOMIAL COEFFICIENTS MOD PRIME  -  O(n) precompute, O(1) per query
// ============================================================================
//
// PROBLEM
//
// Compute `C(n, k) mod p` (binomial coefficient) for many queries with
// `0 <= k <= n <= N` and a fixed prime `p` with `p > N`.
//
// STANDARD TRICK
//
// Precompute
//
//   fact[i]    = i! mod p          for i in [0, N]
//   inv_fact[i] = (i!)^{-1} mod p
//
// Then `C(n, k) = fact[n] * inv_fact[k] * inv_fact[n-k] mod p`.
//
// PRECOMPUTING inv_fact
//
//   inv_fact[N] = mod_pow(fact[N], p - 2, p)               -- Fermat
//   inv_fact[i] = inv_fact[i+1] * (i+1) mod p              -- chain
//
// One `mod_pow` plus `O(N)` multiplications.
//
// COMPLEXITY
//
//   precompute(N, p) : O(N + log p)
//   choose(n, k)     : O(1)
//
// LUCAS' THEOREM
//
// When `n` may exceed the precomputed range (or when `p` is small), use
// **Lucas' theorem**:
//
//   C(n, k) mod p = prod over digit positions C(n_i, k_i) mod p,
//
// where `n_i, k_i` are the base-`p` digits.

///|
fn mod_pow(base : Int64, exp : Int64, p : Int64) -> Int64 {
  if p == 1L {
    return 0L
  }
  let mut b = base % p
  if b < 0L {
    b = b + p
  }
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
/// Precomputed factorial / inverse-factorial tables for binomial
/// coefficient queries mod a prime `p`.
pub struct BinomTable {
  fact : Array[Int64]
  inv_fact : Array[Int64]
  modulus : Int64
}

///|
/// Build factorial tables up to `n` mod prime `p`. Requires `p` prime,
/// `n >= 0`, and `n < p`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let bt = @binomial_mod.build(100, 1000000007L)
///   @debug.assert_eq(bt.choose(10, 3), 120L)
/// }
/// ```
pub fn build(n : Int, p : Int64) -> BinomTable {
  let m = if n < 0 { 0 } else { n }
  let fact = Array::make(m + 1, 1L)
  for i in 1..<=m {
    fact[i] = fact[i - 1] * i.to_int64() % p
  }
  let inv_fact = Array::make(m + 1, 1L)
  if m >= 0 {
    inv_fact[m] = mod_pow(fact[m], p - 2L, p)
  }
  let mut i = m - 1
  while i >= 0 {
    inv_fact[i] = inv_fact[i + 1] * (i + 1).to_int64() % p
    i = i - 1
  }
  { fact, inv_fact, modulus: p, }
}

///|
/// `C(n, k) mod p` using the precomputed tables. Returns `0` for
/// `k < 0` or `k > n`. Returns `0` if `n` exceeds the table.
pub fn BinomTable::choose(self : BinomTable, n : Int, k : Int) -> Int64 {
  if k < 0 || k > n || n < 0 {
    return 0L
  }
  if n >= self.fact.length() {
    return 0L
  }
  self.fact[n] *
  self.inv_fact[k] %
  self.modulus *
  self.inv_fact[n - k] %
  self.modulus
}

///|
/// `n! mod p`.
pub fn BinomTable::factorial(self : BinomTable, n : Int) -> Int64 {
  if n < 0 || n >= self.fact.length() {
    return 0L
  }
  self.fact[n]
}

///|
/// `C(n, k) mod p` via Lucas' theorem, for arbitrary `n, k` (no
/// precomputation needed). `p` must be prime.
///
/// Iterates the base-`p` digits of `n` and `k`, multiplying together
/// `C(n_i, k_i) mod p` -- each of which is `<= C(p-1, p-1) = 1` ...
/// well, it's the small binomial, computed naively in O(p).
pub fn lucas(n : Int64, k : Int64, p : Int64) -> Int64 {
  if k < 0L || k > n || n < 0L {
    return 0L
  }
  let mut result = 1L
  let mut nn = n
  let mut kk = k
  while kk > 0L {
    let ni = (nn % p).to_int()
    let ki = (kk % p).to_int()
    if ki > ni {
      return 0L
    }
    result = result * small_choose(ni, ki, p) % p
    nn = nn / p
    kk = kk / p
  }
  result
}

///|
fn small_choose(n : Int, k : Int, p : Int64) -> Int64 {
  let mut kk = k
  if kk > n - kk {
    kk = n - kk
  }
  let mut num = 1L
  let mut den = 1L
  for i in 0..<kk {
    num = num * (n - i).to_int64() % p
    den = den * (i + 1).to_int64() % p
  }
  num * mod_pow(den, p - 2L, p) % p
}

///|
test "binom small" {
  let p = 1000000007L
  let bt = build(20, p)
  @debug.assert_eq(bt.choose(0, 0), 1L)
  @debug.assert_eq(bt.choose(1, 0), 1L)
  @debug.assert_eq(bt.choose(1, 1), 1L)
  @debug.assert_eq(bt.choose(5, 2), 10L)
  @debug.assert_eq(bt.choose(10, 3), 120L)
  @debug.assert_eq(bt.choose(20, 10), 184756L)
}

///|
test "binom boundary" {
  let bt = build(10, 1000000007L)
  @debug.assert_eq(bt.choose(5, -1), 0L)
  @debug.assert_eq(bt.choose(5, 6), 0L)
  @debug.assert_eq(bt.choose(-1, 0), 0L)
  @debug.assert_eq(bt.choose(100, 50), 0L) // beyond table
}

///|
test "binom factorial" {
  let bt = build(15, 1000000007L)
  // 10! = 3628800
  @debug.assert_eq(bt.factorial(10), 3628800L)
}

///|
test "binom pascal triangle" {
  let p = 1000000007L
  let bt = build(20, p)
  for n in 1..<=20 {
    for k in 1..<n {
      let sum = (bt.choose(n - 1, k - 1) + bt.choose(n - 1, k)) % p
      @debug.assert_eq(bt.choose(n, k), sum)
    }
  }
}

///|
test "lucas matches direct when n < p" {
  // Bigger p, n < p: Lucas should match the precomputed table directly.
  let p = 1000000007L
  let bt = build(30, p)
  for n in 0..<=30 {
    for k in 0..<=n {
      @debug.assert_eq(lucas(n.to_int64(), k.to_int64(), p), bt.choose(n, k))
    }
  }
}

///|
test "lucas large n" {
  // n exceeds reasonable precompute; verify a known identity:
  //   C(2p, p) ≡ 2 (mod p)  for prime p (a classical congruence).
  let p = 1000003L
  let val = lucas(2L * p, p, p)
  @debug.assert_eq(val, 2L)
}

///|
test "lucas k > n is zero" {
  @debug.assert_eq(lucas(5L, 10L, 7L), 0L)
  @debug.assert_eq(lucas(-1L, 0L, 7L), 0L)
}
