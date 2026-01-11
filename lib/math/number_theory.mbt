// ============================================================================
// Number Theory and Bit Manipulation Examples
// Deep mathematical reasoning with cryptographic and computational applications
// ============================================================================

// ============================================================================
// Example N1: Miller-Rabin Primality Test (Deterministic for 32-bit integers)
// Probabilistic primality testing using Fermat's Little Theorem extension
// ============================================================================

///|
/// Modular exponentiation: computes (base^exp) mod m
#warnings("+missing_invariant+missing_reasoning")
fn mod_exp(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for b = base % m, e = exp, acc = 1L {
    if e == 0L {
      break acc
    } else if e % 2L == 0L {
      continue b * b % m, e / 2L, acc
    } else {
      continue b, e - 1L, acc * b % m
    }
  } where {
    invariant: e >= 0L && acc >= 0L && acc < m && b >= 0L && b < m,
    reasoning: (
      #|INVARIANT (Binary exponentiation):
      #|acc * b^e ≡ base^exp (mod m) at every step.
      #|
      #|If e is even, we square b and halve e:
      #|  acc * b^e = acc * (b^2)^(e/2).
      #|
      #|If e is odd, we multiply acc by b and decrement e:
      #|  acc * b^e = (acc*b) * b^(e-1).
      #|
      #|MAINTENANCE:
      #|Each update preserves acc * b^e by either absorbing one b into acc
      #|or squaring b and halving e, so the invariant remains true.
      #|TERMINATION:
      #|When e = 0, acc ≡ base^exp (mod m), which is returned.
    ),
  }
}

///|
/// Check if n is a strong probable prime to base a.
/// Uses the decomposition n-1 = d × 2^r where d is odd.
#warnings("+missing_invariant+missing_reasoning")
fn is_strong_probable_prime(n : Int64, a : Int64) -> Bool {
  guard n > 2L && n % 2L != 0L else { return n == 2L }

  // Factor out powers of 2 from n-1
  // Write n-1 = d × 2^r where d is odd
  let (d, r) = for d = n - 1L, r = 0L {
    if d % 2L != 0L {
      break (d, r)
    } else {
      continue d / 2L, r + 1L
    }
  } where {
    invariant: d >= 1L && r >= 0L && d * (1L << r.to_int()) == n - 1L,
    reasoning: (
      #|INVARIANT (Factorization): d × 2^r = n-1 is maintained.
      #|
      #|Base: d = n-1, r = 0 → (n-1) × 2^0 = n-1. ✓
      #|
      #|MAINTENANCE: When d is even, d' = d/2, r' = r+1.
      #|  d' × 2^r' = (d/2) × 2^(r+1) = d × 2^r = n-1. ✓
      #|
      #|TERMINATION: d is eventually odd (finite binary representation).
    ),
  }

  // Compute a^d mod n
  let mut x = mod_exp(a, d, n)

  // If a^d ≡ 1 (mod n) or a^d ≡ -1 (mod n), n passes this test
  if x == 1L || x == n - 1L {
    return true
  }

  // Square up to r-1 times, looking for -1
  for i = 0L {
    if i >= r - 1L {
      break false
    } else {
      x = x * x % n
      if x == n - 1L {
        break true
      } else if x == 1L {
        // Found a non-trivial square root of 1 → composite
        break false
      } else {
        continue i + 1L
      }
    }
  } where {
    invariant: i >= 0L && i <= r,
    reasoning: (
      #|INVARIANT (Squaring sequence): After i iterations,
      #|x = a^(d × 2^(i+1)) mod n.
      #|
      #|This exploits the structure of Fermat's Little Theorem:
      #|For prime p, a^(p-1) ≡ 1 (mod p).
      #|
      #|Since p-1 = d × 2^r, we have a^(d×2^r) ≡ 1 (mod p).
      #|Taking square roots: a^(d×2^(r-1)) ≡ ±1 (mod p).
      #|  (Only ±1 because p is prime, so no other square roots of 1)
      #|
      #|If a^(d×2^k) ≡ -1 for some k, continuing to square gives 1.
      #|If we never see -1 but eventually get 1, there's a non-trivial
      #|square root of 1, which proves n is composite.
      #|
      #|MAINTENANCE:
      #|Each iteration squares x, so exponent doubles and the invariant
      #|x = a^(d * 2^(i+1)) mod n advances with i.
      #|TERMINATION:
      #|After r-1 squarings, we either found -1 (pass) or proved composite.
      #|
      #|WITNESS PROPERTY: If n is composite, at least 3/4 of bases
      #|a ∈ [2, n-2] will "witness" this by failing the test.
      #|With enough random witnesses, probability of false positive
      #|drops exponentially.
      #|
      #|DETERMINISTIC VERSION: For 32-bit n, testing bases {2, 7, 61}
      #|is sufficient to give correct results for all n < 2^32.
    ),
  }
}

