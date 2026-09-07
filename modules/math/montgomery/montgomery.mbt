// ============================================================================
// MONTGOMERY MODULAR MULTIPLICATION  -  Montgomery 1985
// ============================================================================
//
// PROBLEM
//
// Modular multiplication `a * b mod n` is a hot inner loop in RSA,
// elliptic curves, and many other crypto / number-theory algorithms.
// The naive cost is one multiplication + one division. Division is
// significantly slower than multiplication on most hardware. Montgomery
// reduction replaces the costly modular reduction with a few cheap
// multiplications and one shift, *as long as* operands stay in
// Montgomery form.
//
// MONTGOMERY FORM
//
// Pick `R = 2^w` with `w` such that `R > n` (we use `R = 2^32` so the
// product `a*b` fits in 64 bits). The Montgomery representation of `a`
// is `aR mod n`. Multiplication of two Montgomery values is
//
//   redc(aR * bR) = (aR)(bR) / R  mod n  =  (ab)R  mod n
//
// which is again in Montgomery form. The `redc(x)` operation is:
//
//   m   = (x * n_inv_mod_R) mod R
//   t   = (x + m * n) / R
//   if t >= n: t -= n
//   return t
//
// `n_inv_mod_R = -n^{-1} mod R` is precomputed once. The key trick is
// that division by `R` is now a *shift*, not a real division.
//
// COMPLEXITY
//
//   precompute(n) : O(log n)
//   redc / mul / pow : O(log exp)  (pow uses square-and-multiply on
//                                    Montgomery-form values)
//
// THE INVARIANT
//
// All operations on a `MontgomeryCtx` preserve the relation
//   represent(x) = x * R mod n.
// `redc(a * b)` produces the representative of `a*b mod n` from the
// representatives of `a` and `b`.

///|
/// Precomputed context for modular arithmetic with modulus `n`.
pub struct MontgomeryCtx {
  n : Int64 // the odd modulus
  r2 : Int64 // R^2 mod n, used to convert into Montgomery form
  n_inv : Int64 // -n^{-1} mod R, with R = 2^32
}

///|
const R_BITS : Int = 32

///|
const R_MASK : Int64 = 4294967295L // 2^32 - 1

///|
/// Build a Montgomery context for a positive odd modulus `n` that fits
/// in 32 bits. Requires `n < 2^31` so that `n + m * n` cannot overflow
/// Int64. Returns `None` if `n` is invalid.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   match @montgomery.new(1000000007L) {
///     Some(ctx) => @debug.assert_eq(ctx.mul_mod(3L, 5L), 15L)
///     None => @debug.assert_eq(true, false)
///   }
/// }
/// ```
pub fn new(n : Int64) -> MontgomeryCtx? {
  if n <= 1L || (n & 1L) == 0L || n >= 2147483648L {
    return None
  }
  // n_inv = -n^{-1} mod 2^32. Use Newton's iteration on 2-adics.
  let mut inv = 1L
  for _ in 0..<5 {
    inv = (inv * (2L - n * inv)) & R_MASK
  }
  let n_inv = -inv & R_MASK
  // R^2 mod n.
  let r_mod = (1L << R_BITS) % n
  let r2 = r_mod * r_mod % n
  Some({ n, r2, n_inv, })
}

///|
/// Montgomery reduction: given `x < n * 2^32`, returns `x * R^{-1} mod n`.
fn MontgomeryCtx::redc(self : MontgomeryCtx, x : Int64) -> Int64 {
  let m = ((x & R_MASK) * self.n_inv) & R_MASK
  let mut t = (x + m * self.n) >> R_BITS
  if t >= self.n {
    t = t - self.n
  }
  t
}

///|
/// Convert `a` from ordinary representation (`0 <= a < n`) to Montgomery
/// form (`aR mod n`).
pub fn MontgomeryCtx::to_mont(self : MontgomeryCtx, a : Int64) -> Int64 {
  self.redc(a * self.r2)
}

///|
/// Convert from Montgomery form back to ordinary representation.
pub fn MontgomeryCtx::from_mont(self : MontgomeryCtx, a_mont : Int64) -> Int64 {
  self.redc(a_mont)
}

///|
/// Multiply two values **already in Montgomery form** and return the
/// result in Montgomery form.
pub fn MontgomeryCtx::mul_mont(
  self : MontgomeryCtx,
  a : Int64,
  b : Int64,
) -> Int64 {
  self.redc(a * b)
}

