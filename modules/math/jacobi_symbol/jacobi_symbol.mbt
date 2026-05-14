// ============================================================================
// JACOBI SYMBOL  -  Jacobi 1837
// ============================================================================
//
// PROBLEM
//
// Given an integer `a` and an odd positive integer `n`, compute the
// **Jacobi symbol** `(a / n)`, which generalises the Legendre symbol
// to composite moduli. It takes values in `{-1, 0, +1}`.
//
// DEFINITION
//
// For an odd prime p:
//   (a / p) = 0      if p | a
//           = +1     if a is a non-zero quadratic residue mod p
//           = -1     if a is a quadratic non-residue mod p
//
// For an odd positive composite n = p1^a1 * p2^a2 * ... * pk^ak:
//   (a / n) = (a / p1)^a1 * (a / p2)^a2 * ... * (a / pk)^ak
//
// Key fact: when `n` is prime, the Jacobi symbol equals the Legendre
// symbol -- so the Jacobi symbol is the natural generalisation. When
// `n` is composite, `(a / n) = +1` does NOT imply `a` is a QR mod `n`;
// the symbol can be misleading. But `(a / n) = -1` DOES imply `a` is
// not a QR.
//
// COMPUTATION (without factoring!)
//
// We compute `(a / n)` in O(log n) time using:
//
//   1. (a / n) = (a mod n / n)                                   -- reduce
//   2. (2 / n) = +1 if n ≡ +-1 mod 8, -1 if n ≡ +-3 mod 8        -- supplement
//   3. (a b / n) = (a / n) * (b / n)                              -- multiplicativity
//   4. (a / n) = (n / a) * (-1)^((a-1)(n-1)/4)  for both odd      -- quadratic reciprocity
//
// This is the **Euclidean-style** algorithm: alternate reducing
// `a mod n` and swapping `a, n` (with a sign flip from reciprocity)
// until `a = 0` or `a = 1`.
//
// COMPLEXITY
//
//   Time : O(log^2 n) bit operations (similar to gcd)
//   Space: O(1)
//
// USE
//
//   - Building block for Solovay-Strassen primality testing.
//   - Cryptographic protocols (quadratic-residuosity assumption).
//   - Pell equations, sums of squares, and other classical number
//     theory questions.
//
// THE INVARIANT
//
//   "Throughout the algorithm, the running result `s` satisfies
//    s * (a' / n')  =  (a_initial / n_initial),
//    where (a', n') are the current values."

///|
/// Compute the Jacobi symbol `(a / n)`.
///
/// `n` must be a positive odd integer. Returns `0`, `+1`, or `-1`.
/// `a` may be any integer (negative or larger than `n`).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // (3 / 7) = -1 (3 is a quadratic non-residue mod 7)
///   @debug.assert_eq(@jacobi_symbol.jacobi(3L, 7L), -1)
///   // (4 / 7) = +1 (4 = 2^2, trivially a QR)
///   @debug.assert_eq(@jacobi_symbol.jacobi(4L, 7L), 1)
/// }
/// ```
pub fn jacobi(a : Int64, n : Int64) -> Int {
  // Precondition: n positive and odd.
  if n <= 0L || n.land(1L) == 0L {
    return 0
  }
  let mut a_m = a % n
  if a_m < 0L {
    a_m = a_m + n
  }
  let mut n_m = n
  let mut result : Int = 1
  while a_m != 0L {
    // Pull out factors of 2 from a_m.
    while a_m.land(1L) == 0L {
      a_m = a_m / 2L
      let r = n_m % 8L
      if r == 3L || r == 5L {
        result = -result
      }
    }
    // Now a_m is odd. Swap a_m and n_m (quadratic reciprocity).
    let t = a_m
    a_m = n_m
    n_m = t
    // Reciprocity flip: (-1)^((a-1)/2 * (n-1)/2). For both odd this is
    // -1 iff both ≡ 3 mod 4.
    if a_m % 4L == 3L && n_m % 4L == 3L {
      result = -result
    }
    // Reduce a_m mod n_m.
    a_m = a_m % n_m
  }
  if n_m == 1L {
    result
  } else {
    0
  }
}

///|
test "jacobi basic primes" {
  // (a / p) for p prime equals the Legendre symbol.
  // 7 has QRs {1, 2, 4}; non-QRs {3, 5, 6}.
  @debug.assert_eq(jacobi(1L, 7L), 1)
  @debug.assert_eq(jacobi(2L, 7L), 1)
  @debug.assert_eq(jacobi(4L, 7L), 1)
  @debug.assert_eq(jacobi(3L, 7L), -1)
  @debug.assert_eq(jacobi(5L, 7L), -1)
  @debug.assert_eq(jacobi(6L, 7L), -1)
}

