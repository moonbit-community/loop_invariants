// ============================================================================
// T-DIGEST - Streaming quantile sketch (Dunning 2014)
// ============================================================================
//
// PROBLEM
//
// Given a stream of `n` Double values, estimate any quantile q in
// (0, 1) -- median, p99, p999 -- in O(1) extra space per centroid,
// independent of n.
//
// THE IDEA
//
// Maintain a small array of "centroids" each summarising a contiguous
// run of sorted samples by (mean, weight). The total weight equals
// the number of samples consumed. Centroids near the tails (q ~ 0 or
// q ~ 1) are kept small for accuracy; centroids near the median can
// be larger because we don't need precise rank there.
//
// The size limit on a centroid at empirical quantile q in [0, 1] is
//
//     k(q) = (compression / 2pi) * arcsin(2q - 1) + compression / 4
//
// (so k is monotone increasing in q, with k(0) = 0 and k(1) =
// compression / 2). A centroid is "full" when (k(q_max) - k(q_min))
// reaches 1. Merging proceeds left-to-right; when full, a new
// centroid starts.
//
// THE INVARIANT
//
// After every add or merge:
//
//   I1. Centroids are in non-decreasing order of mean.
//   I2. Sum of weights equals the number of samples consumed.
//   I3. For each centroid, the empirical quantile range [q_lo, q_hi]
//       it covers satisfies k(q_hi) - k(q_lo) <= 1.
//
// I3 is the load-bearing invariant: it bounds the absolute rank error
// for any quantile query to about `n * 2pi / compression` -- so
// `compression = 100` gives ~6% rank error, `compression = 1000`
// gives ~0.6%.
//
// TIME COMPLEXITY  : O(log n) per add (binary search + insert)
// SPACE COMPLEXITY : O(compression)

///|
/// A streaming quantile sketch consisting of a small list of
/// `(mean, weight)` centroids.
pub struct TDigest {
  compression : Double
  // Sorted by mean.
  means : Array[Double]
  weights : Array[Double]
  mut total_weight : Double
}

///|
/// Create a fresh t-digest. `compression` controls the maximum number
/// of centroids the sketch will keep (roughly `compression` of them).
/// Common values: 50-1000.
pub fn new(compression~ : Double) -> TDigest {
  let c = if compression < 20.0 { 20.0 } else { compression }
  { compression: c, means: [], weights: [], total_weight: 0.0 }
}

///|
/// Add one sample to the sketch.
pub fn TDigest::add(self : TDigest, x : Double) -> Unit {
  // Find the insertion index via linear scan (compression is small).
  let mut idx = 0
  while idx < self.means.length() && self.means[idx] < x {
    idx = idx + 1
  }
  // Try merging into an adjacent centroid if there's headroom.
  let n = self.means.length()
  if n == 0 {
    self.means.push(x)
    self.weights.push(1.0)
  } else if idx < n && self.can_merge(idx, 1.0) {
    let w_new = self.weights[idx] + 1.0
    self.means[idx] = self.means[idx] + (x - self.means[idx]) / w_new
    self.weights[idx] = w_new
  } else if idx > 0 && self.can_merge(idx - 1, 1.0) {
    let w_new = self.weights[idx - 1] + 1.0
    self.means[idx - 1] = self.means[idx - 1] +
      (x - self.means[idx - 1]) / w_new
    self.weights[idx - 1] = w_new
  } else {
    self.means.insert(idx, x)
    self.weights.insert(idx, 1.0)
  }
  self.total_weight = self.total_weight + 1.0
  // Lazy compaction: if we have more than compression centroids, run a
  // merge pass.
  if self.means.length().to_double() > self.compression * 2.0 {
    self.compress()
  }
}

///|
/// Check whether the centroid at index `idx` can absorb `extra_weight`
/// more without violating the k-function bound.
fn TDigest::can_merge(self : TDigest, idx : Int, extra_weight : Double) -> Bool {
  if self.total_weight < 1.0 {
    return true
  }
  // Empirical quantile bracket of the centroid at idx.
  let mut prefix = 0.0
  for i in 0..<idx {
    prefix = prefix + self.weights[i]
  }
  let new_total = self.total_weight + extra_weight
  let q_lo = prefix / new_total
  let q_hi = (prefix + self.weights[idx] + extra_weight) / new_total
  // Check k(q_hi) - k(q_lo) <= 1.
  let k_diff = k_value(q_hi, self.compression) - k_value(q_lo, self.compression)
  k_diff <= 1.0
}

///|
/// Scale function k(q) for t-digest with the given compression. Maps
/// [0, 1] -> [0, compression / 2] monotonically.
fn k_value(q : Double, compression : Double) -> Double {
  let qc = if q <= 0.0 { 0.0 } else if q >= 1.0 { 1.0 } else { q }
  // k(q) = (compression / 2pi) * arcsin(2q - 1) + compression / 4
  let two_pi = 6.283185307179586
  let s = 2.0 * qc - 1.0
  let asin_s = asin_approx(s)
  compression / two_pi * asin_s + compression / 4.0
}

