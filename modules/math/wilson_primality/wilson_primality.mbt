// ============================================================================
// WILSON'S THEOREM PRIMALITY TEST
// ============================================================================
//
// PROBLEM
//
// Given an integer n >= 2, decide whether it is prime.
//
// THE THEOREM
//
//   Wilson (1770):
//     n is prime  iff  (n - 1)!  ≡  -1  (mod n)
//
//   The forward direction (prime -> factorial congruence) is the
//   famous part: in Z_p^*, every element x has an inverse x^-1, and
//   x = x^-1 iff x^2 = 1 iff x = +/- 1. Pair up each x in [2, p-2]
//   with its (distinct) inverse; their product is 1. So
//   (p-1)! = 1 * (p-1) * (product of pairs) = (p-1) * 1 = -1 mod p.
//
//   The converse: if n is composite, (n-1)! has the factor that
//   divides n in it (for n > 4), so (n-1)! ≡ 0 mod n. The exception
//   is n = 4: (4-1)! = 6, 6 mod 4 = 2, which is not -1, so the test
//   correctly fails for 4 too.
//
// USE
//
//   Wilson is *not* a practical primality test (computing (n-1)! is
//   O(n) multiplications, each costing O(log^2 n) bits). It is a
//   beautiful theoretical characterisation. For a 64-bit n, the test
//   takes ~n modular multiplications -- only feasible for small n.
//
// THE INVARIANT
//
//   "After processing i in the running product, prod ≡ i! mod n."
//
//   The loop multiplies by 1, 2, ..., n-1, each step preserving the
//   invariant that prod is the running factorial mod n.
//
// COMPLEXITY
//
//   Time  : O(n)
//   Space : O(1)

///|
/// Normalise an Int64 into [0, m).
fn w_mod_norm(x : Int64, m : Int64) -> Int64 {
  let r = x % m
  if r < 0L {
    r + m
  } else {
    r
  }
}

///|
/// Modular multiplication of two values in [0, m), where `m` may be up
/// to ~2^31 so the intermediate `a * b` fits in an Int64.
fn w_mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  w_mod_norm(a * b, m)
}

///|
/// Test whether `n` is prime via Wilson's theorem:
/// n is prime iff (n - 1)! ≡ -1 (mod n).
///
/// This is `O(n)` and therefore only practical for small `n`
/// (say up to a few million). For production primality testing prefer
/// Miller-Rabin or Solovay-Strassen.
///
/// `is_prime(0)` and `is_prime(1)` return `false` (neither is prime).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   assert_eq(@wilson_primality.is_prime(7L), true)
///   assert_eq(@wilson_primality.is_prime(15L), false)
/// }
/// ```
pub fn is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  if n == 2L {
    return true
  }
  // For n >= 4 composite, (n-1)! has all of n's prime factors in it,
  // so (n-1)! ≡ 0. The only sub-case we need to think about: n = 4,
  // where (4-1)! = 6 ≡ 2 mod 4 -- not -1, so the test correctly rejects.
  // The forward direction (prime -> -1) is what gives the if-and-only-if.
  let mut prod : Int64 = 1L
  for k in 2L..<n {
    prod = w_mul_mod(prod, k, n)
    if prod == 0L {
      // Optimisation: once we've absorbed a factor of n, the product
      // stays 0 forever. (n - 1)! ≡ 0 mod n, which is not -1, so n is
      // composite.
      return false
    }
  }
  // Test (n-1)! ≡ -1 mod n.
  prod == n - 1L
}

///|
/// Wilson-quotient: (((p-1)! + 1) / p) mod p, defined for prime p. This
/// is a number-theoretic curiosity studied in connection with Wilson
/// primes (those prime p for which the quotient is 0 mod p). The only
/// known Wilson primes are 5, 13, and 563.
///
/// Returns `None` if `p` is not prime.
pub fn wilson_quotient(p : Int64) -> Int64? {
  if !is_prime(p) {
    return None
  }
  // Compute (p-1)! mod p^2 (so we can divide by p exactly).
  // For p <= a few thousand this is fine.
  let p2 = p * p
  let mut prod : Int64 = 1L
  for k in 2L..<p {
    // Multiply mod p^2 (assumes p^2 fits in Int64).
    prod = prod * k % p2
  }
  // (p-1)! + 1 should be divisible by p.
  let num = (prod + 1L) % p2
  let q = num / p
  Some(q % p)
}

///|
test "wilson primes" {
  @debug.assert_eq(is_prime(2L), true)
  @debug.assert_eq(is_prime(3L), true)
  @debug.assert_eq(is_prime(5L), true)
  @debug.assert_eq(is_prime(7L), true)
  @debug.assert_eq(is_prime(11L), true)
  @debug.assert_eq(is_prime(13L), true)
  @debug.assert_eq(is_prime(97L), true)
  @debug.assert_eq(is_prime(101L), true)
}

///|
test "wilson composites" {
  @debug.assert_eq(is_prime(0L), false)
  @debug.assert_eq(is_prime(1L), false)
  @debug.assert_eq(is_prime(4L), false)
  @debug.assert_eq(is_prime(6L), false)
  @debug.assert_eq(is_prime(8L), false)
  @debug.assert_eq(is_prime(9L), false)
  @debug.assert_eq(is_prime(15L), false)
  @debug.assert_eq(is_prime(25L), false)
  @debug.assert_eq(is_prime(100L), false)
}

///|
test "wilson cross-validates against trial division" {
  fn td(n : Int64) -> Bool {
    if n < 2L {
      return false
    }
    let mut k = 2L
    while k * k <= n {
      if n % k == 0L {
        return false
      }
      k = k + 1L
    }
    true
  }

  for n in 2L..<200L {
    @debug.assert_eq(is_prime(n), td(n))
  }
}

///|
test "wilson edge case n=4" {
  // The famous edge case. (4-1)! = 6 mod 4 = 2 != -1 mod 4 = 3.
  @debug.assert_eq(is_prime(4L), false)
}

///|
test "wilson quotient for known primes" {
  // For p = 5: (5-1)! + 1 = 25, 25 / 5 = 5, 5 mod 5 = 0. 5 IS a Wilson prime.
  @debug.assert_eq(wilson_quotient(5L), Some(0L))
  // For p = 13: (12!) + 1 = 479001601, divisible by 13 (13 is a Wilson prime).
  // Let's just check it's Some(...) and at p=13 it's 0:
  @debug.assert_eq(wilson_quotient(13L), Some(0L))
  // For p = 7: (6!) + 1 = 721 = 7 * 103; 103 mod 7 = 103 - 14*7 = 103 - 98 = 5.
  @debug.assert_eq(wilson_quotient(7L), Some(5L))
}

///|
test "wilson quotient on composite" {
  @debug.assert_eq(wilson_quotient(6L), None)
  @debug.assert_eq(wilson_quotient(9L), None)
}
