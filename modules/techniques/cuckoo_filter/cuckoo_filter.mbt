// ============================================================================
// CUCKOO FILTER - Approximate-membership with deletion (Fan et al. 2014)
// ============================================================================
//
// PROBLEM
//
// Like a Bloom filter: support `insert(x)` and `contains(x)` with no
// false negatives and a tunable false-positive rate, in much less
// space than a hash set. **Unlike** a Bloom filter, a Cuckoo filter
// also supports `delete(x)` for previously inserted x.
//
// THE STRUCTURE
//
// `m` buckets, each holding up to `b` short **fingerprints**
// (typically 4-bit through 16-bit values). Each item `x` has two
// candidate buckets:
//
//     h_1(x) = h(x) mod m
//     h_2(x) = h_1(x) XOR h(fingerprint(x))  mod m
//
// The XOR design has a magical property:
//
//     h_2(x) XOR h(fingerprint(x))  =  h_1(x)
//
// So given just a bucket index `i` and a fingerprint `f`, the "other"
// bucket is `i XOR h(f)`. This is how delete works: we don't need
// the full key, just `f` + one of the buckets.
//
// INSERT
//   1. Compute f = fingerprint(x), b1 = h_1(x), b2 = h_2(x).
//   2. If table[b1] has room, put f there. Else if table[b2] has
//      room, put f there.
//   3. Otherwise, pick one of b1, b2 at random; swap f with a
//      randomly-chosen fingerprint f' from that bucket. Now relocate
//      f' to its alternate bucket. Repeat up to `max_kicks` times.
//   4. If the chain exceeds max_kicks, declare failure.
//
// CONTAINS
//   Return true iff fingerprint(x) is found in table[b1] or table[b2].
//   This can have false positives if some unrelated insertion deposited
//   the same fingerprint -- the controlled error.
//
// DELETE
//   Remove one occurrence of fingerprint(x) from table[b1] OR table[b2].
//   Returns true iff a fingerprint was actually removed.
//
// THE INVARIANT
//
//   For every "live" insert, the item's fingerprint sits in either of
//   its two candidate buckets (or has been displaced by the XOR trick,
//   but always still in one of the two candidate buckets of the
//   *current* fingerprint).
//
// FALSE POSITIVE RATE
//
//   With `b` slots per bucket and `f`-bit fingerprints,
//
//     FP rate  ≈  2 b / 2^f
//
//   So 4-bit fingerprints with `b = 4` give 50% FP, far too high.
//   8-bit fingerprints, b = 4 give ~3%; 16-bit fingerprints, b = 4
//   give ~0.012% -- comparable to a Bloom filter at the same memory.

///|
/// A Cuckoo filter. `m` buckets, each holds up to `b` 16-bit
/// fingerprints. Use 0 to indicate an empty slot (so fingerprints
/// are values in [1, 2^16 - 1]).
pub struct CuckooFilter {
  m : Int
  b : Int
  // Flat array of m * b slots; slot (bucket=i, position=p) is at i*b+p.
  table : Array[Int]
  mut count : Int
  mut rng_state : Int64
}

///|
/// LCG step.
fn cf_lcg(state : Int64) -> Int64 {
  state * 6364136223846793005L + 1442695040888963407L
}

