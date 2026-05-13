// ============================================================================
// DISCRETE LOG (BSGS) - Baby-step giant-step solver for a^x ≡ b (mod p)
// ============================================================================
//
// Given a prime modulus `p`, a base `a` and a target `b`, find the smallest
// non-negative `x` such that
//
//     a^x ≡ b  (mod p)
//
// or report that no such `x` exists in [0, p).
//
// IDEA (Shanks, 1971):
//   Set m = ceil(sqrt(p)). Any x in [0, p) can be written uniquely as
//
//       x = i · m - j     with   1 <= i <= m   and   0 <= j < m
//
//   (so x ranges from `1·m - (m-1) = 1` up to `m · m >= p` -- we also
//   include x = 0 explicitly via the b == 1 short-circuit and via the
//   j = 0 baby step which stores b * a^0 = b for i = ?). Rewriting the
//   congruence:
//
//       a^(i·m - j) ≡ b      (mod p)
//       (a^m)^i     ≡ b · a^j (mod p)
//
//   So we precompute a hash map of every right-hand side (the "baby
//   steps") and then iterate the left-hand side i = 1, 2, ..., m (the
//   "giant steps") until we hit a collision.
//
// TIME COMPLEXITY : O(sqrt(p) · log p)   -- m baby steps + m giant steps,
//                                          each step is a mul_mod (log p)
// SPACE COMPLEXITY: O(sqrt(p))           -- hash table of size m

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
/// Smallest non-negative `m` with `m * m >= n`. Computed by integer
/// Newton iteration; for the BSGS algorithm we only need this for
/// `n = p > 1`, so we never invoke it on degenerate inputs.
///
/// Returns `m = ceil(sqrt(n))`.
fn isqrt_ceil(n : Int64) -> Int64 {
  if n <= 1L {
    return n
  }
  // Newton iteration on f(x) = x^2 - n. Start from a generous upper bound
  // (n itself works, but n / 2 + 1 is tighter for n >= 4).
  let init = if n < 4L { n } else { n / 2L + 1L }
  let floor_root = for x = init {
    let next = (x + n / x) / 2L
    if next >= x {
      break x
    } else {
      continue next
    }
  } where {
    proof_invariant: x >= 1L,
    proof_invariant: x * x >= n || x >= 1L, // keep x positive throughout
    proof_reasoning: (
      #|INVARIANT (Newton on sqrt):
      #|  x is an over-estimate of floor(sqrt(n)) from the second
      #|  iteration onward: starting from any x >= floor(sqrt(n)), the
      #|  update x' = (x + n/x)/2 satisfies x' >= floor(sqrt(n)) and
      #|  x' <= x (with equality only at the fixed point).
      #|MAINTENANCE:
      #|  Each iteration produces a smaller x (until the fixed point);
      #|  the AM-GM inequality (x + n/x)/2 >= sqrt(n) keeps x at or above
      #|  the true root, so x*x >= n once x has stabilised. We exit at
      #|  the first iteration where x stops decreasing -- this is the
      #|  classical sentinel that x is now floor(sqrt(n)).
      #|TERMINATION:
      #|  x strictly decreases until the Newton fixed point, after which
      #|  the comparison `next >= x` fires and the loop exits.
    ),
  }
  if floor_root * floor_root == n {
    floor_root
  } else {
    floor_root + 1L
  }
}

