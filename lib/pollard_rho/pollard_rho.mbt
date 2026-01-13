// ============================================================================
// POLLARD RHO FACTORIZATION (64-bit)
// ============================================================================
//
// Implements Miller-Rabin primality test and Pollard's Rho to factor Int64
// values. Uses safe modular multiplication to avoid overflow.
//
// Deterministic bases for 64-bit integers are used in Miller-Rabin.

///|
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let mut v = x % m
  if v < 0L {
    v = v + m
  }
  v
}

///|
fn add_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  if a >= m - b {
    a - (m - b)
  } else {
    a + b
  }
}

///|
fn mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  let mut res = 0L
  let mut x = mod_norm(a, m)
  let mut y = mod_norm(b, m)
  while y > 0L {
    if (y & 1L) == 1L {
      res = add_mod(res, x, m)
    }
    x = add_mod(x, x, m)
    y = y >> 1
  }
  res
}

///|
fn pow_mod(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for b = mod_norm(base, m), e = exp, acc = 1L % m {
    if e == 0L {
      break acc
    } else if (e & 1L) == 1L {
      continue b, e - 1L, mul_mod(acc, b, m)
    } else {
      continue mul_mod(b, b, m), e / 2L, acc
    }
  } where {
    invariant: e >= 0L && acc >= 0L && acc < m,
    reasoning: (
      #|INVARIANT (modular exponentiation):
      #|acc * b^e ≡ base^exp (mod m) is preserved at every step.
      #|MAINTENANCE:
      #|When e is odd, multiply acc by b and decrement e; when e is even,
      #|square b and halve e.
      #|TERMINATION:
      #|At e = 0, acc is base^exp mod m.
    ),
  }
}

///|
fn gcd(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }
  while y != 0L {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
fn miller_test(n : Int64, a : Int64, d : Int64, s : Int) -> Bool {
  let mut x = pow_mod(a, d, n)
  if x == 1L || x == n - 1L {
    return true
  }
  for r = 1; r < s; r = r + 1 {
    x = mul_mod(x, x, n)
    if x == n - 1L {
      return true
    }
  } where {
    invariant: r >= 1 && r <= s,
    reasoning: (
      #|INVARIANT (Miller-Rabin squaring):
      #|x equals a^(d * 2^r) mod n after r squarings.
      #|MAINTENANCE:
      #|Square x to advance to the next power of two.
      #|TERMINATION:
      #|If x hits n-1, the base passes; otherwise composite is detected.
    ),
  }
  false
}

///|
/// Deterministic Miller-Rabin for 64-bit integers.
pub fn is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  let bases : Array[Int64] = [
    2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L,
  ]
  for p in bases {
    if n == p {
      return true
    }
    if n % p == 0L {
      return false
    }
  }
  let (d, s) = for d = n - 1L, s = 0 {
    if d % 2L != 0L {
      break (d, s)
    } else {
      continue d / 2L, s + 1
    }
  } where {
    invariant: d >= 1L && s >= 0 && d * (1L << s) == n - 1L,
    reasoning: (
      #|INVARIANT (factor n-1):
      #|d * 2^s = n-1 is preserved while d is even.
      #|MAINTENANCE:
      #|Halve d and increment s.
      #|TERMINATION:
      #|d becomes odd, giving the decomposition needed for Miller-Rabin.
    ),
  }
  for a in bases {
    if a % n == 0L {
      continue
    }
    if not(miller_test(n, a, d, s)) {
      return false
    }
  }
  true
}

///|
fn pollard_rho(n : Int64) -> Int64 {
  if (n & 1L) == 0L {
    return 2L
  }
  let constants : Array[Int64] = [1L, 3L, 5L, 7L, 11L, 13L, 17L]
  for idx = 0; idx < constants.length(); idx = idx + 1 {
    let c = constants[idx]
    let mut x = 2L
    let mut y = 2L
    let mut d = 1L
    while d == 1L {
      x = (mul_mod(x, x, n) + c) % n
      y = (mul_mod(y, y, n) + c) % n
      y = (mul_mod(y, y, n) + c) % n
      let diff = if x > y { x - y } else { y - x }
      d = gcd(diff, n)
    }
    if d != n {
      return d
    }
  } where {
    invariant: idx >= 0 && idx <= constants.length(),
    reasoning: (
      #|INVARIANT (rho attempts):
      #|All constants in constants[0..idx) have been tried without success.
      #|MAINTENANCE:
      #|Run a rho iteration with constant c until a nontrivial factor is found.
      #|TERMINATION:
      #|At idx = len, either a factor is found or n is returned as fallback.
    ),
  }
  n
}

///|
fn factor_rec(n : Int64, factors : Array[Int64]) -> Unit {
  if n == 1L {
    return
  }
  if is_prime(n) {
    factors.push(n)
    return
  }
  let d = pollard_rho(n)
  if d == n {
    factors.push(n)
    return
  }
  factor_rec(d, factors)
  factor_rec(n / d, factors)
}

///|
/// Factorize n into prime factors (sorted, with repetition).
pub fn factorize(n : Int64) -> Array[Int64] {
  let factors : Array[Int64] = []
  if n <= 1L {
    return factors
  }
  factor_rec(n, factors)
  factors.sort()
  factors
}

///|
/// Factorization as (prime, exponent) pairs.
pub fn factorize_with_counts(n : Int64) -> Array[(Int64, Int)] {
  let factors = factorize(n)
  let result : Array[(Int64, Int)] = []
  let mut i = 0
  while i < factors.length() {
    let p = factors[i]
    let mut cnt = 1
    i = i + 1
    while i < factors.length() && factors[i] == p {
      cnt = cnt + 1
      i = i + 1
    }
    result.push((p, cnt))
  }
  result
}
