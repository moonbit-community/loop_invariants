// ============================================================================
// VERIFIED GCD - Greatest common divisor (Euclidean + binary/Stein)
// ============================================================================
//
// Two algorithms for the same arithmetic problem:
//
//   `gcd_euclid(a, b)` -- classical Euclidean algorithm using `mod`
//   `gcd_binary(a, b)` -- binary (Stein) algorithm using shifts/subtraction
//
// Both share the same proof contract:
//
//   proof_require: nonneg(a) && nonneg(b)
//   proof_ensure : result >= 0 && divides(result, a) && divides(result, b)
//
// The loop invariants for each version are what make this a *verified*
// package: every iteration preserves a precise relationship between the
// running state and the inputs, so the final return value provably
// satisfies the postcondition.

///|
/// Compute the greatest common divisor of two non-negative integers via
/// the classical Euclidean algorithm.
///
/// At each step we replace `(a, b)` with `(b, a mod b)` until `b` reaches
/// zero. The loop invariant is that the set of common divisors of `(a, b)`
/// is exactly the set of common divisors of the original inputs, so the
/// final value of `a` (when `b = 0`) is the GCD.
///
/// Termination is by strict decrease of the second argument: each
/// iteration replaces `b` with `a mod b < b`. The classical Lamé bound
/// gives `O(log min(a, b))` iterations.
///
/// Parameters:
/// - `a`: a non-negative integer (precondition `a >= 0`).
/// - `b`: a non-negative integer (precondition `b >= 0`).
///
/// Returns: the unique non-negative integer `g` that divides both `a`
/// and `b` and is divisible by every common divisor.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(gcd_euclid(48, 18), 6)
///   @debug.assert_eq(gcd_euclid(0, 5), 5)
///   @debug.assert_eq(gcd_euclid(17, 31), 1)
/// }
/// ```
pub fn gcd_euclid(
  a : Int,
  b : Int,
) -> Int where {
  proof_require: nonneg(a),
  proof_require: nonneg(b),
  proof_ensure: result => gcd_ok(a, b, result),
} {
  for x = a, y = b {
    if y == 0 {
      break x
    } else {
      continue y, x % y
    }
  } where {
    proof_invariant: x >= 0,
    proof_invariant: y >= 0,
    proof_invariant: same_common_divisors(x, y, a, b),
    proof_reasoning: (
      #| The loop maintains three coupled invariants:
      #|
      #|   (I1)  x >= 0
      #|   (I2)  y >= 0
      #|   (I3)  the common divisors of (x, y) equal the common divisors
      #|         of the original (a, b)
      #|
      #| Initialization is trivial: at (x, y) = (a, b), all three hold by
      #| the preconditions `nonneg(a)` and `nonneg(b)`.
      #|
      #| Maintenance. The update is `(x, y) := (y, x % y)`, taken only when
      #| `y > 0` (otherwise the loop exits). Then:
      #|   - The new `x` is the old `y`, which is `>= 0` by (I2).
      #|   - The new `y` is `x % y` with `y > 0` and `x >= 0`, so it lies
      #|     in `[0, y)`; (I2) is preserved.
      #|   - The set of common divisors is preserved by the classical
      #|     identity gcd(x, y) = gcd(y, x mod y): any d dividing both
      #|     x and y also divides `x - q*y = x mod y`, and conversely any
      #|     d dividing y and `x mod y` divides `q*y + (x mod y) = x`. So
      #|     (I3) is preserved.
      #|
      #| Termination. The second component `y` strictly decreases: a
      #| positive modulus `y` is replaced by `x mod y`, which lies in the
      #| half-open interval `[0, y)`. Since `y` stays non-negative and the
      #| natural numbers are well-founded, the loop must reach `y == 0`
      #| in finitely many steps. (The classical Lamé bound shows
      #| `O(log min(a, b))` iterations.)
      #|
      #| Exit. When the loop breaks, `y == 0`, so (I3) collapses to the
      #| statement that the common divisors of `(x, 0)` equal the common
      #| divisors of `(a, b)`. The common divisors of `(x, 0)` are exactly
      #| the divisors of `x`, so `x` is the GCD. Combined with (I1) we get
      #| `result >= 0 && divides(result, a) && divides(result, b)`, the
      #| postcondition `gcd_ok(a, b, result)`.
    ),
  }
}