///|
/// Deterministic Miller-Rabin for 32-bit integers.
/// Tests against witnesses known to work for n < 2^32.
fn is_prime_32(n : Int) -> Bool {
  if n < 2 {
    return false
  }
  if n == 2 || n == 3 {
    return true
  }
  if n % 2 == 0 {
    return false
  }
  let n64 = n.to_int64()
  // These witnesses are proven sufficient for all n < 2^32
  let witnesses : Array[Int64] = [2L, 7L, 61L]
  for i = 0 {
    if i >= witnesses.length() {
      break true
    } else {
      let a = witnesses[i]
      if a >= n64 {
        continue i + 1
      } else if not(is_strong_probable_prime(n64, a)) {
        break false
      } else {
        continue i + 1
      }
    }
  } where {
    invariant: i >= 0 && i <= witnesses.length(),
    reasoning: (
      #|INVARIANT (Witness scan):
      #|After processing witnesses[0..i), n has passed all tested bases so far.
      #|If any base fails the strong probable prime test, n is composite.
      #|
      #|For 32-bit n, the set {2, 7, 61} is proven sufficient: passing all
      #|these bases implies primality for n < 2^32.
      #|MAINTENANCE:
      #|Check witness i; if it passes, advance i, preserving the invariant.
      #|TERMINATION:
      #|At i = witnesses.length(), n passed all bases and is prime.
    ),
  }
}

///|
test "is_prime_32" {
  assert_true(is_prime_32(2))
  assert_true(is_prime_32(3))
  assert_true(is_prime_32(17))
  assert_true(is_prime_32(997))
  assert_true(is_prime_32(7919))
  assert_true(not(is_prime_32(1)))
  assert_true(not(is_prime_32(4)))
  assert_true(not(is_prime_32(100)))
  assert_true(not(is_prime_32(561))) // Carmichael number
  assert_true(not(is_prime_32(1105))) // Another Carmichael number
}

// ============================================================================
// Example N2: Chinese Remainder Theorem Solver
// Solve system of congruences x ≡ a_i (mod m_i) where m_i are pairwise coprime
// ============================================================================

///|
/// Extended GCD: returns (gcd, x, y) such that a*x + b*y = gcd(a,b)
#warnings("+missing_invariant+missing_reasoning")
fn extended_gcd_64(a : Int64, b : Int64) -> (Int64, Int64, Int64) {
  for r0 = a, r1 = b, x0 = 1L, x1 = 0L, y0 = 0L, y1 = 1L {
    if r1 == 0L {
      break (r0, x0, y0)
    } else {
      let q = r0 / r1
      continue r1, r0 - q * r1, x1, x0 - q * x1, y1, y0 - q * y1
    }
  } where {
    invariant: a * x0 + b * y0 == r0,
    reasoning: (
      #|BÉZOUT INVARIANT: a·x0 + b·y0 = r0 and a·x1 + b·y1 = r1.
      #|
      #|This is the key to constructing the Bézout coefficients.
      #|When r1 = 0, we have gcd = r0 and the coefficients x0, y0.
      #|MAINTENANCE:
      #|The Euclidean update on (r0, r1) is mirrored by the coefficient
      #|updates, so the Bézout identities remain true.
      #|TERMINATION:
      #|When r1 = 0, r0 is gcd(a,b) with coefficients x0,y0.
    ),
    invariant: a * x1 + b * y1 == r1,
    reasoning: (
      #|INVARIANT (Second remainder):
      #|r1 always equals a*x1 + b*y1. The Euclidean update
      #|  (r0, r1) <- (r1, r0 - q*r1)
      #|is mirrored by the coefficient update
      #|  (x0, x1) <- (x1, x0 - q*x1)
      #|  (y0, y1) <- (y1, y0 - q*y1),
      #|so both Bézout identities stay true together.
      #|MAINTENANCE:
      #|The linear combination for r1 follows directly from the update.
      #|TERMINATION:
      #|At r1 = 0, r0 is gcd(a,b) and r1's identity is vacuous.
    ),
  }
}

