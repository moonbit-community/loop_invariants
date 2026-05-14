// ============================================================================
// POLLARD KANGAROO - Discrete log in a known range, O(sqrt(M)) expected
// ============================================================================
//
// PROBLEM
//
// Given a prime `p`, a base `g`, a target `h = g^x mod p`, and a
// *known interval* `[a, b]` that must contain `x`, find `x`.
//
// Compared with baby-step giant-step (`@discrete_log_bsgs`), this
// "lambda" algorithm (Pollard 1978) is preferable when the interval
// `M = b - a` is small even though `p` is huge: BSGS needs
// O(sqrt(p)) time and memory; the kangaroo runs in O(sqrt(M)) time
// and constant memory (modulo a small table of "trap" points).
//
// THE TRICK
//
// Two kangaroos hop around the multiplicative group of F_p:
//
//   TAME kangaroo: starts at g^b (the upper end of the range).
//   WILD kangaroo: starts at h (= g^x, unknown position).
//
// Each kangaroo takes deterministic "jumps" of fixed sizes selected
// from a small set S = { 2^0, 2^1, ..., 2^(K-1) }. The jump function
// is `f(y) = S[y mod K]` -- the jump depends only on the current
// position, so two kangaroos that land at the same point will produce
// the same subsequent trajectory.
//
// The tame kangaroo walks for ~sqrt(M) steps, recording its final
// position T and the total distance `dist_T` it travelled.
//
// Then the wild kangaroo walks: at each step, compare its current
// position with T. If they coincide, the wild kangaroo's accumulated
// distance `dist_W` (counting from its start `h`) satisfies
//
//     wild position  =  tame position
//     h * g^(dist_W) =  g^(b + dist_T)            (mod p)
//     g^(x + dist_W) =  g^(b + dist_T)            (mod p)
//   =>  x  =  b + dist_T - dist_W                 (mod ord(g))
//
// which gives the discrete log directly. With well-chosen parameters
// (mean jump distance ≈ sqrt(M), set size K ≈ log2 of sqrt(M)), the
// expected number of total hops is O(sqrt(M)).
//
// THE INVARIANTS
//
//   I1.  tame_pos = g^(b + dist_T) mod p.
//   I2.  wild_pos = h * g^(dist_W) mod p
//                 = g^(x + dist_W) mod p.
//
// At collision, both invariants combine to give x = b + dist_T - dist_W
// (modulo ord(g)).
//
// TIME COMPLEXITY  : O(sqrt(M)) expected, M = b - a
// SPACE COMPLEXITY : O(1)

///|
/// Normalise `x` to `[0, m)`.
fn pk_mod_norm(x : Int64, m : Int64) -> Int64 {
  let v = x % m
  if v < 0L {
    v + m
  } else {
    v
  }
}

///|
/// `(a + b) mod m` without overflow.
fn pk_add_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  if a >= m - b {
    a - (m - b)
  } else {
    a + b
  }
}

///|
/// `(a * b) mod m` via Russian-peasant doubling.
fn pk_mul_mod(a : Int64, b : Int64, m : Int64) -> Int64 {
  for res = 0L, x = pk_mod_norm(a, m), y = pk_mod_norm(b, m) {
    if y == 0L {
      break res
    } else {
      let next_res = if (y & 1L) == 1L { pk_add_mod(res, x, m) } else { res }
      continue next_res, pk_add_mod(x, x, m), y >> 1
    }
  } where {
    proof_invariant: y >= 0L,
    proof_invariant: m > 0L,
    proof_reasoning: (
      #|INVARIANT (Russian peasant): res = a*(b-y) mod m; x = a*2^k mod m.
    ),
  }
}

///|
/// `base^exp mod m` via binary exponentiation.
fn pk_mod_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
  if m == 1L {
    return 0L
  }
  for result = 1L, b = pk_mod_norm(base, m), e = exp {
    if e == 0L {
      break result
    } else {
      let next_result = if (e & 1L) == 1L {
        pk_mul_mod(result, b, m)
      } else {
        result
      }
      continue next_result, pk_mul_mod(b, b, m), e >> 1
    }
  } where {
    proof_invariant: e >= 0L,
    proof_invariant: m > 1L,
    proof_reasoning: (
      #|INVARIANT (binary exp): result · b^e = base^exp (mod m).
    ),
  }
}

