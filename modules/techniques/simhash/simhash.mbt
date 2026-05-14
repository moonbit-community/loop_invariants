// ============================================================================
// SIMHASH - Locality-sensitive 64-bit fingerprint for cosine similarity
// ============================================================================
//
// PROBLEM
//
// Given two large feature sets (think: tokens of a document, n-grams
// of a web page), produce 64-bit fingerprints so that the Hamming
// distance between fingerprints scales with the *cosine angle*
// between the underlying feature vectors. This is the algorithm
// behind Google's near-duplicate detection for the web crawl.
//
// THE ALGORITHM (Charikar 2002)
//
// For each item to be added, compute a uniform 64-bit hash. For each
// of the 64 bit positions, contribute `+1` if the bit is set, `-1`
// otherwise (or `+weight / -weight` for weighted variants).
//
// After all items have been added, the fingerprint is built bit by
// bit: position i is 1 iff its accumulator is strictly positive.
//
// THE CORE PROPERTY (Charikar 2002)
//
//     Pr[ fingerprint_A bit i  =  fingerprint_B bit i ]
//       =  1  -  theta(A, B) / pi
//
// where theta(A, B) is the angle between the feature vectors of A
// and B in the underlying inner-product space. So the expected
// Hamming distance between the two fingerprints is
//
//     E[ d_hamming ]  =  64 * theta(A, B) / pi
//
// which is monotonic in the cosine of the angle. Near-duplicates have
// small Hamming distance; orthogonal documents have ~32 bits of
// Hamming distance.
//
// HOW THIS COMPARES TO MINHASH
//
//   - MinHash estimates **Jaccard similarity** (|A ∩ B| / |A ∪ B|).
//   - SimHash estimates **cosine similarity** of TF (or TF-IDF) vectors.
//   - SimHash's "signature" is a single 64-bit Int -- much smaller than
//     MinHash's k-slot signature. Trade-off: less granularity.
//
// USES IN PRODUCTION
//
//   - Google's web-page near-duplicate detection (Manku, Jain, Sarma 2007)
//   - Cassandra / Riak's anti-entropy reconciliation
//   - DNA sequence clustering for short-read similarity
//
// TIME COMPLEXITY  : O(64) per `add` (one hash, one 64-bit scan)
// SPACE COMPLEXITY : O(64) per fingerprint (the array of counters)

///|
/// A SimHash builder accumulating per-bit-position counters across a
/// feature set. Call `signature()` once all features have been added
/// to extract the 64-bit fingerprint.
pub struct SimHash {
  counters : Array[Int]
}

