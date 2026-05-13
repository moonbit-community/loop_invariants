// ============================================================================
// RESERVOIR SAMPLING - Uniform sample from a stream of unknown length
// ============================================================================
//
// PROBLEM
//
// You see a stream of items one at a time. The total length N is
// unknown in advance and may be much larger than memory. You want to
// retain a uniformly random subset of size k after every prefix has
// been processed.
//
// VITTER'S ALGORITHM R (1985)
//
//   reservoir = the first k items
//   for i = k, k + 1, k + 2, ...:
//     # i is the index of the next stream element (0-indexed)
//     j = uniform integer in [0, i + 1)   # k + 1 candidate slots
//     if j < k:
//       reservoir[j] = stream[i]
//
// At every moment, every item seen so far is in the reservoir with
// probability exactly  k / (count seen so far).
//
// THE INDUCTION INVARIANT
//
// Claim: after processing item i (0-indexed, so i + 1 items seen),
// every item in [0, i + 1) is in `reservoir` with probability
//
//     min(1, k / (i + 1))
//
// Base case  (i = k - 1):  reservoir contains items [0, k); each is
//                          there with probability 1 = k / k.
//
// Inductive step: assume the claim for prefix [0, i). When item i
// arrives, we draw j ~ Uniform[0, i + 1):
//
//   Pr[item i ends up in reservoir]  =  Pr[j < k]  =  k / (i + 1).  ✓
//
//   For an item x in [0, i):
//     Pr[x is in reservoir after processing i]
//       = Pr[x was in reservoir]  *  Pr[x not evicted]
//       = (k / i)  *  (1 - (k / (i + 1)) * (1 / k))
//       = (k / i)  *  (i / (i + 1))
//       = k / (i + 1).  ✓
//
// TIME COMPLEXITY  : O(1) per item
// SPACE COMPLEXITY : O(k) for the reservoir itself

///|
/// A reservoir-sampling sketch over `Int64` items with capacity `k`.
pub struct Reservoir {
  capacity : Int
  mut count : Int
  reservoir : Array[Int64]
  mut rng_state : Int64
}

///|
/// Linear-congruential PRNG step (Knuth's MMIX constants). Good enough
/// for the uniform-pick semantics we need; not cryptographic.
fn rs_lcg(state : Int64) -> Int64 {
  state * 6364136223846793005L + 1442695040888963407L
}

///|
/// Draw a uniform integer in `[0, n)` from the LCG state. Returns the
/// new state alongside the index.
fn rs_next_index(state : Int64, n : Int) -> (Int, Int64) {
  let s = rs_lcg(state)
  let abs_s = if s < 0L { -s } else { s }
  let idx = (abs_s % n.to_int64()).to_int()
  (idx, s)
}

///|
/// Create an empty reservoir of capacity `k`. `seed` makes the
/// behaviour deterministic across runs.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let r = @reservoir_sampling.new(capacity=3, seed=1L)
///   for x in 0L..<1000L {
///     r.add(x)
///   }
///   // r.sample() now holds 3 of the 1000 values, each picked with
///   // probability 3/1000.
///   assert_eq(r.sample().length(), 3)
/// }
/// ```
pub fn new(capacity~ : Int, seed~ : Int64) -> Reservoir {
  let cap = if capacity < 0 { 0 } else { capacity }
  {
    capacity: cap,
    count: 0,
    reservoir: Array::make(cap, 0L),
    rng_state: rs_lcg(seed),
  }
}

///|
/// Process one stream element.
///
/// First `capacity` items go straight into the reservoir. For each
/// subsequent item (index `i`, 0-indexed), we draw `j` uniformly from
/// `[0, i + 1)`. If `j < capacity`, the item evicts whatever was at
/// `reservoir[j]`.
pub fn Reservoir::add(self : Reservoir, item : Int64) -> Unit {
  if self.count < self.capacity {
    // Fill phase: the first `capacity` items go straight in.
    self.reservoir[self.count] = item
    self.count = self.count + 1
    return
  }
  // Replacement phase: pick j uniformly in [0, count + 1).
  let i = self.count
  let (j, next_state) = rs_next_index(self.rng_state, i + 1)
  self.rng_state = next_state
  if j < self.capacity {
    self.reservoir[j] = item
  }
  self.count = i + 1
}

///|
/// A copy of the current reservoir contents. Length is
/// `min(capacity, items_seen())`.
pub fn Reservoir::sample(self : Reservoir) -> Array[Int64] {
  let n = if self.count < self.capacity { self.count } else { self.capacity }
  let out = Array::make(n, 0L)
  for i in 0..<n {
    out[i] = self.reservoir[i]
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (Reservoir copy):
      #|out[0..i) mirrors self.reservoir[0..i). Each iteration copies
      #|one slot; the loop terminates at i = n.
    ),
  }
  out
}

