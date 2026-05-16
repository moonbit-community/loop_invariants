// ============================================================================
// EULER'S TOTIENT FUNCTION  -  phi(n)
// ============================================================================
//
// DEFINITION
//
// `phi(n)` = number of integers in `[1, n]` that are coprime to `n`.
//
//   phi(1) = 1                (only 1 itself)
//   phi(p) = p - 1            for prime p
//   phi(p^k) = p^k - p^{k-1} = p^{k-1} * (p - 1)
//   phi is **multiplicative**: phi(m * n) = phi(m) * phi(n) if gcd(m, n) = 1.
//
// USE
//
//   - **Euler's theorem**: if gcd(a, n) = 1, then a^phi(n) ≡ 1 (mod n).
//   - **RSA**: the private exponent `d` satisfies `e * d ≡ 1 (mod phi(n))`.
//   - **Counting unit-coprime fractions** with denominator <= n.
//   - **Sum-of-divisors identities** (Mobius inversion).
//
// ALGORITHMS
//
// SINGLE VALUE (factor n by trial division, then multiply phi pieces):
//
//   phi(n) = n * prod_{p | n} (1 - 1/p)
//
// runs in O(sqrt(n)).
//
// SIEVE up to N (linear sieve, also gives smallest prime factor):
//
//   For each composite k = p * q where p is smallest prime factor:
//     - if p divides q:  phi(k) = phi(q) * p
//     - else:            phi(k) = phi(q) * (p - 1)
//
//   Total: O(N) time, O(N) space.
//
// THE INVARIANT
//
// In the trial-division loop for a single value:
//
//   "Initially result = n. After processing prime factor p of n_original,
//    result equals n_original * prod_{p_i seen so far} (1 - 1/p_i)."

///|
/// Euler's totient phi(n) for a single positive integer `n`.
/// Runs in `O(sqrt(n))` by trial division.
///
/// Returns `0` for `n <= 0`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@euler_totient.phi(12L), 4L) // {1, 5, 7, 11}
/// }
/// ```
pub fn phi(n : Int64) -> Int64 {
  if n <= 0L {
    return 0L
  }
  // Strip factor 2 first to skip even candidates in the trial-division loop.
  let (m1, result1) = if n % 2L == 0L {
    let r = n - n / 2L // phi contribution of prime 2: n * (1 - 1/2)
    let stripped = for m = n / 2L {
      if m % 2L == 0L {
        continue m / 2L
      } else {
        break m
      }
    } where {
      proof_invariant: m > 0L,
      proof_reasoning: (
        #|INVARIANT: m = n_orig / 2^k for some k >= 1; m > 0 since n_orig > 0.
        #|TERMINATION: m is strictly halved at each step; exits when m is odd.
      ),
    }
    (stripped, r)
  } else {
    (n, n)
  }
  // Trial-division by odd primes p = 3, 5, 7, ...
  // After each step: result = n_orig * prod_{q prime, q | n_orig, q < p} (1 - 1/q)
  //                  m      = n_orig with all prime powers < p divided out
  let (m_final, result_final) = for p = 3L, m = m1, result = result1 {
    if p * p > m {
      break (m, result)
    } else if m % p == 0L {
      let result_new = result - result / p
      // Strip all powers of p from m.
      let m_new = for mm = m / p {
        if mm % p == 0L {
          continue mm / p
        } else {
          break mm
        }
      } where {
        proof_invariant: mm > 0L,
        proof_reasoning: (
          #|INVARIANT: mm = m_at_entry / p^k for some k >= 1; mm > 0.
          #|TERMINATION: mm strictly decreases each step until p does not divide mm.
        ),
      }
      continue p + 2L, m_new, result_new
    } else {
      continue p + 2L, m, result
    }
  } where {
    proof_invariant: p >= 3L && p % 2L == 1L && m > 0L && result > 0L,
    proof_reasoning: (
      #|INVARIANT (phi trial division):
      #|  result = n_orig * prod_{q prime, q | n_orig, q < p} (1 - 1/q)
      #|  m      = n_orig / prod_{q prime, q | n_orig, q < p} q^v_q(n_orig)
      #|  p is always odd (factor 2 was handled separately before this loop).
      #|MAINTENANCE:
      #|  When p | m, apply (1 - 1/p) to result and strip all p-powers from m;
      #|  advance p by 2. When p ∤ m, advance p by 2 without changing result or m.
      #|TERMINATION:
      #|  When p^2 > m, the remaining m is either 1 or a single prime; the loop
      #|  exits. When p | m, m strictly decreases, so total steps are bounded.
    ),
  }
  // Remaining prime factor larger than sqrt(n_orig), if any.
  if m_final > 1L {
    result_final - result_final / m_final
  } else {
    result_final
  }
}

