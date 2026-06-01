// ============================================================================
// LINEAR SIEVE FOR MULTIPLICATIVE FUNCTIONS  -  O(n)
// ============================================================================
//
// PROBLEM
//
// Many number-theoretic functions are **multiplicative**: `f(mn) =
// f(m) * f(n)` whenever `gcd(m, n) = 1`. Given the rules
//
//   f(1)         = 1
//   f(p)         = prime-case value                       (caller-supplied)
//   f(p^k)       = prime-power value                      (caller-supplied)
//
// we can compute `f(k)` for every `k` in `[1, n]` in **linear time**
// using the linear (Euler) sieve, which guarantees each composite is
// hit exactly once -- through its smallest prime factor.
//
// CALLBACKS PROVIDED BY THE USER
//
//   f_prime(p)         -- value at a prime
//   f_prime_power(p, k) -- value at p^k, for k >= 1
//
// We also track, at every i, the **smallest prime factor** `spf[i]`,
// its **exponent** `spe[i]`, and `coprime[i] = i / spf[i]^spe[i]`,
// which is coprime to `spf[i]`. Using these, `f[i] = f(spf^spe) *
// f[coprime[i]]` by multiplicativity.
//
// COMPLEXITY
//
//   O(n) time, O(n) space.

///|
fn ipow(p : Int, e : Int) -> Int {
  let mut r = 1
  for _ in 0..<e {
    r = r * p
  }
  r
}

///|
/// Linear sieve for a generic multiplicative function `f`.
///
/// - `n`               upper bound; computes `f[0..n]`. `n < 1` returns
///                     a single-element array `[1]` (convention).
/// - `f_prime`         `f(p)` for prime `p`.
/// - `f_prime_power`   `f(p^k)` for `k >= 1`.
///
/// Returns `f[k]` for `k` in `[0, n]`. `f[0] = 0` by convention,
/// `f[1] = 1`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Euler totient: f(p) = p-1, f(p^k) = (p-1) * p^(k-1).
///   let phi = @multiplicative_sieve.sieve(10, p => (p - 1).to_int64(), (p, k) => {
///     let mut r = (p - 1).to_int64()
///     for _ in 1..<k {
///       r = r * p.to_int64()
///     }
///     r
///   })
///   @debug.assert_eq(phi[10], 4L)
/// }
/// ```
pub fn sieve(
  n : Int,
  f_prime : (Int) -> Int64,
  f_prime_power : (Int, Int) -> Int64,
) -> Array[Int64] {
  if n < 0 {
    return [0L]
  }
  let res = Array::make(n + 1, 0L)
  if n < 1 {
    return res
  }
  res[1] = 1L
  // i = spf^spe * coprime_i; coprime_i is coprime to spf.
  let spf = Array::make(n + 1, 0)
  let spe = Array::make(n + 1, 0)
  let coprime = Array::make(n + 1, 1) // index into res for the coprime part
  let primes : Array[Int] = []
  for i in 2..<=n {
    if spf[i] == 0 {
      spf[i] = i
      spe[i] = 1
      coprime[i] = 1
      res[i] = f_prime(i)
      primes.push(i)
    }
    for j in 0..<primes.length() {
      let p = primes[j]
      if p > spf[i] || p.to_int64() * i.to_int64() > n.to_int64() {
        break
      }
      let k = p * i
      spf[k] = p
      if i % p == 0 {
        // Same smallest prime; exponent grows.
        spe[k] = spe[i] + 1
        coprime[k] = coprime[i]
        let f_pk = f_prime_power(p, spe[k])
        res[k] = f_pk * res[coprime[k]]
        break
      } else {
        // Coprime to existing smallest prime.
        spe[k] = 1
        coprime[k] = i
        res[k] = f_prime(p) * res[i]
      }
    }
  }
  // Drop spf, spe, coprime as we return only res.
  let _ = spf
  let _ = spe
  let _ = coprime
  let _ = ipow // keep for potential reuse
  res
}

