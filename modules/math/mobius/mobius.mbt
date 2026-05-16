// ============================================================================
// MOBIUS FUNCTION  -  mu(n)
// ============================================================================
//
// DEFINITION
//
//   mu(1) = 1
//   mu(n) = 0                          if n is not squarefree
//   mu(n) = (-1)^k                     if n = p_1 * p_2 * ... * p_k
//                                       (distinct primes, squarefree)
//
// USE
//
// **Mobius inversion**: for any arithmetic functions f, g related by
//   g(n) = sum_{d | n} f(d)   <=>   f(n) = sum_{d | n} mu(d) * g(n/d)
//
// The Mobius function is the multiplicative inverse of the constant-1
// function under Dirichlet convolution.
//
// **Standard identity**:
//   sum_{d | n} mu(d) = [n == 1]    (the Iverson bracket)
//
// ALGORITHMS
//
// SINGLE VALUE: factor n by trial division. If any prime divides n at
// least twice, return 0; otherwise return (-1)^(number of distinct primes).
// Runs in O(sqrt(n)).
//
// SIEVE up to N (linear sieve): for each composite k = p * q where p is
// k's smallest prime factor:
//   - if p divides q, then p^2 | k, so mu(k) = 0
//   - else            mu(k) = -mu(q)
// Total: O(N) time, O(N) space.
//
// THE INVARIANT (single value)
//
//   "Outside the trial-division loop, sign tracks the parity of the
//    distinct prime factors of n discovered so far, and the running
//    m has had those factors removed (at first occurrence; if any
//    factor recurs we abort with 0)."

///|
/// Mobius function `mu(n)` for a single positive integer.
/// Returns `0` for `n <= 0`. Runs in `O(sqrt(n))` by trial division.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@mobius.mu(30L), -1) // 30 = 2*3*5, 3 distinct primes
/// }
/// ```
pub fn mu(n : Int64) -> Int {
  if n <= 0L {
    return 0
  }
  if n == 1L {
    return 1
  }
  let mut m = n
  let mut sign = 1
  // Strip factor 2 (at most once for squarefree).
  if m % 2L == 0L {
    m = m / 2L
    sign = -sign
    if m % 2L == 0L {
      return 0
    }
  }
  let mut p = 3L
  while p * p <= m {
    if m % p == 0L {
      m = m / p
      sign = -sign
      if m % p == 0L {
        return 0
      }
    }
    p = p + 2L
  }
  // Remaining factor (if any) is a prime > sqrt(original).
  if m > 1L {
    sign = -sign
  }
  sign
}

///|
/// Compute `mu(k)` for every `k` in `[0, n]` via a linear sieve.
///
/// Returns an array of length `n + 1` (or empty for `n < 0`). Element 0
/// is `0` by convention; elements 1..n are the Mobius values.
///
/// Time `O(n)`, space `O(n)`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let m = @mobius.sieve(10)
///   // mu(1..10) = 1, -1, -1, 0, -1, 1, -1, 0, 0, 1
///   @debug.assert_eq(m[6], 1)
/// }
/// ```
pub fn sieve(n : Int) -> Array[Int] {
  if n < 0 {
    return []
  }
  let res = Array::make(n + 1, 0)
  if n < 1 {
    return res
  }
  res[1] = 1
  let spf = Array::make(n + 1, 0)
  let primes : Array[Int] = []
  for i in 2..<=n {
    if spf[i] == 0 {
      spf[i] = i
      primes.push(i)
      res[i] = -1
    }
    for j in 0..<primes.length() {
      let p = primes[j]
      if p > spf[i] || p.to_int64() * i.to_int64() > n.to_int64() {
        break
      }
      let k = p * i
      spf[k] = p
      if i % p == 0 {
        // p divides i, so p^2 | k.
        res[k] = 0
      } else {
        res[k] = -res[i]
      }
    }
  }
  res
}

///|
test "mu small values" {
  // mu(1..12) = 1, -1, -1, 0, -1, 1, -1, 0, 0, 1, -1, 0
  let expected = [1, -1, -1, 0, -1, 1, -1, 0, 0, 1, -1, 0]
  for i in 1..<=12 {
    @debug.assert_eq(mu(i.to_int64()), expected[i - 1])
  }
}

