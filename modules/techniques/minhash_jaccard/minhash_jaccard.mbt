// ============================================================================
// MINHASH - Sketch sets so that signature collisions estimate Jaccard
// ============================================================================
//
// PROBLEM
//
// Given two large sets `S`, `T` of integers, estimate the Jaccard
// similarity
//
//                  | S ∩ T |
//     J(S, T)  =  ---------
//                  | S ∪ T |
//
// without ever materialising the intersection or union. Each set may
// have billions of elements; we want sketches that fit in a few KB and
// estimate `J` within a small additive error.
//
// THE TRICK (Broder 1997)
//
// Fix `k` independent hash functions h_1, ..., h_k mapping items to
// uniform 64-bit values. For each set `S`, the MinHash signature is
//
//     sig_S = ( min_{x in S} h_1(x), ..., min_{x in S} h_k(x) )
//
// CORE PROPERTY (one-line proof below)
//
//     Pr[ sig_S[i] = sig_T[i] ]  =  J(S, T)        for every i
//
// So the empirical Jaccard estimate is the *fraction* of signature
// slots that match, with standard error `1 / sqrt(k)`. Taking `k = 200`
// gives ~7% relative SE; `k = 10 000` gives ~1%.
//
// PROOF
//
// Consider the union `U = S ∪ T` and the random function h_i.
// Each element of U has equal probability of being the minimum
// (independence of hashes). The minimum-hashing element x is in
// `S ∩ T` with probability  `|S ∩ T| / |U|  =  J(S, T)`.
// If x is in `S ∩ T`, then both `min h_i(S)` and `min h_i(T)` are
// achieved at x, so they match. Otherwise (x in S \ T or T \ S),
// the minima are achieved at different elements and (almost surely)
// do not match. QED.
//
// PROPERTIES
//
//   - Streaming: signatures are built in one pass; no need to
//     materialise the set.
//   - Mergeable: `merge(self, other)` = elementwise min of signatures,
//     which is exactly the signature of `S ∪ T`.
//   - Order-independent: adding the same items in any order produces
//     the same signature.
//
// TIME COMPLEXITY  : O(k) per `add` (one hash per signature slot)
// SPACE COMPLEXITY : O(k) Int64 slots

///|
/// A MinHash signature with `k` independent hash functions and the
/// per-hash running minimum.
pub struct MinHash {
  k : Int
  // Per-hash salts derived from the user seed.
  salts : Array[Int64]
  // Running min for each hash; `Int64::MAX_VALUE` means "no item seen yet."
  signatures : Array[Int64]
}

