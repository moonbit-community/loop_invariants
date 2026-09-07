// ============================================================================
// WELFORD'S STREAMING MEAN AND VARIANCE  -  Welford 1962
// ============================================================================
//
// PROBLEM
//
// Maintain the running mean, variance, and standard deviation of a
// stream of `Double` values without storing the inputs and **without
// losing precision** to catastrophic cancellation.
//
// THE NAIVE FORMULA `Var = E[X^2] - E[X]^2` accumulates `sum_x_sq` and
// `sum_x`. Their final subtraction can lose nearly all significant
// digits when the values are clustered far from zero.
//
// WELFORD'S RECURRENCE (numerically stable)
//
//   delta1 = x - mean_{n-1}
//   mean_n = mean_{n-1} + delta1 / n
//   delta2 = x - mean_n
//   M2_n   = M2_{n-1} + delta1 * delta2
//
// At step n: `M2_n` is the sum of squared deviations from the running
// mean. Population variance = `M2_n / n`; sample (unbiased) variance =
// `M2_n / (n - 1)`.
//
// COMPLEXITY
//
//   add   : O(1)
//   mean / variance / std : O(1)
//   merge : O(1) -- Chan et al.'s parallel form combines two summaries
//                   without revisiting the data.
//
// THE INVARIANT
//
//   "After `n` samples have been added, count = n, mean equals the true
//    arithmetic mean of all inputs, and m2 equals sum_{i=1..n}
//    (x_i - mean)^2."

///|
/// Online accumulator for streaming mean and variance.
pub struct Welford {
  mut count : Int64
  mut mean : Double
  mut m2 : Double
}

///|
/// Empty accumulator.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let w = @welford.new()
///   w.add(1.0)
///   w.add(2.0)
///   w.add(3.0)
///   @debug.assert_eq(w.mean(), 2.0)
/// }
/// ```
pub fn new() -> Welford {
  { count: 0L, mean: 0.0, m2: 0.0, }
}

///|
/// Add a value to the stream.
pub fn Welford::add(self : Welford, x : Double) -> Unit {
  self.count = self.count + 1L
  let delta1 = x - self.mean
  self.mean = self.mean + delta1 / self.count.to_double()
  let delta2 = x - self.mean
  self.m2 = self.m2 + delta1 * delta2
}

///|
/// Number of values seen so far.
pub fn Welford::count(self : Welford) -> Int64 {
  self.count
}

///|
/// Mean of the values seen so far. `0.0` for an empty stream.
pub fn Welford::mean(self : Welford) -> Double {
  self.mean
}

///|
/// **Population** variance: `M2 / n`. `0.0` for an empty stream.
pub fn Welford::variance_pop(self : Welford) -> Double {
  if self.count == 0L {
    return 0.0
  }
  self.m2 / self.count.to_double()
}

///|
/// **Sample** (unbiased) variance: `M2 / (n - 1)`. `0.0` for fewer
/// than 2 samples.
pub fn Welford::variance_sample(self : Welford) -> Double {
  if self.count < 2L {
    return 0.0
  }
  self.m2 / (self.count - 1L).to_double()
}

///|
/// Sample standard deviation: `sqrt(variance_sample)`.
pub fn Welford::std_sample(self : Welford) -> Double {
  sqrt(self.variance_sample())
}

///|
fn sqrt(x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  let mut g = x
  let mut i = 0
  while i < 60 {
    let next = 0.5 * (g + x / g)
    if next == g {
      break
    }
    g = next
    i = i + 1
  }
  g
}

///|
/// Merge another stream into this one. Implements Chan's parallel form:
///
///   delta = b.mean - a.mean
///   a.mean = (n_a * mean_a + n_b * mean_b) / (n_a + n_b)
///   a.m2   = m2_a + m2_b + delta^2 * n_a * n_b / (n_a + n_b)
///   a.count = n_a + n_b
pub fn Welford::merge_in(self : Welford, other : Welford) -> Unit {
  if other.count == 0L {
    return
  }
  if self.count == 0L {
    self.count = other.count
    self.mean = other.mean
    self.m2 = other.m2
    return
  }
  let na = self.count.to_double()
  let nb = other.count.to_double()
  let delta = other.mean - self.mean
  let total = na + nb
  self.mean = (na * self.mean + nb * other.mean) / total
  self.m2 = self.m2 + other.m2 + delta * delta * na * nb / total
  self.count = self.count + other.count
}

///|
fn abs_d(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
test "welford basic" {
  let w = new()
  w.add(1.0)
  w.add(2.0)
  w.add(3.0)
  @debug.assert_eq(w.mean(), 2.0)
  // variance_pop = (1 + 0 + 1) / 3 = 2/3.
  @debug.assert_eq(abs_d(w.variance_pop() - 2.0 / 3.0) < 1.0e-12, true)
  // variance_sample = 2 / 2 = 1.0.
  @debug.assert_eq(abs_d(w.variance_sample() - 1.0) < 1.0e-12, true)
}

///|
test "welford empty" {
  let w = new()
  @debug.assert_eq(w.count(), 0L)
  @debug.assert_eq(w.mean(), 0.0)
  @debug.assert_eq(w.variance_pop(), 0.0)
  @debug.assert_eq(w.variance_sample(), 0.0)
}

///|
test "welford single sample" {
  let w = new()
  w.add(42.0)
  @debug.assert_eq(w.mean(), 42.0)
  @debug.assert_eq(w.variance_sample(), 0.0)
}

///|
test "welford constant stream zero variance" {
  let w = new()
  for _ in 0..<100 {
    w.add(7.5)
  }
  @debug.assert_eq(w.mean(), 7.5)
  @debug.assert_eq(w.variance_pop() < 1.0e-12, true)
}

///|
test "welford merge equals serial" {
  let a = new()
  let b = new()
  let serial = new()
  for x in [1.0, 2.0, 3.0, 4.0, 5.0] {
    a.add(x)
    serial.add(x)
  }
  for x in [6.0, 7.0, 8.0, 9.0, 10.0] {
    b.add(x)
    serial.add(x)
  }
  a.merge_in(b)
  @debug.assert_eq(a.count(), serial.count())
  @debug.assert_eq(abs_d(a.mean() - serial.mean()) < 1.0e-9, true)
  @debug.assert_eq(
    abs_d(a.variance_pop() - serial.variance_pop()) < 1.0e-9,
    true,
  )
}

///|
test "welford numerical stability vs naive" {
  // Welford should compute variance accurately even when all samples
  // are far from zero. The naive E[X^2] - E[X]^2 cancels here.
  let w = new()
  for i in 0L..<10000L {
    w.add(1.0e9 + (i % 3L).to_double())
  }
  // True variance for {0, 1, 2} uniformly over 10000 samples:
  // Mean 1; var_pop = ((0-1)^2 + (1-1)^2 + (2-1)^2)/3 = 2/3.
  let v = w.variance_pop()
  @debug.assert_eq(abs_d(v - 2.0 / 3.0) < 1.0e-3, true)
}

///|
test "welford negative values" {
  let w = new()
  for x in [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0] {
    w.add(x)
  }
  @debug.assert_eq(abs_d(w.mean() - 0.0) < 1.0e-12, true)
  // var_pop = (25 + 9 + 1 + 1 + 9 + 25) / 6 = 70 / 6.
  @debug.assert_eq(abs_d(w.variance_pop() - 70.0 / 6.0) < 1.0e-12, true)
}
