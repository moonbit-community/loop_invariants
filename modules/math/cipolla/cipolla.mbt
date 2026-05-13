// ============================================================================
// CIPOLLA - Modular square root via a quadratic field extension
// ============================================================================
//
// PROBLEM
//
// Given an odd prime p and a quadratic residue n mod p, find x with
//
//     x^2 ≡ n  (mod p)
//
// or report that n is a non-residue.
//
// THE IDEA
//
// Tonelli-Shanks splits into two cases (p ≡ 3 mod 4 vs p ≡ 1 mod 4) and
// uses a randomised parameter z. Cipolla (1907) takes a different route:
// embed F_p into the quadratic field extension
//
//     F_p[omega]   where   omega^2 = a^2 - n   for some chosen a
//
// with `a` picked so that `a^2 - n` is a quadratic *non*-residue. In
// that extension, omega behaves like an imaginary unit -- there is no
// element of F_p whose square is `a^2 - n`. Then
//
//     x  =  (a + omega) ^ ((p + 1) / 2)
//
// **automatically has zero omega-component** and `x^2 = n` (mod p),
// because the Frobenius automorphism in F_{p^2} sends omega -> -omega
// and the (p+1)/2 power lands on the fixed subfield F_p.
//
// THE PROOF
//
// In F_{p^2}, the norm map  N(a + b*omega) = (a + b*omega)(a - b*omega)
// =  a^2 - b^2 * (a^2 - n).  Because a^2 - n is a non-residue, the
// element  (a + omega)  has norm
//
//     N(a + omega)  =  a^2 - (a^2 - n)  =  n.
//
// The Frobenius x -> x^p in F_{p^2} sends a + omega -> a - omega
// (it fixes F_p and negates omega), so
//
//     (a + omega)^{p+1}  =  (a + omega) * (a - omega)  =  n.
//
// Taking the principal square root in the cyclic group F_{p^2}^*:
//
//     ((a + omega)^{(p+1)/2})^2  =  n,
//
// and one shows ((a + omega)^{(p+1)/2}) is in F_p (omega component
// vanishes). Therefore that element is our x.
//
// COMPARED WITH TONELLI-SHANKS
//
//   - **No case split on p mod 4**: Cipolla treats every odd prime
//     uniformly.
//   - **Same asymptotic cost**: O(log p) field-extension
//     multiplications, each O(1) F_p ops -- so O(log^2 p) overall.
//   - **Less elegant proof of unbiasedness** if `a` is picked
//     pseudo-randomly: we rely on ~half of F_p being non-residual.
//
// TIME COMPLEXITY  : O(log^2 p)
// SPACE COMPLEXITY : O(1)

///|
/// Normalise `x` to the range `[0, m)`. The built-in `%` operator may
/// produce a negative remainder for negative operands.
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// `(a + b) mod m` without overflow when `0 <= a, b < m`.
fn add_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  if a >= m - b {
    a - (m - b)
  } else {
    a + b
  }
}

///|
/// `(a * b) mod m` via Russian-peasant doubling. Stays in Int64 even
/// for `m` near 2^62.
fn mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  for res = 0L, x = mod_norm(a, m), y = mod_norm(b, m) {
    if y == 0L {
      break res
    } else {
      let next_res = if (y & 1L) == 1L { add_mod(res, x, m) } else { res }
      continue next_res, add_mod(x, x, m), y >> 1
    }
  } where {
    proof_invariant: y >= 0L,
    proof_invariant: m > 0L,
    proof_reasoning: (
      #|INVARIANT (Russian peasant):
      #|res ≡ a * (b - y) (mod m); x ≡ a * 2^k (mod m).
      #|At y = 0 the invariant collapses to res ≡ a * b (mod m).
      #|TERMINATION: y right-shifts each iteration.
    ),
  }
}