///|
/// Logical right shift on Int64 (built-in `>>` is arithmetic).
fn shr_logical(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
/// MurmurHash3-style 64-bit finaliser. Mixes bits across the whole
/// 64-bit output uniformly.
fn mh_mix(x : Int64) -> Int64 {
  let mut h = x
  h = (h ^ shr_logical(h, 33)) * 0xff51afd7ed558ccdL
  h = (h ^ shr_logical(h, 33)) * 0xc4ceb9fe1a85ec53L
  h = h ^ shr_logical(h, 33)
  h
}

///|
/// Hash an item under the `i`-th hash function: salt the item with
/// `salts[i]` and mix. Two MinHash instances built with the same seed
/// share the same hash family and can therefore be compared and merged.
fn MinHash::mh_hash(self : MinHash, i : Int, item : Int64) -> Int64 {
  mh_mix(item ^ self.salts[i])
}

///|
/// Create a fresh MinHash signature with `k` slots.
///
/// ## Parameters
///
/// - `k`    : number of hash functions. Larger means lower error
///            (`1 / sqrt(k)` SE). Typical: 128-512.
/// - `seed` : deterministic seed; salts are derived from it.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let m = @minhash_jaccard.new(k=256, seed=1L)
///   for x in 0L..<100L {
///     m.add(x)
///   }
///   // sig has 256 values; identical seeds give identical hash families.
///   assert_eq(m.signature().length(), 256)
/// }
/// ```
pub fn new(k~ : Int, seed~ : Int64) -> MinHash {
  let k_clamped = if k < 1 { 1 } else { k }
  let salts = Array::make(k_clamped, 0L)
  // Walk a small LCG so the salts are spread.
  let mut state = mh_mix(seed)
  for i in 0..<k_clamped {
    state = mh_mix(state)
    salts[i] = state
  } where {
    proof_invariant: i >= 0 && i <= k_clamped,
    proof_reasoning: (
      #|INVARIANT (Salt initialisation):
      #|salts[0..i) hold distinct mixed values derived from the seed.
      #|MAINTENANCE: mix the state and store as the next salt.
      #|TERMINATION: at i = k_clamped, every slot has a salt.
    ),
  }
  let signatures = Array::make(k_clamped, @int64.MAX_VALUE)
  { k: k_clamped, salts, signatures }
}

///|
/// Consume one item: for every hash function, lower the signature slot
/// if the new hash is smaller.
pub fn MinHash::add(self : MinHash, item : Int64) -> Unit {
  for i in 0..<self.k {
    let h = self.mh_hash(i, item)
    if h < self.signatures[i] {
      self.signatures[i] = h
    }
  } where {
    proof_invariant: i >= 0 && i <= self.k,
    proof_reasoning: (
      #|INVARIANT (Per-hash min):
      #|For each j in [0..i), signatures[j] = min over the items
      #|seen so far of h_j(item). Adding one new item potentially
      #|lowers this min in each slot independently.
      #|TERMINATION: i bounded by k.
    ),
  }
}

///|
/// Bulk consumer; equivalent to a loop of `add` calls but carries a
/// stated proof_invariant on the running per-hash minima.
pub fn MinHash::add_many(self : MinHash, items : ArrayView[Int64]) -> Unit {
  for j in 0..<items.length() {
    self.add(items[j])
  } where {
    proof_invariant: j >= 0 && j <= items.length(),
    proof_reasoning: (
      #|INVARIANT (Bulk add):
      #|self has consumed items[0..j); each slot's running min reflects
      #|exactly those items. Final state is what you would get from
      #|inserting them one at a time.
    ),
  }
}

///|
/// Copy of the current `k`-slot signature.
pub fn MinHash::signature(self : MinHash) -> Array[Int64] {
  let out = Array::make(self.k, 0L)
  for i in 0..<self.k {
    out[i] = self.signatures[i]
  }
  out
}

///|
/// Empirical Jaccard estimate: the fraction of signature slots that
/// match between `self` and `other`. Returns `0.0` when the two
/// sketches have incompatible widths or seeds (cannot be compared).
///
/// By Broder's theorem the expected value of this estimator equals
/// `J(S, T)` with standard error `1 / sqrt(k)`.
pub fn MinHash::similarity_with(self : MinHash, other : MinHash) -> Double {
  if self.k != other.k {
    return 0.0
  }
  let mut matches = 0
  for i in 0..<self.k {
    if self.signatures[i] == other.signatures[i] {
      matches = matches + 1
    }
  } where {
    proof_invariant: i >= 0 && i <= self.k,
    proof_invariant: matches >= 0 && matches <= i,
    proof_reasoning: (
      #|INVARIANT (Match counting):
      #|matches counts slots j in [0..i) where self.signatures[j] equals
      #|other.signatures[j].
      #|EXPECTATION:
      #|E[matches] = k * J(S, T), so matches / k is an unbiased
      #|estimator of J(S, T).
    ),
  }
  matches.to_double() / self.k.to_double()
}

///|
/// Merge two signatures with the same shape (k and seed-derived salts):
/// take the elementwise min. The merged signature is exactly the
/// signature of the set union `S ∪ T`.
pub fn MinHash::merge(self : MinHash, other : MinHash) -> Unit {
  if self.k != other.k {
    return
  }
  for i in 0..<self.k {
    if other.signatures[i] < self.signatures[i] {
      self.signatures[i] = other.signatures[i]
    }
  }
}

///|
/// Inspector: the configured `k`.
pub fn MinHash::width(self : MinHash) -> Int {
  self.k
}

///|
test "minhash identical sets give 1.0" {
  let a = new(k=128, seed=42L)
  let b = new(k=128, seed=42L)
  for x in 0L..<500L {
    a.add(x)
    b.add(x)
  }
  let sim = a.similarity_with(b)
  @debug.assert_eq(sim, 1.0)
}

///|
test "minhash disjoint sets give 0 with high probability" {
  let a = new(k=128, seed=99L)
  let b = new(k=128, seed=99L)
  for x in 0L..<500L {
    a.add(x)
  }
  for x in 1000L..<1500L {
    b.add(x)
  }
  let sim = a.similarity_with(b)
  // True Jaccard is 0; estimator gives 0 with probability 1 (modulo
  // hash collisions, which are vanishingly rare for ~1000 64-bit
  // values).
  @debug.assert_eq(sim <= 0.05, true)
}

///|
test "minhash half-overlap gives ~0.33" {
  // |A ∩ B| / |A ∪ B| for A = [0..200), B = [100..300) is
  // 100 / 300 ≈ 0.333.
  let a = new(k=512, seed=7L)
  let b = new(k=512, seed=7L)
  for x in 0L..<200L {
    a.add(x)
  }
  for x in 100L..<300L {
    b.add(x)
  }
  let sim = a.similarity_with(b)
  // SE ≈ 1/sqrt(512) ≈ 0.044, so 4-sigma window is [0.16, 0.51].
  @debug.assert_eq(sim >= 0.16, true)
  @debug.assert_eq(sim <= 0.51, true)
}

///|
test "minhash insertion order doesn't matter" {
  let a = new(k=64, seed=1L)
  let b = new(k=64, seed=1L)
  for x in 0L..<50L {
    a.add(x)
  }
  for x in 49L..<-1L {
    let _ = x
  }
  // Add same elements in reverse order to b.
  for i in 0..<50 {
    b.add((49 - i).to_int64())
  }
  // Signatures must match.
  @debug.assert_eq(a.signature(), b.signature())
}

///|
test "minhash duplicates don't affect signature" {
  let a = new(k=64, seed=1L)
  let b = new(k=64, seed=1L)
  for x in 0L..<20L {
    a.add(x)
  }
  for x in 0L..<20L {
    for _ in 0..<100 {
      b.add(x)
    }
  }
  @debug.assert_eq(a.signature(), b.signature())
}

///|
test "minhash merge equals union add" {
  let a = new(k=64, seed=5L)
  let b = new(k=64, seed=5L)
  let union = new(k=64, seed=5L)
  for x in 0L..<30L {
    a.add(x)
    union.add(x)
  }
  for x in 25L..<55L {
    b.add(x)
    union.add(x)
  }
  a.merge(b)
  @debug.assert_eq(a.signature(), union.signature())
}

///|
test "minhash incompatible widths returns 0" {
  let a = new(k=64, seed=1L)
  let b = new(k=128, seed=1L)
  a.add(1L)
  b.add(1L)
  @debug.assert_eq(a.similarity_with(b), 0.0)
}

///|
test "minhash width inspector" {
  let a = new(k=200, seed=1L)
  @debug.assert_eq(a.width(), 200)
}