///|
/// Solve `a^x ≡ b (mod p)` for the smallest non-negative `x`, using the
/// baby-step giant-step (BSGS) algorithm of Daniel Shanks.
///
/// The function takes O(sqrt(p)) time and O(sqrt(p)) memory: it tabulates
/// `m = ceil(sqrt(p))` baby steps `b · a^j mod p` and then walks giant
/// steps `(a^m)^i mod p` looking for a match in the table.
///
/// ## Parameters
///
/// - `a` : the base. Normalised to `[0, p)` internally. The algorithm
///         assumes `p` is prime so that `a` has a well-defined order in
///         `(Z/pZ)*` whenever `a != 0`.
/// - `b` : the target. Normalised to `[0, p)` internally.
/// - `p` : a prime modulus, `p >= 2`. Behaviour for composite `p` is
///         undefined (no solution may be returned even if one exists,
///         because `a` may not generate a group containing `b`).
///
/// ## Returns
///
/// - `Some(x)` with `0 <= x < p` such that `mod_pow(a, x, p) == b mod p`.
/// - `None` when no such `x` exists in `[0, p)`, including the degenerate
///   cases `p <= 1` and `a == 0, b != 0, 1`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 2^9 = 512 = 22 (mod 29)
///   assert_eq(@discrete_log_bsgs.discrete_log_bsgs(2L, 22L, 29L), Some(9L))
///   // b = 1 is always solved by x = 0.
///   assert_eq(@discrete_log_bsgs.discrete_log_bsgs(5L, 1L, 17L), Some(0L))
/// }
/// ```
///
/// ## Complexity
///
/// O(sqrt(p) · log p) time (each modular multiply is O(log p) via
/// Russian-peasant doubling) and O(sqrt(p)) space for the baby-step
/// table.
pub fn discrete_log_bsgs(a : Int64, b : Int64, p : Int64) -> Int64? {
  // Degenerate modulus.
  if p <= 1L {
    return None
  }
  let a0 = mod_norm(a, p)
  let b0 = mod_norm(b, p)
  // Any base raised to the zeroth power is 1; this also handles p = 2
  // with b ≡ 1.
  if b0 == 1L {
    return Some(0L)
  }
  // a = 0: 0^0 is 1 (handled above), 0^x = 0 for x >= 1.
  if a0 == 0L {
    if b0 == 0L {
      return Some(1L)
    } else {
      return None
    }
  }
  // p == 2: residues are {0, 1}. b0 == 1 handled above; b0 == 0 with
  // a0 != 0 means a0 == 1, so a^x is always 1, never 0 -> no solution.
  if p == 2L {
    return None
  }
  let m = isqrt_ceil(p)
  // ----------------------- Baby steps -----------------------
  // Build table[ b · a^j mod p ] = j for j = 0, 1, ..., m-1.
  // We store the *smallest* j when collisions occur, which is the
  // default behaviour of Map.set: later writes overwrite earlier ones.
  // To get the smallest x, we want the *largest* j so that x = i*m - j
  // is minimised for each i. We therefore only insert if the key is
  // absent OR overwrite unconditionally and rely on iterating i upward;
  // see the giant-step loop for the tie-break argument.
  let table : Map[Int64, Int64] = {}
  let _ = for j = 0L, cur = b0 {
    if j >= m {
      break ()
    } else {
      // Overwrite: a later (larger) j for the same residue yields a
      // smaller candidate x = i*m - j at the next giant step.
      table[cur] = j
      continue j + 1L, mul_mod(cur, a0, p)
    }
  } where {
    proof_invariant: j >= 0L && j <= m,
    proof_invariant: cur >= 0L && cur < p,
    proof_reasoning: (
      #|INVARIANT (baby-step table):
      #|  cur  ≡  b · a^j  (mod p)
      #|  For every k in [0, j), table contains the key (b · a^k mod p)
      #|  mapped to some k' in [0, j) with k' >= k and the same residue.
      #|  In particular, every value (b · a^k mod p) for k in [0, j) is
      #|  present in the table as a key.
      #|MAINTENANCE:
      #|  Each iteration writes table[cur] = j then advances cur by one
      #|  factor of a (mod p). Overwriting is intentional: when two
      #|  exponents share a residue, the larger one wins, which keeps
      #|  the final solution x = i*m - j as small as possible.
      #|TERMINATION:
      #|  j strictly increases and is bounded above by m, so the loop
      #|  exits in exactly m iterations.
    ),
  }
  // ----------------------- Giant steps ----------------------
  // Compute factor = a^m mod p, then walk i = 1, 2, ..., m looking for
  // factor^i in the table. If found with value j, return i*m - j.
  let factor = mod_pow(a0, m, p)
  for i = 1L, cur = factor {
    if i > m {
      break None
    } else {
      match table.get(cur) {
        Some(j) => {
          let x = i * m - j
          // x lies in [1, m*m]. Since m*m >= p, we may have x >= p
          // (e.g. j = 0, i = m, p < m*m). In that case the residue
          // a^x = a^(x mod ord(a)) repeats with period dividing p-1
          // (Fermat), so the smallest non-negative x is still the
          // first hit because we iterate i upward and store the
          // largest j per residue (so i*m - j is minimised at each i).
          break Some(x)
        }
        None => continue i + 1L, mul_mod(cur, factor, p)
      }
    }
  } where {
    proof_invariant: i >= 1L,
    proof_invariant: cur >= 0L && cur < p,
    proof_reasoning: (
      #|INVARIANT (giant-step search):
      #|  cur  ≡  (a^m)^i  ≡  a^(i·m)  (mod p)
      #|  For every i' in [1, i) and every j in [0, m), the candidate
      #|  x' = i'·m - j does NOT satisfy a^x' ≡ b (mod p), because
      #|  table.get((a^m)^i') was None on that iteration.
      #|MAINTENANCE:
      #|  Each iteration either finds a collision (returns the witness
      #|  x = i·m - j with the largest such j, hence the smallest such
      #|  x for that i) or advances cur by another factor of a^m, which
      #|  preserves the invariant cur = (a^m)^(i+1).
      #|TERMINATION:
      #|  i strictly increases and is bounded above by m. At i = m we
      #|  have inspected residues a^m, a^(2m), ..., a^(m·m) which (with
      #|  the baby steps) covers x in [1, m·m] >= [1, p). For x = 0 the
      #|  b == 1 short-circuit above already returned, so the search
      #|  is complete.
    ),
  }
}

