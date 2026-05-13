// ============================================================================
// CYCLE DETECTION - Floyd's tortoise-and-hare and Brent's variant
// ============================================================================
//
// Given a deterministic function `f : T -> T` and a starting value `x0`,
// the sequence
//
//     x_0, x_1, x_2, ...     where   x_{i+1} = f(x_i)
//
// must eventually repeat itself, because if `T` is finite (or if the
// values reached from `x0` form a finite set) the pigeonhole principle
// guarantees a collision.  Once we hit a value we have seen before, the
// sequence is locked into a cycle.
//
// Two natural quantities describe the trajectory:
//
//   - `mu`  (the "tail length"):    the index of the first value that
//                                   belongs to the cycle.
//   - `lam` (the "cycle length"):   the period, i.e. the smallest
//                                   positive integer with
//                                   `x_{mu + lam} == x_mu`.
//
// Visually:
//
//           x0 -> x1 -> ... -> x_{mu-1} -> x_mu -> x_{mu+1} -> ...
//                                            ^                  |
//                                            |__________________|
//                                                 lam steps
//
// Detecting `(mu, lam)` with O(1) extra memory is the classic problem
// solved by Floyd's tortoise-and-hare (1967) and Brent's improvement
// (1980).  Both run in O(mu + lam) time; Brent's variant uses fewer
// applications of `f` in practice.
//
// This module is for **functional iteration on values** (Pollard rho,
// RNG period detection, hash-chain analysis).  See
// `modules/techniques/techniques/advanced.mbt` for the linked-list
// pointer-chasing variant, which is a different (more specialised) use
// of the same algorithm and is intentionally not modified here.

///|
/// Floyd's tortoise-and-hare cycle detection.
///
/// Given a deterministic function `f` and a starting value `x0`,
/// returns the pair `(mu, lam)` describing the eventual cycle of the
/// orbit `x0, f(x0), f(f(x0)), ...`:
///
/// - `mu`  -- index of the first value belonging to the cycle (the
///            length of the "tail" before the cycle starts).
/// - `lam` -- the period of the cycle (the smallest positive integer
///            with `f^lam(x_mu) == x_mu`).
///
/// ## Algorithm (three phases)
///
/// 1. **Detect a collision.**  Move a "tortoise" one step at a time and
///    a "hare" two steps at a time.  They must meet at some value inside
///    the cycle, because once both have entered the cycle the hare gains
///    one step on the tortoise per iteration, modulo `lam`.
/// 2. **Find `mu`.**  Reset the tortoise to `x0`; leave the hare at the
///    meeting point.  Step both by one until they coincide.  The number
///    of steps is `mu`; the meeting point is `x_mu`, the cycle entrance.
/// 3. **Find `lam`.**  Keep one pointer at the entrance; step the other
///    by one until it returns.  The number of steps is `lam`.
///
/// ## Requirements
///
/// - `f` must be deterministic (a pure function of its input).
/// - The orbit must reach a cycle eventually -- this is automatic if
///   the values reached from `x0` come from a finite set.
///
/// ## Complexity
///
/// O(mu + lam) calls to `f` and O(1) extra space (besides what the
/// equality check on `T` may allocate).
pub fn[T : Eq] floyd_cycle(f : (T) -> T, x0 : T) -> (Int, Int) {
  // Phase 1: find a meeting point inside the cycle.
  //
  // We start the tortoise one step in and the hare two steps in, then
  // step them at speeds 1 and 2.  The loop exits with both equal to
  // some value `x_meet = x_t = x_{2t}` for some `t >= 1`.
  let meet = for tortoise = f(x0), hare = f(f(x0)) {
    if tortoise == hare {
      break tortoise
    } else {
      continue f(tortoise), f(f(hare))
    }
  } where {
    proof_reasoning: (
      #|INVARIANT (Floyd phase 1, parameterised by a step counter t >= 1):
      #|  tortoise == f^t(x0)
      #|  hare     == f^(2t)(x0)
      #|MAINTENANCE:
      #|  Each iteration replaces (tortoise, hare) with
      #|  (f(tortoise), f(f(hare))) and increments t by 1, so the new
      #|  values are f^(t+1)(x0) and f^(2(t+1))(x0).
      #|TERMINATION:
      #|  Once t >= mu both pointers are inside the cycle. The hare's
      #|  position relative to the tortoise (measured around the cycle)
      #|  decreases by 1 modulo lam each step, so the two coincide
      #|  within at most lam more iterations. Hence the loop runs in
      #|  O(mu + lam) iterations regardless of how long the tail is or
      #|  how large the cycle is.
    ),
  }

  // Phase 2: walk from x0 and from the meeting point at the same speed.
  // Their first coincidence is exactly the cycle entrance, x_mu.
  let (mu, entrance) = for tortoise = x0, hare = meet, steps = 0 {
    if tortoise == hare {
      break (steps, tortoise)
    } else {
      continue f(tortoise), f(hare), steps + 1
    }
  } where {
    proof_invariant: steps >= 0,
    proof_reasoning: (
      #|INVARIANT (Floyd phase 2):
      #|  tortoise == f^steps(x0)
      #|  hare     == f^(steps + meet_distance)(x0)
      #|  where meet_distance == t (Phase 1 step count). Equivalently
      #|  the hare is exactly `t` steps ahead in the underlying orbit.
      #|MAINTENANCE:
      #|  Both pointers advance by one step, so `steps` grows by one and
      #|  the gap of `meet_distance` is preserved.
      #|TERMINATION & CORRECTNESS:
      #|  From the math of Phase 1, `meet_distance` is a multiple of
      #|  `lam`. Once `steps == mu`, the tortoise has just entered the
      #|  cycle and the hare -- being a whole number of cycles ahead --
      #|  is at the same point. They cannot coincide earlier because for
      #|  `steps < mu` the tortoise is in the tail (a non-cycle value
      #|  cannot equal a cycle value). So `steps == mu` at exit and
      #|  `tortoise == hare == x_mu`, the cycle entrance.
    ),
  }

  // Phase 3: from the cycle entrance, count one full lap.
  let lam = for cur = f(entrance), n = 1 {
    if cur == entrance {
      break n
    } else {
      continue f(cur), n + 1
    }
  } where {
    proof_invariant: n >= 1,
    proof_reasoning: (
      #|INVARIANT (Floyd phase 3):
      #|  cur == f^n(entrance), and entrance is the cycle entrance x_mu.
      #|  All values f(entrance), f^2(entrance), ..., f^(n-1)(entrance)
      #|  are distinct from entrance (else we would have broken earlier).
      #|MAINTENANCE:
      #|  Each step replaces (cur, n) with (f(cur), n + 1).
      #|TERMINATION:
      #|  The orbit from entrance is a pure cycle of length lam (no
      #|  tail), so cur returns to entrance after exactly lam steps,
      #|  giving n == lam at exit.
    ),
  }
  (mu, lam)
}

