// ============================================================================
// STERN-BROCOT - Best rational approximation via the Stern-Brocot tree
// ============================================================================
//
// The Stern-Brocot tree is an infinite binary tree whose nodes are exactly
// the positive rationals in lowest terms, each appearing once. It is built
// by repeatedly taking *mediants* of bracketing rationals starting from the
// frontier (0/1, 1/0).
//
// MEDIANT:
//   mediant(a/b, c/d) = (a+c)/(b+d)
//
// At any node the current "bounds" are (a/b, c/d) with the invariant
//
//     a*d - b*c == -1                     (Farey neighbour property)
//
// which implies a/b < c/d strictly and the mediant (a+c)/(b+d) is in lowest
// terms and lies strictly between them. The left child uses bounds
// (a/b, mediant), the right child uses (mediant, c/d).
//
// COMPARING TARGET t = num/den TO THE MEDIANT (a+c)/(b+d):
//
//     sign(t - mediant)
//   = sign(num*(b+d) - den*(a+c))    (since den, b+d > 0)
//
// We descend LEFT if the sign is negative (target < mediant), RIGHT if
// positive, and STOP if zero (target equals the mediant).
//
// BEST APPROXIMATION WITH DENOMINATOR <= max_denom:
//   Walk down while the mediant's denominator b + d <= max_denom. The
//   answer is either the last valid mediant or one of the bounds
//   reachable inside the cap; we pick whichever minimises |t - p/q|.
//
// TIME COMPLEXITY : O(log max(num, den))   -- depth of the descent
// SPACE COMPLEXITY: O(1)                   -- four Int64s for bounds
// PATH FUNCTION   : returns an Array[Char] of length O(log max(num, den))

///|
/// Compute `gcd(a, b)` for non-negative `a` and `b` via the standard
/// Euclidean algorithm. Used to reduce the input fraction before walking
/// the tree.
fn gcd_i64(a : Int64, b : Int64) -> Int64 {
  for x = a, y = b {
    if y == 0L {
      break x
    } else {
      continue y, x % y
    }
  } where {
    proof_invariant: x >= 0L,
    proof_invariant: y >= 0L,
    proof_reasoning: (
      #|INVARIANT (Euclidean reduction):
      #|  gcd(x, y) == gcd(a, b) at every iteration.
      #|MAINTENANCE:
      #|  (x, y) -> (y, x mod y) preserves the gcd, because every common
      #|  divisor of x and y divides x mod y = x - (x/y)*y, and vice versa.
      #|TERMINATION:
      #|  y strictly decreases each iteration (the new y is `x mod y < y`)
      #|  and is bounded below by 0; the loop exits when y == 0, at which
      #|  point x holds the gcd.
    ),
  }
}

///|
/// Floored integer division for non-negative dividend and positive divisor.
/// Used only on values where the result is `>= 0`.
fn floor_div(num : Int64, den : Int64) -> Int64 {
  // Inputs into this helper are always non-negative numerator and
  // positive denominator, so the built-in `/` already truncates toward
  // zero and matches the floored value.
  num / den
}

///|
/// Find the rational `p/q` in lowest terms with `q <= max_denom` that best
/// approximates `target = num / den` (the closest such rational by absolute
/// difference). Returns `(p, q)`.
///
/// The walk uses the Stern-Brocot tree: starting from the frontier bounds
/// `(0/1, 1/0)`, repeatedly take mediants and descend toward the target.
/// Stop just before the mediant's denominator exceeds `max_denom`. The
/// returned rational is the closest of the last mediant, the left bound,
/// and the right bound (subject to the denominator cap).
///
/// ## Parameters
///
/// - `num` : numerator of the target. May be zero or negative; the result
///           inherits the sign of `num`.
/// - `den` : denominator of the target. Must be `> 0`. Behaviour for
///           `den <= 0` is unspecified.
/// - `max_denom` : maximum allowed denominator. Must be `>= 1`. If `1`
///           the result is `(floor or ceil)(num/den) / 1`, whichever is
///           closer (ties round toward zero).
///
/// ## Returns
///
/// A pair `(p, q)` in lowest terms with `1 <= q <= max_denom`, minimising
/// `|num/den - p/q|`. When the input already has `den <= max_denom`, the
/// returned rational is exactly `num/den` reduced.
///
/// ## Examples
///
/// ```moonbit nocheck
/// test {
///   // 22/7 itself fits, so the result is exact.
///   assert_eq(@stern_brocot.best_rational_approximation(22L, 7L, 7L), (22L, 7L))
///   // 355/113 ≈ π; best approximation with denominator <= 7 is 22/7.
///   assert_eq(
///     @stern_brocot.best_rational_approximation(355L, 113L, 7L),
///     (22L, 7L),
///   )
/// }
/// ```
///
/// ## Complexity
///
/// `O(log max(num, max_denom))` time and `O(1)` space.
pub fn best_rational_approximation(
  num : Int64,
  den : Int64,
  max_denom : Int64,
) -> (Int64, Int64) {
  // Reject malformed denominator caps; fall back to floor(num/den)/1.
  if max_denom < 1L {
    return (num / den, 1L)
  }
  // Handle the sign of `num` outside the tree walk: the Stern-Brocot tree
  // enumerates *positive* rationals. Zero is the left frontier 0/1.
  if num == 0L {
    return (0L, 1L)
  }
  let sign = if num < 0L { -1L } else { 1L }
  let abs_num = if num < 0L { -num } else { num }
  // Walk the tree with bounds (a/b, c/d) maintaining the Farey
  // determinant a*d - b*c == -1 and abs_num/den ∈ [a/b, c/d].
  //
  // Termination occurs when either the mediant equals the target or
  // the next mediant would exceed the denominator cap.
  let (p, q) = walk(abs_num, den, max_denom)
  (sign * p, q)
}

