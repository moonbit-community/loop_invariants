// ============================================================================
// MORRIS COUNTER - Approximate counting in O(log log N) bits
// ============================================================================
//
// THE TRICK
//
// To count N events you might think you need at least log2(N) bits of
// storage. Morris (1978) showed you can do it in **roughly
// log2(log2(N)) bits** by storing the LOG of the count and updating it
// probabilistically.
//
// Concretely, keep a small integer counter `c` (8 bits is plenty for any
// count fitting in 64 bits). To increment the conceptual counter:
//
//     with probability   1 / a^c     do  c := c + 1
//     otherwise          do nothing
//
// where `a > 1` is a fixed parameter (`a = 2` is the original).
//
// The expected counter value after N events satisfies
//
//     E[a^c]  =  1 + (a - 1) * N
//
// so the unbiased estimate of N is
//
//     estimate  =  (a^c - 1) / (a - 1)
//
// VARIANCE TRADE-OFF
//
// The relative standard error is roughly  sqrt((a - 1) / 2),
// independent of N. Choosing a = 2 gives ~70% relative error; using
// a closer to 1 (e.g. 1.08) brings it under 20% at the cost of a few
// more bits in `c`.
//
// SPACE
//
// `c` only needs log2(log_a(N) + 1) bits. For N = 10^18 and a = 2,
// log2(N) ≈ 60, so `c` fits in 6 bits. Compare to 60 bits for an exact
// counter -- a 10x reduction.

///|
/// A Morris approximate counter with parameter `base` (= `a` above).
///
/// The internal counter `c` is bumped with probability `1 / base^c` on
/// each `increment`. The estimated count is `(base^c - 1) / (base - 1)`.
///
/// The RNG state is deterministic so two counters initialised with the
/// same seed produce identical traces, which is useful for testing and
/// for parallel "sharded" counts that you later combine.
pub struct MorrisCounter {
  mut c : Int
  base : Double
  mut rng_state : Int64
}

///|
/// A tiny linear-congruential PRNG. Constants taken from Knuth's
/// "MMIX" generator; we only need *some* spread, not statistical
/// quality, so a 1-step LCG suffices for the Morris probability test.
fn morris_lcg_next(state : Int64) -> Int64 {
  state * 6364136223846793005L + 1442695040888963407L
}

///|
/// Draw a uniform Double in [0, 1) from the LCG state.
fn morris_uniform(state : Int64) -> Double {
  // Take the top 53 bits of the absolute LCG output and divide by 2^53.
  let abs_state = if state < 0L { -state } else { state }
  let top = (abs_state >> 11).to_double()
  top / 9007199254740992.0
}

///|
/// Create a fresh Morris counter with parameter `base` (> 1) and the
/// given RNG seed. Common choices:
///
/// - `base = 2.0`    -- the original Morris '78 design; ~70% RSE.
/// - `base = 1.08`   -- ~20% RSE; recommended for monitoring metrics.
/// - `base = 1.0078` -- ~7% RSE; HyperLogLog-class accuracy.
///
/// ## Parameters
///
/// - `base` : multiplicative base; must be strictly greater than 1.
/// - `seed` : deterministic seed for the probability draws.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let mc = @morris_counter.new(base=2.0, seed=42L)
///   for _ in 0..<1000 {
///     mc.increment()
///   }
///   // estimate ~ 1000; expect order of magnitude correctness.
///   assert_true(mc.estimate() >= 100L && mc.estimate() <= 10000L)
/// }
/// ```
pub fn new(base~ : Double, seed~ : Int64) -> MorrisCounter {
  let b = if base <= 1.0 { 2.0 } else { base }
  // Initial RNG mix so two seeds that differ by 1 don't produce the
  // same first sample.
  let s = morris_lcg_next(seed)
  { c: 0, base: b, rng_state: s }
}

///|
/// Process a single increment. With probability `1 / base^c` the
/// internal counter is bumped; otherwise nothing happens.
pub fn MorrisCounter::increment(self : MorrisCounter) -> Unit {
  self.rng_state = morris_lcg_next(self.rng_state)
  let u = morris_uniform(self.rng_state)
  let threshold = 1.0 / @math.pow(self.base, self.c.to_double())
  if u < threshold {
    self.c = self.c + 1
  }
}

///|
/// Process `n` increments in a row. Equivalent to calling
/// `increment()` n times but runs in a single loop with a stated
/// proof_invariant.
pub fn MorrisCounter::increment_n(self : MorrisCounter, n : Int) -> Unit {
  for _ in 0..<n {
    self.increment()
  } where {
    proof_invariant: self.c >= 0,
    proof_reasoning: (
      #|INVARIANT (Counter non-negativity):
      #|self.c is initialised to 0 and only ever increases. Each call to
      #|`increment` either leaves it unchanged or adds one.
      #|TERMINATION:
      #|The loop runs exactly n times (one iteration per call), bounded
      #|by the loop index range.
    ),
  }
}