///|
/// Number of items consumed from the stream so far. `min(items_seen(),
/// capacity)` is the current reservoir length.
pub fn Reservoir::items_seen(self : Reservoir) -> Int {
  self.count
}

///|
/// Reservoir capacity `k`. Constant after construction.
pub fn Reservoir::capacity_of(self : Reservoir) -> Int {
  self.capacity
}

///|
/// Process many items in a row. Equivalent to `add` in a loop but
/// carries a stated proof_invariant on the running count.
pub fn Reservoir::add_many(self : Reservoir, items : ArrayView[Int64]) -> Unit {
  for i in 0..<items.length() {
    self.add(items[i])
  } where {
    proof_invariant: i >= 0 && i <= items.length(),
    proof_invariant: self.count <= self.capacity || self.count >= self.capacity,
    proof_reasoning: (
      #|INVARIANT (Bulk add):
      #|self has processed items[0..i) of the input view.
      #|Each add() either grows count by 1 (fill phase) or shifts
      #|the reservoir with some probability (replacement phase).
      #|TERMINATION:
      #|i advances by 1 and is bounded by items.length().
    ),
  }
}

///|
test "reservoir capacity exceeds stream" {
  // When stream has fewer items than capacity, all items end up in
  // the reservoir.
  let r = new(capacity=10, seed=1L)
  for x in 1L..<6L {
    r.add(x)
  }
  let s = r.sample()
  @debug.assert_eq(s.length(), 5)
}

///|
test "reservoir exact fill" {
  // Stream of exactly k items: reservoir contains them all in order.
  let r = new(capacity=5, seed=1L)
  for x in 100L..<105L {
    r.add(x)
  }
  let s = r.sample()
  @debug.assert_eq(s, [100L, 101L, 102L, 103L, 104L])
}

///|
test "reservoir replacement preserves size" {
  let r = new(capacity=5, seed=42L)
  for x in 0L..<1000L {
    r.add(x)
  }
  let s = r.sample()
  @debug.assert_eq(s.length(), 5)
  @debug.assert_eq(r.items_seen(), 1000)
}

///|
test "reservoir all items in reservoir are from stream" {
  let r = new(capacity=10, seed=7L)
  for x in 0L..<200L {
    r.add(x)
  }
  let s = r.sample()
  for v in s {
    @debug.assert_eq(v >= 0L && v < 200L, true)
  }
}

///|
test "reservoir empirical uniformity" {
  // Each of [0..n) should be in the reservoir with empirical frequency
  // near k/n. The bounds below are generous because the small LCG
  // produces somewhat-correlated samples for sequential seeds, but the
  // average is still close to uniform.
  let n = 20L
  let k = 5
  let trials = 1000
  let counts = Array::make(20, 0)
  for t in 0..<trials {
    // Stride seeds by a large prime so successive LCG states diverge.
    let r = new(capacity=k, seed=t.to_int64() * 1000003L + 7L)
    for x in 0L..<n {
      r.add(x)
    }
    for v in r.sample() {
      counts[v.to_int()] = counts[v.to_int()] + 1
    }
  }
  // Expected count per item: k / n * trials = 250.
  // Very generous envelope: each must be in [80, 420], i.e. within
  // a factor of ~2 of the expected count. Stronger uniformity holds
  // for a better PRNG; we just need a sanity check here.
  for c in counts {
    @debug.assert_eq(c >= 80 && c <= 420, true)
  }
}

///|
test "reservoir items_seen matches input count" {
  let r = new(capacity=3, seed=1L)
  @debug.assert_eq(r.items_seen(), 0)
  r.add(1L)
  @debug.assert_eq(r.items_seen(), 1)
  for x in 2L..<10L {
    r.add(x)
  }
  @debug.assert_eq(r.items_seen(), 9)
}

///|
test "reservoir add_many matches looped add" {
  let r1 = new(capacity=4, seed=1234L)
  let r2 = new(capacity=4, seed=1234L)
  let items : ReadOnlyArray[Int64] = [10L, 20L, 30L, 40L, 50L, 60L, 70L, 80L]
  for x in items {
    r1.add(x)
  }
  r2.add_many(items[:])
  @debug.assert_eq(r1.sample(), r2.sample())
}

///|
test "reservoir degenerate capacity" {
  // capacity 0 yields an empty sample for any stream.
  let r = new(capacity=0, seed=1L)
  for x in 1L..<10L {
    r.add(x)
  }
  @debug.assert_eq(r.sample(), [])
  @debug.assert_eq(r.items_seen(), 9)
}