///|
/// Inner descent for `best_rational_approximation`. Takes a non-negative
/// numerator and returns the best `(p, q)` with `q <= max_denom`.
fn walk(num : Int64, den : Int64, max_denom : Int64) -> (Int64, Int64) {
  // Initial bounds: 0/1 on the left, 1/0 on the right. The first mediant
  // is 1/1.
  let init_a = 0L
  let init_b = 1L
  let init_c = 1L
  let init_d = 0L
  for a = init_a, b = init_b, c = init_c, d = init_d {
    let p = a + c
    let q = b + d
    // If the next mediant overshoots the cap, the descent is over.
    if q > max_denom {
      break choose_best(num, den, a, b, c, d, max_denom)
    }
    // Compare target num/den against mediant p/q via cross product.
    //   diff = num * q - den * p
    //   diff > 0  =>  target > mediant, descend right
    //   diff < 0  =>  target < mediant, descend left
    //   diff = 0  =>  target == mediant, done
    let diff = num * q - den * p
    if diff == 0L {
      break (p, q)
    } else if diff > 0L {
      // Descend right: new left bound is the mediant.
      continue p, q, c, d
    } else {
      // Descend left: new right bound is the mediant.
      continue a, b, p, q
    }
  } where {
    proof_invariant: b >= 0L && d >= 0L,
    proof_invariant: b + d >= 1L,
    proof_invariant: a * d - b * c == -1L,
    proof_reasoning: (
      #|INVARIANT (Stern-Brocot descent):
      #|  (I1) a/b <= target <= c/d   (with strict inequality once we have
      #|       descended at least once away from the 0/1, 1/0 frontier)
      #|  (I2) a*d - b*c == -1        (Farey neighbour property)
      #|  (I3) b + d > previous b + d (denominators strictly grow)
      #|
      #|MAINTENANCE:
      #|  Let m = (a+c)/(b+d). Compute sign s = sign(num*(b+d) - den*(a+c)).
      #|  - If s == 0, target == m and we return (a+c, b+d).
      #|  - If s > 0, target > m: new bounds (a+c)/(b+d), c/d.
      #|       The new determinant is (a+c)*d - (b+d)*c = a*d - b*c = -1
      #|       which preserves (I2).
      #|  - If s < 0, target < m: new bounds a/b, (a+c)/(b+d).
      #|       New determinant a*(b+d) - b*(a+c) = a*d - b*c = -1.
      #|  In both descent cases the sum of denominators strictly grows,
      #|  preserving (I3).
      #|
      #|TERMINATION:
      #|  Either (a) the mediant exactly equals the target (which must
      #|  happen because every positive rational appears at a finite
      #|  depth in the tree); or (b) b + d exceeds max_denom, at which
      #|  point we exit and pick the closest valid candidate.
      #|
      #|CORRECTNESS AT EXIT:
      #|  - Exact match: target == (a+c)/(b+d), reduced (by (I2)).
      #|  - Cap exit:    the closest p/q with q <= max_denom is one of
      #|      the bounds or the last valid mediant; `choose_best`
      #|      compares the three and returns the winner.
    ),
  }
}

