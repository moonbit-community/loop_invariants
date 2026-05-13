// ============================================================================
// TONELLI-SHANKS - Modular square root mod an odd prime
// ============================================================================
//
// Given an odd prime `p` and an integer `n`, compute `r` such that
//
//     r^2 ≡ n  (mod p)
//
// or report that no such `r` exists (i.e. `n` is a quadratic non-residue
// modulo `p`).
//
// EXISTENCE (Euler's criterion):
//   `n^((p-1)/2) mod p`  =  +1   if n is a quadratic residue
//                        =  p-1  if n is a non-residue
//                        =  0    iff n ≡ 0
//
// CASE p ≡ 3 (mod 4):
//   A closed form works:  r  =  n^((p+1)/4) mod p
//   Then r^2 = n^((p+1)/2) = n · n^((p-1)/2) = n · 1 = n  (mod p).
//
// CASE p ≡ 1 (mod 4):
//   Write p - 1 = Q · 2^S with Q odd. The Tonelli-Shanks loop maintains
//
//     (M, c, t, R)   such that   R^2 ≡ t · n  (mod p),
//                                ord(t) | 2^M,
//                                c is a primitive 2^M-th root of unity.
//
//   The loop reduces the order of t by at least one power of two per
//   iteration until t = 1, at which point R^2 ≡ n.
//
// TIME COMPLEXITY : O(log^2 p)   -- dominated by mod-pow on each iteration
// SPACE COMPLEXITY: O(1)         -- just a constant number of Int64 slots

///|
/// Normalize `x` to the range `[0, m)`. The built-in `%` operator may
/// produce a negative remainder for negative operands; the rest of this
/// file requires non-negative residues.
fn mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// `(a + b) mod m` without intermediate overflow. Requires
/// `0 <= a < m` and `0 <= b < m`.
fn add_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  if a >= m - b {
    a - (m - b)
  } else {
    a + b
  }
}

///|
/// `(a * b) mod m` via Russian-peasant doubling. Each iteration halves
/// `y`, so it runs in O(log b) time. Both `add_mod` and the doubling step
/// stay within `Int64`.
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
      #|  res  ≡  a * (b - y)  (mod m)   when reaching the top of the loop
      #|  x    ≡  a * 2^k      (mod m)   where k is the bit position
      #|At y = 0 the invariant gives res ≡ a * b (mod m).
      #|TERMINATION:
      #|  y strictly decreases (it is right-shifted each iteration); the
      #|  loop exits when the last 1-bit is consumed.
    ),
  }
}

///|
/// `base^exp mod m` by binary exponentiation. Returns 1 when `exp` is 0,
/// even for `m == 1`; callers should treat that as a degenerate value.
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
      #|  result · b^e  ≡  base^exp  (mod m)
      #|  b             ≡  base^(2^k)  (mod m)  where k is the current bit index
      #|MAINTENANCE:
      #|  If the low bit of e is set, fold the current b into result; then
      #|  square b and shift e. Both operations preserve the invariant.
      #|TERMINATION:
      #|  e is right-shifted each iteration and the loop exits when e == 0.
    ),
  }
}

