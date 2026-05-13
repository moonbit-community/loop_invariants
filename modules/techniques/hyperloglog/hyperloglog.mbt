// ============================================================================
// HYPERLOGLOG - Cardinality estimation in O(log log N) bits per register
// ============================================================================
//
// Estimate `|{ x : x has been added }|` for a stream of items, using
// `m = 2^precision` tiny registers and a single hash function. The
// register width is `O(log log N)` (5-6 bits per register suffices for
// streams up to 10^9), so a `precision = 14` HLL fits in ~12 KB and
// estimates cardinalities up to 10^9 within a 1% standard error.
//
// THE TRICK (Flajolet, Fusy, Gandouet, Meunier, 2007)
//
// Hash each item to a uniform 64-bit string.
//
//   bits [0..precision) of the hash  -- bucket index j in [0, m)
//   bits [precision..64) of the hash -- a "tail" we examine
//
// Let `rho(tail)` = position of the leftmost 1-bit in `tail` (1-indexed).
// Update register j by `register[j] := max(register[j], rho(tail))`.
//
// For uniformly random hashes, the probability of seeing `rho >= k` for
// at least one of `n` items hashing into bucket `j` is `1 - (1 - 2^-k)^n`,
// so the *max* of `n` rho-values tracks `log2(n)` quite tightly.
//
// THE ESTIMATOR
//
//   E_raw  =  alpha_m * m^2  /  sum_{j} 2^{-register[j]}
//
// The denominator is the *harmonic* mean of `2^register[j]`. The
// constant `alpha_m` corrects for a small bias introduced by the
// expectation-of-max approximation:
//
//   alpha_16 = 0.673   alpha_32 = 0.697   alpha_64 = 0.709
//   alpha_m  = 0.7213 / (1 + 1.079 / m)         (m >= 128)
//
// Two corrections smooth out the small-range and large-range regimes:
//
//   - small  (E_raw <= 2.5 * m):  count empty registers V; if V > 0,
//                                 use E = m * ln(m / V)  ("linear
//                                 counting").
//   - large  (E_raw > 2^32 / 30): no correction needed in our Int64
//                                 setting -- we never overflow.
//
// THEORETICAL ERROR
//
//   Standard error  ~  1.04 / sqrt(m)
//
// With m = 16384 (precision = 14), SE ~= 0.81%.
//
// TIME COMPLEXITY  : O(1) per add, O(m) per estimate
// SPACE COMPLEXITY : O(m) registers; in practice 6 bits each

///|
/// HyperLogLog cardinality sketch.
pub struct HyperLogLog {
  precision : Int
  m : Int
  registers : Array[Int]
}

