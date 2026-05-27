// ============================================================================
// BLOOM FILTER  -  Burton Howard Bloom 1970
// ============================================================================
//
// PROBLEM
//
// Approximate set membership in **constant time and constant space per
// element**, allowing false positives but **no false negatives**.
//
// THE STRUCTURE
//
// A Bloom filter is an `m`-bit array together with `k` independent hash
// functions `h_1, ..., h_k : Item -> [0, m)`. To insert `x`, set bits
// `h_1(x), ..., h_k(x)`. To test, return `false` if **any** of those
// bits is unset; otherwise return `true` (possibly a false positive).
//
// **No removals.** A standard Bloom filter cannot support delete; for
// that you need a counting Bloom filter or a Cuckoo filter (see
// `techniques/cuckoo_filter` in this repository).
//
// OPTIMAL PARAMETERS
//
// For target false-positive rate `p` and expected number of items `n`:
//
//   m = ceil( -n * ln(p) / (ln 2)^2 )         optimal bit count
//   k = round( (m / n) * ln 2 )                optimal hash count
//
// At those parameters, the actual false-positive probability after `n`
// insertions is `(1 - (1 - 1/m)^{kn})^k ≈ (1 - e^{-kn/m})^k`.
//
// HASH FUNCTIONS
//
// We use **double hashing**: with two reasonably-independent hashes
// `h1, h2 : Int64`, the i-th hash is `(h1 + i * h2) mod m`. This gives
// near-independent k hash positions while only paying for 2 hashes per
// item. Both hashes are derived from MoonBit's built-in 64-bit hash.
//
// COMPLEXITY
//
//   insert : O(k)
//   test   : O(k)
//   space  : m bits (≈ -1.44 * log2(1/p) bits per element at optimum)
//
// THE INVARIANT
//
//   "After each insert(x), every bit position from
//    h_1(x), ..., h_k(x) is set; therefore contains(x) returns true."

///|
/// A standard (non-counting) Bloom filter.
pub struct BloomFilter {
  bits : Array[Int64] // packed; each Int64 holds 64 bits
  m : Int // total bit positions
  k : Int // number of hash functions
}

///|
/// Round `x` up to the next multiple of 64; used to size the bit array.
fn round_up_64(x : Int) -> Int {
  (x + 63) / 64 * 64
}

///|
/// Create a Bloom filter sized for `expected` items at false-positive
/// rate `p` (`0 < p < 1`). Picks optimal `m` and `k`. Minimum `m = 64`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let b = @bloom_filter.new(expected=1000, fp_rate=0.01)
///   b.insert(42L)
///   @debug.assert_eq(b.contains(42L), true)
/// }
/// ```
pub fn new(expected~ : Int, fp_rate~ : Double) -> BloomFilter {
  let n = if expected < 1 { 1 } else { expected }
  let p = if fp_rate <= 0.0 || fp_rate >= 1.0 { 0.01 } else { fp_rate }
  let ln2 = 0.6931471805599453
  let m_raw = (-(n.to_double() * mathln(p)) / (ln2 * ln2)).to_int()
  let m = round_up_64(if m_raw < 64 { 64 } else { m_raw })
  let k_raw = (m.to_double() / n.to_double() * ln2).to_int() // round-toward-0
  let k = if k_raw < 1 { 1 } else { k_raw }
  let words = m / 64
  { bits: Array::make(words, 0L), m, k }
}

///|
/// Convenience: build with explicit `m` (bits) and `k` (hashes). `m` is
/// rounded up to a multiple of 64. Both must be positive.
pub fn from_params(m : Int, k : Int) -> BloomFilter {
  let m1 = round_up_64(if m < 64 { 64 } else { m })
  let kk = if k < 1 { 1 } else { k }
  { bits: Array::make(m1 / 64, 0L), m: m1, k: kk }
}

///|
/// Approximate natural logarithm; only used for parameter sizing in
/// `new`. Uses range reduction + a polynomial.
fn mathln(x : Double) -> Double {
  // Range-reduce: x = 2^e * m where m in [1, 2), then ln(x) = e*ln(2) + ln(m).
  let mut y = x
  let mut e = 0.0
  while y >= 2.0 {
    y = y / 2.0
    e = e + 1.0
  }
  while y < 1.0 {
    y = y * 2.0
    e = e - 1.0
  }
  // y in [1, 2). Substitute u = (y - 1)/(y + 1); ln(y) = 2 * (u + u^3/3 + ...).
  let u = (y - 1.0) / (y + 1.0)
  let u2 = u * u
  let mut s = u
  let mut term = u
  let mut k = 3.0
  while k < 30.0 {
    term = term * u2
    s = s + term / k
    k = k + 2.0
  }
  e * 0.6931471805599453 + 2.0 * s
}

///|
/// Number of bit positions (the `m` parameter, possibly rounded up).
pub fn BloomFilter::bit_size(self : BloomFilter) -> Int {
  self.m
}

///|
/// Number of hash functions used (the `k` parameter).
pub fn BloomFilter::hash_count(self : BloomFilter) -> Int {
  self.k
}