///|
/// Modular square root via the Tonelli-Shanks algorithm.
///
/// Solves `r^2 ≡ n  (mod p)` for an *odd prime* `p`. The function returns
/// `Some(r)` with `0 <= r < p` when a solution exists, and `None`
/// otherwise. Note `-r mod p` is the other root; this function returns
/// the canonical one in `[0, p)`.
///
/// ## Parameters
///
/// - `n` : the value whose square root mod `p` is sought. May be negative
///         or `>= p`; it is normalised to `[0, p)` internally.
/// - `p` : an odd prime modulus, `p >= 3`. The function also handles
///         `p = 2` as a special case (every `n` is its own square root
///         modulo 2). Behaviour for composite `p` is undefined.
///
/// ## Returns
///
/// - `Some(r)` such that `(r * r) mod p == ((n mod p + p) mod p)`.
/// - `None` when `n` (mod p) is a quadratic non-residue.
///
/// ## Examples
///
/// ```moonbit nocheck
/// test {
///   // 41 is a quadratic residue mod 113; one root is 51 (and 113-51=62).
///   assert_eq(@tonelli_shanks.tonelli_shanks(41L, 113L), Some(51L))
///   // 2 is not a quadratic residue mod 3.
///   assert_eq(@tonelli_shanks.tonelli_shanks(2L, 3L), None)
/// }
/// ```
///
/// ## Complexity
///
/// O(log^2 p) time and O(1) space, dominated by the `mod_pow` calls in
/// the main loop. The non-residue search at the start is constant on
/// average (probability one half per trial).
pub fn tonelli_shanks(n : Int64, p : Int64) -> Int64? {
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
  // Euler's criterion: n is a QR iff n^((p-1)/2) ≡ 1 (mod p).
  let legendre = mod_pow(n0, (p - 1L) / 2L, p)
  if legendre != 1L {
    return None
  }
  // Easy case: p ≡ 3 (mod 4) → r = n^((p+1)/4) mod p.
  if (p & 3L) == 3L {
    return Some(mod_pow(n0, (p + 1L) / 4L, p))
  }
  // General case. Factor p - 1 = q * 2^s with q odd.
  let (q, s) = factor_out_twos(p - 1L)
  // Find any quadratic non-residue z by linear search starting at 2.
  // 1 is always a residue, so we skip it; in practice z is found within
  // a handful of tries because half of [2, p-1] is non-residual.
  let z = find_nonresidue(p)
  // Initial state of the Tonelli-Shanks loop.
  let init_m = s
  let init_c = mod_pow(z, q, p)
  let init_t = mod_pow(n0, q, p)
  let init_r = mod_pow(n0, (q + 1L) / 2L, p)
  // Main loop. See the file-top header for the loop-invariant formulation.
  for m = init_m, c = init_c, t = init_t, r = init_r {
    if t == 1L {
      break Some(r)
    }
    // Find smallest i in (0, m) with t^(2^i) ≡ 1 (mod p).
    let i = least_order_witness(t, m, p)
    if i == m {
      // Should not happen when the input is a QR mod p; defensive return.
      break None
    }
    // Reduction step.
    let b = mod_pow(c, 1L << (m - i - 1L).to_int(), p)
    let b2 = mul_mod(b, b, p)
    continue i, b2, mul_mod(t, b2, p), mul_mod(r, b, p)
  } where {
    proof_invariant: m >= 0L && m <= s,
    proof_invariant: r >= 0L && r < p,
    proof_invariant: t >= 0L && t < p,
    proof_invariant: c >= 0L && c < p,
    proof_reasoning: (
      #|INVARIANT (Tonelli-Shanks main loop):
      #|  r^2  ≡  t · n  (mod p)
      #|  ord(t) divides 2^m   (i.e. t^(2^m) ≡ 1)
      #|  c is a primitive 2^m-th root of unity mod p
      #|
      #|MAINTENANCE:
      #|  When t ≠ 1, let i be the smallest positive integer with
      #|  t^(2^i) ≡ 1. Necessarily i < m. Define b = c^(2^(m-i-1)).
      #|  Then:
      #|    - b^2 has order 2^i (it is a primitive 2^i-th root of unity).
      #|    - (t · b^2)^(2^(i-1)) = t^(2^(i-1)) · b^(2^i) = (-1) · (-1) = 1,
      #|      so ord(t · b^2) | 2^(i-1) ≤ 2^i.
      #|    - (r · b)^2 = r^2 · b^2 ≡ t · n · b^2 ≡ (t · b^2) · n (mod p).
      #|  So the new tuple (i, b^2, t·b^2, r·b) preserves all three
      #|  invariants with a strictly smaller m.
      #|
      #|TERMINATION:
      #|  m strictly decreases each iteration, so the loop runs at most
      #|  s = v_2(p-1) times.
      #|
      #|CORRECTNESS AT EXIT (t == 1):
      #|  r^2 ≡ 1 · n ≡ n  (mod p), so r is the requested square root.
    ),
  }
}

///|
/// Factor `n = q * 2^s` with `q` odd. Requires `n > 0`.
fn factor_out_twos(n : Int64) -> (Int64, Int64) {
  for q = n, s = 0L {
    if (q & 1L) == 1L {
      break (q, s)
    } else {
      continue q >> 1, s + 1L
    }
  } where {
    proof_invariant: q > 0L,
    proof_invariant: s >= 0L,
    proof_reasoning: (
      #|INVARIANT:
      #|  q * 2^s == n (the original input)
      #|MAINTENANCE:
      #|  If q is even, halve q and increment s. q remains positive.
      #|TERMINATION:
      #|  q strictly decreases as long as it stays even; it is bounded
      #|  below by 1, so the loop exits in at most log2(n) iterations.
    ),
  }
}

