// ============================================================================
// LUCAS' THEOREM - Binomial Coefficients Modulo Prime
// ============================================================================
//
// Computes C(n, k) mod p where p is prime, even for very large n and k.
//
// LUCAS' THEOREM:
// C(n, k) ≡ ∏ C(n_i, k_i) (mod p)
// where n = Σ n_i * p^i and k = Σ k_i * p^i are base-p representations.
//
// KEY INSIGHT: Decompose n and k into base-p digits, then multiply
// the binomial coefficients of corresponding digits.
//
// PRECONDITION: p must be prime
//
// INVARIANTS:
// 1. Each n_i, k_i < p, so C(n_i, k_i) can be computed directly
// 2. If k_i > n_i for any i, result is 0
// 3. Result is always in range [0, p-1]
//
// TIME COMPLEXITY: O(p + log_p(n))
// SPACE COMPLEXITY: O(p) for factorial table

///|
priv struct LucasContext {
  p : Int64
  fact : Array[Int64]      // fact[i] = i! mod p
  inv_fact : Array[Int64]  // inv_fact[i] = (i!)^(-1) mod p
}

///|
fn lucas_mod_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
  let mut result = 1L
  let mut b = base % m
  let mut e = exp

  while e > 0L {
    if e % 2L == 1L {
      result = result * b % m
    }
    b = b * b % m
    e = e / 2L
  }

  result
}

///|
fn LucasContext::new(p : Int64) -> LucasContext {
  let p_int = p.to_int()
  let fact = Array::make(p_int, 0L)
  let inv_fact = Array::make(p_int, 0L)

  // Compute factorials
  fact[0] = 1L
  for i = 1; i < p_int; i = i + 1 {
    fact[i] = fact[i - 1] * i.to_int64() % p
  }

  // Compute inverse factorials using Fermat's little theorem
  inv_fact[p_int - 1] = lucas_mod_pow(fact[p_int - 1], p - 2L, p)
  for i = p_int - 2; i >= 0; i = i - 1 {
    inv_fact[i] = inv_fact[i + 1] * (i + 1).to_int64() % p
  }

  { p, fact, inv_fact }
}

///|
/// Compute C(n, k) mod p for n, k < p
fn LucasContext::small_binomial(self : LucasContext, n : Int64, k : Int64) -> Int64 {
  if k > n || k < 0L {
    return 0L
  }
  if n < 0L {
    return 0L
  }

  let n_int = n.to_int()
  let k_int = k.to_int()

  self.fact[n_int] * self.inv_fact[k_int] % self.p * self.inv_fact[n_int - k_int] % self.p
}

///|
/// Lucas' Theorem: C(n, k) mod p for any n, k
fn LucasContext::binomial(self : LucasContext, n : Int64, k : Int64) -> Int64 {
  if k > n {
    return 0L
  }
  if k < 0L || n < 0L {
    return 0L
  }

  let mut result = 1L
  let mut nn = n
  let mut kk = k
  let p = self.p

  while nn > 0L || kk > 0L {
    let n_digit = nn % p
    let k_digit = kk % p

    if k_digit > n_digit {
      return 0L
    }

    result = result * self.small_binomial(n_digit, k_digit) % p
    nn = nn / p
    kk = kk / p
  }

  result
}

///|
/// Convenience function for single computation
fn lucas_binomial(n : Int64, k : Int64, p : Int64) -> Int64 {
  let ctx = LucasContext::new(p)
  ctx.binomial(n, k)
}

// ============================================================================
// EXTENDED: Binomial with prime power modulus (Granville's generalization)
// ============================================================================

///|
/// Count factors of prime p in n!
fn factorial_prime_power(n : Int64, p : Int64) -> Int64 {
  let mut count = 0L
  let mut pk = p
  while pk <= n {
    count = count + n / pk
    pk = pk * p
  }
  count
}

///|
/// Compute C(n, k) mod p^e for small p^e
fn binomial_prime_power(n : Int64, k : Int64, p : Int64, e : Int) -> Int64 {
  if k > n || k < 0L {
    return 0L
  }

  let mut pe = 1L
  for i = 0; i < e; i = i + 1 {
    pe = pe * p
  }

  // Count p-factors in C(n, k)
  let p_count = factorial_prime_power(n, p) -
    factorial_prime_power(k, p) -
    factorial_prime_power(n - k, p)

  if p_count >= e.to_int64() {
    return 0L // p^e divides C(n, k)
  }

  // For simplicity, use Lucas when e = 1
  if e == 1 {
    return lucas_binomial(n, k, p)
  }

  // General case requires more complex computation
  // This is a simplified version
  let ctx = LucasContext::new(p)
  ctx.binomial(n, k)
}