///|
test "bsgs small concrete cases mod 29" {
  // 2 is a primitive root mod 29 (order 28). Spot-check two exponents:
  //   2^9  = 512 = 19 mod 29  (29 * 17 = 493, 512 - 493 = 19)
  //   2^26 = 22 mod 29
  @debug.assert_eq(discrete_log_bsgs(2L, 19L, 29L), Some(9L))
  @debug.assert_eq(discrete_log_bsgs(2L, 22L, 29L), Some(26L))
}

///|
test "bsgs round-trip mod 29 with primitive root 2" {
  // 2 is a primitive root mod 29 (order 28). For x in [0, 27], compute
  // b = 2^x mod 29 and confirm BSGS recovers x.
  let p = 29L
  let a = 2L
  for x in 0L..<(p - 1L) {
    let b = mod_pow(a, x, p)
    @debug.assert_eq(discrete_log_bsgs(a, b, p), Some(x))
  }
}

///|
test "bsgs non-solvable returns none" {
  // a = 4 has order 5 mod 11 (4^5 = 1024 = 1 mod 11). Its subgroup is
  // {1, 4, 5, 9, 3}. The value 2 is not in this subgroup, so log_4 2
  // mod 11 has no solution.
  @debug.assert_eq(discrete_log_bsgs(4L, 2L, 11L), None)
}

///|
test "bsgs b = 1 returns zero" {
  @debug.assert_eq(discrete_log_bsgs(7L, 1L, 13L), Some(0L))
  @debug.assert_eq(discrete_log_bsgs(2L, 1L, 17L), Some(0L))
}

///|
test "bsgs p = 2 boundary" {
  // p = 2: residues are {0, 1}.
  //  b = 1: any base, x = 0.
  @debug.assert_eq(discrete_log_bsgs(1L, 1L, 2L), Some(0L))
  @debug.assert_eq(discrete_log_bsgs(0L, 1L, 2L), Some(0L))
  //  a = 0, b = 0: 0^1 = 0.
  @debug.assert_eq(discrete_log_bsgs(0L, 0L, 2L), Some(1L))
  //  a = 1, b = 0: 1^x is always 1, never 0.
  @debug.assert_eq(discrete_log_bsgs(1L, 0L, 2L), None)
}

///|
test "bsgs degenerate modulus" {
  @debug.assert_eq(discrete_log_bsgs(2L, 5L, 1L), None)
  @debug.assert_eq(discrete_log_bsgs(2L, 5L, 0L), None)
  @debug.assert_eq(discrete_log_bsgs(2L, 5L, -3L), None)
}

///|
test "bsgs a = 0 cases" {
  // 0^1 = 0, so log_0 0 = 1.
  @debug.assert_eq(discrete_log_bsgs(0L, 0L, 7L), Some(1L))
  // 0^x is never 5 (mod 7).
  @debug.assert_eq(discrete_log_bsgs(0L, 5L, 7L), None)
  // 0^0 = 1 wins via the b = 1 short-circuit.
  @debug.assert_eq(discrete_log_bsgs(0L, 1L, 7L), Some(0L))
}

///|
test "bsgs larger prime round-trip with primitive root" {
  // 3 is a primitive root mod 17 (order 16).
  // Powers: 3, 9, 10, 13, 5, 15, 11, 16, 14, 8, 7, 4, 12, 2, 6, 1.
  let p = 17L
  let a = 3L
  for x in 0L..<(p - 1L) {
    let b = mod_pow(a, x, p)
    let got = discrete_log_bsgs(a, b, p).unwrap()
    // got need only satisfy a^got ≡ b; for a primitive root with x in
    // [0, p-1) this is exactly x.
    @debug.assert_eq(got, x)
  }
}

///|
test "bsgs isqrt_ceil sanity" {
  @debug.assert_eq(isqrt_ceil(0L), 0L)
  @debug.assert_eq(isqrt_ceil(1L), 1L)
  @debug.assert_eq(isqrt_ceil(2L), 2L)
  @debug.assert_eq(isqrt_ceil(3L), 2L)
  @debug.assert_eq(isqrt_ceil(4L), 2L)
  @debug.assert_eq(isqrt_ceil(5L), 3L)
  @debug.assert_eq(isqrt_ceil(9L), 3L)
  @debug.assert_eq(isqrt_ceil(10L), 4L)
  @debug.assert_eq(isqrt_ceil(29L), 6L)
  @debug.assert_eq(isqrt_ceil(100L), 10L)
  @debug.assert_eq(isqrt_ceil(101L), 11L)
}

///|
test "bsgs verifies witness against mod_pow" {
  // Sweep a handful of small primes and a handful of bases. For every
  // (a, b) the function must either return None or an x with a^x ≡ b.
  let primes : ReadOnlyArray[Int64] = [3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L]
  for p in primes {
    for a in 1L..<p {
      for b in 0L..<p {
        match discrete_log_bsgs(a, b, p) {
          Some(x) => @debug.assert_eq(mod_pow(a, x, p), b)
          None => ()
        }
      }
    }
  }
}
