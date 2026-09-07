// ============================================================================
// BITSET  -  packed bit array on top of Array[Int64]
// ============================================================================
//
// A fixed-capacity set of integers `[0, n)` stored 64 bits per word.
// Supports the standard bitwise operations on whole sets.
//
//   - set / unset / flip / test
//   - count_set                       O(n / 64) popcount
//   - or_in / and_in / xor_in         in-place bulk ops
//   - first_set / last_set / next_set bit-twiddling scans
//
// COMPLEXITY
//
//   Per-bit op : O(1)
//   Bulk op    : O(n / 64)
//   Set scans  : O(n / 64) worst case
//
// THE INVARIANT
//
//   "After every operation, every bit at position >= capacity is 0
//    (i.e. high bits in the last word are zeroed)."

///|
/// A fixed-capacity bit array.
pub struct BitSet {
  bits : Array[Int64]
  cap : Int
}

///|
/// Build an empty bit set of capacity `capacity` (bits indexed 0..capacity).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let b = @bitset.new(100)
///   b.set(7)
///   @debug.assert_eq(b.contains(7), true)
/// }
/// ```
pub fn new(capacity : Int) -> BitSet {
  let cap = if capacity < 0 { 0 } else { capacity }
  let words = (cap + 63) / 64
  { bits: Array::make(words, 0L), cap, }
}

///|
/// Capacity (highest valid bit index + 1).
pub fn BitSet::capacity(self : BitSet) -> Int {
  self.cap
}

///|
fn BitSet::in_range(self : BitSet, i : Int) -> Bool {
  i >= 0 && i < self.cap
}

///|
/// Set bit `i` to `1`.
pub fn BitSet::set(self : BitSet, i : Int) -> Unit {
  if !self.in_range(i) {
    return
  }
  self.bits[i / 64] = self.bits[i / 64] | (1L << (i % 64))
}

///|
/// Clear bit `i` to `0`.
pub fn BitSet::unset(self : BitSet, i : Int) -> Unit {
  if !self.in_range(i) {
    return
  }
  let mask = 1L << (i % 64)
  self.bits[i / 64] = self.bits[i / 64] & mask.lnot()
}

///|
/// Toggle bit `i`.
pub fn BitSet::flip(self : BitSet, i : Int) -> Unit {
  if !self.in_range(i) {
    return
  }
  self.bits[i / 64] = self.bits[i / 64] ^ (1L << (i % 64))
}

///|
/// `true` iff bit `i` is set. Out-of-range queries return `false`.
pub fn BitSet::contains(self : BitSet, i : Int) -> Bool {
  if !self.in_range(i) {
    return false
  }
  (self.bits[i / 64] & (1L << (i % 64))) != 0L
}

///|
fn popcount64(x : Int64) -> Int {
  let mut y = x
  let mut c = 0
  while y != 0L {
    c = c + 1
    y = y & (y - 1L)
  }
  c
}

///|
/// Number of set bits.
pub fn BitSet::count_set(self : BitSet) -> Int {
  let mut total = 0
  for w in self.bits {
    total = total + popcount64(w)
  }
  total
}

///|
fn BitSet::masked_last_word(self : BitSet) -> Int64 {
  // The last word may have padding bits at the top. Return its
  // logically-valid bits (high padding zeroed).
  let words = self.bits.length()
  if words == 0 {
    return 0L
  }
  let last_bits = self.cap - 64 * (words - 1)
  if last_bits == 64 {
    self.bits[words - 1]
  } else {
    self.bits[words - 1] & ((1L << last_bits) - 1L)
  }
}

///|
/// Smallest index >= 0 that is set, or `-1` when none.
pub fn BitSet::first_set(self : BitSet) -> Int {
  let words = self.bits.length()
  for w in 0..<words {
    let v = if w + 1 == words { self.masked_last_word() } else { self.bits[w] }
    if v != 0L {
      // Find lowest set bit.
      let mut bit = 0
      let mut t = v
      while (t & 1L) == 0L {
        t = (t.reinterpret_as_uint64() >> 1).reinterpret_as_int64()
        bit = bit + 1
      }
      return 64 * w + bit
    }
  }
  -1
}

///|
/// Smallest index >= `start` that is set, or `-1` when none.
pub fn BitSet::next_set(self : BitSet, start : Int) -> Int {
  if start >= self.cap {
    return -1
  }
  let s = if start < 0 { 0 } else { start }
  let words = self.bits.length()
  let mut wi = s / 64
  // Mask out bits below s in word wi.
  let mask = if s % 64 == 0 {
    -1L
  } else {
    let shift = s % 64
    -(1L << shift)
  }
  while wi < words {
    let raw = if wi + 1 == words {
      self.masked_last_word()
    } else {
      self.bits[wi]
    }
    let v = if wi == s / 64 { raw & mask } else { raw }
    if v != 0L {
      let mut bit = 0
      let mut t = v
      while (t & 1L) == 0L {
        t = (t.reinterpret_as_uint64() >> 1).reinterpret_as_int64()
        bit = bit + 1
      }
      return 64 * wi + bit
    }
    wi = wi + 1
  }
  -1
}