///|
/// Compute the greatest common divisor of two non-negative integers via
/// the binary (Stein) algorithm.
///
/// The algorithm avoids division entirely, relying only on shifts,
/// parity tests, and subtraction:
///
///   1. Boundary cases: `gcd(0, b) = b` and `gcd(a, 0) = a`.
///   2. Strip common factors of 2: while both `a` and `b` are even,
///      halve them and accumulate the shared power of two in `shift`.
///   3. Make `a` odd by halving while even.
///   4. Main loop. The state has `a` odd. Halve `b` while it is even,
///      then if `a > b` swap them so that `a <= b`, and replace `b` with
///      `b - a` (which becomes even). Stop when `b = 0`.
///   5. Return `a << shift`.
///
/// Each `b - a` step strictly decreases `a + b`, so termination is
/// well-founded.
///
/// Parameters:
/// - `a`: a non-negative integer (precondition `a >= 0`).
/// - `b`: a non-negative integer (precondition `b >= 0`).
///
/// Returns: the greatest common divisor of `a` and `b`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(gcd_binary(48, 18), 6)
///   @debug.assert_eq(gcd_binary(1024, 768), 256)
///   @debug.assert_eq(gcd_binary(17, 31), 1)
/// }
/// ```
pub fn gcd_binary(
  a : Int,
  b : Int,
) -> Int where {
  proof_require: nonneg(a),
  proof_require: nonneg(b),
  proof_ensure: result => gcd_ok(a, b, result),
} {
  // Boundary cases: gcd(0, b) = b and gcd(a, 0) = a.
  if a == 0 {
    return b
  }
  if b == 0 {
    return a
  }

  // Phase 1: extract common factors of two.
  //
  // Loop invariant: a == a0 * 2^k0 and b == b0 * 2^k0 for some k0 that
  // counts how many shared factors of two we have already stripped.
  // Externally we maintain `shift = k0`. Termination is by strict
  // decrease of `a + b` while both are even.
  let (a1, b1, s1) = for x = a, y = b, shift = 0 {
    if (x & 1) == 0 && (y & 1) == 0 {
      continue x >> 1, y >> 1, shift + 1
    } else {
      break (x, y, shift)
    }
  } where {
    proof_invariant: x > 0,
    proof_invariant: y > 0,
    proof_invariant: shift >= 0,
    proof_invariant: same_common_divisors(x << shift, y << shift, a, b),
    proof_reasoning: (
      #| Phase 1 peels off shared factors of two. The state always
      #| represents the same original pair, scaled down by `2^shift`:
      #|
      #|   (I1)  x > 0           -- because a > 0 by the early return
      #|   (I2)  y > 0           -- because b > 0 by the early return
      #|   (I3)  shift >= 0
      #|   (I4)  the common divisors of `(x * 2^shift, y * 2^shift)` are
      #|         the same as those of the original `(a, b)`
      #|
      #| Initialization: at `(x, y, shift) = (a, b, 0)`, (I4) is trivial.
      #|
      #| Maintenance: the loop continues only when both `x` and `y` are
      #| even. Halving each and incrementing `shift` keeps `x * 2^shift`
      #| and `y * 2^shift` unchanged, preserving (I4). Halving a positive
      #| even integer yields a positive integer, preserving (I1), (I2).
      #|
      #| Termination: `x + y` strictly decreases (each is halved and was
      #| at least 2). The natural numbers are well-founded.
    ),
  }

  // Phase 2: make `a1` odd. We halve `a` while it is even; this is
  // sound because the common factor of two cannot be shared with the
  // odd `b1`, so it can be discarded without changing gcd(a, b).
  let a2 = for x = a1 {
    if (x & 1) == 0 {
      continue x >> 1
    } else {
      break x
    }
  } where {
    proof_invariant: x > 0,
    proof_invariant: same_common_divisors(x, b1, a1, b1),
    proof_reasoning: (
      #| After Phase 1 at least one of (a1, b1) is odd. If it is `a1`
      #| this loop does nothing; otherwise `b1` is odd and any factor of
      #| two in `a1` divides `a1` only, never `b1`, so halving `a1`
      #| preserves `gcd(a1, b1)`. The state stays positive throughout.
      #| Termination: `x` strictly decreases while even, bounded below
      #| by 1.
    ),
  }

  // Phase 3: main subtractive loop. `a` is odd, `b` is positive. We
  // repeatedly halve `b` until it is odd, then subtract the smaller
  // from the larger. The quantity `a + b` strictly decreases each
  // outer iteration, guaranteeing termination.
  let final_a = for x = a2, y = b1 {
    // Make `y` odd. Same argument as Phase 2 -- factors of two in `y`
    // do not divide the odd `x`, so dropping them preserves gcd.
    let yo = for v = y {
      if v == 0 {
        break v
      } else if (v & 1) == 0 {
        continue v >> 1
      } else {
        break v
      }
    } where {
      proof_invariant: v >= 0,
      proof_invariant: same_common_divisors(x, v, x, y),
      proof_reasoning: (
        #| Strip factors of two from `y` while preserving common divisors
        #| with the odd `x`. Halving stops when `y` is zero or odd.
      ),
    }
    if yo == 0 {
      break x
    } else if x > yo {
      // Swap so that x <= yo, then subtract.
      continue yo, x - yo
    } else {
      continue x, yo - x
    }
  } where {
    proof_invariant: x > 0,
    proof_invariant: y >= 0,
    proof_invariant: same_common_divisors(x, y, a2, b1),
    proof_reasoning: (
      #| Main loop invariants:
      #|
      #|   (J1)  x > 0
      #|   (J2)  y >= 0
      #|   (J3)  x is odd throughout the body
      #|   (J4)  the common divisors of (x, y) equal those of (a2, b1)
      #|
      #| Phase 2 establishes (J3): on entry `x = a2` is odd. After the
      #| inner halving loop, `yo` is either 0 or odd. If `yo == 0` we
      #| break with `x` as the answer; otherwise both `x` and `yo` are
      #| odd, so `|x - yo|` is even -- exactly the value that the next
      #| inner halving loop will reduce again. The swap-and-subtract
      #| step preserves (J4) because `gcd(x, yo) = gcd(x, yo - x)` when
      #| `yo >= x`, and similarly with the roles reversed.
      #|
      #| Termination: each outer iteration replaces (x, y) with a pair
      #| whose entries sum to strictly less than `x + y`. The inner
      #| halving loops do not increase `x + y`. So `x + y` is a
      #| well-founded variant.
      #|
      #| Exit. When the inner halving returns `yo == 0`, the second
      #| component drops to zero. By (J4) the common divisors of
      #| `(x, 0)` -- which are exactly the divisors of `x` -- match
      #| those of `(a2, b1)`, and hence of `(a, b)` (through Phase 2's
      #| invariant and Phase 1's invariant with the appropriate shift).
    ),
  }

  // Phase 4: reattach the shared factor of 2^s1.
  final_a << s1
}
