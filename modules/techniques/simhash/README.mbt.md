# SimHash

## Overview

Charikar's 64-bit locality-sensitive fingerprint for **cosine
similarity**. The Hamming distance between two SimHash fingerprints
scales linearly with the cosine angle between the underlying feature
vectors — so near-duplicate documents have small Hamming distances
and orthogonal documents have ~32 bits of distance.

- **Time**: O(64) per `add`
- **Space**: 64 counters per accumulator; **8 bytes per fingerprint**
- **Signatures**:
  - `new() -> SimHash`
  - `s.add(item) -> Unit`
  - `s.add_weighted(item, weight) -> Unit`
  - `s.signature() -> Int64`
  - `s.merge(other) -> Unit`
  - `hamming_distance(a, b) -> Int`

SimHash (Charikar 2002) is the fingerprint behind Google's web-scale
near-duplicate detection (Manku, Jain, Sarma 2007), Cassandra's
anti-entropy reconciliation, and many production deduplication
pipelines. The fingerprint is just an `Int64` — a single 64-bit
fingerprint per document.

---

## The algorithm

For each item in the feature set:

1. Compute a uniform 64-bit hash.
2. For each of the 64 bit positions, contribute `+1` if the bit is set
   and `-1` otherwise. Multiply by the item's weight if you have one
   (TF, TF-IDF, etc.).

When all items have been added, the fingerprint's `i`-th bit is `1`
iff the `i`-th counter is strictly positive.

```
def add(item, weight = 1):
  h = hash(item)
  for i in 0..<64:
    counters[i] += weight if bit_i_of(h) else -weight

def signature():
  return Int64 with bit i set iff counters[i] > 0
```

---

## Charikar's core theorem

For two feature vectors `A, B` over the same item universe,

```
Pr[ signature(A) bit i  =  signature(B) bit i ]  =  1  -  θ(A, B) / π
```

where `θ(A, B)` is the angle between `A` and `B` in the inner-product
space. Expected Hamming distance:

```
E[ d_hamming(signature(A), signature(B)) ]  =  64 · θ(A, B) / π
```

So Hamming distance is a faithful linear proxy for the cosine angle.
The "lift" from items to bits via hashing is what makes the bound
hold even when `A` and `B` live in an enormous (effectively infinite)
feature space.

---

## SimHash vs MinHash

| | MinHash | SimHash |
|---|---|---|
| Estimates | Jaccard similarity `|A∩B|/|A∪B|` | Cosine similarity of TF vectors |
| Signature size | k · 64 bits (k = 64..4096) | **64 bits** |
| Granularity | Match-count, fine-grained | Hamming, ~64 levels |
| Weighted variants | Weighted MinHash | `add_weighted` is built in |
| Best for | Set similarity | Weighted-feature similarity (text) |

Choose SimHash when you care about cosine on weighted features (text
TF-IDF, n-gram counts). Choose MinHash when you care about set
overlap.

---

## Tests and examples

### Identical streams → identical fingerprints

```mbt check
///|
test "simhash identical" {
  let a = @simhash.new()
  let b = @simhash.new()
  for x in 1L..<100L {
    a.add(x)
    b.add(x)
  }
  debug_inspect(a.signature() == b.signature(), content="true")
}
```

### Order doesn't matter

```mbt check
///|
test "simhash order independent" {
  let asc = @simhash.new()
  let desc = @simhash.new()
  for x in 0L..<50L {
    asc.add(x)
  }
  for i in 0..<50 {
    desc.add((49 - i).to_int64())
  }
  debug_inspect(asc.signature() == desc.signature(), content="true")
}
```

### Hamming distance counts differing bits

```mbt check
///|
test "simhash hamming" {
  debug_inspect(@simhash.hamming_distance(0b0101L, 0b0011L), content="2")
  debug_inspect(@simhash.hamming_distance(0L, -1L), content="64")
}
```

### Weighted is consistent with repeated add

```mbt check
///|
test "simhash weighted" {
  let a = @simhash.new()
  let b = @simhash.new()
  a.add_weighted(42L, 3)
  for _ in 0..<3 {
    b.add(42L)
  }
  debug_inspect(a.signature() == b.signature(), content="true")
}
```

---

## Complexity

| Operation                  | Time    | Space        |
|----------------------------|---------|--------------|
| `new()`                    | O(64)   | O(64)        |
| `add(x)`                   | O(64)   | O(1) extra   |
| `add_weighted(x, w)`       | O(64)   | O(1) extra   |
| `signature()`              | O(64)   | O(1) extra   |
| `hamming_distance(a, b)`   | O(popcount) ≤ 64 | O(1) |
| `merge(other)`             | O(64)   | O(1) extra   |

All operations are constant-time in 64-bit-word terms; bounded loops
of length 64 throughout.

---

## When to reach for it

- **Text near-duplicate detection**: each document's TF-IDF feature
  vector hashed into a 64-bit fingerprint; cluster by Hamming
  distance.
- **Web crawl deduplication**: per-page fingerprints, fast
  bit-distance lookups via bit-position banding (similar to MinHash
  LSH).
- **DNA sequence clustering**: k-mer counts as features; SimHash gives
  a fast first pass.
- **Image-feature deduplication**: convert SIFT/HOG features to
  weighted SimHash inputs.

---

## Common pitfalls

- **Fingerprint comparison only**. The signature is order-independent
  and stable across runs (same hash, same insertion stream → same
  fingerprint), but is **not interchangeable with a hashtable key**;
  two fingerprints can differ by 1 bit and still represent very
  similar documents.
- **Counter overflow**. After ~2^31 add calls, the `Int` counters can
  saturate. Use `Int64` counters for streams larger than ~billions.
- **Weight semantics**. `add_weighted(item, w)` is the same as `w`
  calls to `add(item)` for positive `w`. Negative `w` reverses the
  direction — useful for "downweight" operations but not commonly
  applied.

---

## Related concepts

```
SimHash (this)                cosine similarity, 64-bit fingerprint
MinHash                       Jaccard similarity, k-slot signature
Random projection             general LSH for L_2 / cosine
HyperLogLog                   cardinality, not similarity
Bit Sampling                  LSH for Hamming distance on bit vectors
SuperBit / Spherical LSH      finer-grained cosine LSH variants
```