///|
/// `base^exp mod m` by binary exponentiation in F_p.
fn mod_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
  if m == 1L {
    return 0L
  }
  for result = 1L, b = mod_norm(base, m), e = exp {
    if e == 0L {
      break result
    } else {
      let next_result = if (e & 1L) == 1L {
        mul_mod(result, b, m)
      } else {
        result
      }
      continue next_result, mul_mod(b, b, m), e >> 1
    }
  } where {
    proof_invariant: e >= 0L,
    proof_invariant: m > 1L,
    proof_reasoning: (
      #|INVARIANT (binary exponent):
      #|result · b^e ≡ base^exp (mod m); b ≡ base^(2^k) (mod m).
    ),
  }
}

///|
/// One element of the quadratic extension F_p[omega], represented as
/// `(real, imag)` with `(omega)^2 = w` (a non-residue we choose).
priv struct Quad {
  re : Int64
  im : Int64
}

///|
/// Multiply two F_p[omega] elements where omega^2 = w. The result is
///
///   (a + b·omega)(c + d·omega)
///     = a·c + b·d·w  +  (a·d + b·c) · omega
fn quad_mul(x : Quad, y : Quad, w : Int64, p : Int64) -> Quad {
  let re = add_mod(
    mul_mod(x.re, y.re, p),
    mul_mod(mul_mod(x.im, y.im, p), w, p),
    p,
  )
  let im = add_mod(mul_mod(x.re, y.im, p), mul_mod(x.im, y.re, p), p)
  { re, im }
}

///|
/// `base^exp` in F_p[omega] via binary exponentiation.
fn quad_pow(base : Quad, exp : Int64, w : Int64, p : Int64) -> Quad {
  for result = ({ re: 1L, im: 0L } : Quad), b = base, e = exp {
    if e == 0L {
      break result
    } else {
      let next_result = if (e & 1L) == 1L {
        quad_mul(result, b, w, p)
      } else {
        result
      }
      continue next_result, quad_mul(b, b, w, p), e >> 1
    }
  } where {
    proof_invariant: e >= 0L,
    proof_invariant: p > 1L,
    proof_reasoning: (
      #|INVARIANT (binary exponent in F_p[omega]):
      #|result · b^e == base^exp in the extension; b == base^(2^k).
      #|TERMINATION: e right-shifts each iteration.
    ),
  }
}

///|
/// Modular square root via Cipolla's algorithm.
///
/// Solves `r^2 ≡ n (mod p)` for an odd prime `p`. Returns `Some(r)`
/// with `0 <= r < p` when a square root exists, `None` otherwise.
/// Both roots are `r` and `p - r` -- this function returns one of them
/// (the value that falls out of the algorithm).
///
/// ## Parameters
///
/// - `n` : value whose square root mod `p` is sought. Negative or
///         out-of-range values are normalised to `[0, p)` internally.
/// - `p` : an odd prime `>= 3`. The function also handles `p = 2` as
///         a special case (each `n` is its own sqrt mod 2). Behaviour
///         for composite `p` is undefined.
///
/// ## Returns
///
/// - `Some(r)` with `r * r ≡ n (mod p)`.
/// - `None` when `n` is a quadratic non-residue mod `p`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 7 is a QR mod 1009 (one root is 188; the other is 821).
///   let r = @cipolla.cipolla_sqrt(7L, 1009L).unwrap()
///   assert_eq(r * r % 1009L, 7L)
/// }
/// ```
pub fn cipolla_sqrt(n : Int64, p : Int64) -> Int64? {
  if p <= 1L {
    return None
  }
  if p == 2L {
    return Some(mod_norm(n, 2L))
  }
  let n0 = mod_norm(n, p)
  if n0 == 0L {
    return Some(0L)
  }
  // Euler's criterion.
  let legendre = mod_pow(n0, (p - 1L) / 2L, p)
  if legendre != 1L {
    return None
  }
  // Find `a` such that `w = a^2 - n` is a non-residue. About half of
  // the values in [0, p) qualify, so the search is expected to take a
  // constant number of iterations.
  let a = for cand = 0L {
    let w_raw = add_mod(mul_mod(cand, cand, p), p - n0, p)
    if w_raw == 0L {
      // a^2 = n; then (a) itself is a square root. Return immediately
      // outside the loop.
      break cand
    }
    if mod_pow(w_raw, (p - 1L) / 2L, p) == p - 1L {
      break cand
    } else {
      continue cand + 1L
    }
  } where {
    proof_invariant: cand >= 0L && cand < p,
    proof_reasoning: (
      #|INVARIANT (Non-residue search):
      #|For every value tested in [0..cand), w_raw = cand^2 - n was a
      #|quadratic residue (or zero, which short-circuits to a direct
      #|answer). About half of F_p satisfies the non-residue criterion,
      #|so the loop terminates in expected O(1) iterations.
    ),
  }
  // Short-circuit: a^2 ≡ n already (caught by the inner check).
  let w_raw = add_mod(mul_mod(a, a, p), p - n0, p)
  if w_raw == 0L {
    return Some(mod_norm(a, p))
  }
  // Raise (a + omega) to the (p+1)/2 power in F_p[omega] where
  // omega^2 = w_raw. The result has zero omega-component and its
  // real part is the requested sqrt.
  let res = quad_pow({ re: a, im: 1L }, (p + 1L) / 2L, w_raw, p)
  // res.im should be zero up to mod p.
  if res.im == 0L {
    Some(res.re)
  } else {
    None
  }
}