///|
/// Solve x ≡ a1 (mod m1), x ≡ a2 (mod m2) where gcd(m1, m2) = 1.
/// Returns (solution, combined_modulus).
fn solve_crt_pair(
  a1 : Int64,
  m1 : Int64,
  a2 : Int64,
  m2 : Int64,
) -> (Int64, Int64) {
  let (g, p, _) = extended_gcd_64(m1, m2)
  // By CRT construction: x = a1 + m1 * p * (a2 - a1) / g
  // When g = 1: x = a1 + m1 * p * (a2 - a1)
  guard g == 1L else {
    // Not coprime - return dummy (caller should validate)
    return (0L, m1 * m2)
  }
  let diff = ((a2 - a1) % m2 + m2) % m2
  let x = (a1 + m1 * (p * diff % m2)) % (m1 * m2)
  let x_normalized = (x + m1 * m2) % (m1 * m2)
  (x_normalized, m1 * m2)
}

///|
/// Solve system of congruences using CRT.
/// Input: array of (remainder, modulus) pairs.
/// Returns (solution, product_of_moduli).
#warnings("+missing_invariant+missing_reasoning")
fn chinese_remainder(congruences : ArrayView[(Int64, Int64)]) -> (Int64, Int64) {
  guard congruences.length() > 0 else { return (0L, 1L) }
  let (a0, m0) = congruences[0]
  for i = 1, acc_a = a0, acc_m = m0 {
    if i >= congruences.length() {
      break (acc_a, acc_m)
    } else {
      let (ai, mi) = congruences[i]
      let (new_a, new_m) = solve_crt_pair(acc_a, acc_m, ai, mi)
      continue i + 1, new_a, new_m
    }
  } where {
    invariant: i >= 1 && i <= congruences.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds and progress):
      #|i is the next congruence to merge. Each iteration combines exactly
      #|one new pair into the accumulator, so we eventually process all
      #|congruences and terminate at i == congruences.length().
      #|MAINTENANCE:
      #|Increment i after merging the next congruence, keeping i aligned with
      #|the number of merged pairs.
      #|TERMINATION:
      #|At i = congruences.length(), all pairs are merged.
    ),
    invariant: acc_m >= 1L,
    reasoning: (
      #|INVARIANT 2 (CRT accumulator):
      #|acc_a is the unique solution modulo acc_m to the first i congruences.
      #|
      #|Base: i=1, acc_a = a0, acc_m = m0.
      #|  a0 ≡ a0 (mod m0) is the unique solution for one congruence. ✓
      #|
      #|Inductive: Given acc_a ≡ aj (mod mj) for j < i,
      #|  we compute new_a, new_m = solve_crt_pair(acc_a, acc_m, ai, mi).
      #|
      #|  By CRT: If gcd(acc_m, mi) = 1, there exists unique x (mod acc_m × mi)
      #|  such that x ≡ acc_a (mod acc_m) and x ≡ ai (mod mi).
      #|
      #|  CONSTRUCTION:
      #|  Let p, q satisfy acc_m · p + mi · q = 1 (from extended GCD).
      #|  Then x = acc_a · mi · q + ai · acc_m · p satisfies:
      #|    x ≡ acc_a · mi · q ≡ acc_a · 1 ≡ acc_a (mod acc_m)
      #|    x ≡ ai · acc_m · p ≡ ai · 1 ≡ ai (mod mi)
      #|
      #|  UNIQUENESS:
      #|  If x' also satisfies both, then x - x' ≡ 0 (mod acc_m)
      #|  and x - x' ≡ 0 (mod mi). Since gcd(acc_m, mi) = 1,
      #|  x - x' ≡ 0 (mod acc_m × mi), so x ≡ x' (mod acc_m × mi).
      #|
      #|At termination: acc_a is unique solution mod ∏mj to all congruences.
      #|MAINTENANCE:
      #|solve_crt_pair merges one more congruence while preserving uniqueness
      #|modulo the expanded product acc_m * mi.
      #|TERMINATION:
      #|At i = congruences.length(), acc_a solves all input congruences.
    ),
  }
}