///|
/// Current point estimate of the true count: `(base^c - 1) / (base - 1)`.
///
/// This estimator is unbiased: `E[estimate] = N` where `N` is the true
/// number of `increment` calls. The standard deviation grows linearly
/// in `N` with slope `sqrt((base - 1) / 2)`.
///
/// ## Returns
///
/// The estimate rounded to the nearest non-negative Int64. Small `c`
/// values give exact small counts because `(base^0 - 1) / (base - 1) = 0`,
/// `(base^1 - 1) / (base - 1) = 1`, etc.
pub fn MorrisCounter::estimate(self : MorrisCounter) -> Int64 {
  let pow_c = @math.pow(self.base, self.c.to_double())
  let raw = (pow_c - 1.0) / (self.base - 1.0)
  if raw < 0.0 {
    0L
  } else {
    (raw + 0.5).to_int64()
  }
}

///|
/// The raw stored counter `c`. Useful for serialisation and for merging
/// counters across machines (the "combine" rule is non-trivial; see the
/// README for guidance).
pub fn MorrisCounter::raw(self : MorrisCounter) -> Int {
  self.c
}

///|
/// The configured base.
pub fn MorrisCounter::base_of(self : MorrisCounter) -> Double {
  self.base
}

///|
test "morris zero counter estimates zero" {
  let mc = new(base=2.0, seed=1L)
  @debug.assert_eq(mc.estimate(), 0L)
}

///|
test "morris c equals 1 estimates 1 with base 2" {
  let mc = new(base=2.0, seed=1L)
  // Force the counter by direct increment of the field via repeated
  // increments: with c = 0 the threshold is 1.0 / 2^0 = 1.0, so the
  // first call to increment is guaranteed to bump c to 1.
  mc.increment()
  @debug.assert_eq(mc.raw(), 1)
  @debug.assert_eq(mc.estimate(), 1L)
}

///|
test "morris within order of magnitude for moderate counts" {
  // After 1000 base-2 Morris increments, the estimate should be within
  // a factor of ~3 of 1000 with overwhelming probability, even though
  // the standard error is ~70% of N.
  let mc = new(base=2.0, seed=12345L)
  for _ in 0..<1000 {
    mc.increment()
  }
  let est = mc.estimate()
  @debug.assert_eq(est >= 200L, true)
  @debug.assert_eq(est <= 5000L, true)
}

///|
test "morris small base produces a positive estimate" {
  // Smaller base means more probability mass in the increment branch,
  // so the counter is non-trivial even after only a few hundred steps.
  // We don't pin the estimate to a tight range here -- a single
  // deterministic seed gives one fixed (random) trajectory, and the
  // analytic guarantees are *expected* over many seeds. The variance
  // analysis lives in the README.
  let mc = new(base=1.1, seed=12345L)
  for _ in 0..<1000 {
    mc.increment()
  }
  // With base = 1.1 every increment has high probability of bumping c,
  // so c grows quickly and the estimate is definitely above zero.
  @debug.assert_eq(mc.estimate() > 0L, true)
  // And the counter value c is bounded by N: trivially the LCG can
  // never bump c more often than the number of `increment` calls.
  @debug.assert_eq(mc.raw() <= 1000, true)
}

///|
test "morris counter monotonic" {
  // The raw counter is monotonically non-decreasing across increments.
  let mc = new(base=2.0, seed=7L)
  let mut prev = 0
  for _ in 0..<200 {
    mc.increment()
    @debug.assert_eq(mc.raw() >= prev, true)
    prev = mc.raw()
  }
}

///|
test "morris increment_n matches looped increment" {
  // increment_n(n) and a loop of n increments should produce identical
  // counter state when started from the same RNG seed.
  let mc1 = new(base=2.0, seed=99L)
  let mc2 = new(base=2.0, seed=99L)
  for _ in 0..<500 {
    mc1.increment()
  }
  mc2.increment_n(500)
  @debug.assert_eq(mc1.raw(), mc2.raw())
}

///|
test "morris degenerate base coerced to 2" {
  // base <= 1 is coerced internally.
  let mc = new(base=0.5, seed=1L)
  @debug.assert_eq(mc.base_of(), 2.0)
}

///|
test "morris large counter stays in Int64 range" {
  // Push the counter to a high value via a small-base counter so we can
  // exercise the estimate formula without billions of increments.
  let mc = new(base=2.0, seed=42L)
  for _ in 0..<10000 {
    mc.increment()
  }
  let est = mc.estimate()
  @debug.assert_eq(est > 0L, true)
}