///|
/// At the point of cap exit, return the rational with denominator
/// `<= max_denom` that minimises `|num/den - p/q|`. The candidates are the
/// two current bounds `a/b` and `c/d` and the *semiconvergent* obtained
/// by descending as far as possible in the same direction without
/// exceeding the cap.
fn choose_best(
  num : Int64,
  den : Int64,
  a : Int64,
  b : Int64,
  c : Int64,
  d : Int64,
  max_denom : Int64,
) -> (Int64, Int64) {
  // The next mediant (a+c)/(b+d) would exceed the cap. The best step we
  // can still take in either direction is to advance the closer bound by
  // some integer multiple k of the farther bound, where k is the largest
  // value such that the resulting denominator stays within the cap.
  //
  //   Right-descent step:  a/b -> (a + k*c)/(b + k*d)
  //   Left-descent  step:  c/d -> (k*a + c)/(k*b + d)
  //
  // We compute the "semiconvergent" appropriate to whichever side the
  // target lies on (determined by which bound is currently closer).
  let semi = semiconvergent(num, den, a, b, c, d, max_denom)
  // Among (a, b), (c, d), semi, return whichever minimises the distance
  // |num*q - den*p|/q. We compare by |num*q - den*p| * other_q to avoid
  // floating-point and division.
  let candidates = [(a, b), (c, d), semi]
  let mut best_p = a
  let mut best_q = b
  let mut have_best = false
  for cand in candidates {
    let (p, q) = cand
    if q < 1L || q > max_denom {
      continue
    }
    if !have_best {
      best_p = p
      best_q = q
      have_best = true
    } else if closer(num, den, p, q, best_p, best_q) {
      best_p = p
      best_q = q
    }
  }
  (best_p, best_q)
}

///|
/// Return `true` when `p1/q1` is strictly closer to `num/den` than
/// `p2/q2`. Uses only integer arithmetic. Assumes all denominators are
/// positive.
fn closer(
  num : Int64,
  den : Int64,
  p1 : Int64,
  q1 : Int64,
  p2 : Int64,
  q2 : Int64,
) -> Bool {
  // |num/den - p1/q1| < |num/den - p2/q2|
  // |num*q1 - den*p1| * q2 < |num*q2 - den*p2| * q1
  let d1 = abs_i64(num * q1 - den * p1) * q2
  let d2 = abs_i64(num * q2 - den * p2) * q1
  d1 < d2
}

///|
/// Absolute value for `Int64`.
fn abs_i64(x : Int64) -> Int64 {
  if x < 0L {
    -x
  } else {
    x
  }
}

///|
/// Compute the semiconvergent from the current bounds. The semiconvergent
/// is the largest descent in a single direction that keeps the
/// denominator within `max_denom`. It coincides with the convergent in
/// the standard continued-fraction sense.
fn semiconvergent(
  num : Int64,
  den : Int64,
  a : Int64,
  b : Int64,
  c : Int64,
  d : Int64,
  max_denom : Int64,
) -> (Int64, Int64) {
  // Decide which side to step on by comparing target to the next mediant.
  // diff = num*(b+d) - den*(a+c)
  let diff = num * (b + d) - den * (a + c)
  if diff >= 0L {
    // Target lies on the right of the mediant; step right from (a, b) as
    // far as possible. Largest k with b + k*d <= max_denom is
    // k_max = (max_denom - b) / d  (when d > 0).
    if d == 0L {
      // Right frontier (1/0); no semiconvergent in this direction.
      (a, b)
    } else {
      let k = floor_div(max_denom - b, d)
      (a + k * c, b + k * d)
    }
    // Target lies on the left of the mediant; step left from (c, d).
  } else if b == 0L {
    // Left frontier (0/1); no semiconvergent in this direction.
    (c, d)
  } else {
    let k = floor_div(max_denom - d, b)
    (k * a + c, k * b + d)
  }
}