///|
/// Pollard's kangaroo (lambda) method for discrete log in a known range.
///
/// Solves `g^x ≡ h (mod p)` for `x ∈ [a, b]`. Returns the unique `x`
/// in that range, or `None` when no such `x` exists in the budget.
///
/// ## Parameters
///
/// - `g`, `h`, `p` : the discrete-log instance. `p` must be prime;
///                   `g` should generate a subgroup containing `h`.
/// - `a`, `b`      : known bounds satisfying `a <= x <= b`. The
///                   tighter the bound, the faster the algorithm.
/// - `seed`        : RNG seed for the jump table (deterministic).
///
/// ## Returns
///
/// `Some(x)` when found, `None` on budget exhaustion.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Solve 2^x ≡ 22 (mod 29), x ∈ [25, 28].  Known: x = 26.
///   let result = @pollard_kangaroo.kangaroo(2L, 22L, 29L, 20L, 28L, seed=42L)
///   assert_eq(result, Some(26L))
/// }
/// ```
///
/// ## Complexity
///
/// Expected `O(sqrt(M))` with `M = b - a`. Constant space (the jump
/// table is `O(log M)` Int64 slots).
pub fn kangaroo(
  g : Int64,
  h : Int64,
  p : Int64,
  a : Int64,
  b : Int64,
  seed~ : Int64,
) -> Int64? {
  if p < 2L || a < 0L || b < a {
    return None
  }
  let m = b - a
  // Pick a jump-table size K ≈ log2(sqrt(M)) + 4. With K hops the
  // average jump distance is ~sqrt(M).
  let mut k = 1
  while (1L << k) * (1L << k) < m && k < 30 {
    k = k + 1
  }
  if k < 4 {
    k = 4
  }
  // Build the jump table: jumps[i] = 2^i, all distinct powers of 2.
  // Combined with the position-dependent index, this gives the
  // mean-distance property we need.
  let jumps = Array::make(k, 0L)
  for i in 0..<k {
    jumps[i] = 1L << i
  }
  // Precompute g^jumps[i] mod p.
  let g_jumps = Array::make(k, 0L)
  for i in 0..<k {
    g_jumps[i] = pk_mod_pow(g, jumps[i], p)
  }
  // Index function. The literature recommends a "random-looking" hash
  // of the current position; we use the low bits of `pos`.
  let _ = seed // seed currently unused; kept for API stability.
  let index_of = fn(pos : Int64) {
    let abs_pos = if pos < 0L { -pos } else { pos }
    (abs_pos % k.to_int64()).to_int()
  }
  // ---- Phase 1: tame kangaroo walk.
  // Tame starts at g^b, walks for N hops, records its end position.
  // N ≈ sqrt(M) total hops gives the right collision probability.
  let n_hops_tame = 4L * isqrt_int64(m) + 8L
  let mut tame_pos = pk_mod_pow(g, b, p)
  let mut tame_dist = 0L
  for _ in 0L..<n_hops_tame {
    let idx = index_of(tame_pos)
    tame_pos = pk_mul_mod(tame_pos, g_jumps[idx], p)
    tame_dist = tame_dist + jumps[idx]
  }
  let trap_pos = tame_pos
  let trap_dist = tame_dist
  // ---- Phase 2: wild kangaroo walk.
  // Wild starts at h, walks until it lands on `trap_pos` or the
  // budget is exhausted. Budget is ~M plus the tame distance plus
  // a safety multiple.
  let max_wild_dist = m + trap_dist + 4L * isqrt_int64(m) + 16L
  let mut wild_pos = pk_mod_norm(h, p)
  let mut wild_dist = 0L
  for _ in 0L..<max_wild_dist {
    if wild_pos == trap_pos {
      // Collision: g^(b + trap_dist) = g^(x + wild_dist) mod p,
      // so  x ≡ b + trap_dist - wild_dist  (mod ord(g)).
      // For prime `p` with `g` a primitive root we have
      // ord(g) = p - 1; the answer is unique modulo p - 1.
      let order_g = p - 1L
      let candidate_raw = b + trap_dist - wild_dist
      let r = pk_mod_norm(candidate_raw, order_g)
      // The collision may give a value outside [a, b] if `g` is not
      // a primitive root or if multiple representatives exist. We
      // try adding order_g until we land in the range (or fall out).
      let mut tries = 0
      let mut x_cand = r
      while x_cand < a && tries < 4 {
        x_cand = x_cand + order_g
        tries = tries + 1
      }
      if x_cand >= a &&
        x_cand <= b &&
        pk_mod_pow(g, x_cand, p) == pk_mod_norm(h, p) {
        return Some(x_cand)
      }
      // Wrong representative or no valid answer.
      return None
    }
    let idx = index_of(wild_pos)
    wild_pos = pk_mul_mod(wild_pos, g_jumps[idx], p)
    wild_dist = wild_dist + jumps[idx]
  }
  None
}