///|
test "jacobi zero" {
  // (0 / n) = 0 for any n.
  @debug.assert_eq(jacobi(0L, 7L), 0)
  @debug.assert_eq(jacobi(0L, 15L), 0)
  // (a / n) where gcd(a, n) > 1 is 0.
  @debug.assert_eq(jacobi(15L, 15L), 0)
  @debug.assert_eq(jacobi(6L, 15L), 0)
}

///|
test "jacobi composite modulus" {
  // (a / 15) = (a / 3) * (a / 5). Tabulate:
  //   a=1: (1/3)=1, (1/5)=1 -> 1
  //   a=2: (2/3)=-1, (2/5)=-1 -> 1
  //   a=4: (4/3)=1, (4/5)=1 -> 1
  //   a=7: (7/3)=(1/3)=1, (7/5)=(2/5)=-1 -> -1
  //   a=8: (8/3)=(2/3)=-1, (8/5)=(3/5)=-1 -> 1
  //   a=11: (11/3)=(2/3)=-1, (11/5)=(1/5)=1 -> -1
  //   a=13: (13/3)=(1/3)=1, (13/5)=(3/5)=-1 -> -1
  //   a=14: (14/3)=(2/3)=-1, (14/5)=(4/5)=1 -> -1
  @debug.assert_eq(jacobi(1L, 15L), 1)
  @debug.assert_eq(jacobi(2L, 15L), 1)
  @debug.assert_eq(jacobi(4L, 15L), 1)
  @debug.assert_eq(jacobi(7L, 15L), -1)
  @debug.assert_eq(jacobi(8L, 15L), 1)
  @debug.assert_eq(jacobi(11L, 15L), -1)
  @debug.assert_eq(jacobi(13L, 15L), -1)
  @debug.assert_eq(jacobi(14L, 15L), -1)
}

///|
test "jacobi by Euler's criterion" {
  // For prime p, (a / p) ≡ a^((p-1)/2) mod p. Cross-check.
  fn mod_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
    let mut b = base % m
    if b < 0L {
      b = b + m
    }
    let mut e = exp
    let mut r = 1L
    while e > 0L {
      if e.land(1L) == 1L {
        r = r * b % m
      }
      b = b * b % m
      e = e / 2L
    }
    r
  }

  for p in [3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L] {
    for a in 1L..<p {
      let j = jacobi(a, p)
      let euler = mod_pow(a, (p - 1L) / 2L, p)
      let euler_norm = if euler == p - 1L { -1 } else { euler.to_int() }
      @debug.assert_eq(j, euler_norm)
    }
  }
}

///|
test "jacobi negative a" {
  // (-1 / n) = +1 if n ≡ 1 mod 4, -1 if n ≡ 3 mod 4.
  @debug.assert_eq(jacobi(-1L, 5L), 1) // 5 ≡ 1 mod 4
  @debug.assert_eq(jacobi(-1L, 7L), -1) // 7 ≡ 3 mod 4
  @debug.assert_eq(jacobi(-1L, 13L), 1) // 13 ≡ 1 mod 4
  @debug.assert_eq(jacobi(-1L, 11L), -1) // 11 ≡ 3 mod 4
}

///|
test "jacobi reduction modulo" {
  // (a / n) = ((a mod n) / n).
  @debug.assert_eq(jacobi(10L, 7L), jacobi(3L, 7L))
  @debug.assert_eq(jacobi(100L, 7L), jacobi(100L % 7L, 7L))
  @debug.assert_eq(jacobi(1000000L, 13L), jacobi(1000000L % 13L, 13L))
}

///|
test "jacobi invalid n returns 0" {
  // n must be positive odd.
  @debug.assert_eq(jacobi(3L, 4L), 0)
  @debug.assert_eq(jacobi(3L, 0L), 0)
  @debug.assert_eq(jacobi(3L, -7L), 0)
}

///|
test "jacobi large modulus" {
  // (3 / 1009) for prime 1009. By Euler: 3^504 mod 1009 = ?
  let j = jacobi(3L, 1009L)
  // 1009 mod 12 = 1, so (3/1009) = +1 (by reciprocity: 3 is QR mod p
  // iff p ≡ ±1 mod 12).
  @debug.assert_eq(j, 1)
}

///|
test "jacobi multiplicativity numerator" {
  // (a*b / n) = (a/n) * (b/n).
  let n = 21L
  for a in 1L..<20L {
    for b in 1L..<20L {
      let jab = jacobi(a * b, n)
      let ja = jacobi(a, n)
      let jb = jacobi(b, n)
      @debug.assert_eq(jab, ja * jb)
    }
  }
}