///|
/// Brent's variant of cycle detection.
///
/// Same return contract as `floyd_cycle`: the pair `(mu, lam)` with
/// `mu` the tail length and `lam` the cycle length of the orbit
/// `x0, f(x0), f(f(x0)), ...`.
///
/// ## How it differs from Floyd
///
/// Floyd advances the hare by `f(f(...))` per step, costing two calls
/// to `f`.  Brent instead keeps the tortoise stationary while the hare
/// walks forward, and only resets the tortoise to the hare's current
/// position when the hare has walked a power-of-two number of steps.
/// Once `tortoise == hare`, the distance walked since the last reset
/// is exactly `lam`.  In practice this performs ~30% fewer calls to
/// `f` than Floyd because the hare only advances by one each step.
///
/// ## Complexity
///
/// O(mu + lam) calls to `f` and O(1) extra space.
pub fn[T : Eq] brent_cycle(f : (T) -> T, x0 : T) -> (Int, Int) {
  // Phase 1: power-of-two doubling search for lam.
  //
  // `tortoise` is the snapshot of the orbit at index `start_of_window`,
  // and `hare` is the orbit at index `start_of_window + power - lam`
  // where `power` is the current window size and `lam` counts how far
  // the hare has walked within the window. Each time `lam == power`
  // (the hare has covered a full window without meeting the tortoise),
  // we double the window and reset: `tortoise := hare`, `lam := 0`.
  let (lam, hare_meet) = for tortoise = x0, hare = f(x0), power = 1, lam = 1 {
    if tortoise == hare {
      break (lam, hare)
    } else if lam == power {
      // Reset: tortoise jumps to the hare's position; window doubles.
      continue hare, f(hare), power * 2, 1
    } else {
      continue tortoise, f(hare), power, lam + 1
    }
  } where {
    proof_invariant: power >= 1,
    proof_invariant: lam >= 1,
    proof_invariant: lam <= power,
    proof_reasoning: (
      #|INVARIANT (Brent phase 1, doubling search):
      #|  Let `start_of_window` be the orbit index of `tortoise`. Then
      #|     tortoise == f^start_of_window(x0)
      #|     hare     == f^(start_of_window + lam)(x0)
      #|     1 <= lam <= power     (within the current window)
      #|MAINTENANCE:
      #|  - Non-reset step: tortoise unchanged, hare := f(hare),
      #|    lam := lam + 1. The new hare is one orbit step further.
      #|  - Reset step (lam == power): the hare has walked `power`
      #|    steps since the last reset without meeting tortoise, which
      #|    means the cycle length (if any cycle is detectable from
      #|    this window) exceeds `power`. We double the window:
      #|    start_of_window jumps forward by `power`, tortoise := hare,
      #|    lam := 1 (we count from the new hare := f(hare)), and
      #|    power := 2 * power.
      #|TERMINATION:
      #|  Eventually `start_of_window >= mu`, so the tortoise is in the
      #|  cycle. The window size doubles until `power >= lam_true`
      #|  (the true cycle length); once that happens, within the next
      #|  window the hare wraps around and meets the tortoise. So the
      #|  loop runs in O(mu + lam_true) iterations even on inputs with
      #|  very long tails or large cycles.
      #|CORRECTNESS AT EXIT:
      #|  When tortoise == hare, lam equals the true cycle length:
      #|  it is the distance the hare has walked since being placed at
      #|  the tortoise position, and the hare's orbit is now back to
      #|  the tortoise's value, so lam is a positive multiple of the
      #|  cycle length, and minimality follows from the bound
      #|  lam <= power < 2 * lam_true together with `power >= lam_true`
      #|  the first time the equality occurs.
    ),
  }
  let _ = hare_meet // hare_meet is unused; `lam` already characterises Phase 1's result.

  // Phase 2: find mu by walking tortoise and hare lockstep, after first
  // separating them by `lam`.
  let hare_start = for cur = x0, k = 0 {
    if k == lam {
      break cur
    } else {
      continue f(cur), k + 1
    }
  } where {
    proof_invariant: k >= 0 && k <= lam,
    proof_reasoning: (
      #|INVARIANT (Brent phase 2 -- separator):
      #|  cur == f^k(x0).  We are pre-walking the hare so that hare and
      #|  tortoise are exactly `lam` steps apart in the orbit.
      #|TERMINATION:
      #|  k strictly increases, so the loop exits after exactly lam
      #|  iterations with cur == f^lam(x0).
    ),
  }
  let mu = for tortoise = x0, hare = hare_start, steps = 0 {
    if tortoise == hare {
      break steps
    } else {
      continue f(tortoise), f(hare), steps + 1
    }
  } where {
    proof_invariant: steps >= 0,
    proof_reasoning: (
      #|INVARIANT (Brent phase 2 -- coincidence search):
      #|  tortoise == f^steps(x0)
      #|  hare     == f^(steps + lam)(x0)
      #|MAINTENANCE:
      #|  Both pointers advance by one step; the gap of `lam` is
      #|  preserved.
      #|TERMINATION & CORRECTNESS:
      #|  The first index s with f^s(x0) == f^(s + lam)(x0) is exactly
      #|  s == mu: for s < mu the tortoise is in the tail (and not on
      #|  the cycle), so it cannot equal a cycle value; for s == mu the
      #|  tortoise has just entered the cycle and the hare, being a
      #|  full period ahead, is at the same point.
    ),
  }
  (mu, lam)
}