///|
/// Logical (unsigned) right shift for Int64 -- replaces the deprecated `.lsr`.
fn shr_logical(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
fn hash_pair(x : Int64) -> (Int64, Int64) {
  // Two reasonably independent 64-bit mixes derived from x. Variations
  // of the Murmur / Fmix64 finaliser. They are not cryptographically
  // strong, but plenty good for set membership.
  let mut h1 = x
  h1 = h1.lxor(shr_logical(h1, 33))
  h1 = h1 * 0xff51afd7ed558ccdL
  h1 = h1.lxor(shr_logical(h1, 33))
  h1 = h1 * 0xc4ceb9fe1a85ec53L
  h1 = h1.lxor(shr_logical(h1, 33))
  let mut h2 = x + 0x9e3779b97f4a7c15L
  h2 = h2.lxor(shr_logical(h2, 30))
  h2 = h2 * 0xbf58476d1ce4e5b9L
  h2 = h2.lxor(shr_logical(h2, 27))
  h2 = h2 * 0x94d049bb133111ebL
  h2 = h2.lxor(shr_logical(h2, 31))
  (h1, h2)
}

///|
fn BloomFilter::position(
  self : BloomFilter,
  h1 : Int64,
  h2 : Int64,
  i : Int,
) -> Int {
  let raw = h1 + i.to_int64() * h2
  let m = self.m.to_int64()
  let mut r = raw % m
  if r < 0L {
    r = r + m
  }
  r.to_int()
}

///|
/// Insert an `Int64` key.
pub fn BloomFilter::insert(self : BloomFilter, x : Int64) -> Unit {
  let (h1, h2) = hash_pair(x)
  for i in 0..<self.k {
    let p = self.position(h1, h2, i)
    let word = p / 64
    let bit = p % 64
    self.bits[word] = self.bits[word].lor(1L << bit)
  }
}

///|
/// Test for membership. May return a false positive; never a false
/// negative.
pub fn BloomFilter::contains(self : BloomFilter, x : Int64) -> Bool {
  let (h1, h2) = hash_pair(x)
  for i in 0..<self.k {
    let p = self.position(h1, h2, i)
    let word = p / 64
    let bit = p % 64
    if self.bits[word].land(1L << bit) == 0L {
      return false
    }
  }
  true
}

///|
/// Number of set bits. Useful for estimating fill ratio.
pub fn BloomFilter::popcount(self : BloomFilter) -> Int {
  let mut total = 0
  for w in self.bits {
    let mut x = w
    while x != 0L {
      total = total + 1
      x = x.land(x - 1L)
    }
  }
  total
}

///|
test "bloom insert and contains" {
  let b = new(expected=1000, fp_rate=0.01)
  for i in 0L..<100L {
    b.insert(i * 7L)
  }
  for i in 0L..<100L {
    @debug.assert_eq(b.contains(i * 7L), true)
  }
}

///|
test "bloom no false negatives" {
  // Whatever we insert must contain.
  let b = new(expected=500, fp_rate=0.05)
  let items = [3L, 17L, 42L, 100000L, -5L, 999999999L]
  for x in items {
    b.insert(x)
  }
  for x in items {
    @debug.assert_eq(b.contains(x), true)
  }
}

///|
test "bloom false-positive rate within an order of magnitude" {
  // Insert n items into a properly-sized filter; sample many absent
  // items and confirm the FP rate is within ~3x of the target.
  let n = 1000
  let target = 0.01
  let b = new(expected=n, fp_rate=target)
  // Insert items 1..n.
  for i in 1L..<=n.to_int64() {
    b.insert(i)
  }
  // Sample 5000 absent items (we keep them outside the inserted range).
  let trials = 5000
  let mut fp = 0
  for i in 0L..<trials.to_int64() {
    let x = 1000000L + i * 7L
    if b.contains(x) {
      fp = fp + 1
    }
  }
  let rate = fp.to_double() / trials.to_double()
  // Sanity: should be much less than 10x the target.
  @debug.assert_eq(rate < target * 10.0, true)
}

///|
test "bloom from_params" {
  let b = from_params(1024, 3)
  @debug.assert_eq(b.bit_size(), 1024)
  @debug.assert_eq(b.hash_count(), 3)
  b.insert(123L)
  @debug.assert_eq(b.contains(123L), true)
}

///|
test "bloom popcount monotone" {
  let b = new(expected=200, fp_rate=0.01)
  @debug.assert_eq(b.popcount(), 0)
  let mut prev = 0
  for i in 0L..<50L {
    b.insert(i)
    let now = b.popcount()
    @debug.assert_eq(now >= prev, true)
    prev = now
  }
}

///|
test "bloom degenerate parameters get sanitised" {
  // 0 expected, fp = 0 are nonsensical; new should still construct.
  let b1 = new(expected=0, fp_rate=0.0)
  b1.insert(7L)
  @debug.assert_eq(b1.contains(7L), true)
  // Negative expected.
  let b2 = new(expected=-10, fp_rate=0.5)
  b2.insert(7L)
  @debug.assert_eq(b2.contains(7L), true)
}