///|
/// Convenience: multiply two values in **ordinary representation**;
/// returns the ordinary result `a * b mod n`.
pub fn MontgomeryCtx::mul_mod(
  self : MontgomeryCtx,
  a : Int64,
  b : Int64,
) -> Int64 {
  let am = self.to_mont(a)
  let bm = self.to_mont(b)
  self.from_mont(self.mul_mont(am, bm))
}

///|
/// Modular exponentiation `base^exp mod n` using Montgomery
/// multiplication inside the square-and-multiply loop.
pub fn MontgomeryCtx::pow_mod(
  self : MontgomeryCtx,
  base : Int64,
  exp : Int64,
) -> Int64 {
  if self.n == 1L {
    return 0L
  }
  if exp < 0L {
    return 0L
  }
  let one_mont = self.to_mont(1L)
  let mut result = one_mont
  let mut b = self.to_mont(base % self.n)
  let mut e = exp
  while e > 0L {
    if (e & 1L) == 1L {
      result = self.mul_mont(result, b)
    }
    b = self.mul_mont(b, b)
    e = e >> 1
  }
  self.from_mont(result)
}

///|
test "montgomery new rejects bad moduli" {
  match new(0L) {
    None => ()
    _ => @debug.assert_eq(true, false)
  }
  match new(1L) {
    None => ()
    _ => @debug.assert_eq(true, false)
  }
  match new(2L) {
    None => ()
    _ => @debug.assert_eq(true, false)
  }
  match new(-7L) {
    None => ()
    _ => @debug.assert_eq(true, false)
  }
  // 2^31 is too large.
  match new(2147483648L) {
    None => ()
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "montgomery basic multiply" {
  let n = 1000000007L
  match new(n) {
    None => @debug.assert_eq(true, false)
    Some(ctx) => {
      @debug.assert_eq(ctx.mul_mod(3L, 5L), 15L)
      @debug.assert_eq(
        ctx.mul_mod(123456789L, 987654321L),
        123456789L * 987654321L % n,
      )
    }
  }
}

///|
test "montgomery roundtrip identity" {
  // to_mont then from_mont is the identity for any 0 <= a < n.
  let n = 65537L
  match new(n) {
    None => @debug.assert_eq(true, false)
    Some(ctx) =>
      for a in 0L..<100L {
        @debug.assert_eq(ctx.from_mont(ctx.to_mont(a)), a)
      }
  }
}

///|
test "montgomery pow matches naive" {
  fn naive_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
    let mut b = base % m
    let mut e = exp
    let mut r = 1L
    while e > 0L {
      if (e & 1L) == 1L {
        r = r * b % m
      }
      b = b * b % m
      e = e >> 1
    }
    r
  }

  let n = 1000000007L
  match new(n) {
    None => @debug.assert_eq(true, false)
    Some(ctx) => {
      // Fermat's little theorem: a^(n-1) ≡ 1 (mod n) for prime n.
      @debug.assert_eq(ctx.pow_mod(2L, n - 1L), 1L)
      @debug.assert_eq(ctx.pow_mod(3L, n - 1L), 1L)
      // Random spot checks vs naive.
      let pairs : ReadOnlyArray[(Int64, Int64)] = [
        (2L, 10L),
        (3L, 100L),
        (123L, 1000L),
        (5L, 1000000L),
      ]
      for p in pairs {
        @debug.assert_eq(ctx.pow_mod(p.0, p.1), naive_pow(p.0, p.1, n))
      }
    }
  }
}

///|
test "montgomery agrees with plain mod on many products" {
  let n = 998244353L
  match new(n) {
    None => @debug.assert_eq(true, false)
    Some(ctx) =>
      for a in [1L, 2L, 17L, 12345L, 99999999L, 500000000L, 998244352L] {
        for b in [3L, 19L, 5000L, 314159L, 998244351L] {
          @debug.assert_eq(ctx.mul_mod(a, b), a * b % n)
        }
      }
  }
}

///|
test "montgomery zero handling" {
  let n = 65521L
  match new(n) {
    None => @debug.assert_eq(true, false)
    Some(ctx) => {
      @debug.assert_eq(ctx.mul_mod(0L, 42L), 0L)
      @debug.assert_eq(ctx.mul_mod(42L, 0L), 0L)
      @debug.assert_eq(ctx.pow_mod(0L, 5L), 0L)
      @debug.assert_eq(ctx.pow_mod(5L, 0L), 1L)
    }
  }
}