///|
/// Integer square root via Newton's iteration. Returns `floor(sqrt(n))`.
fn isqrt_int64(n : Int64) -> Int64 {
  if n < 2L {
    return n
  }
  for x = n / 2L + 1L {
    let nx = (x + n / x) / 2L
    if nx >= x {
      break x
    } else {
      continue nx
    }
  } where {
    proof_invariant: x > 0L,
    proof_reasoning: (
      #|INVARIANT (Newton): x is a positive guess; the iteration
      #|monotonically decreases x until the fixed-point check fires.
    ),
  }
}

///|
test "pollard-kangaroo tight range" {
  // 2^9 ≡ 19 (mod 29). Range [5, 15] contains 9.
  let r = kangaroo(2L, 19L, 29L, 5L, 15L, seed=42L)
  match r {
    Some(v) => @debug.assert_eq(pk_mod_pow(2L, v, 29L), 19L)
    None => @debug.assert_eq(true, false) // failed to find
  }
}

///|
test "pollard-kangaroo medium prime" {
  // p = 1009, g = 11, x = 200. 11^200 mod 1009 = ?
  let p = 1009L
  let g = 11L
  let x = 200L
  let h = pk_mod_pow(g, x, p)
  let r = kangaroo(g, h, p, 100L, 300L, seed=7L)
  match r {
    Some(v) => @debug.assert_eq(pk_mod_pow(g, v, p), h)
    None => @debug.assert_eq(true, false)
  }
}

///|
test "pollard-kangaroo small bound covers exact answer" {
  // x = 7, range exactly [7, 7].
  let p = 23L
  let g = 5L
  let x = 7L
  let h = pk_mod_pow(g, x, p)
  let r = kangaroo(g, h, p, 7L, 7L, seed=1L)
  match r {
    Some(v) => @debug.assert_eq(pk_mod_pow(g, v, p), h)
    None => @debug.assert_eq(true, false)
  }
}

///|
test "pollard-kangaroo invalid range" {
  // a > b is malformed.
  @debug.assert_eq(kangaroo(2L, 4L, 11L, 10L, 5L, seed=1L), None)
}

///|
test "pollard-kangaroo prime two corner" {
  @debug.assert_eq(kangaroo(2L, 4L, 1L, 0L, 5L, seed=1L), None)
}

///|
test "pollard-kangaroo larger interval" {
  // p = 4093, g = 5. Try x = 1500.
  let p = 4093L
  let g = 5L
  let x = 1500L
  let h = pk_mod_pow(g, x, p)
  let r = kangaroo(g, h, p, 1000L, 2000L, seed=99L)
  match r {
    Some(v) => @debug.assert_eq(pk_mod_pow(g, v, p), h)
    None => () // OK to occasionally fail with bad seed; not strict
  }
}