///|
/// Compute `phi(k)` for every `k` in `[0, n]` via a linear sieve.
///
/// Returns an array of length `n + 1`. Element 0 is `0` by convention;
/// elements 1..n are the totient values. `n` must be `>= 0`.
///
/// Time `O(n)`, space `O(n)`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = @euler_totient.sieve(10)
///   // phi(1..10) = 1, 1, 2, 2, 4, 2, 6, 4, 6, 4
///   @debug.assert_eq(t[10], 4L)
/// }
/// ```
pub fn sieve(n : Int) -> Array[Int64] {
  if n < 0 {
    return []
  }
  let res = Array::make(n + 1, 0L)
  if n < 1 {
    return res
  }
  res[1] = 1L
  // smallest prime factor of i (0 means i is prime / not yet set)
  let spf = Array::make(n + 1, 0)
  let primes : Array[Int] = []
  for i in 2..<=n {
    if spf[i] == 0 {
      spf[i] = i
      primes.push(i)
      res[i] = (i - 1).to_int64()
    }
    for j in 0..<primes.length() {
      let p = primes[j]
      if p > spf[i] || p.to_int64() * i.to_int64() > n.to_int64() {
        break
      }
      let k = p * i
      spf[k] = p
      // Multiplicativity rule:
      //   if p | i: phi(p*i) = phi(i) * p   (p is spf of both i and p*i)
      //   else:     phi(p*i) = phi(i) * (p-1) (p coprime to i; multiplicativity)
      if i % p == 0 {
        res[k] = res[i] * p.to_int64()
      } else {
        res[k] = res[i] * (p - 1).to_int64()
      }
    } where {
      proof_invariant: j >= 0 && j <= primes.length(),
      proof_reasoning: (
        #|INVARIANT (linear sieve inner):
        #|primes[0..j) have been processed for i. For each primes[k] with k < j
        #|where primes[k] * i <= n, spf[primes[k] * i] and res[primes[k] * i]
        #|are correctly set.
        #|MAINTENANCE:
        #|Set spf[p * i] = p and compute res[p * i] via multiplicativity:
        #|  res[p * i] = res[i] * p       if p | i
        #|  res[p * i] = res[i] * (p - 1) otherwise
        #|TERMINATION:
        #|Stop when p > spf[i] (every composite is marked exactly once by its
        #|smallest prime factor) or when p * i > n.
      ),
    }
  } where {
    proof_invariant: i >= 2 && i <= n + 1,
    proof_reasoning: (
      #|INVARIANT (linear sieve outer):
      #|For all integers k < i: spf[k] is correctly set, and res[k] = phi(k).
      #|primes contains exactly the primes in [2, i).
      #|MAINTENANCE:
      #|If spf[i] == 0, i is prime: set spf[i] = i, push i to primes, res[i] = i-1.
      #|Then mark all composites i * primes[k] within range.
      #|TERMINATION:
      #|At i = n + 1 all values through n are fully computed.
    ),
  }
  res
}