///|
test "mu zero and negative" {
  @debug.assert_eq(mu(0L), 0)
  @debug.assert_eq(mu(-3L), 0)
}

///|
test "mu prime" {
  for p in [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 97L] {
    @debug.assert_eq(mu(p), -1)
  }
}

///|
test "mu prime square" {
  // p^2 is not squarefree -> 0.
  for p in [2L, 3L, 5L, 7L, 11L, 13L, 17L] {
    @debug.assert_eq(mu(p * p), 0)
  }
}

///|
test "mu product of distinct primes" {
  // mu(p1*p2*...*pk) = (-1)^k.
  @debug.assert_eq(mu(6L), 1) // 2*3
  @debug.assert_eq(mu(15L), 1) // 3*5
  @debug.assert_eq(mu(30L), -1) // 2*3*5
  @debug.assert_eq(mu(105L), -1) // 3*5*7
  @debug.assert_eq(mu(210L), 1) // 2*3*5*7
  @debug.assert_eq(mu(2310L), -1) // 2*3*5*7*11
}

///|
test "mu agrees with definition by brute force" {
  // Brute force: factor n, return 0 if any prime appears > 1, else (-1)^omega.
  fn brute(n : Int64) -> Int {
    if n <= 0L {
      return 0
    }
    let mut m = n
    let mut omega = 0
    let mut p = 2L
    while p * p <= m {
      if m % p == 0L {
        omega = omega + 1
        m = m / p
        if m % p == 0L {
          return 0
        }
      }
      p = p + 1L
    }
    if m > 1L {
      omega = omega + 1
    }
    if omega % 2 == 0 {
      1
    } else {
      -1
    }
  }

  for n in 1L..<300L {
    @debug.assert_eq(mu(n), brute(n))
  }
}

///|
test "mobius identity sum over divisors" {
  // sum_{d | n} mu(d) = [n == 1].
  fn sum_mu_div(n : Int64) -> Int {
    let mut total = 0
    let mut d = 1L
    while d * d <= n {
      if n % d == 0L {
        total = total + mu(d)
        if d * d != n {
          total = total + mu(n / d)
        }
      }
      d = d + 1L
    }
    total
  }

  for n in 1L..<60L {
    let s = sum_mu_div(n)
    if n == 1L {
      @debug.assert_eq(s, 1)
    } else {
      @debug.assert_eq(s, 0)
    }
  }
}

///|
test "sieve matches single" {
  let m = sieve(500)
  @debug.assert_eq(m[0], 0)
  for n in 1..<=500 {
    @debug.assert_eq(m[n], mu(n.to_int64()))
  }
}

///|
test "sieve small example" {
  // mu(1..10) = 1, -1, -1, 0, -1, 1, -1, 0, 0, 1
  let m = sieve(10)
  let expected = [0, 1, -1, -1, 0, -1, 1, -1, 0, 0, 1]
  for i in 0..<=10 {
    @debug.assert_eq(m[i], expected[i])
  }
}

///|
test "sieve degenerate inputs" {
  let m0 = sieve(0)
  @debug.assert_eq(m0.length(), 1)
  @debug.assert_eq(m0[0], 0)
  let mneg = sieve(-5)
  @debug.assert_eq(mneg.length(), 0)
}

///|
test "mu inversion of constant-1" {
  // If g(n) = sum_{d | n} 1 = d(n), then f(n) = sum_{d | n} mu(d) * d(n/d) = 1.
  // Verify the Mobius inversion identity for small n.
  fn divisor_count(n : Int64) -> Int64 {
    let mut c = 0L
    let mut d = 1L
    while d * d <= n {
      if n % d == 0L {
        c = c + 1L
        if d * d != n {
          c = c + 1L
        }
      }
      d = d + 1L
    }
    c
  }

  fn invert(n : Int64) -> Int64 {
    let mut total = 0L
    let mut d = 1L
    while d * d <= n {
      if n % d == 0L {
        total = total + mu(d).to_int64() * divisor_count(n / d)
        if d * d != n {
          let other = n / d
          total = total + mu(other).to_int64() * divisor_count(n / other)
        }
      }
      d = d + 1L
    }
    total
  }

  for n in 1L..<40L {
    @debug.assert_eq(invert(n), 1L)
  }
}