///|
/// Logical right shift on Int64 (Int64's built-in `>>` is arithmetic
/// and would sign-extend negative values, which we don't want when
/// using the result as a hash bit-pattern).
fn shr_logical(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
/// MurmurHash3-style 64-bit finaliser. We need uniformly mixed bits
/// across the whole 64-bit output for the HLL register/tail split to
/// be approximately uniform.
fn hll_mix(x : Int64) -> Int64 {
  let mut h = x
  h = (h ^ shr_logical(h, 33)) * 0xff51afd7ed558ccdL
  h = (h ^ shr_logical(h, 33)) * 0xc4ceb9fe1a85ec53L
  h = h ^ shr_logical(h, 33)
  h
}

///|
/// Build an empty HyperLogLog sketch with `precision` index bits.
///
/// ## Parameters
///
/// - `precision` : number of hash bits used for register selection.
///                 Must satisfy `4 <= precision <= 16`. The number of
///                 registers is `2^precision`; typical pick is 14
///                 (16384 registers, ~1% standard error).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let h = @hyperloglog.new(14)
///   for x in 0L..<1000L {
///     h.add(x)
///   }
///   let estimate = h.estimate()
///   // estimate ~ 1000 (within ~1% standard error)
///   assert_true(estimate > 900 && estimate < 1100)
/// }
/// ```
pub fn new(precision : Int) -> HyperLogLog {
  let p = if precision < 4 {
    4
  } else if precision > 16 {
    16
  } else {
    precision
  }
  let m = 1 << p
  let registers = Array::make(m, 0)
  { precision: p, m, registers }
}

///|
/// Count the leading zeros in the low `(64 - precision)` bits of a
/// hash, plus 1 (i.e. the 1-indexed position of the leftmost 1-bit
/// among those bits). If all `64 - precision` bits are zero, return
/// `64 - precision + 1`.
fn count_leading(tail : Int64, bits : Int) -> Int {
  for r = 1, mask = 1L << (bits - 1) {
    if mask == 0L {
      // We've scanned all `bits` bits and saw no 1.
      break bits + 1
    }
    if (tail & mask) != 0L {
      break r
    }
    continue r + 1, mask >> 1
  } where {
    proof_invariant: r >= 1 && r <= bits + 1,
    proof_invariant: mask >= 0L,
    proof_reasoning: (
      #|INVARIANT (Leading-zero scan):
      #|At step r we have already confirmed that bits [bits .. bits - r + 1)
      #|are all zero. `mask` is the bit being tested in this iteration.
      #|MAINTENANCE:
      #|Right-shift the mask; increment r; loop continues if the bit is 0.
      #|TERMINATION:
      #|After at most `bits` iterations the mask reaches zero and we
      #|return bits + 1.
    ),
  }
}

///|
/// Add one item to the sketch.
pub fn HyperLogLog::add(self : HyperLogLog, x : Int64) -> Unit {
  let h = hll_mix(x)
  // Top `precision` bits choose the bucket; rest of the hash is the tail.
  let bucket_bits = self.precision
  let tail_bits = 64 - bucket_bits
  let bucket = (h >> tail_bits).land((1L << bucket_bits) - 1L).to_int()
  let tail = h.land((1L << tail_bits) - 1L)
  let rho = count_leading(tail, tail_bits)
  if self.registers[bucket] < rho {
    self.registers[bucket] = rho
  }
}

///|
/// Compute the cardinality estimate.
pub fn HyperLogLog::estimate(self : HyperLogLog) -> Int64 {
  let m_double = self.m.to_double()
  // Harmonic mean of 2^register[j].
  let mut sum_inv = 0.0
  for r in self.registers {
    sum_inv = sum_inv + @math.pow(2.0, -r.to_double())
  }
  let alpha = alpha_m(self.m)
  let raw = alpha * m_double * m_double / sum_inv
  // Small-range correction (linear counting).
  if raw <= 2.5 * m_double {
    let mut zeros = 0
    for r in self.registers {
      if r == 0 {
        zeros = zeros + 1
      }
    }
    if zeros > 0 {
      let lin = m_double * @math.ln(m_double / zeros.to_double())
      return (lin + 0.5).to_int64()
    }
  }
  // Large-range correction is unnecessary in our Int64 setting.
  (raw + 0.5).to_int64()
}

///|
/// HLL bias-correction constant. Special-cased for small m as per the
/// original paper.
fn alpha_m(m : Int) -> Double {
  if m == 16 {
    0.673
  } else if m == 32 {
    0.697
  } else if m == 64 {
    0.709
  } else {
    0.7213 / (1.0 + 1.079 / m.to_double())
  }
}

///|
/// Merge two sketches with the same precision: take the elementwise
/// max of registers. This is the standard distributed-aggregation
/// trick that makes HLL work across machines.
pub fn HyperLogLog::merge(self : HyperLogLog, other : HyperLogLog) -> Unit {
  if self.m != other.m {
    return
  }
  for j in 0..<self.m {
    if other.registers[j] > self.registers[j] {
      self.registers[j] = other.registers[j]
    }
  }
}

///|
/// Number of registers (m = 2^precision).
pub fn HyperLogLog::register_count(self : HyperLogLog) -> Int {
  self.m
}

///|
test "hll empty has zero estimate" {
  let h = new(10)
  @debug.assert_eq(h.estimate(), 0L)
}

///|
test "hll single element" {
  let h = new(10)
  h.add(42L)
  // One distinct value -- linear counting gives a small positive estimate.
  let est = h.estimate()
  @debug.assert_eq(est >= 0L, true)
  @debug.assert_eq(est <= 5L, true)
}

///|
test "hll 1000 distinct elements within tolerance" {
  let h = new(14) // 16384 registers, SE ~ 0.8%
  for x in 0L..<1000L {
    h.add(x)
  }
  let est = h.estimate()
  // Should be within ~5% (5σ) of the truth.
  @debug.assert_eq(est >= 950L, true)
  @debug.assert_eq(est <= 1050L, true)
}

///|
test "hll duplicates don't inflate estimate" {
  let h = new(12)
  // Add the same 50 values 100 times each -- still only 50 distinct.
  for v in 0L..<50L {
    for _ in 0..<100 {
      h.add(v)
    }
  }
  let est = h.estimate()
  // Within a wide tolerance: not 5000 (would mean we counted dupes).
  @debug.assert_eq(est < 200L, true)
}

///|
test "hll merge takes elementwise max" {
  let a = new(10)
  let b = new(10)
  for v in 0L..<500L {
    a.add(v)
  }
  for v in 500L..<1000L {
    b.add(v)
  }
  a.merge(b)
  let est = a.estimate()
  // Merged sketch reflects ~1000 distinct values. With m = 1024,
  // SE ~3%, a 3-sigma envelope is roughly [900, 1100]; we give a
  // wider band for hash-finaliser tails on small integer inputs.
  @debug.assert_eq(est >= 850L, true)
  @debug.assert_eq(est <= 1150L, true)
}

///|
test "hll merge mismatched precisions is noop" {
  let a = new(10)
  let b = new(12)
  a.add(1L)
  b.add(2L)
  a.merge(b) // shape mismatch -- nothing changes
  @debug.assert_eq(a.estimate() <= 5L, true)
}

///|
test "hll degenerate precision coerced into range" {
  let h_low = new(0) // coerced to 4
  let h_high = new(100) // coerced to 16
  @debug.assert_eq(h_low.register_count(), 16)
  @debug.assert_eq(h_high.register_count(), 65536)
}

///|
test "hll register count is 2^precision" {
  let h10 = new(10)
  let h14 = new(14)
  @debug.assert_eq(h10.register_count(), 1024)
  @debug.assert_eq(h14.register_count(), 16384)
}