///|
/// Bulk OR: `self |= other`. The other's capacity is treated as zero
/// padding past its end.
pub fn BitSet::or_in(self : BitSet, other : BitSet) -> Unit {
  let n = if self.bits.length() < other.bits.length() {
    self.bits.length()
  } else {
    other.bits.length()
  }
  for i in 0..<n {
    self.bits[i] = self.bits[i] | other.bits[i]
  }
}

///|
/// Bulk AND: `self &= other`.
pub fn BitSet::and_in(self : BitSet, other : BitSet) -> Unit {
  let n = self.bits.length()
  for i in 0..<n {
    let mask = if i < other.bits.length() { other.bits[i] } else { 0L }
    self.bits[i] = self.bits[i] & mask
  }
}

///|
/// Bulk XOR: `self ^= other`.
pub fn BitSet::xor_in(self : BitSet, other : BitSet) -> Unit {
  let n = if self.bits.length() < other.bits.length() {
    self.bits.length()
  } else {
    other.bits.length()
  }
  for i in 0..<n {
    self.bits[i] = self.bits[i] ^ other.bits[i]
  }
}

///|
test "bitset basic set test" {
  let b = new(100)
  b.set(0)
  b.set(63)
  b.set(64)
  b.set(99)
  @debug.assert_eq(b.contains(0), true)
  @debug.assert_eq(b.contains(63), true)
  @debug.assert_eq(b.contains(64), true)
  @debug.assert_eq(b.contains(99), true)
  @debug.assert_eq(b.contains(50), false)
  @debug.assert_eq(b.contains(100), false)
}

///|
test "bitset count_set" {
  let b = new(200)
  for i in [3, 17, 64, 65, 199] {
    b.set(i)
  }
  @debug.assert_eq(b.count_set(), 5)
}

///|
test "bitset unset and flip" {
  let b = new(10)
  b.set(3)
  @debug.assert_eq(b.contains(3), true)
  b.unset(3)
  @debug.assert_eq(b.contains(3), false)
  b.flip(5)
  @debug.assert_eq(b.contains(5), true)
  b.flip(5)
  @debug.assert_eq(b.contains(5), false)
}

///|
test "bitset first_set / next_set" {
  let b = new(100)
  @debug.assert_eq(b.first_set(), -1)
  b.set(50)
  b.set(75)
  b.set(2)
  @debug.assert_eq(b.first_set(), 2)
  @debug.assert_eq(b.next_set(3), 50)
  @debug.assert_eq(b.next_set(51), 75)
  @debug.assert_eq(b.next_set(76), -1)
}

///|
test "bitset bulk ops" {
  let a = new(64)
  let b = new(64)
  for x in [1, 3, 5, 7] {
    a.set(x)
  }
  for x in [3, 7, 11] {
    b.set(x)
  }
  let c = new(64)
  for x in [1, 3, 5, 7] {
    c.set(x)
  }
  c.and_in(b)
  // c should now have bits 3 and 7 only.
  @debug.assert_eq(c.contains(1), false)
  @debug.assert_eq(c.contains(3), true)
  @debug.assert_eq(c.contains(7), true)
  @debug.assert_eq(c.contains(11), false)
  let d = new(64)
  for x in [1, 3, 5, 7] {
    d.set(x)
  }
  d.or_in(b)
  @debug.assert_eq(d.contains(11), true)
  @debug.assert_eq(d.contains(1), true)
  let e = new(64)
  for x in [1, 3, 5, 7] {
    e.set(x)
  }
  e.xor_in(b)
  // Differences: 1, 5, 11; common 3, 7 cancelled.
  @debug.assert_eq(e.contains(3), false)
  @debug.assert_eq(e.contains(1), true)
  @debug.assert_eq(e.contains(11), true)
}

///|
test "bitset out of range ignored" {
  let b = new(8)
  b.set(-1)
  b.set(100)
  @debug.assert_eq(b.contains(-1), false)
  @debug.assert_eq(b.contains(100), false)
  @debug.assert_eq(b.count_set(), 0)
}

///|
test "bitset zero capacity" {
  let b = new(0)
  @debug.assert_eq(b.capacity(), 0)
  @debug.assert_eq(b.first_set(), -1)
  b.set(0)
  @debug.assert_eq(b.contains(0), false)
}