///|
/// Logical right shift on Int64.
fn shr_logical(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
/// MurmurHash3-style 64-bit mixer.
fn sh_mix(x : Int64) -> Int64 {
  let mut h = x
  h = (h ^ shr_logical(h, 33)) * 0xff51afd7ed558ccdL
  h = (h ^ shr_logical(h, 33)) * 0xc4ceb9fe1a85ec53L
  h = h ^ shr_logical(h, 33)
  h
}

///|
/// Build an empty SimHash accumulator. All 64 counters start at 0.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = @simhash.new()
///   for w in [1L, 2L, 3L, 4L] {
///     s.add(w)
///   }
///   let fp = s.signature()
///   // fp is an Int64 fingerprint suitable for Hamming-distance comparisons.
///   assert_true(fp != 0L)
/// }
/// ```
pub fn new() -> SimHash {
  { counters: Array::make(64, 0) }
}

///|
/// Consume one feature with implicit weight `1`. For each bit
/// position of the feature's hash, the corresponding counter is
/// incremented if that bit is set, decremented otherwise.
pub fn SimHash::add(self : SimHash, item : Int64) -> Unit {
  self.add_weighted(item, 1)
}

///|
/// Consume one feature with explicit `weight` (positive Int). Useful
/// for TF or TF-IDF weighting: each item contributes `weight` units
/// of signal to each bit position.
///
/// A negative `weight` is allowed and is treated symmetrically — the
/// counter moves in the opposite direction. Pass `0` for a no-op.
pub fn SimHash::add_weighted(
  self : SimHash,
  item : Int64,
  weight : Int,
) -> Unit {
  let h = sh_mix(item)
  for i in 0..<64 {
    let bit = shr_logical(h, i).land(1L)
    if bit == 1L {
      self.counters[i] = self.counters[i] + weight
    } else {
      self.counters[i] = self.counters[i] - weight
    }
  } where {
    proof_invariant: i >= 0 && i <= 64,
    proof_reasoning: (
      #|INVARIANT (Per-bit accumulation):
      #|For each j in [0..i), counters[j] has been updated to account
      #|for the contribution of `item` (+ or - weight depending on
      #|whether bit j of hash(item) is set).
      #|TERMINATION: i bounded by 64.
    ),
  }
}

///|
/// Finalise the accumulator into a 64-bit fingerprint. Bit `i` of the
/// result is 1 iff `counters[i] > 0`.
///
/// The accumulator is not consumed: subsequent `add`s continue to
/// adjust the counters and `signature()` reflects the running state.
pub fn SimHash::signature(self : SimHash) -> Int64 {
  let mut result = 0L
  for i in 0..<64 {
    if self.counters[i] > 0 {
      result = result.lor(1L << i)
    }
  } where {
    proof_invariant: i >= 0 && i <= 64,
    proof_reasoning: (
      #|INVARIANT (Sign-bit extraction):
      #|Bits 0..i of result encode the sign of counters[0..i):
      #|set iff the counter is strictly positive.
      #|TERMINATION: i bounded by 64.
    ),
  }
  result
}

///|
/// Inspector: snapshot of the current counters. Useful for debugging
/// and for streaming/distributed implementations that merge state.
pub fn SimHash::counters_of(self : SimHash) -> Array[Int] {
  let out = Array::make(64, 0)
  for i in 0..<64 {
    out[i] = self.counters[i]
  }
  out
}

///|
/// Merge another SimHash accumulator into this one by componentwise
/// addition. The merged counters represent the union of both feature
/// streams.
pub fn SimHash::merge(self : SimHash, other : SimHash) -> Unit {
  for i in 0..<64 {
    self.counters[i] = self.counters[i] + other.counters[i]
  }
}

///|
/// Hamming distance between two 64-bit fingerprints: the number of
/// bit positions where they differ. The proxy for "1 - cosine
/// similarity" up to the Charikar scaling factor.
///
/// Implementation uses the standard popcount idiom -- successively
/// halve and accumulate.
pub fn hamming_distance(a : Int64, b : Int64) -> Int {
  let mut x = a ^ b
  let mut count = 0
  for _ in 0..<64 {
    if x == 0L {
      break
    }
    count = count + 1
    // Clear the lowest set bit: x &= x - 1.
    x = x.land(x - 1L)
  } where {
    proof_invariant: count >= 0 && count <= 64,
    proof_reasoning: (
      #|INVARIANT (Set-bit counting):
      #|count equals the number of 1-bits already cleared from x.
      #|MAINTENANCE:
      #|`x & (x - 1)` clears the lowest set bit. count increments.
      #|TERMINATION:
      #|At most 64 set bits in any Int64; loop exits as soon as x = 0.
    ),
  }
  count
}

///|
test "simhash empty signature is zero" {
  let s = new()
  @debug.assert_eq(s.signature(), 0L)
}

///|
test "simhash identical streams give identical fingerprints" {
  let a = new()
  let b = new()
  for x in 1L..<100L {
    a.add(x)
    b.add(x)
  }
  @debug.assert_eq(a.signature(), b.signature())
}

///|
test "simhash insertion order doesn't matter" {
  let a = new()
  let b = new()
  for x in 0L..<50L {
    a.add(x)
  }
  for i in 0..<50 {
    b.add((49 - i).to_int64())
  }
  @debug.assert_eq(a.signature(), b.signature())
}

///|
test "simhash identical fingerprints have distance zero" {
  @debug.assert_eq(hamming_distance(42L, 42L), 0)
  @debug.assert_eq(hamming_distance(0L, 0L), 0)
  @debug.assert_eq(hamming_distance(-1L, -1L), 0)
}

///|
test "simhash hamming distance counts differing bits" {
  // 0b0101 vs 0b0011 -> two differing bit positions.
  @debug.assert_eq(hamming_distance(0b0101L, 0b0011L), 2)
  // 0 vs -1 (all ones) -> 64 differing bits.
  @debug.assert_eq(hamming_distance(0L, -1L), 64)
}

///|
test "simhash similar streams have small hamming distance" {
  // Two streams sharing 90% of their elements should have closer
  // fingerprints than two streams sharing only 10%.
  let near_a = new()
  let near_b = new()
  for x in 0L..<200L {
    near_a.add(x)
  }
  for x in 0L..<190L {
    near_b.add(x)
  }
  for x in 1000L..<1010L {
    near_b.add(x)
  }
  let near_dist = hamming_distance(near_a.signature(), near_b.signature())
  let far_a = new()
  let far_b = new()
  for x in 0L..<200L {
    far_a.add(x)
  }
  for x in 1000L..<1200L {
    far_b.add(x)
  }
  let far_dist = hamming_distance(far_a.signature(), far_b.signature())
  // Near pair should be closer than far pair. (Both are stochastic;
  // this holds with overwhelming probability.)
  @debug.assert_eq(near_dist < far_dist, true)
  // And the near distance is bounded below by 32 — well below
  // expectation for orthogonal-ish documents.
  @debug.assert_eq(near_dist < 32, true)
}

///|
test "simhash merge equals union-add" {
  let a = new()
  let b = new()
  let u = new()
  for x in 0L..<50L {
    a.add(x)
    u.add(x)
  }
  for x in 50L..<100L {
    b.add(x)
    u.add(x)
  }
  a.merge(b)
  @debug.assert_eq(a.signature(), u.signature())
}

///|
test "simhash weighted is consistent with repeated add" {
  let a = new()
  let b = new()
  a.add_weighted(42L, 3)
  for _ in 0..<3 {
    b.add(42L)
  }
  @debug.assert_eq(a.signature(), b.signature())
}