// ============================================================================
// Tests
// ============================================================================

///|
test "floyd quadratic mod 7 starting at 1" {
  // f(x) = (x*x + 1) mod 7
  //   f(0)=1, f(1)=2, f(2)=5, f(5)=26 mod 7 = 5  (fixed point).
  // Orbit from x0 = 1: 1, 2, 5, 5, 5, ...   so mu = 2, lam = 1.
  let f = fn(x : Int) { (x * x + 1) % 7 }
  let (mu, lam) = floyd_cycle(f, 1)
  @debug.assert_eq(mu, 2)
  @debug.assert_eq(lam, 1)
}

///|
test "brent quadratic mod 7 starting at 1" {
  let f = fn(x : Int) { (x * x + 1) % 7 }
  let (mu, lam) = brent_cycle(f, 1)
  @debug.assert_eq(mu, 2)
  @debug.assert_eq(lam, 1)
}

///|
test "floyd quadratic mod 5 starting at 1 (cycle from index 0)" {
  // f(x) = (x*x + 1) mod 5
  //   f(0)=1, f(1)=2, f(2)=0, f(3)=0, f(4)=2.
  // Orbit from 1: 1 -> 2 -> 0 -> 1 -> 2 -> 0 -> ...  mu=0, lam=3.
  let f = fn(x : Int) { (x * x + 1) % 5 }
  let (mu, lam) = floyd_cycle(f, 1)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 3)
}