///|
/// Logical right shift on Int64.
fn cf_shr_logical(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
/// MurmurHash3-style mixer.
fn cf_hash(x : Int64) -> Int64 {
  let mut h = x
  h = (h ^ cf_shr_logical(h, 33)) * 0xff51afd7ed558ccdL
  h = (h ^ cf_shr_logical(h, 33)) * 0xc4ceb9fe1a85ec53L
  h = h ^ cf_shr_logical(h, 33)
  h
}

///|
/// Create a fresh filter with `m` buckets and `b` slots each.
///
/// Typical: `m = 1024 to 65536`, `b = 4`. False-positive rate is
/// roughly `2 b / 65535 ≈ 0.012%` with this 16-bit fingerprint
/// scheme.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let cf = @cuckoo_filter.new(m=1024, b=4, seed=1L)
///   for x in 0L..<500L {
///     cf.insert(x) |> ignore
///   }
///   assert_eq(cf.contains(42L), true)
/// }
/// ```
pub fn new(m~ : Int, b~ : Int, seed~ : Int64) -> CuckooFilter {
  let mc = if m < 4 { 4 } else { m }
  let bc = if b < 1 { 1 } else { b }
  {
    m: mc,
    b: bc,
    table: Array::make(mc * bc, 0),
    count: 0,
    rng_state: cf_lcg(seed),
  }
}

///|
/// 16-bit fingerprint of `x`. Always in [1, 65535] so 0 can be the
/// empty-slot sentinel.
///
/// Hashes `x` via a different mix than the bucket index, so that two
/// inputs with the same `h(x) mod m` are not forced to share the same
/// fingerprint.
fn fingerprint(x : Int64) -> Int {
  let h = cf_hash(x ^ 0xa5a5a5a5a5a5a5a5L)
  let f = cf_shr_logical(h, 32).land(65535L).to_int()
  if f == 0 {
    1
  } else {
    f
  }
}

///|
/// Convert a fingerprint to an Int64 hash for the XOR trick.
fn fp_hash(f : Int) -> Int64 {
  cf_hash(f.to_int64() * 2654435761L)
}

///|
/// Buckets containing `x`'s fingerprint, in order: (bucket_1, bucket_2).
fn CuckooFilter::buckets_of(self : CuckooFilter, x : Int64) -> (Int, Int, Int) {
  let f = fingerprint(x)
  let h1 = cf_hash(x)
  let b1 = (h1.land(2147483647L) % self.m.to_int64()).to_int()
  let b2_raw = (b1.to_int64() ^ fp_hash(f)).land(2147483647L)
  let b2 = (b2_raw % self.m.to_int64()).to_int()
  (b1, b2, f)
}

///|
/// `i XOR h(f)` -- the alternate bucket given a bucket index and a
/// fingerprint, regardless of which "side" we were on.
fn CuckooFilter::other_bucket(self : CuckooFilter, i : Int, f : Int) -> Int {
  let b = (i.to_int64() ^ fp_hash(f)).land(2147483647L)
  (b % self.m.to_int64()).to_int()
}

///|
/// Try to insert `f` into bucket `b`. Returns true if a slot was found.
fn CuckooFilter::try_insert(self : CuckooFilter, bucket : Int, f : Int) -> Bool {
  for p in 0..<self.b {
    if self.table[bucket * self.b + p] == 0 {
      self.table[bucket * self.b + p] = f
      return true
    }
  }
  false
}

///|
/// Insert `key`. Returns true on success; false when the eviction
/// chain exceeds `max_kicks` (consider growing or re-seeding).
pub fn CuckooFilter::insert(self : CuckooFilter, key : Int64) -> Bool {
  let (b1, b2, f) = self.buckets_of(key)
  if self.try_insert(b1, f) || self.try_insert(b2, f) {
    self.count = self.count + 1
    return true
  }
  // Both buckets full -- eviction chain.
  let mut current_bucket = b1
  let mut current_f = f
  let max_kicks = 500
  for _ in 0..<max_kicks {
    // Pick a random slot to evict.
    self.rng_state = cf_lcg(self.rng_state)
    let raw = if self.rng_state < 0L { -self.rng_state } else { self.rng_state }
    let slot = (raw % self.b.to_int64()).to_int()
    let evicted = self.table[current_bucket * self.b + slot]
    self.table[current_bucket * self.b + slot] = current_f
    current_f = evicted
    current_bucket = self.other_bucket(current_bucket, current_f)
    if self.try_insert(current_bucket, current_f) {
      self.count = self.count + 1
      return true
    }
  }
  false
}

///|
/// Membership test. Returns true if the fingerprint is present (false
/// positives possible at controlled rate, no false negatives for
/// genuinely-inserted keys not yet deleted).
pub fn CuckooFilter::contains(self : CuckooFilter, key : Int64) -> Bool {
  let (b1, b2, f) = self.buckets_of(key)
  for p in 0..<self.b {
    if self.table[b1 * self.b + p] == f {
      return true
    }
    if self.table[b2 * self.b + p] == f {
      return true
    }
  }
  false
}

///|
/// Delete one occurrence of `key`'s fingerprint. Returns true iff a
/// fingerprint was actually removed -- which may correspond to a
/// genuine deletion or to a false-positive collision with another
/// key's fingerprint.
pub fn CuckooFilter::delete(self : CuckooFilter, key : Int64) -> Bool {
  let (b1, b2, f) = self.buckets_of(key)
  for p in 0..<self.b {
    if self.table[b1 * self.b + p] == f {
      self.table[b1 * self.b + p] = 0
      self.count = self.count - 1
      return true
    }
  }
  for p in 0..<self.b {
    if self.table[b2 * self.b + p] == f {
      self.table[b2 * self.b + p] = 0
      self.count = self.count - 1
      return true
    }
  }
  false
}

///|
/// Current item count.
pub fn CuckooFilter::count_of(self : CuckooFilter) -> Int {
  self.count
}

///|
/// Total capacity (m * b).
pub fn CuckooFilter::capacity(self : CuckooFilter) -> Int {
  self.m * self.b
}

///|
test "cuckoo filter basic insert and contains" {
  let cf = new(m=128, b=4, seed=1L)
  for x in 0L..<100L {
    cf.insert(x) |> ignore
  }
  // Every inserted key must be reported as present.
  for x in 0L..<100L {
    @debug.assert_eq(cf.contains(x), true)
  }
}

///|
test "cuckoo filter low false-positive rate" {
  let cf = new(m=1024, b=4, seed=42L)
  for x in 0L..<2000L {
    cf.insert(x) |> ignore
  }
  // Probe with values outside the inserted range; expect very few
  // false positives.
  let mut fp = 0
  for x in 100000L..<102000L {
    if cf.contains(x) {
      fp = fp + 1
    }
  }
  // With m = 1024, b = 4, 2 b / 2^16 ~ 0.012% theoretical FP rate.
  // Allow some slack for the constant factor of our hash family.
  @debug.assert_eq(fp <= 10, true)
}

///|
test "cuckoo filter delete restores absence" {
  let cf = new(m=128, b=4, seed=7L)
  cf.insert(99L) |> ignore
  @debug.assert_eq(cf.contains(99L), true)
  let removed = cf.delete(99L)
  @debug.assert_eq(removed, true)
  // After deletion, contains might still report true if a collision
  // exists; for a single insert this is impossible.
  @debug.assert_eq(cf.contains(99L), false)
}

///|
test "cuckoo filter count tracks inserts" {
  let cf = new(m=128, b=4, seed=1L)
  for x in 0L..<50L {
    cf.insert(x) |> ignore
  }
  @debug.assert_eq(cf.count_of(), 50)
  cf.delete(25L) |> ignore
  @debug.assert_eq(cf.count_of(), 49)
}

///|
test "cuckoo filter delete on missing returns false" {
  let cf = new(m=64, b=4, seed=1L)
  cf.insert(1L) |> ignore
  @debug.assert_eq(cf.delete(999L), false)
}

///|
test "cuckoo filter capacity" {
  let cf = new(m=256, b=4, seed=1L)
  @debug.assert_eq(cf.capacity(), 1024)
}

///|
test "cuckoo filter degenerate sizes" {
  let cf = new(m=0, b=0, seed=1L)
  // Coerced to m=4, b=1.
  @debug.assert_eq(cf.capacity(), 4)
}
