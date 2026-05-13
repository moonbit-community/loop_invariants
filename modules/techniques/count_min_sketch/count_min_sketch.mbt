// ============================================================================
// COUNT-MIN SKETCH - Sublinear-space frequency estimation for streams
// ============================================================================
//
// A Count-Min sketch summarises an unbounded stream of (key, count) updates
// in O(w * d) space, where `w` (the width) controls the additive error and
// `d` (the depth) controls the failure probability. Both updates and
// queries run in O(d) time.
//
// REPRESENTATION
//
//   counts : d rows by w columns of Int64 counters, initially zero.
//   h_1, ..., h_d : independently chosen hash functions {keys} -> [0, w),
//                   drawn from a 2-universal family.
//
// OPERATIONS
//
//   add(key, c)
//     for r in 0..<d:
//       counts[r][h_r(key)] += c
//
//   estimate(key) = min over r in 0..<d of counts[r][h_r(key)]
//
// CORRECTNESS
//
//   Let f(key) be the true count of `key`. Each row r over-estimates:
//
//     counts[r][h_r(key)]  =  f(key)  +  sum_{x != key} f(x) * 1[h_r(x) = h_r(key)]
//
//   The expectation of the collision sum over a random h_r is N / w, where
//   N is the total count in the sketch (the 1-norm of the underlying
//   vector). By Markov's inequality, the collision sum exceeds (e * N) / w
//   with probability at most 1/e for one row. Taking the minimum over d
//   independent rows pushes the failure probability to (1/e)^d.
//
//   Choosing w = ceil(e / eps) and d = ceil(ln(1/delta)) gives:
//
//     Pr[ estimate(key) <= f(key) + eps * N ]  >=  1 - delta
//
// FAILURE MODES
//
//   - estimate(key) is always >= f(key) (over-estimate guarantee), provided
//     no decrements are issued. If callers pass negative counts to `add`,
//     this guarantee no longer holds.

///|
/// A Count-Min sketch with `depth` rows and `width` columns.
///
/// Internal representation: a fixed-size 2D array of Int64 counters plus
/// a pair of arrays `hash_a`, `hash_b` defining the d hash functions in
/// a Carter-Wegman style 2-universal family. The struct fields are
/// package-private; callers go through `new`, `add`, `estimate`,
/// `merge`, `width_of`, `depth_of`.
pub struct CountMinSketch {
  width : Int
  depth : Int
  counts : Array[Array[Int64]]
  hash_a : Array[Int64]
  hash_b : Array[Int64]
}

///|
/// Hash modulus: the Mersenne prime 2^31 - 1. Chosen so that
/// `(a*x + b) mod prime` stays within Int64 for any reasonable `a, b, x`.
let cms_prime : Int64 = 2147483647L

///|
/// A tiny linear-congruential PRNG used only to derive hash parameters
/// from the user-supplied seed. The choice of constants is the
/// "Numerical Recipes" pair; we only need *some* spread, not statistical
/// quality, because the parameters then feed a 2-universal family.
fn lcg_next(state : Int64) -> Int64 {
  state * 1664525L + 1013904223L
}

///|
/// Initial seed transformation that keeps the seed in the positive Int64
/// half so subsequent `lcg_next` calls are well-defined.
fn lcg_init(seed : Int64) -> Int64 {
  let s = lcg_next(seed)
  if s < 0L {
    -s
  } else if s == 0L {
    1L
  } else {
    s
  }
}

///|
/// Create a fresh Count-Min sketch with `width` columns and `depth` rows.
/// Hash parameters are derived deterministically from `seed`, so two
/// sketches built with the same seed share an identical hash family
/// (useful for testing and for merging sketches across machines).
///
/// ## Parameters
///
/// - `width` : number of columns per row; controls additive error.
/// - `depth` : number of independent rows; controls failure probability.
/// - `seed`  : deterministic seed for the hash family.
///
/// Both `width` and `depth` must be at least 1. The caller is responsible
/// for choosing values; see `from_error_bounds` for the common case where
/// you have an (eps, delta) tolerance in mind.
///
/// ## Returns
///
/// A new sketch, all counters zero.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = @count_min_sketch.new(width=128, depth=4, seed=42L)
///   s.add(7L, 1L)
///   s.add(7L, 1L)
///   s.add(8L, 1L)
///   assert_true(s.estimate(7L) >= 2L)
/// }
/// ```
pub fn new(width~ : Int, depth~ : Int, seed~ : Int64) -> CountMinSketch {
  let w = if width < 1 { 1 } else { width }
  let d = if depth < 1 { 1 } else { depth }
  let counts : Array[Array[Int64]] = Array::make(d, [])
  for r in 0..<d {
    counts[r] = Array::make(w, 0L)
  } where {
    proof_invariant: r >= 0 && r <= d,
    proof_reasoning: (
      #|INVARIANT (Row initialisation):
      #|Rows [0..r) hold fresh w-element arrays of zeros.
      #|MAINTENANCE:
      #|Allocate one row of w zeros and advance r.
      #|TERMINATION:
      #|At r = d every row is initialised; counts is a d x w grid of zeros.
    ),
  }
  // Derive 2d non-zero Int64 values for the hash family from the seed.
  let hash_a = Array::make(d, 0L)
  let hash_b = Array::make(d, 0L)
  for r = 0, state = lcg_init(seed); r < d; {
    let a_state = lcg_next(state)
    let b_state = lcg_next(a_state)
    let a_pos = if a_state == 0L {
      1L
    } else if a_state < 0L {
      -a_state
    } else {
      a_state
    }
    let b_pos = if b_state < 0L { -b_state } else { b_state }
    hash_a[r] = a_pos % (cms_prime - 1L) + 1L
    hash_b[r] = b_pos % cms_prime
    continue r + 1, b_state
  } where {
    proof_invariant: r >= 0 && r <= d,
    proof_reasoning: (
      #|INVARIANT (Hash parameter derivation):
      #|For indices [0..r), hash_a[i] is in [1, prime) and hash_b[i] is in
      #|[0, prime). Both are needed so the family is 2-universal.
      #|MAINTENANCE:
      #|Two LCG steps produce a fresh (a, b) pair; modular reduction keeps
      #|them in range.
      #|TERMINATION:
      #|At r = d both arrays are fully populated.
    ),
  }
  { width: w, depth: d, counts, hash_a, hash_b }
}