///|
test "brent quadratic mod 5 starting at 1 (cycle from index 0)" {
  let f = fn(x : Int) { (x * x + 1) % 5 }
  let (mu, lam) = brent_cycle(f, 1)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 3)
}

///|
test "floyd quadratic mod 5 starting at 3 (tail of length 1)" {
  // From 3:  3 -> 0 -> 1 -> 2 -> 0 -> 1 -> 2 -> ...   mu=1, lam=3.
  let f = fn(x : Int) { (x * x + 1) % 5 }
  let (mu, lam) = floyd_cycle(f, 3)
  @debug.assert_eq(mu, 1)
  @debug.assert_eq(lam, 3)
}

///|
test "brent quadratic mod 5 starting at 3 (tail of length 1)" {
  let f = fn(x : Int) { (x * x + 1) % 5 }
  let (mu, lam) = brent_cycle(f, 3)
  @debug.assert_eq(mu, 1)
  @debug.assert_eq(lam, 3)
}

///|
test "floyd pure ring of length 4" {
  // f(x) = (x + 1) mod 4 -- a perfect cycle of length 4.
  let f = fn(x : Int) { (x + 1) % 4 }
  let (mu, lam) = floyd_cycle(f, 0)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 4)
}

///|
test "brent pure ring of length 4" {
  let f = fn(x : Int) { (x + 1) % 4 }
  let (mu, lam) = brent_cycle(f, 0)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 4)
}

///|
test "floyd fixed point" {
  // f(x) = x.  The starting value is itself a fixed point, so mu = 0
  // and lam = 1.
  let f = fn(x : Int) { x }
  let (mu, lam) = floyd_cycle(f, 42)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 1)
}

///|
test "brent fixed point" {
  let f = fn(x : Int) { x }
  let (mu, lam) = brent_cycle(f, 42)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 1)
}

///|
test "floyd long tail short cycle" {
  // f(x) = x + 1 if x < 100 else 100.  Long tail 0,1,...,99 then a
  // self-loop at 100.  Starting at 0 we expect mu = 100, lam = 1.
  let f = fn(x : Int) { if x < 100 { x + 1 } else { 100 } }
  let (mu, lam) = floyd_cycle(f, 0)
  @debug.assert_eq(mu, 100)
  @debug.assert_eq(lam, 1)
}

///|
test "brent long tail short cycle" {
  let f = fn(x : Int) { if x < 100 { x + 1 } else { 100 } }
  let (mu, lam) = brent_cycle(f, 0)
  @debug.assert_eq(mu, 100)
  @debug.assert_eq(lam, 1)
}

///|
test "floyd and brent agree on a sweep" {
  // Cross-check the two implementations on every quadratic-mod-m
  // starting point for several small m.
  let ms : ReadOnlyArray[Int] = [3, 4, 5, 7, 11, 13]
  for m in ms {
    let f = fn(x : Int) { (x * x + 1) % m }
    for x0 in 0..<m {
      let (mu_f, lam_f) = floyd_cycle(f, x0)
      let (mu_b, lam_b) = brent_cycle(f, x0)
      @debug.assert_eq(mu_f, mu_b)
      @debug.assert_eq(lam_f, lam_b)
      // Sanity check: f^mu and f^(mu + lam) must agree.
      let after_mu = for v = x0, i = 0 {
        if i == mu_f {
          break v
        } else {
          continue f(v), i + 1
        }
      }
      let after_mu_plus_lam = for v = x0, i = 0 {
        if i == mu_f + lam_f {
          break v
        } else {
          continue f(v), i + 1
        }
      }
      @debug.assert_eq(after_mu, after_mu_plus_lam)
    }
  }
}

///|
test "floyd cycle entered immediately" {
  // f(x) = (x + 1) mod 3 starting from 1: 1 -> 2 -> 0 -> 1.  mu=0, lam=3.
  let f = fn(x : Int) { (x + 1) % 3 }
  let (mu, lam) = floyd_cycle(f, 1)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 3)
}

///|
test "brent cycle entered immediately" {
  let f = fn(x : Int) { (x + 1) % 3 }
  let (mu, lam) = brent_cycle(f, 1)
  @debug.assert_eq(mu, 0)
  @debug.assert_eq(lam, 3)
}
