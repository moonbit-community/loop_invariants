# MinHash for Jaccard Similarity

## Overview

Sketch large sets so that signature collisions estimate Jaccard
similarity. For sets `S, T`,

```
J(S, T) = |S ∩ T| / |S ∪ T|
```

and the MinHash signatures `sig_S, sig_T` satisfy

```
Pr[ sig_S[i] = sig_T[i] ] = J(S, T)
```

at every slot. The fraction of matching slots is an unbiased
estimator of `J(S, T)` with standard error `1 / sqrt(k)`.

- **Time**: O(k) per `add`, O(k) per `similarity_with`
- **Space**: O(k) Int64 slots
- **Signatures**:
  - `new(k~, seed~) -> MinHash`
  - `m.add(item) -> Unit`
  - `m.add_many(items) -> Unit`
  - `m.signature() -> Array[Int64]`
  - `m.similarity_with(other) -> Double`
  - `m.merge(other) -> Unit`
  - `m.width() -> Int`

This is the algorithm behind near-duplicate web-page detection (Broder,
AltaVista), plagiarism detection, MinHash LSH for nearest-neighbour
search, and DNA short-read similarity.

---

## One-line proof of the core property

Consider `U = S ∪ T` and a uniform random hash `h`. Each element of `U`
is equally likely to achieve `min_{x ∈ U} h(x)`. That minimum is in
`S ∩ T` with probability `|S ∩ T| / |U| = J(S, T)`. When it is, both
`min h(S)` and `min h(T)` are achieved at the same element and the
signatures match. Otherwise (the minimum is in `S \ T` or `T \ S`),
exactly one of the two min's includes that element and the signatures
differ (almost surely; perfect hashes avoid collisions among distinct
inputs).

So `Pr[sig_S[i] = sig_T[i]] = J(S, T)` for each independent hash. The
match-count across `k` hashes is Binomial(`k`, `J`), giving the
unbiased estimator with SE `1 / sqrt(k)`.

---

## When to reach for it

| Use case | How |
|---|---|
| **Near-duplicate detection** | Build a signature per document; pairs with high estimated Jaccard are likely near-duplicates. |
| **LSH for nearest neighbours** | Hash signatures into bands and look for collisions to find candidate pairs. |
| **DNA similarity** | Set-of-k-mers per genome; MinHash gives a fast first pass. |
| **Collaborative filtering** | "Users who liked X" as a set; MinHash estimates user-similarity in O(k). |

Note that MinHash estimates **Jaccard** specifically. For **cosine
similarity**, use SimHash. For **inner product**, use a different
sketch.

---

## Reference implementation

```
pub struct MinHash
pub fn new(k~ : Int, seed~ : Int64) -> MinHash
pub fn MinHash::add(self, item : Int64) -> Unit
pub fn MinHash::add_many(self, items : ArrayView[Int64]) -> Unit
pub fn MinHash::signature(self) -> Array[Int64]
pub fn MinHash::similarity_with(self, other : MinHash) -> Double
pub fn MinHash::merge(self, other : MinHash) -> Unit
pub fn MinHash::width(self) -> Int
```

---

## Tests and examples

### Identical sets give similarity 1.0

```mbt check
///|
test "minhash identical" {
  let a = @minhash_jaccard.new(k=128, seed=42L)
  let b = @minhash_jaccard.new(k=128, seed=42L)
  for x in 0L..<500L {
    a.add(x)
    b.add(x)
  }
  debug_inspect(a.similarity_with(b), content="1")
}
```

### Disjoint sets give ~0

```mbt check
///|
test "minhash disjoint" {
  let a = @minhash_jaccard.new(k=128, seed=99L)
  let b = @minhash_jaccard.new(k=128, seed=99L)
  for x in 0L..<500L {
    a.add(x)
  }
  for x in 1000L..<1500L {
    b.add(x)
  }
  debug_inspect(a.similarity_with(b) <= 0.05, content="true")
}
```

### Half-overlap recovers ~0.33

```mbt check
///|
test "minhash half overlap" {
  let a = @minhash_jaccard.new(k=512, seed=7L)
  let b = @minhash_jaccard.new(k=512, seed=7L)
  for x in 0L..<200L {
    a.add(x)
  }
  for x in 100L..<300L {
    b.add(x)
  }
  // True J = 100/300 ≈ 0.333
  let sim = a.similarity_with(b)
  debug_inspect(sim >= 0.20, content="true")
  debug_inspect(sim <= 0.45, content="true")
}
```

### Merge equals union-add

```mbt check
///|
test "minhash merge equals union" {
  let a = @minhash_jaccard.new(k=64, seed=5L)
  let b = @minhash_jaccard.new(k=64, seed=5L)
  let u = @minhash_jaccard.new(k=64, seed=5L)
  for x in 0L..<30L {
    a.add(x)
    u.add(x)
  }
  for x in 25L..<55L {
    b.add(x)
    u.add(x)
  }
  a.merge(b)
  debug_inspect(a.signature() == u.signature(), content="true")
}
```

---

## Complexity

| Operation              | Time   | Space        |
|------------------------|--------|--------------|
| `new(k, seed)`         | O(k)   | O(k)         |
| `add(x)`               | O(k)   | O(1) extra   |
| `add_many(xs)`         | O(\|xs\| · k) | O(1) extra |
| `signature()`          | O(k)   | O(k) output  |
| `similarity_with(o)`   | O(k)   | O(1) extra   |
| `merge(o)`             | O(k)   | O(1) extra   |

For `k = 200` (~7% SE), `add` is `O(200)` operations — still fast in
absolute terms, fast enough for million-element streams in seconds.

---

## Choosing `k`

| `k`    | Standard error | Use case |
|--------|----------------|----------|
| 64     | ~12.5%         | Quick prototyping |
| 200    | ~7%            | Document near-duplicates |
| 512    | ~4.4%          | Sensitive Jaccard estimates |
| 4096   | ~1.6%          | Production / per-query ML features |

Memory grows linearly in `k` (each signature is `k` × `Int64`); time
also grows linearly in `k` per element.

---

## Common pitfalls

- **Hash family must match**. Two sketches built with the same `seed`
  and same `k` share the same hash family, so their `similarity_with`
  is meaningful. Sketches with different seeds compare to garbage.
- **`Int64` items only**. For string sets, hash strings to `Int64`
  first. Choose a good string-hash (e.g. CityHash) for the prior
  step, otherwise hash collisions there cap your Jaccard SE.
- **The signature is a *uniform random projection* of the set**;
  exposing it externally is essentially exposing a small fraction of
  your data. Be aware of this in adversarial settings.
- **Estimator variance is binomial**. Even with `k = 1024`, single
  experiments can deviate by 3 SE on rare occasions. Use multiple
  independent signatures for paranoid estimates.

---

## Related concepts

```
MinHash (this)               Jaccard similarity, O(k) per add
SimHash                      cosine similarity via random hyperplanes
MinHash LSH                  banding trick for O(1) candidate lookup
Weighted MinHash             handles multisets
HyperLogLog                  cardinality, not similarity
b-Bit MinHash                truncate signatures to b bits for compression
Jaccard distance             1 - J; used as a metric in clustering
```