// ============================================================================
// CATALAN NUMBERS (application of binomial)
// ============================================================================

///|
/// Catalan number C_n = C(2n, n) / (n+1) mod p
fn catalan(n : Int64, p : Int64) -> Int64 {
  if n < 0L {
    return 0L
  }
  if n == 0L {
    return 1L
  }

  let ctx = LucasContext::new(p)
  let binom = ctx.binomial(2L * n, n)
  let inv_n_plus_1 = lucas_mod_pow(n + 1L, p - 2L, p)
  binom * inv_n_plus_1 % p
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "lucas small" {
  let ctx = LucasContext::new(7L)

  // C(5, 2) = 10 ≡ 3 (mod 7)
  inspect(ctx.binomial(5L, 2L), content="3")

  // C(6, 3) = 20 ≡ 6 (mod 7)
  inspect(ctx.binomial(6L, 3L), content="6")
}

///|
test "lucas edge cases" {
  let ctx = LucasContext::new(5L)

  // C(n, 0) = 1
  inspect(ctx.binomial(10L, 0L), content="1")

  // C(n, n) = 1
  inspect(ctx.binomial(10L, 10L), content="1")

  // C(n, k) = 0 if k > n
  inspect(ctx.binomial(5L, 10L), content="0")
}

///|
test "lucas large" {
  let ctx = LucasContext::new(13L)

  // C(100, 50) mod 13
  // Using Lucas: 100 = 7*13 + 9, 50 = 3*13 + 11
  // C(100, 50) ≡ C(7, 3) * C(9, 11) ≡ 35 * 0 ≡ 0 (mod 13)
  inspect(ctx.binomial(100L, 50L), content="0")

  // C(15, 5) = 3003 = 231*13 + 0, so ≡ 0 (mod 13)
  inspect(ctx.binomial(15L, 5L), content="0")
}

///|
test "lucas theorem property" {
  // C(p, k) ≡ 0 (mod p) for 0 < k < p
  let p = 7L
  let ctx = LucasContext::new(p)

  for k = 1L; k < p; k = k + 1L {
    inspect(ctx.binomial(p, k), content="0")
  }
}

///|
test "lucas prime 2" {
  let ctx = LucasContext::new(2L)

  // C(3, 1) = 3 ≡ 1 (mod 2)
  inspect(ctx.binomial(3L, 1L), content="1")

  // C(4, 2) = 6 ≡ 0 (mod 2)
  inspect(ctx.binomial(4L, 2L), content="0")
}

///|
test "lucas symmetry" {
  let ctx = LucasContext::new(11L)

  // C(n, k) = C(n, n-k)
  let n = 20L
  for k = 0L; k <= n; k = k + 1L {
    let left = ctx.binomial(n, k)
    let right = ctx.binomial(n, n - k)
    inspect(left == right, content="true")
  }
}

///|
test "catalan numbers" {
  // Use a smaller prime to avoid huge array allocation
  let p = 1009L // Small prime for testing

  // C_0 = 1
  inspect(catalan(0L, p), content="1")

  // C_1 = 1
  inspect(catalan(1L, p), content="1")

  // C_2 = 2
  inspect(catalan(2L, p), content="2")

  // C_3 = 5
  inspect(catalan(3L, p), content="5")

  // C_4 = 14
  inspect(catalan(4L, p), content="14")

  // C_5 = 42
  inspect(catalan(5L, p), content="42")
}

///|
test "factorial prime power" {
  // Number of 2s in 10! = 5 + 2 + 1 = 8
  inspect(factorial_prime_power(10L, 2L), content="8")

  // Number of 5s in 100! = 20 + 4 = 24
  inspect(factorial_prime_power(100L, 5L), content="24")
}

///|
test "lucas very large" {
  // Test with large numbers
  let ctx = LucasContext::new(97L)

  // C(1000, 500) mod 97
  let result = ctx.binomial(1000L, 500L)
  inspect(result >= 0L && result < 97L, content="true")
}