///|
test "chinese_remainder" {
  // x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7)
  // Solution: x = 23 (mod 105)
  let congruences : Array[(Int64, Int64)] = [(2L, 3L), (3L, 5L), (2L, 7L)]
  let (x, m) = chinese_remainder(congruences[:])
  assert_eq(m, 105L)
  assert_eq(x % 3L, 2L)
  assert_eq(x % 5L, 3L)
  assert_eq(x % 7L, 2L)

  // x ≡ 0 (mod 2), x ≡ 0 (mod 3), x ≡ 1 (mod 5)
  // Solution: x = 6 (mod 30)
  let congruences2 : Array[(Int64, Int64)] = [(0L, 2L), (0L, 3L), (1L, 5L)]
  let (x2, m2) = chinese_remainder(congruences2[:])
  assert_eq(m2, 30L)
  assert_eq(x2 % 2L, 0L)
  assert_eq(x2 % 3L, 0L)
  assert_eq(x2 % 5L, 1L)
}

// ============================================================================
// Example N3: Binary GCD (Stein's Algorithm)
// Compute GCD using only subtraction and bit shifts (no division)
// ============================================================================

///|
/// Binary GCD: efficient when division is expensive.
/// Uses the identities:
///   gcd(2a, 2b) = 2·gcd(a, b)
///   gcd(2a, b) = gcd(a, b) when b is odd
///   gcd(a, b) = gcd(|a-b|, min(a,b)) when both odd
#warnings("+missing_invariant+missing_reasoning")
fn binary_gcd(a : Int, b : Int) -> Int {
  guard a > 0 && b > 0 else { return if a > 0 { a } else { b } }

  // Count common factors of 2
  let shift = for k = 0, x = a | b {
    if x % 2 != 0 {
      break k
    } else {
      continue k + 1, x / 2
    }
  } where {
    invariant: k >= 0 && (a | b) == x * (1 << k),
    reasoning: (
      #|INVARIANT (Power of 2 extraction):
      #|We count the common trailing zeros in a|b.
      #|k = min(v2(a), v2(b)) where v2 is the 2-adic valuation.
      #|
      #|This is because gcd(a,b) = 2^k × gcd(a/2^k, b/2^k) where k is
      #|the number of common factors of 2.
      #|MAINTENANCE:
      #|When x is even, divide by 2 and increment k, preserving
      #|(a|b) == x * 2^k.
      #|TERMINATION:
      #|When x is odd, all common factors of 2 are counted in k.
    ),
  }

  // Remove remaining factors of 2 from a
  let a1 = for x = a {
    if x % 2 != 0 {
      break x
    } else {
      continue x / 2
    }
  } where {
    invariant: x >= 1 &&
    gcd_spec(x, b / (1 << shift)) == gcd_spec(a, b) / (1 << shift),
    reasoning: (
      #|INVARIANT (Odd part of a):
      #|We repeatedly strip factors of 2 from a until it becomes odd.
      #|Because all common powers of 2 were already removed into shift,
      #|this loop only removes extra powers of 2 from a, which do not affect
      #|the odd component of gcd(a, b). The invariant preserves the scaled gcd.
      #|MAINTENANCE:
      #|Divide x by 2 when even, keeping the scaled gcd unchanged.
      #|TERMINATION:
      #|When x is odd, we have isolated the odd part of a.
    ),
  }

  // Main loop: both u and v are odd
  for u = a1, v = b {
    // Make v odd by removing factors of 2
    let v1 = for x = v {
      if x % 2 != 0 {
        break x
      } else {
        continue x / 2
      }
    } where {
      invariant: x >= 1,
      reasoning: (
        #|INVARIANT (Odd part of v):
        #|Because u is odd, gcd(u, v) is unchanged by removing powers of 2
        #|from v. The loop returns the odd part of v, allowing the main
        #|subtraction step to operate only on odd numbers.
        #|MAINTENANCE:
        #|Strip one factor of 2 from v at a time, preserving gcd(u, v).
        #|TERMINATION:
        #|When x is odd, v1 is the odd part of v.
      ),
    }
    // Now both u and v1 are odd
    if u > v1 {
      continue v1, u - v1
    } else if u < v1 {
      continue u, v1 - u
    } else {
      break u << shift
    }
  } where {
    invariant: u >= 1 && u % 2 == 1,
    reasoning: (
      #|INVARIANT (Odd GCD preservation):
      #|gcd(u, v) = gcd(original a, original b) / 2^shift
      #|
      #|KEY INSIGHT: For odd a, b:
      #|  gcd(a, b) = gcd(a, b - a) = gcd(a, (b-a)/2^k)
      #|  where k = v2(b-a) is the 2-adic valuation of (b-a).
      #|
      #|Since a is odd and b is odd, b-a is even.
      #|We can keep removing 2s from the difference because
      #|they don't contribute to the odd part of the gcd.
      #|
      #|MAINTENANCE:
      #|Replacing (u, v) with (min(u, v), |u - v|) preserves gcd(u, v).
      #|After stripping 2s from |u - v|, both values remain odd.
      #|
      #|TERMINATION: |u - v| < max(u, v) when u ≠ v.
      #|The maximum of (u, v) strictly decreases each iteration.
      #|
      #|When u = v: gcd(u, v) = u, so answer is u × 2^shift.
      #|
      #|WHY NO DIVISION?
      #|This algorithm only uses:
      #|  - Parity check (x % 2 or x & 1)
      #|  - Right shift (x / 2 or x >> 1)
      #|  - Left shift (x << k)
      #|  - Subtraction
      #|
      #|On hardware without fast division, this is more efficient
      #|than the Euclidean algorithm. Used in cryptographic libraries.
    ),
  }
}

