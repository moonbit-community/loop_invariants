// ============================================================================
// POLLARD'S RHO - Integer Factorization
// ============================================================================
//
// Pollard's rho algorithm finds a non-trivial factor of a composite number.
// Based on the birthday paradox and Floyd's cycle detection.
//
// KEY INSIGHT: Generate pseudo-random sequence x_{i+1} = f(x_i) mod n.
// By birthday paradox, after O(√p) steps, we expect x_i ≡ x_j (mod p)
// for some prime factor p of n.
//
// ALGORITHM:
// 1. Use f(x) = x² + c for some constant c
// 2. Detect cycle using Floyd's algorithm (tortoise and hare)
// 3. Factor found when gcd(|x - y|, n) > 1
//
// BRENT'S OPTIMIZATION: More efficient cycle detection variant.
//
// INVARIANTS:
// 1. d = gcd(|x - y|, n) divides n
// 2. If d > 1 and d < n, d is a non-trivial factor
// 3. Expected O(n^(1/4)) iterations for balanced semiprime
//
// TIME COMPLEXITY: O(n^(1/4)) expected
// SPACE COMPLEXITY: O(1)

///|
/// Modular multiplication (handles potential overflow)
fn mul_mod_rho(a : Int64, b : Int64, m : Int64) -> Int64 {
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
/// GCD using Euclidean algorithm
fn gcd(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }

  while y > 0L {
    let t = y
    y = x % y
    x = t
  }

  x
}

///|
/// Absolute value
fn abs64(x : Int64) -> Int64 {
  if x < 0L { -x } else { x }
}

///|
/// Pollard's rho with Floyd's cycle detection
fn pollard_rho_floyd(n : Int64) -> Int64 {
  if n == 1L {
    return 1L
  }
  if n % 2L == 0L {
    return 2L
  }

  // f(x) = x² + c mod n
  let c = 1L

  fn f(x : Int64, n : Int64, c : Int64) -> Int64 {
    (mul_mod_rho(x, x, n) + c) % n
  }

  let mut x = 2L
  let mut y = 2L
  let mut d = 1L

  while d == 1L {
    x = f(x, n, c)
    y = f(f(y, n, c), n, c)
    d = gcd(abs64(x - y), n)
  }

  d
}

///|
/// Pollard's rho with Brent's cycle detection (more efficient)
fn pollard_rho_brent(n : Int64) -> Int64 {
  if n == 1L {
    return 1L
  }
  if n % 2L == 0L {
    return 2L
  }
  if n % 3L == 0L {
    return 3L
  }

  let c = 1L

  fn f(x : Int64, n : Int64, c : Int64) -> Int64 {
    (mul_mod_rho(x, x, n) + c) % n
  }

  let mut y = 2L
  let c_val = c
  let m = 10L
  let mut g = 1L
  let mut r = 1L
  let mut q = 1L

  let mut ys = 0L
  let mut x = 0L

  while g == 1L {
    x = y
    for i = 0L; i < r; i = i + 1L {
      y = f(y, n, c_val)
    }

    let mut k = 0L
    while k < r && g == 1L {
      ys = y
      let bound = if m < r - k { m } else { r - k }
      for i = 0L; i < bound; i = i + 1L {
        y = f(y, n, c_val)
        q = mul_mod_rho(q, abs64(x - y), n)
      }
      g = gcd(q, n)
      k = k + m
    }
    r = r * 2L
  }

  if g == n {
    // Backtrack
    g = 1L
    while g == 1L {
      ys = f(ys, n, c_val)
      g = gcd(abs64(x - ys), n)
    }
  }

  g
}

///|
/// Miller-Rabin primality test (simplified)
fn is_prime_for_factorization(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  if n == 2L || n == 3L {
    return true
  }
  if n % 2L == 0L {
    return false
  }

  let witnesses : Array[Int64] = [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L]

  // Write n-1 as 2^s * d
  let mut d = n - 1L
  let mut s = 0

  while d % 2L == 0L {
    d = d / 2L
    s = s + 1
  }

  for w = 0; w < witnesses.length(); w = w + 1 {
    let a = witnesses[w]
    if a >= n {
      continue
    }

    let mut x = 1L
    let mut base = a % n
    let mut e = d

    while e > 0L {
      if e % 2L == 1L {
        x = mul_mod_rho(x, base, n)
      }
      base = mul_mod_rho(base, base, n)
      e = e / 2L
    }

    if x == 1L || x == n - 1L {
      continue
    }

    let mut composite = true
    for r = 0; r < s - 1; r = r + 1 {
      x = mul_mod_rho(x, x, n)
      if x == n - 1L {
        composite = false
        break
      }
    }

    if composite {
      return false
    }
  }

  true
}

