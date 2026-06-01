// ============================================================================
// DIVISOR-SUM FUNCTION  -  sigma_k(n) = sum of d^k over divisors d of n
// ============================================================================
//
// PROBLEM
//
// For an integer `n >= 1`, compute
//
//   sigma_k(n) = sum_{d | n} d^k
//
// Two important cases:
//
//   k = 0 :  d(n)     = number of divisors
//   k = 1 :  sigma(n) = sum of divisors
//
// `sigma_k` is **multiplicative**: for coprime m, n,
//   sigma_k(m * n) = sigma_k(m) * sigma_k(n).
//
// PRIME-POWER FORMULA
//
//   sigma_0(p^e) = e + 1
//   sigma_k(p^e) = (p^{k(e+1)} - 1) / (p^k - 1)   for k >= 1
//
// SIEVE up to N (linear sieve via multiplicative-function framework)
//
//   For each composite k = p * i where p is k's smallest prime factor:
//     If p divides i (so p^v | k for v >= 2):
//       sigma_k(k) = sigma_k(p^{v+1}) * sigma_k(k / p^{v+1})
//     Else (p coprime to i):
//       sigma_k(k) = sigma_k(p) * sigma_k(i)
//
//   Total: O(N) time.
//
// SINGLE VALUE (factor n by trial division, then multiply prime-power
// pieces): O(sqrt(n)).
//
// THE INVARIANT
//
//   "After processing the i-th iteration of the linear sieve outer loop,
//    sigma_k_table[j] = sigma_k(j) for every 1 <= j < i."

///|
fn ipow(p : Int64, e : Int) -> Int64 {
  let mut r = 1L
  for _ in 0..<e {
    r = r * p
  }
  r
}

///|
/// Number of divisors `d(n) = sigma_0(n)`. Returns `0` for `n <= 0`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@divisor_sigma.divisor_count(12L), 6L)
/// }
/// ```
pub fn divisor_count(n : Int64) -> Int64 {
  if n <= 0L {
    return 0L
  }
  if n == 1L {
    return 1L
  }
  let mut m = n
  let mut total = 1L
  let mut p = 2L
  while p * p <= m {
    if m % p == 0L {
      let mut e = 0
      while m % p == 0L {
        m = m / p
        e = e + 1
      }
      total = total * (e + 1).to_int64()
    }
    p = p + 1L
  }
  if m > 1L {
    total = total * 2L
  }
  total
}

///|
/// Sum of divisors `sigma(n) = sigma_1(n)`. Returns `0` for `n <= 0`.
pub fn divisor_sum(n : Int64) -> Int64 {
  sigma_k(n, 1)
}

///|
/// `sigma_k(n) = sum_{d | n} d^k`. `k >= 0`.
pub fn sigma_k(n : Int64, k : Int) -> Int64 {
  if n <= 0L || k < 0 {
    return 0L
  }
  if n == 1L {
    return 1L
  }
  if k == 0 {
    return divisor_count(n)
  }
  let mut m = n
  let mut total = 1L
  let mut p = 2L
  while p * p <= m {
    if m % p == 0L {
      let mut e = 0
      while m % p == 0L {
        m = m / p
        e = e + 1
      }
      // (p^{k(e+1)} - 1) / (p^k - 1)
      let pk = ipow(p, k)
      let num = ipow(pk, e + 1) - 1L
      let den = pk - 1L
      total = total * (num / den)
    }
    p = p + 1L
  }
  if m > 1L {
    // m is a single prime to the first power.
    let pk = ipow(m, k)
    total = total * (pk + 1L)
  }
  total
}

///|
/// Bulk: `divisor_count(k)` for every `k` in `[0, n]` via linear sieve.
/// `result[0] = 0`, `result[1..n] = d(k)`.
pub fn divisor_count_sieve(n : Int) -> Array[Int64] {
  if n < 0 {
    return []
  }
  let d = Array::make(n + 1, 0L)
  if n < 1 {
    return d
  }
  d[1] = 1L
  let spf = Array::make(n + 1, 0)
  let cnt = Array::make(n + 1, 0) // exponent of spf in i
  let primes : Array[Int] = []
  for i in 2..<=n {
    if spf[i] == 0 {
      spf[i] = i
      cnt[i] = 1
      d[i] = 2L
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
        cnt[k] = cnt[i] + 1
        // d(p^{cnt+1} * q) = (cnt+2) * d(q) where q = i / p^cnt[i].
        // Equivalent: d(k) = d(i) / (cnt[i] + 1) * (cnt[i] + 2).
        d[k] = d[i] / (cnt[i] + 1).to_int64() * (cnt[i] + 2).to_int64()
        break
      } else {
        cnt[k] = 1
        d[k] = d[i] * 2L
      }
    }
  }
  d
}