///|
/// Specification for gcd (recursive definition).
fn gcd_spec(a : Int, b : Int) -> Int {
  if b == 0 {
    a
  } else {
    gcd_spec(b, a % b)
  }
}

///|
test "binary_gcd" {
  assert_eq(binary_gcd(48, 18), 6)
  assert_eq(binary_gcd(100, 35), 5)
  assert_eq(binary_gcd(17, 13), 1)
  assert_eq(binary_gcd(1024, 512), 512)
  assert_eq(binary_gcd(7, 7), 7)
  assert_eq(binary_gcd(1, 1000), 1)
}

// ============================================================================
// Example N4: Count Trailing Zeros (de Bruijn sequence method)
// Find position of lowest set bit using multiplication and lookup
// ============================================================================

///|
/// de Bruijn sequence for 32-bit: maps each 5-bit suffix to unique position
let de_bruijn_32 : Int = 0x077CB531

///|
/// Lookup table: de_bruijn_table[((x & -x) * de_bruijn_32) >> 27] = ctz(x & -x)
let de_bruijn_table : Array[Int] = [
  0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8, 31, 27, 13, 23, 21, 19,
  16, 7, 26, 12, 18, 6, 11, 5, 10, 9,
]

///|
/// Count trailing zeros using de Bruijn sequence.
/// For n > 0, returns position of lowest set bit (0-indexed).
#warnings("+missing_invariant+missing_reasoning")
fn count_trailing_zeros(n : Int) -> Int {
  guard n != 0 else { return 32 }

  // Isolate the lowest set bit: x & (-x) = x & (~x + 1)
  let lowest_bit = n & -n

  // The magic: multiply by de Bruijn sequence and extract high bits
  // This maps each power of 2 to a unique index in the lookup table
  let hash = lowest_bit * de_bruijn_32

  // Use top 5 bits as index
  let index = (hash >> 27) & 0x1F
  de_bruijn_table[index]
}

///|
test "count_trailing_zeros" {
  assert_eq(count_trailing_zeros(1), 0) // 0b1
  assert_eq(count_trailing_zeros(2), 1) // 0b10
  assert_eq(count_trailing_zeros(4), 2) // 0b100
  assert_eq(count_trailing_zeros(8), 3) // 0b1000
  assert_eq(count_trailing_zeros(12), 2) // 0b1100, lowest is at position 2
  assert_eq(count_trailing_zeros(0x80000000), 31)
  assert_eq(count_trailing_zeros(0), 32) // Convention: all zeros
}

// ============================================================================
// Example N5: Integer Logarithm Base 2 (Floor)
// Compute floor(log2(n)) using bit manipulation
// ============================================================================