///|
/// Factorize n into prime factors
fn factorize(n : Int64) -> Array[Int64] {
  let result : Array[Int64] = []

  if n <= 1L {
    return result
  }

  fn factor_recursive(n : Int64, result : Array[Int64]) -> Unit {
    if n == 1L {
      return
    }
    if is_prime_for_factorization(n) {
      result.push(n)
      return
    }

    let mut d = pollard_rho_brent(n)
    if d == n {
      d = pollard_rho_floyd(n)
    }

    factor_recursive(d, result)
    factor_recursive(n / d, result)
  }

  // Extract powers of 2
  let mut num = n
  while num % 2L == 0L {
    result.push(2L)
    num = num / 2L
  }

  factor_recursive(num, result)

  // Sort factors
  for i = 0; i < result.length(); i = i + 1 {
    for j = i + 1; j < result.length(); j = j + 1 {
      if result[j] < result[i] {
        let tmp = result[i]
        result[i] = result[j]
        result[j] = tmp
      }
    }
  }

  result
}

///|
/// Get unique prime factors
fn unique_factors(n : Int64) -> Array[Int64] {
  let all = factorize(n)
  let result : Array[Int64] = []

  for i = 0; i < all.length(); i = i + 1 {
    if result.length() == 0 || result[result.length() - 1] != all[i] {
      result.push(all[i])
    }
  }

  result
}

///|
/// Count number of divisors
fn count_divisors(n : Int64) -> Int64 {
  let factors = factorize(n)
  if factors.length() == 0 {
    return 1L
  }

  let mut count = 1L
  let mut current = factors[0]
  let mut power = 0L

  for i = 0; i < factors.length(); i = i + 1 {
    if factors[i] == current {
      power = power + 1L
    } else {
      count = count * (power + 1L)
      current = factors[i]
      power = 1L
    }
  }

  count * (power + 1L)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "pollard_rho small" {
  let f = pollard_rho_floyd(15L)
  inspect(f == 3L || f == 5L, content="true")
}

///|
test "pollard_rho even" {
  inspect(pollard_rho_floyd(100L), content="2")
}

///|
test "pollard_rho prime" {
  // For prime, should return the prime itself
  let result = pollard_rho_floyd(17L)
  inspect(result, content="17")
}

///|
test "factorize small" {
  let factors = factorize(12L)
  inspect(factors.length(), content="3") // 2, 2, 3
  inspect(factors[0], content="2")
  inspect(factors[1], content="2")
  inspect(factors[2], content="3")
}

///|
test "factorize prime" {
  let factors = factorize(13L)
  inspect(factors.length(), content="1")
  inspect(factors[0], content="13")
}

///|
test "factorize power of 2" {
  let factors = factorize(16L)
  inspect(factors.length(), content="4") // 2^4
  for i = 0; i < 4; i = i + 1 {
    inspect(factors[i], content="2")
  }
}

///|
test "factorize semiprime" {
  let factors = factorize(91L) // 7 * 13
  inspect(factors.length(), content="2")
  inspect(factors[0], content="7")
  inspect(factors[1], content="13")
}

///|
test "unique_factors" {
  let factors = unique_factors(12L)
  inspect(factors.length(), content="2") // 2, 3
  inspect(factors[0], content="2")
  inspect(factors[1], content="3")
}

///|
test "count_divisors" {
  inspect(count_divisors(1L), content="1")
  inspect(count_divisors(2L), content="2")
  inspect(count_divisors(6L), content="4") // 1, 2, 3, 6
  inspect(count_divisors(12L), content="6") // 1, 2, 3, 4, 6, 12
}

///|
test "gcd" {
  inspect(gcd(12L, 8L), content="4")
  inspect(gcd(17L, 13L), content="1")
  inspect(gcd(100L, 25L), content="25")
}

///|
test "factorize one" {
  let factors = factorize(1L)
  inspect(factors.length(), content="0")
}

///|
test "pollard_brent" {
  let f = pollard_rho_brent(35L)
  // Should find a non-trivial factor
  inspect(35L % f == 0L && f > 1L, content="true")
}