///|
/// Walk the Stern-Brocot tree to the exact rational `num/den` (reduced to
/// lowest terms), returning the sequence of `'L'` / `'R'` moves taken.
///
/// The walk starts at the root mediant `1/1` (between bounds `0/1` and
/// `1/0`). Each step compares the current mediant to the target via the
/// sign of `num*(b+d) - den*(a+c)`. Returns an empty array when the
/// reduced fraction is `0/1` (left frontier) or `1/0` (right frontier),
/// neither of which is an interior node of the tree.
///
/// ## Parameters
///
/// - `num` : numerator of the target. Must be non-negative; the function
///           operates on positive rationals (the tree's domain).
/// - `den` : denominator of the target. Must be non-negative. `den == 0`
///           is treated as the right frontier `1/0`.
///
/// ## Returns
///
/// `Array[Char]` of `'L'` and `'R'` characters; the empty array when the
/// reduced input is on a frontier (`0/1` or `1/0`).
///
/// ## Examples
///
/// ```moonbit nocheck
/// test {
///   // 1/2 is the left child of 1/1, so the path is a single 'L'.
///   assert_eq(@stern_brocot.stern_brocot_path(1L, 2L), ['L'])
///   // 2/3 = mediant of 1/2 and 1/1, reached by L then R.
///   assert_eq(@stern_brocot.stern_brocot_path(2L, 3L), ['L', 'R'])
/// }
/// ```
///
/// ## Complexity
///
/// `O(log max(num, den))` time and space; the path length is at most the
/// sum of the partial quotients of the continued-fraction expansion of
/// `num/den`.
pub fn stern_brocot_path(num : Int64, den : Int64) -> Array[Char] {
  let path : Array[Char] = []
  // Frontier inputs have no interior path.
  if num == 0L && den == 1L {
    return path
  }
  if num == 1L && den == 0L {
    return path
  }
  // Reduce to lowest terms. The path is the same for n/d and any common
  // multiple, but the descent equality test uses the reduced form.
  if num <= 0L || den <= 0L {
    return path
  }
  let g = gcd_i64(num, den)
  let rnum = num / g
  let rden = den / g
  // Walk down with bounds (a/b, c/d). On each step compute the mediant
  // and compare to the reduced target.
  for a = 0L, b = 1L, c = 1L, d = 0L {
    let p = a + c
    let q = b + d
    let diff = rnum * q - rden * p
    if diff == 0L {
      break path
    } else if diff > 0L {
      // Target > mediant; record 'R' and descend right.
      path.push('R')
      continue p, q, c, d
    } else {
      // Target < mediant; record 'L' and descend left.
      path.push('L')
      continue a, b, p, q
    }
  } where {
    proof_invariant: b >= 0L && d >= 0L,
    proof_invariant: b + d >= 1L,
    proof_invariant: a * d - b * c == -1L,
    proof_reasoning: (
      #|INVARIANT (Path descent):
      #|  (I1) rnum/rden is strictly between a/b and c/d (after the first
      #|       step; before that, rnum/rden is some positive rational and
      #|       the frontier 0/1, 1/0 brackets every positive rational).
      #|  (I2) a*d - b*c == -1   (Farey neighbour invariant, preserved by
      #|       both descent steps).
      #|  (I3) `path` records the sequence of moves taken so far. The
      #|       final mediant of the descent equals rnum/rden when the
      #|       loop terminates.
      #|
      #|MAINTENANCE:
      #|  Let mediant = p/q = (a+c)/(b+d). Sign of diff decides direction:
      #|    diff > 0: rnum/rden > mediant; new bounds (p/q, c/d) -- step R.
      #|    diff < 0: rnum/rden < mediant; new bounds (a/b, p/q) -- step L.
      #|  Cross-multiplying preserves the determinant a*d - b*c == -1.
      #|
      #|TERMINATION:
      #|  Each step strictly increases b + d, and the depth at which any
      #|  positive rational p/q in lowest terms appears in the tree is
      #|  the sum of its continued-fraction partial quotients minus one,
      #|  which is finite. The exact equality test (diff == 0) fires at
      #|  that depth.
      #|
      #|CORRECTNESS AT EXIT:
      #|  diff == 0 means rnum*q == rden*p; combined with (I2) (which
      #|  forces gcd(p, q) == 1) we conclude (p, q) == (rnum, rden).
    ),
  }
}

///|
/// Re-evaluate the final mediant reached by walking the recorded path.
/// Convenient for the round-trip property test.
fn replay_path(path : Array[Char]) -> (Int64, Int64) {
  for a = 0L, b = 1L, c = 1L, d = 0L, i = 0 {
    if i == path.length() {
      break (a + c, b + d)
    } else {
      let p = a + c
      let q = b + d
      let mv = path[i]
      if mv == 'L' {
        continue a, b, p, q, i + 1
      } else {
        continue p, q, c, d, i + 1
      }
    }
  } where {
    proof_invariant: i >= 0 && i <= path.length(),
    proof_invariant: a * d - b * c == -1L,
    proof_reasoning: (
      #|INVARIANT:
      #|  After `i` steps the bounds (a/b, c/d) are the same ones that
      #|  the descent loop in `stern_brocot_path` would hold after
      #|  consuming `path[0..i)`. The Farey determinant is preserved.
      #|TERMINATION:
      #|  `i` strictly increases each iteration and is bounded by
      #|  `path.length()`.
    ),
  }
}