///|
/// Find the smallest non-residue z in `[2, p-1]` by linear search.
/// Used inside `tonelli_shanks` for the p ≡ 1 (mod 4) branch. By
/// quadratic reciprocity exactly half of `[1, p-1]` is non-residual, so
/// this expected one or two iterations.
fn find_nonresidue(p : Int64) -> Int64 {
  for z = 2L {
    if mod_pow(z, (p - 1L) / 2L, p) == p - 1L {
      break z
    } else {
      continue z + 1L
    }
  } where {
    proof_invariant: z >= 2L && z < p,
    proof_reasoning: (
      #|INVARIANT:
      #|  All values in [2, z) are quadratic residues mod p.
      #|TERMINATION:
      #|  Half of [1, p-1] is non-residual (an elementary group-theory
      #|  fact about the squaring map on (Z/pZ)*), so the loop is
      #|  guaranteed to terminate well before exhausting the range. For
      #|  p ≡ 1 (mod 4) a non-residue exists in [2, p-1].
    ),
  }
}

///|
/// Return the smallest positive `i` such that `t^(2^i) ≡ 1 (mod p)`, or
/// `m` if no such `i < m` exists. Called from the Tonelli-Shanks main
/// loop with `t != 1`, so `i >= 1` in practice.
fn least_order_witness(t : Int64, m : Int64, p : Int64) -> Int64 {
  for power = mul_mod(t, t, p), i = 1L {
    if power == 1L {
      break i
    } else if i >= m {
      break i
    } else {
      continue mul_mod(power, power, p), i + 1L
    }
  } where {
    proof_invariant: i >= 1L,
    proof_invariant: power >= 0L && power < p,
    proof_reasoning: (
      #|INVARIANT (Order witness):
      #|  power == t^(2^i) mod p
      #|MAINTENANCE:
      #|  Square power and advance i; the new power is t^(2^(i+1)).
      #|TERMINATION:
      #|  Either power reaches 1 (we found the witness) or i reaches m
      #|  (defensive bound; only triggers when t has order exactly 2^m).
    ),
  }
}

///|
test "tonelli quadratic residue mod prime" {
  // 41 is a QR mod 113; check both roots square to 41 mod 113.
  let r1 = tonelli_shanks(41L, 113L).unwrap()
  @debug.assert_eq(mul_mod(r1, r1, 113L), 41L)
  let r2 = (113L - r1) % 113L
  @debug.assert_eq(mul_mod(r2, r2, 113L), 41L)
}

///|
test "tonelli closed-form case p == 3 mod 4" {
  // p = 7: sqrt(2) mod 7 = 3 (since 3*3 = 9 = 2 mod 7) or 4.
  let r = tonelli_shanks(2L, 7L).unwrap()
  @debug.assert_eq(mul_mod(r, r, 7L), 2L)
}

///|
test "tonelli non-residue returns none" {
  // 2 mod 3:  2^1 ≡ -1 mod 3 -> non-residue.
  @debug.assert_eq(tonelli_shanks(2L, 3L), None)
  // 3 mod 7:  3^3 = 27 ≡ -1 mod 7 -> non-residue.
  @debug.assert_eq(tonelli_shanks(3L, 7L), None)
  // 6 mod 11: 6^5 ≡ 10 ≡ -1 mod 11 -> non-residue.
  @debug.assert_eq(tonelli_shanks(6L, 11L), None)
}

///|
test "tonelli zero and one boundaries" {
  @debug.assert_eq(tonelli_shanks(0L, 11L), Some(0L))
  let r = tonelli_shanks(1L, 11L).unwrap()
  @debug.assert_eq(mul_mod(r, r, 11L), 1L)
}

///|
test "tonelli small prime sweep" {
  // For each small prime, every quadratic residue must round-trip.
  let primes : ReadOnlyArray[Int64] = [3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L]
  for p in primes {
    for n in 0L..<p {
      match tonelli_shanks(n, p) {
        Some(r) => @debug.assert_eq(mul_mod(r, r, p), n)
        None =>
          // Verify Euler's criterion: a non-residue has n^((p-1)/2) == p-1.
          if n != 0L {
            @debug.assert_eq(mod_pow(n, (p - 1L) / 2L, p), p - 1L)
          }
      }
    }
  }
}

///|
test "tonelli p == 2 special case" {
  @debug.assert_eq(tonelli_shanks(0L, 2L), Some(0L))
  @debug.assert_eq(tonelli_shanks(1L, 2L), Some(1L))
}

///|
test "tonelli larger prime p == 1 mod 4" {
  // 1009 is prime and 1009 ≡ 1 (mod 4), so the general loop runs.
  // 7 is a QR mod 1009 (one can check 7^504 ≡ 1 mod 1009).
  let p = 1009L
  let n = 7L
  let r = tonelli_shanks(n, p).unwrap()
  @debug.assert_eq(mul_mod(r, r, p), n)
}