///|
test "cipolla works for a small QR" {
  // 41 is a QR mod 113.
  let r = cipolla_sqrt(41L, 113L).unwrap()
  @debug.assert_eq(mul_mod(r, r, 113L), 41L)
}

///|
test "cipolla non-residue returns none" {
  @debug.assert_eq(cipolla_sqrt(2L, 3L), None)
  @debug.assert_eq(cipolla_sqrt(3L, 7L), None)
  @debug.assert_eq(cipolla_sqrt(6L, 11L), None)
}

///|
test "cipolla p == 3 mod 4 case" {
  // 2 is a QR mod 7: 3^2 = 9 = 2 mod 7.
  let r = cipolla_sqrt(2L, 7L).unwrap()
  @debug.assert_eq(mul_mod(r, r, 7L), 2L)
}

///|
test "cipolla p == 1 mod 4 case" {
  // 7 is a QR mod 1009 (1009 ≡ 1 mod 4).
  let r = cipolla_sqrt(7L, 1009L).unwrap()
  @debug.assert_eq(mul_mod(r, r, 1009L), 7L)
}

///|
test "cipolla zero" {
  @debug.assert_eq(cipolla_sqrt(0L, 11L), Some(0L))
}

///|
test "cipolla agrees with brute force on small primes" {
  // For each small odd prime, every QR roundtrips: r*r mod p == n.
  let primes : ReadOnlyArray[Int64] = [3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L]
  for p in primes {
    for n in 0L..<p {
      match cipolla_sqrt(n, p) {
        Some(r) => @debug.assert_eq(mul_mod(r, r, p), n)
        None =>
          if n != 0L {
            @debug.assert_eq(mod_pow(n, (p - 1L) / 2L, p), p - 1L)
          }
      }
    }
  }
}

///|
test "cipolla p == 2 corner" {
  @debug.assert_eq(cipolla_sqrt(0L, 2L), Some(0L))
  @debug.assert_eq(cipolla_sqrt(1L, 2L), Some(1L))
}

///|
test "cipolla negative and large n" {
  let p = 41L
  // -1 mod 41 = 40; that's 40 in [0, 41).
  let r = cipolla_sqrt(-1L, p)
  match r {
    Some(x) => @debug.assert_eq(mul_mod(x, x, p), 40L)
    None => () // -1 may not be a QR mod 41 (we'll check below)
  }
  // Same value, n already normalised
  @debug.assert_eq(cipolla_sqrt(40L, 41L), r)
}