///|
/// Compute floor(log2(n)) for n > 0.
/// Uses binary search within the integer, doubling check range each step.
#warnings("+missing_invariant+missing_reasoning")
fn ilog2(n : Int) -> Int {
  guard n > 0 else { return -1 }
  for x = n, log = 0 {
    if x <= 1 {
      break log
    } else {
      // Binary search approach: check if high bits are set
      // This is equivalent to repeated halving
      continue x >> 1, log + 1
    }
  } where {
    invariant: x >= 1 &&
    log >= 0 &&
    n >= x * (1 << log) &&
    n < (x + 1) * (1 << log),
    reasoning: (
      #|INVARIANT (Logarithm bounds):
      #|x × 2^log ≤ n < (x+1) × 2^log
      #|
      #|This means log2(n) ∈ [log + log2(x), log + log2(x+1)).
      #|
      #|Base: x = n, log = 0.
      #|  n × 2^0 = n ≤ n < n+1 = (n+1) × 2^0. ✓
      #|
      #|Inductive: x' = x >> 1 = floor(x/2), log' = log + 1.
      #|  Need: x' × 2^log' ≤ n < (x'+1) × 2^log'
      #|
      #|  x' × 2^log' = floor(x/2) × 2^(log+1) = floor(x/2) × 2 × 2^log
      #|              ≤ x × 2^log ≤ n. ✓
      #|
      #|  (x'+1) × 2^log' = (floor(x/2)+1) × 2^(log+1)
      #|                  ≥ (x/2) × 2^(log+1) = x × 2^log
      #|  And x+1 > x implies (x'+1) × 2 > x when x > 1, so bound holds. ✓
      #|
      #|MAINTENANCE:
      #|Right shift reduces x and incrementing log keeps the bounds aligned.
      #|TERMINATION:
      #|x strictly decreases until x ≤ 1. When x = 1:
      #|n ∈ [2^log, 2^(log+1)), so floor(log2(n)) = log.
    ),
  }
}

///|
test "ilog2" {
  assert_eq(ilog2(1), 0)
  assert_eq(ilog2(2), 1)
  assert_eq(ilog2(3), 1)
  assert_eq(ilog2(4), 2)
  assert_eq(ilog2(7), 2)
  assert_eq(ilog2(8), 3)
  assert_eq(ilog2(1023), 9)
  assert_eq(ilog2(1024), 10)
}

// ============================================================================
// Example N6: Modular Multiplicative Inverse
// Find x such that a·x ≡ 1 (mod m) using extended GCD
// ============================================================================

///|
/// Compute modular inverse of a modulo m.
/// Returns Some(x) where a·x ≡ 1 (mod m), or None if gcd(a,m) ≠ 1.
#warnings("+missing_invariant+missing_reasoning")
fn mod_inverse(a : Int64, m : Int64) -> Int64? {
  let (gcd, x, _) = extended_gcd_64(a, m)
  if gcd != 1L {
    None
  } else {
    // Normalize x to be positive
    Some((x % m + m) % m)
  }
}

///|
test "mod_inverse" {
  // 3 × 7 = 21 ≡ 1 (mod 10)
  assert_eq(mod_inverse(3L, 10L), Some(7L))

  // 2 has no inverse mod 4 (gcd = 2)
  assert_eq(mod_inverse(2L, 4L), None)

  // 17 × 8 = 136 ≡ 1 (mod 27)
  match mod_inverse(17L, 27L) {
    Some(inv) => assert_eq(17L * inv % 27L, 1L)
    None => assert_true(false)
  }
}

// ============================================================================
// Example N7: Perfect Power Detection
// Check if n = a^b for some a, b > 1
// ============================================================================

///|
/// Check if n is a perfect power (n = a^b for integers a, b > 1).
#warnings("+missing_invariant+missing_reasoning")
fn is_perfect_power(n : Int) -> Bool {
  guard n > 1 else { return false }

  // Try each possible exponent b from 2 to log2(n)
  let max_exp = ilog2(n)
  for b = 2 {
    if b > max_exp {
      break false
    } else {
      // Binary search for a such that a^b = n
      let a = nth_root(n, b)
      if int_pow(a, b) == n {
        break true
      } else {
        continue b + 1
      }
    }
  } where {
    invariant: b >= 2 && b <= max_exp + 1,
    reasoning: (
      #|INVARIANT (Exhaustive exponent search):
      #|We try each possible exponent from 2 up to floor(log2(n)).
      #|
      #|WHY max_exp = floor(log2(n))?
      #|If n = a^b with a ≥ 2 and b ≥ 2, then:
      #|  n ≥ 2^b, so b ≤ log2(n).
      #|
      #|COMPLETENESS: If n is a perfect power, there exists smallest b ≥ 2
      #|such that n = a^b for some a. We'll find it by trying all b.
      #|
      #|For each b, we compute floor(n^(1/b)) and check if it's exact.
      #|MAINTENANCE:
      #|Check exponent b and advance to b+1 if no exact root is found.
      #|TERMINATION:
      #|At b = max_exp + 1, all feasible exponents are tested.
    ),
  }
}