///|
/// Specialised: Euler's totient via the generic framework.
pub fn totient(n : Int) -> Array[Int64] {
  sieve(n, p => (p - 1).to_int64(), (p, k) => {
    let mut r = (p - 1).to_int64()
    for _ in 1..<k {
      r = r * p.to_int64()
    }
    r
  })
}

///|
/// Specialised: Mobius function via the generic framework.
pub fn mobius(n : Int) -> Array[Int64] {
  sieve(n, _p => -1L, (_p, k) => if k == 1 { -1L } else { 0L })
}

///|
/// Specialised: number-of-divisors function `d(n)`.
pub fn divisor_count(n : Int) -> Array[Int64] {
  sieve(n, _p => 2L, (_p, k) => (k + 1).to_int64())
}

///|
test "sieve produces totient values" {
  let phi = totient(12)
  // phi(1..12) = 1, 1, 2, 2, 4, 2, 6, 4, 6, 4, 10, 4
  let expected : ReadOnlyArray[Int64] = [
    0L, 1L, 1L, 2L, 2L, 4L, 2L, 6L, 4L, 6L, 4L, 10L, 4L,
  ]
  for i in 0..<=12 {
    @debug.assert_eq(phi[i], expected[i])
  }
}

///|
test "sieve produces mobius values" {
  let mu = mobius(12)
  // mu(1..12) = 1, -1, -1, 0, -1, 1, -1, 0, 0, 1, -1, 0
  let expected : ReadOnlyArray[Int64] = [
    0L, 1L, -1L, -1L, 0L, -1L, 1L, -1L, 0L, 0L, 1L, -1L, 0L,
  ]
  for i in 0..<=12 {
    @debug.assert_eq(mu[i], expected[i])
  }
}

///|
test "sieve produces divisor counts" {
  let d = divisor_count(12)
  // d(1..12) = 1, 2, 2, 3, 2, 4, 2, 4, 3, 4, 2, 6
  let expected : ReadOnlyArray[Int64] = [
    0L, 1L, 2L, 2L, 3L, 2L, 4L, 2L, 4L, 3L, 4L, 2L, 6L,
  ]
  for i in 0..<=12 {
    @debug.assert_eq(d[i], expected[i])
  }
}

///|
test "sieve handles small n" {
  let one = totient(1)
  @debug.assert_eq(one, [0L, 1L])
  let zero = totient(0)
  @debug.assert_eq(zero, [0L])
  let neg = totient(-3)
  @debug.assert_eq(neg, [0L])
}

///|
test "sieve totient larger n" {
  let phi = totient(500)
  // Sanity: phi(p) = p - 1 for known small primes.
  for p in [499, 491, 487, 479, 467, 463, 461, 457, 449, 443, 439, 433] {
    @debug.assert_eq(phi[p], (p - 1).to_int64())
  }
}

///|
test "sieve mobius larger n" {
  let mu = mobius(100)
  // mu(p) = -1 for prime p.
  for p in [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47] {
    @debug.assert_eq(mu[p], -1L)
  }
  // mu(p^2) = 0.
  for p in [2, 3, 5, 7] {
    @debug.assert_eq(mu[p * p], 0L)
  }
}

///|
test "sieve totient agrees with brute force" {
  fn gcd(a : Int, b : Int) -> Int {
    let mut x = a
    let mut y = b
    while y != 0 {
      let t = x % y
      x = y
      y = t
    }
    x
  }

  fn brute_phi(n : Int) -> Int {
    if n == 1 {
      return 1
    }
    let mut c = 0
    for k in 1..<=n {
      if gcd(k, n) == 1 {
        c = c + 1
      }
    }
    c
  }

  let phi = totient(200)
  for n in 1..<=200 {
    @debug.assert_eq(phi[n], brute_phi(n).to_int64())
  }
}