///|
/// Polynomial approximation of arcsin(x) for x in [-1, 1]. Adequate
/// for the t-digest size bound.
fn asin_approx(x : Double) -> Double {
  let xc = if x < -1.0 { -1.0 } else if x > 1.0 { 1.0 } else { x }
  // Use math::asin when available; fall back to atan2-based.
  // (MoonBit's math may not have asin directly; we use the identity
  // asin(x) = atan2(x, sqrt(1 - x*x)).)
  let s = xc * xc
  let denom = (1.0 - s).sqrt()
  if denom < 1.0e-15 {
    if xc >= 0.0 {
      1.5707963267948966
    } else {
      -1.5707963267948966
    }
  } else {
    @math.atan2(xc, denom)
  }
}

///|
/// Force a compaction pass: re-merge centroids greedily under the k
/// budget.
pub fn TDigest::compress(self : TDigest) -> Unit {
  let n = self.means.length()
  if n <= 1 {
    return
  }
  let new_means : Array[Double] = []
  let new_weights : Array[Double] = []
  let mut cur_mean = self.means[0]
  let mut cur_weight = self.weights[0]
  let mut prefix = 0.0
  for i in 1..<n {
    let extra = self.weights[i]
    let q_lo = prefix / self.total_weight
    let q_hi = (prefix + cur_weight + extra) / self.total_weight
    let k_diff = k_value(q_hi, self.compression) -
      k_value(q_lo, self.compression)
    if k_diff <= 1.0 {
      // Merge.
      let new_w = cur_weight + extra
      cur_mean = cur_mean + (self.means[i] - cur_mean) * extra / new_w
      cur_weight = new_w
    } else {
      // Emit and start fresh.
      new_means.push(cur_mean)
      new_weights.push(cur_weight)
      prefix = prefix + cur_weight
      cur_mean = self.means[i]
      cur_weight = self.weights[i]
    }
  }
  new_means.push(cur_mean)
  new_weights.push(cur_weight)
  // Replace.
  self.means.clear()
  self.weights.clear()
  for v in new_means {
    self.means.push(v)
  }
  for v in new_weights {
    self.weights.push(v)
  }
}

///|
/// Estimate the value at quantile `q` ∈ [0, 1].
///
/// Returns 0.0 for an empty sketch.
pub fn TDigest::quantile(self : TDigest, q : Double) -> Double {
  let n = self.means.length()
  if n == 0 {
    return 0.0
  }
  if q <= 0.0 {
    return self.means[0]
  }
  if q >= 1.0 {
    return self.means[n - 1]
  }
  let target = q * self.total_weight
  let mut prefix = 0.0
  for i in 0..<n {
    let mid = prefix + self.weights[i] / 2.0
    if target <= mid {
      if i == 0 {
        return self.means[0]
      }
      let prev_mid = prefix - self.weights[i - 1] / 2.0
      // Linear interpolation between the previous centroid's mid and this one.
      let span = mid - prev_mid
      if span <= 0.0 {
        return self.means[i]
      }
      let alpha = (target - prev_mid) / span
      return self.means[i - 1] + (self.means[i] - self.means[i - 1]) * alpha
    }
    prefix = prefix + self.weights[i]
  }
  self.means[n - 1]
}

///|
/// Total number of samples consumed.
pub fn TDigest::count(self : TDigest) -> Int {
  (self.total_weight + 0.5).to_int()
}

///|
/// Number of centroids currently held (for inspection / debugging).
pub fn TDigest::centroid_count(self : TDigest) -> Int {
  self.means.length()
}

///|
test "tdigest empty" {
  let t = new(compression=100.0)
  @debug.assert_eq(t.count(), 0)
  @debug.assert_eq(t.quantile(0.5), 0.0)
}

///|
test "tdigest single value" {
  let t = new(compression=100.0)
  t.add(42.0)
  @debug.assert_eq(t.count(), 1)
  // All quantiles equal the single value.
  @debug.assert_eq(t.quantile(0.5), 42.0)
}

///|
test "tdigest uniform 1000 samples median" {
  let t = new(compression=100.0)
  for i in 1..<=1000 {
    t.add(i.to_double())
  }
  let m = t.quantile(0.5)
  // Expected median ~500.5; within 10% is plenty for compression=100.
  @debug.assert_eq(m >= 450.0 && m <= 550.0, true)
}

///|
test "tdigest p99 of uniform" {
  let t = new(compression=200.0)
  for i in 1..<=1000 {
    t.add(i.to_double())
  }
  let p = t.quantile(0.99)
  // Expected p99 ≈ 990; with compression=200, ~3% error in the tail.
  @debug.assert_eq(p >= 950.0 && p <= 1010.0, true)
}

///|
test "tdigest min and max" {
  let t = new(compression=100.0)
  for x in [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0] {
    t.add(x)
  }
  @debug.assert_eq(t.quantile(0.0), 1.0)
  @debug.assert_eq(t.quantile(1.0), 9.0)
}

///|
test "tdigest count is accurate" {
  let t = new(compression=50.0)
  for _ in 0..<500 {
    t.add(0.0)
  }
  @debug.assert_eq(t.count(), 500)
}

///|
test "tdigest centroid_count bounded" {
  let t = new(compression=100.0)
  for i in 0..<10000 {
    t.add(i.to_double())
  }
  // After many samples, the centroid count is bounded near the
  // compression parameter (typically <= 4 * compression).
  @debug.assert_eq(t.centroid_count() <= 400, true)
}