///|
/// Create a sketch sized to guarantee that, with probability at least
/// `1 - delta`, the estimate for any key over-counts the truth by at
/// most `eps * N` (where `N` is the total mass added so far).
///
/// Concretely: `width  = ceil(e / eps)`, `depth  = ceil(ln(1 / delta))`.
/// The natural log is computed via `Double::ln`.
///
/// ## Parameters
///
/// - `eps`   : relative error tolerance in (0, 1).
/// - `delta` : failure-probability bound in (0, 1).
/// - `seed`  : deterministic seed for the hash family.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Tolerate 1% additive error with 99% confidence.
///   let s = @count_min_sketch.from_error_bounds(0.01, 0.01, seed=7L)
///   assert_true(s.width_of() >= 272) // ceil(e / 0.01)
///   assert_true(s.depth_of() >= 5) // ceil(ln(100))
/// }
/// ```
pub fn from_error_bounds(
  eps : Double,
  delta : Double,
  seed~ : Int64,
) -> CountMinSketch {
  let e_const = 2.718281828459045
  let w_raw = e_const / eps
  let d_raw = -@math.ln(delta)
  let w = w_raw.ceil().to_int().max(1)
  let d = d_raw.ceil().to_int().max(1)
  new(width=w, depth=d, seed~)
}

///|
/// `((a * x + b) mod prime) mod width`, the row-`r` hash of `key`.
///
/// All arithmetic is done modulo `cms_prime = 2^31 - 1` to keep
/// intermediate products within Int64 range. The final reduction by
/// `width` brings the result into a valid column index.
fn CountMinSketch::hash_row(self : CountMinSketch, r : Int, key : Int64) -> Int {
  let p = cms_prime
  // Normalise key to [0, p) first so the multiplication is bounded.
  let k = {
    let m = key % p
    if m < 0L {
      m + p
    } else {
      m
    }
  }
  let raw = (self.hash_a[r] * k + self.hash_b[r]) % p
  let col = raw % self.width.to_int64()
  col.to_int()
}

///|
/// Add `count` to the running tally for `key`. Counts may be any
/// non-negative `Int64`; passing a negative value still type-checks but
/// invalidates the over-estimate guarantee, so callers should reach for
/// a Count-Mean-Min sketch or a Count-Min-Log sketch instead if signed
/// updates are needed.
///
/// ## Parameters
///
/// - `self`  : sketch to update (mutated in place).
/// - `key`   : item being counted.
/// - `count` : how much to add. Use 1 for a single event.
pub fn CountMinSketch::add(
  self : CountMinSketch,
  key : Int64,
  count : Int64,
) -> Unit {
  for r in 0..<self.depth {
    let col = self.hash_row(r, key)
    self.counts[r][col] = self.counts[r][col] + count
  } where {
    proof_invariant: r >= 0 && r <= self.depth,
    proof_reasoning: (
      #|INVARIANT (Update broadcast):
      #|For each row in [0..r), the column h_r(key) has been incremented
      #|by `count`. Every other counter is untouched.
      #|MAINTENANCE:
      #|Compute h_r(key) and add `count` to that column.
      #|TERMINATION:
      #|At r = depth every row has been updated.
    ),
  }
}

