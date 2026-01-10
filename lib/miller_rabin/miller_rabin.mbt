// ============================================================================
// MILLER-RABIN - Probabilistic Primality Test
// ============================================================================
//
// Miller-Rabin is a probabilistic primality test with controllable error rate.
// For random witness, false positive probability ≤ 1/4 per round.
//
// KEY INSIGHT: Based on Fermat's little theorem and the fact that for prime p,
// the only square roots of 1 mod p are 1 and -1.
//
// ALGORITHM: Write n-1 = 2^s * d (d odd)
// For witness a:
// 1. Compute x = a^d mod n
// 2. Square x repeatedly s times
// 3. If x becomes 1 without passing through -1, n is composite
//
// DETERMINISTIC VERSION: For n < 3,317,044,064,679,887,385,961,981,
// using witnesses {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37} is sufficient.
//
// INVARIANTS:
// 1. a^(n-1) ≡ 1 (mod n) for prime n (Fermat's little theorem)
// 2. If n is prime and x² ≡ 1 (mod n), then x ≡ ±1 (mod n)
// 3. Each witness test has ≤ 1/4 false positive rate
//
// TIME COMPLEXITY: O(k log³ n) where k is number of witnesses
// SPACE COMPLEXITY: O(1)

///|
/// Modular exponentiation: a^exp mod m
fn mod_pow(a : Int64, exp : Int64, m : Int64) -> Int64 {
  let mut result = 1L
  let mut base = a % m
  let mut e = exp

  while e > 0L {
    if e % 2L == 1L {
      result = mul_mod(result, base, m)
    }
    base = mul_mod(base, base, m)
    e = e / 2L
  }

  result
}

///|
/// Multiplication with modulo (handles overflow)
fn mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  // For 64-bit, we use a slower but safe method
  let mut result = 0L
  let mut aa = a % m
  let mut bb = b

  while bb > 0L {
    if bb % 2L == 1L {
      result = (result + aa) % m
    }
    aa = (aa * 2L) % m
    bb = bb / 2L
  }

  result
}

///|
/// Single Miller-Rabin witness test
fn miller_rabin_witness(n : Int64, a : Int64) -> Bool {
  if n <= 1L {
    return false
  }
  if n == 2L {
    return true
  }
  if n % 2L == 0L {
    return false
  }

  // Write n-1 as 2^s * d
  let mut d = n - 1L
  let mut s = 0

  while d % 2L == 0L {
    d = d / 2L
    s = s + 1
  }

  // Compute a^d mod n
  let mut x = mod_pow(a % n, d, n)

  if x == 1L || x == n - 1L {
    return true // Probably prime
  }

  // Square x repeatedly
  for r = 0; r < s - 1; r = r + 1 {
    x = mul_mod(x, x, n)
    if x == n - 1L {
      return true // Probably prime
    }
  }

  false // Definitely composite
}

///|
/// Miller-Rabin primality test with multiple witnesses
fn is_prime_miller_rabin(n : Int64, k : Int) -> Bool {
  if n < 2L {
    return false
  }
  if n == 2L || n == 3L {
    return true
  }
  if n % 2L == 0L {
    return false
  }

  // Small primes as witnesses for deterministic test up to certain bounds
  let witnesses : Array[Int64] = [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L]

  let count = if k < witnesses.length() { k } else { witnesses.length() }

  for i = 0; i < count; i = i + 1 {
    if witnesses[i] >= n {
      continue
    }
    if not(miller_rabin_witness(n, witnesses[i])) {
      return false
    }
  }

  true
}

///|
/// Deterministic primality test for 64-bit integers
fn is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  if n == 2L {
    return true
  }
  if n % 2L == 0L {
    return false
  }

  // Check small primes
  let small_primes : Array[Int64] = [3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L]
  for i = 0; i < small_primes.length(); i = i + 1 {
    if n == small_primes[i] {
      return true
    }
    if n % small_primes[i] == 0L {
      return false
    }
  }

  if n < 1000L {
    // Trial division for small numbers
    let mut i = 37L
    while i * i <= n {
      if n % i == 0L {
        return false
      }
      i = i + 2L
    }
    return true
  }

  // Miller-Rabin with sufficient witnesses for 64-bit
  is_prime_miller_rabin(n, 12)
}