///|
test "sigma_k small d(n)" {
  // d(1..12) = 1, 2, 2, 3, 2, 4, 2, 4, 3, 4, 2, 6
  let expected : ReadOnlyArray[Int64] = [
    1L, 2L, 2L, 3L, 2L, 4L, 2L, 4L, 3L, 4L, 2L, 6L,
  ]
  for i in 1..<=12 {
    @debug.assert_eq(divisor_count(i.to_int64()), expected[i - 1])
  }
}

///|
test "sigma_k small sigma(n)" {
  // sigma(1..12) = 1, 3, 4, 7, 6, 12, 8, 15, 13, 18, 12, 28
  let expected : ReadOnlyArray[Int64] = [
    1L, 3L, 4L, 7L, 6L, 12L, 8L, 15L, 13L, 18L, 12L, 28L,
  ]
  for i in 1..<=12 {
    @debug.assert_eq(divisor_sum(i.to_int64()), expected[i - 1])
  }
}

///|
test "sigma_k k=2" {
  // sigma_2(6) = 1 + 4 + 9 + 36 = 50.
  @debug.assert_eq(sigma_k(6L, 2), 50L)
  // sigma_2(10) = 1 + 4 + 25 + 100 = 130.
  @debug.assert_eq(sigma_k(10L, 2), 130L)
}

///|
test "sigma_k prime" {
  for p in [2L, 3L, 5L, 7L, 11L, 13L, 97L] {
    @debug.assert_eq(divisor_count(p), 2L)
    @debug.assert_eq(divisor_sum(p), p + 1L)
    @debug.assert_eq(sigma_k(p, 2), p * p + 1L)
  }
}

///|
test "sigma_k prime power" {
  // p^e divisors are 1, p, p^2, ..., p^e -> count = e+1.
  @debug.assert_eq(divisor_count(8L), 4L) // 2^3
  @debug.assert_eq(divisor_count(81L), 5L) // 3^4
  // sigma(8) = 1 + 2 + 4 + 8 = 15.
  @debug.assert_eq(divisor_sum(8L), 15L)
  // sigma(81) = 1 + 3 + 9 + 27 + 81 = 121.
  @debug.assert_eq(divisor_sum(81L), 121L)
}

///|
test "sigma_k edge cases" {
  @debug.assert_eq(divisor_count(0L), 0L)
  @debug.assert_eq(divisor_count(-7L), 0L)
  @debug.assert_eq(divisor_count(1L), 1L)
  @debug.assert_eq(divisor_sum(1L), 1L)
  @debug.assert_eq(sigma_k(5L, -1), 0L)
}

///|
test "sigma_k bulk sieve" {
  let n = 200
  let table = divisor_count_sieve(n)
  for k in 1..<=n {
    @debug.assert_eq(table[k], divisor_count(k.to_int64()))
  }
}

///|
test "sigma_k multiplicativity" {
  // sigma_k(m*n) = sigma_k(m) * sigma_k(n) for coprime m, n.
  let coprimes : ReadOnlyArray[(Int64, Int64)] = [
    (3L, 7L),
    (4L, 9L),
    (5L, 8L),
    (15L, 28L),
    (49L, 25L),
  ]
  for p in coprimes {
    let m = p.0
    let n = p.1
    let prod = m * n
    @debug.assert_eq(divisor_count(prod), divisor_count(m) * divisor_count(n))
    @debug.assert_eq(divisor_sum(prod), divisor_sum(m) * divisor_sum(n))
    @debug.assert_eq(sigma_k(prod, 2), sigma_k(m, 2) * sigma_k(n, 2))
  }
}