///|
test "best approximation: exact target fits within cap" {
  // 22/7 has denominator 7, so with max_denom = 7 we get it exactly.
  @debug.assert_eq(best_rational_approximation(22L, 7L, 7L), (22L, 7L))
  // 3/4 fits with cap 4.
  @debug.assert_eq(best_rational_approximation(3L, 4L, 4L), (3L, 4L))
  // 5/8 fits with cap 8.
  @debug.assert_eq(best_rational_approximation(5L, 8L, 8L), (5L, 8L))
}

///|
test "best approximation: pi-ish bounded by denominator 7" {
  // 355/113 is a famous near-π convergent. The best rational with q <= 7
  // approximating it is 22/7.
  @debug.assert_eq(best_rational_approximation(355L, 113L, 7L), (22L, 7L))
}

///|
test "best approximation: max_denom == 1 rounds to nearest integer" {
  // 7/4 = 1.75 rounds to 2/1 with cap 1.
  @debug.assert_eq(best_rational_approximation(7L, 4L, 1L), (2L, 1L))
  // 9/4 = 2.25 rounds to 2/1.
  @debug.assert_eq(best_rational_approximation(9L, 4L, 1L), (2L, 1L))
  // 1/3 rounds to 0/1.
  @debug.assert_eq(best_rational_approximation(1L, 3L, 1L), (0L, 1L))
}

///|
test "best approximation: zero numerator and signs" {
  @debug.assert_eq(best_rational_approximation(0L, 5L, 10L), (0L, 1L))
  // Negative numerator yields negative numerator on output.
  @debug.assert_eq(best_rational_approximation(-22L, 7L, 7L), (-22L, 7L))
}

///|
test "stern brocot path: small targets" {
  // 1/2 is the left child of the root (1/1).
  @debug.assert_eq(stern_brocot_path(1L, 2L), ['L'])
  // 2/1 is the right child of the root.
  @debug.assert_eq(stern_brocot_path(2L, 1L), ['R'])
  // 1/3: from 1/1 go L (bounds 0/1, 1/1, mediant 1/2),
  //      then L again (bounds 0/1, 1/2, mediant 1/3) -> equal, stop.
  @debug.assert_eq(stern_brocot_path(1L, 3L), ['L', 'L'])
  // 2/3: from 1/1 go L (mediant becomes 1/2),
  //      then R (bounds 1/2, 1/1, mediant 2/3) -> equal, stop.
  @debug.assert_eq(stern_brocot_path(2L, 3L), ['L', 'R'])
  // 3/2: mirror image of 2/3 across the root.
  @debug.assert_eq(stern_brocot_path(3L, 2L), ['R', 'L'])
  // 3/5: 1/1 -L-> 1/2 -R-> 2/3 -L-> 3/5
  @debug.assert_eq(stern_brocot_path(3L, 5L), ['L', 'R', 'L'])
}

///|
test "stern brocot path: round-trip" {
  // Walking the recorded path must reproduce the input rational.
  let samples : ReadOnlyArray[(Int64, Int64)] = [
    (1L, 2L),
    (2L, 3L),
    (3L, 5L),
    (5L, 8L),
    (22L, 7L),
    (355L, 113L),
    (17L, 31L),
    (7L, 12L),
  ]
  for pair in samples {
    let (n, d) = pair
    let path = stern_brocot_path(n, d)
    let (p, q) = replay_path(path)
    @debug.assert_eq((p, q), (n, d))
  }
}

///|
test "stern brocot path: frontier inputs return empty" {
  @debug.assert_eq(stern_brocot_path(0L, 1L), [])
  @debug.assert_eq(stern_brocot_path(1L, 0L), [])
}

///|
test "stern brocot path: non-reduced input matches reduced" {
  // 6/10 reduces to 3/5; the paths must agree.
  @debug.assert_eq(stern_brocot_path(6L, 10L), stern_brocot_path(3L, 5L))
  @debug.assert_eq(stern_brocot_path(44L, 14L), stern_brocot_path(22L, 7L))
}

///|
test "best approximation: every candidate within cap is reachable" {
  // For every denominator q in 1..=10, the best approximation of some
  // p/q must be exactly p/q (since the target itself is reachable).
  for q in 1L..<=10L {
    for p in 1L..<=q {
      let g = gcd_i64(p, q)
      if g == 1L {
        @debug.assert_eq(best_rational_approximation(p, q, q), (p, q))
      }
    }
  }
}