///|
/// Find next prime >= n
fn next_prime(n : Int64) -> Int64 {
  if n <= 2L {
    return 2L
  }

  let mut candidate = if n % 2L == 0L { n + 1L } else { n }

  while not(is_prime(candidate)) {
    candidate = candidate + 2L
  }

  candidate
}

///|
/// Find previous prime <= n
fn prev_prime(n : Int64) -> Int64? {
  if n < 2L {
    return None
  }
  if n == 2L {
    return Some(2L)
  }

  let mut candidate = if n % 2L == 0L { n - 1L } else { n }

  while candidate > 1L && not(is_prime(candidate)) {
    candidate = candidate - 2L
  }

  if candidate < 2L { None } else { Some(candidate) }
}

///|
/// Count primes up to n using Miller-Rabin
fn count_primes_naive(n : Int64) -> Int {
  if n < 2L {
    return 0
  }

  let mut count = 1 // Count 2
  let mut i = 3L
  while i <= n {
    if is_prime(i) {
      count = count + 1
    }
    i = i + 2L
  }

  count
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "miller_rabin small primes" {
  inspect(is_prime(2L), content="true")
  inspect(is_prime(3L), content="true")
  inspect(is_prime(5L), content="true")
  inspect(is_prime(7L), content="true")
  inspect(is_prime(11L), content="true")
  inspect(is_prime(13L), content="true")
}

///|
test "miller_rabin small composites" {
  inspect(is_prime(1L), content="false")
  inspect(is_prime(4L), content="false")
  inspect(is_prime(6L), content="false")
  inspect(is_prime(8L), content="false")
  inspect(is_prime(9L), content="false")
  inspect(is_prime(10L), content="false")
}

///|
test "miller_rabin larger primes" {
  inspect(is_prime(101L), content="true")
  inspect(is_prime(1009L), content="true")
  inspect(is_prime(10007L), content="true")
  inspect(is_prime(100003L), content="true")
}

///|
test "miller_rabin larger composites" {
  inspect(is_prime(100L), content="false")
  inspect(is_prime(1001L), content="false") // 7 * 11 * 13
  inspect(is_prime(10001L), content="false") // 73 * 137
}

///|
test "miller_rabin carmichael numbers" {
  // Carmichael numbers fool Fermat test but not Miller-Rabin
  inspect(is_prime(561L), content="false") // 3 * 11 * 17
  inspect(is_prime(1105L), content="false") // 5 * 13 * 17
  inspect(is_prime(1729L), content="false") // 7 * 13 * 19 (Hardy-Ramanujan number)
}

///|
test "next_prime" {
  inspect(next_prime(1L), content="2")
  inspect(next_prime(2L), content="2")
  inspect(next_prime(3L), content="3")
  inspect(next_prime(4L), content="5")
  inspect(next_prime(10L), content="11")
  inspect(next_prime(100L), content="101")
}

///|
test "prev_prime" {
  inspect(prev_prime(1L), content="None")
  inspect(prev_prime(2L), content="Some(2)")
  inspect(prev_prime(10L), content="Some(7)")
  inspect(prev_prime(100L), content="Some(97)")
}

///|
test "count_primes" {
  // There are 25 primes <= 100
  inspect(count_primes_naive(100L), content="25")
  // There are 4 primes <= 10
  inspect(count_primes_naive(10L), content="4")
}

///|
test "mod_pow" {
  inspect(mod_pow(2L, 10L, 1000L), content="24") // 1024 mod 1000
  inspect(mod_pow(3L, 4L, 100L), content="81")
  inspect(mod_pow(2L, 0L, 100L), content="1")
}

///|
test "miller_rabin edge cases" {
  inspect(is_prime(0L), content="false")
  inspect(is_prime(-1L), content="false")
}

///|
test "miller_rabin twin primes" {
  // Twin primes: (3,5), (5,7), (11,13), (17,19), (29,31), (41,43)
  inspect(is_prime(41L), content="true")
  inspect(is_prime(43L), content="true")
  inspect(is_prime(42L), content="false")
}