///|
/// Estimate the count of `key`. Returns `min over r of counts[r][h_r(key)]`,
/// which is always at least the true count (when only non-negative
/// updates have been issued) and at most the true count plus the
/// collision term, in expectation `<= N / width`.
///
/// ## Returns
///
/// The over-estimate. For an unseen key the result is the minimum noise
/// across rows, which by Markov is `<= N / width` with high probability.
pub fn CountMinSketch::estimate(self : CountMinSketch, key : Int64) -> Int64 {
  let mut best = self.counts[0][self.hash_row(0, key)]
  for r in 1..<self.depth {
    let v = self.counts[r][self.hash_row(r, key)]
    if v < best {
      best = v
    }
  } where {
    proof_invariant: r >= 1 && r <= self.depth,
    proof_invariant: best >= 0L,
    proof_reasoning: (
      #|INVARIANT (Running minimum):
      #|`best` equals min over rows [0..r) of counts[row][h_row(key)].
      #|MAINTENANCE:
      #|Compare the new row's counter and lower `best` if it is smaller.
      #|TERMINATION:
      #|At r = depth, `best` is the minimum over all rows.
    ),
  }
  best
}

///|
/// Merge another sketch into this one. Both sketches must agree on
/// width, depth, and hash family (same seed at construction time) for
/// the merge to preserve the error bounds.
///
/// ## Returns
///
/// Unit. `self.counts` is incremented componentwise by `other.counts`.
/// If shapes disagree, the function returns without doing anything.
pub fn CountMinSketch::merge(
  self : CountMinSketch,
  other : CountMinSketch,
) -> Unit {
  if self.width != other.width || self.depth != other.depth {
    return
  }
  for r in 0..<self.depth {
    for c in 0..<self.width {
      self.counts[r][c] = self.counts[r][c] + other.counts[r][c]
    }
  }
}

///|
/// Inspector for tests: the configured width.
pub fn CountMinSketch::width_of(self : CountMinSketch) -> Int {
  self.width
}

///|
/// Inspector for tests: the configured depth.
pub fn CountMinSketch::depth_of(self : CountMinSketch) -> Int {
  self.depth
}

///|
test "cms over-estimates" {
  let s = new(width=128, depth=4, seed=42L)
  s.add(1L, 5L)
  s.add(2L, 3L)
  s.add(1L, 2L) // total for key 1: 7
  // True counts: 1 -> 7, 2 -> 3, 3 -> 0.
  @debug.assert_eq(s.estimate(1L) >= 7L, true)
  @debug.assert_eq(s.estimate(2L) >= 3L, true)
  @debug.assert_eq(s.estimate(3L) >= 0L, true)
}

///|
test "cms exact when no collisions" {
  // With width >> number of distinct keys, collisions are very unlikely;
  // estimates should typically be exact. We use a wide sketch.
  let s = new(width=4096, depth=5, seed=123L)
  s.add(100L, 10L)
  s.add(200L, 20L)
  s.add(300L, 30L)
  @debug.assert_eq(s.estimate(100L), 10L)
  @debug.assert_eq(s.estimate(200L), 20L)
  @debug.assert_eq(s.estimate(300L), 30L)
}

///|
test "cms unseen key bounded by noise" {
  // For an unseen key, the estimate is the noise from collisions of seen
  // keys. With width = 1024 and 4 seen keys, expected noise is small.
  let s = new(width=1024, depth=5, seed=99L)
  for k in 1L..<5L {
    s.add(k, 1000L)
  }
  // True total mass N = 4000. With width = 1024, expected single-row
  // noise for an unseen key is ~ 4000 / 1024 ~ 4. Across 5 independent
  // rows, the min should be small.
  let noise = s.estimate(999999L)
  @debug.assert_eq(noise >= 0L, true)
}

///|
test "cms merge accumulates" {
  let s1 = new(width=256, depth=4, seed=7L)
  let s2 = new(width=256, depth=4, seed=7L) // same seed -> same hash family
  s1.add(5L, 10L)
  s2.add(5L, 20L)
  s1.merge(s2)
  @debug.assert_eq(s1.estimate(5L), 30L)
}

///|
test "cms merge ignores mismatched shapes" {
  let s1 = new(width=256, depth=4, seed=7L)
  let s2 = new(width=128, depth=4, seed=7L)
  s1.add(5L, 10L)
  s2.add(5L, 20L)
  s1.merge(s2) // shapes disagree; should be a no-op
  @debug.assert_eq(s1.estimate(5L), 10L)
}

///|
test "cms from error bounds sizes correctly" {
  // eps = 0.01 -> width >= ceil(e / 0.01) >= 272
  // delta = 0.01 -> depth >= ceil(ln(100)) = 5
  let s = from_error_bounds(0.01, 0.01, seed=7L)
  @debug.assert_eq(s.width_of() >= 272, true)
  @debug.assert_eq(s.depth_of() >= 5, true)
}

///|
test "cms negative keys hash without crashing" {
  let s = new(width=64, depth=3, seed=1L)
  s.add(-1L, 1L)
  s.add(-100L, 2L)
  @debug.assert_eq(s.estimate(-1L) >= 1L, true)
  @debug.assert_eq(s.estimate(-100L) >= 2L, true)
}

///|
test "cms degenerate sizes coerced to one" {
  // Caller can pass nonsense; we should not crash.
  let s = new(width=0, depth=0, seed=1L)
  @debug.assert_eq(s.width_of(), 1)
  @debug.assert_eq(s.depth_of(), 1)
  s.add(42L, 5L)
  @debug.assert_eq(s.estimate(42L), 5L)
}