///|
/// Compute floor(n^(1/b)) using binary search.
fn nth_root(n : Int, b : Int) -> Int {
  guard n > 0 && b > 0 else { return 0 }
  for lo = 1, hi = n {
    if lo >= hi {
      break lo
    } else {
      let mid = lo + (hi - lo + 1) / 2
      let pow = int_pow_checked(mid, b, n)
      if pow <= n {
        continue mid, hi
      } else {
        continue lo, mid - 1
      }
    }
  } where {
    invariant: lo >= 1 && hi <= n && lo <= hi + 1,
    reasoning: (
      #|INVARIANT (Root bracket):
      #|lo is always a candidate with lo^b <= n, and hi is always a candidate
      #|with hi^b >= n. The update keeps the true floor root inside [lo, hi].
      #|Using the upper mid (lo + (hi-lo+1)/2) guarantees progress.
      #|MAINTENANCE:
      #|If mid^b <= n, move lo up to mid; otherwise move hi down to mid-1.
      #|TERMINATION:
      #|When lo >= hi, lo is the floor b-th root.
    ),
  }
}

///|
/// Compute a^b, with overflow check against max value.
fn int_pow_checked(a : Int, b : Int, max_val : Int) -> Int {
  for base = a, exp = b, acc = 1 {
    if exp == 0 {
      break acc
    } else if exp % 2 == 0 {
      let new_base = if base > max_val / base {
        max_val + 1
      } else {
        base * base
      }
      continue new_base, exp / 2, acc
    } else {
      let new_acc = if acc > max_val / base { max_val + 1 } else { acc * base }
      continue base, exp - 1, new_acc
    }
  } where {
    invariant: exp >= 0,
    reasoning: (
      #|INVARIANT (Exponentiation by squaring):
      #|At each step, acc * base^exp equals a^b, unless overflow is detected.
      #|When a multiplication would exceed max_val, we clamp to max_val+1
      #|to signal overflow and keep comparisons sound.
      #|MAINTENANCE:
      #|Odd exp multiplies acc; even exp squares base. Both preserve the
      #|acc * base^exp relation while guarding overflow.
      #|TERMINATION:
      #|exp decreases to 0, yielding the checked power in acc.
    ),
  }
}

///|
/// Simple integer power.
fn int_pow(a : Int, b : Int) -> Int {
  for base = a, exp = b, acc = 1 {
    if exp == 0 {
      break acc
    } else if exp % 2 == 0 {
      continue base * base, exp / 2, acc
    } else {
      continue base, exp - 1, acc * base
    }
  } where {
    invariant: exp >= 0,
    reasoning: (
      #|INVARIANT (Exponentiation by squaring):
      #|acc * base^exp == a^b. When exp is even, we square base and halve exp;
      #|when exp is odd, we multiply acc by base and decrement exp.
      #|MAINTENANCE:
      #|Each update preserves acc * base^exp by moving one factor of base
      #|into acc or by squaring base and halving exp.
      #|TERMINATION:
      #|exp decreases to 0, leaving acc = a^b.
    ),
  }
}

///|
test "is_perfect_power" {
  assert_true(is_perfect_power(4)) // 2^2
  assert_true(is_perfect_power(8)) // 2^3
  assert_true(is_perfect_power(9)) // 3^2
  assert_true(is_perfect_power(16)) // 2^4 or 4^2
  assert_true(is_perfect_power(27)) // 3^3
  assert_true(is_perfect_power(125)) // 5^3
  assert_true(not(is_perfect_power(2)))
  assert_true(not(is_perfect_power(3)))
  assert_true(not(is_perfect_power(5)))
  assert_true(not(is_perfect_power(6)))
  assert_true(not(is_perfect_power(10)))
}