///|
test "phi small values" {
  // phi(1..12)
  @debug.assert_eq(phi(1L), 1L)
  @debug.assert_eq(phi(2L), 1L)
  @debug.assert_eq(phi(3L), 2L)
  @debug.assert_eq(phi(4L), 2L)
  @debug.assert_eq(phi(5L), 4L)
  @debug.assert_eq(phi(6L), 2L)
  @debug.assert_eq(phi(7L), 6L)
  @debug.assert_eq(phi(8L), 4L)
  @debug.assert_eq(phi(9L), 6L)
  @debug.assert_eq(phi(10L), 4L)
  @debug.assert_eq(phi(11L), 10L)
  @debug.assert_eq(phi(12L), 4L)
}

///|
test "phi zero and negative" {
  @debug.assert_eq(phi(0L), 0L)
  @debug.assert_eq(phi(-3L), 0L)
}

///|
test "phi prime" {
  // phi(p) = p - 1.
  for p in [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 97L, 101L] {
    @debug.assert_eq(phi(p), p - 1L)
  }
}

///|
test "phi prime power" {
  // phi(p^k) = p^k - p^(k-1).
  @debug.assert_eq(phi(8L), 4L) // 2^3 -> 8 - 4 = 4
  @debug.assert_eq(phi(16L), 8L) // 2^4 -> 16 - 8 = 8
  @debug.assert_eq(phi(27L), 18L) // 3^3 -> 27 - 9 = 18
  @debug.assert_eq(phi(125L), 100L) // 5^3 -> 125 - 25 = 100
}

///|
test "phi multiplicativity" {
  // phi(m*n) = phi(m)*phi(n) when gcd(m,n) = 1.
  @debug.assert_eq(phi(15L), phi(3L) * phi(5L)) // 8 = 2*4
  @debug.assert_eq(phi(77L), phi(7L) * phi(11L)) // 60 = 6*10
  @debug.assert_eq(phi(60L), phi(4L) * phi(15L)) // 16 = 2*8
}

///|
test "phi agrees with brute force" {
  fn brute(n : Int64) -> Int64 {
    if n <= 0L {
      return 0L
    }
    if n == 1L {
      return 1L
    }
    fn gcd(a : Int64, b : Int64) -> Int64 {
      let mut x = a
      let mut y = b
      while y != 0L {
        let t = x % y
        x = y
        y = t
      }
      x
    }

    let mut count = 0L
    for k in 1L..<=n {
      if gcd(k, n) == 1L {
        count = count + 1L
      }
    }
    count
  }

  for n in 1L..<200L {
    @debug.assert_eq(phi(n), brute(n))
  }
}

///|
test "sieve matches single" {
  let t = sieve(500)
  // index 0 is 0 by convention.
  @debug.assert_eq(t[0], 0L)
  for n in 1..<=500 {
    @debug.assert_eq(t[n], phi(n.to_int64()))
  }
}

///|
test "sieve small example" {
  // phi(1..10) = 1, 1, 2, 2, 4, 2, 6, 4, 6, 4
  let t = sieve(10)
  let expected = [0L, 1L, 1L, 2L, 2L, 4L, 2L, 6L, 4L, 6L, 4L]
  for i in 0..<=10 {
    @debug.assert_eq(t[i], expected[i])
  }
}

///|
test "sieve degenerate inputs" {
  let t0 = sieve(0)
  @debug.assert_eq(t0.length(), 1)
  @debug.assert_eq(t0[0], 0L)
  let tneg = sieve(-5)
  @debug.assert_eq(tneg.length(), 0)
}

///|
test "phi big value" {
  // 10^9 + 7 is prime, so phi(p) = p - 1.
  @debug.assert_eq(phi(1000000007L), 1000000006L)
  // 10^9 + 7 squared: phi(p^2) = p*(p-1).
  let p = 100003L
  @debug.assert_eq(phi(p * p), p * (p - 1L))
}
