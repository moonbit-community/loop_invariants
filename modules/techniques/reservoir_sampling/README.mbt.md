# Reservoir Sampling

## Overview

Maintain a uniformly random size-`k` sample from a stream of unknown
length `N`. After every prefix has been processed, every item seen so
far is in the reservoir with probability exactly `k / (count so far)`.

- **Time**: O(1) per item
- **Space**: O(k) reservoir + a single PRNG state
- **Signatures**:
  - `new(capacity~, seed~) -> Reservoir`
  - `r.add(item) -> Unit`
  - `r.add_many(items) -> Unit`
  - `r.sample() -> Array[Int64]`
  - `r.items_seen() -> Int`
  - `r.capacity_of() -> Int`

This is Vitter's Algorithm R (1985). It is the textbook example of an
algorithm whose proof is more interesting than its code — the
implementation is six lines but the induction invariant takes a
page to write down properly.

---

## The algorithm

```
reservoir = first k items of stream

for i = k, k + 1, k + 2, ...:
  # i is the 0-indexed position of the next stream element
  j = uniform integer in [0, i + 1)
  if j < k:
    reservoir[j] = stream[i]
```

Two phases:

1. **Fill phase** (items `[0, k)`): straight copy into the reservoir.
2. **Replacement phase** (items `[k, N)`): each new item lands in the
   reservoir with probability exactly `k / (i + 1)`; if it does, it
   evicts a uniformly chosen incumbent.

That's it. No second pass over the stream.

---

## The induction invariant (the entire point)

> After processing `i + 1` items (indices `[0, i + 1)`), every item is
> in the reservoir with probability exactly `min(1, k / (i + 1))`.

**Base case** (`i = k - 1`): the first `k` items are in the reservoir
with probability `1 = k / k`. ✓

**Inductive step**: assume the claim for prefix `[0, i)`. When item
`i` arrives, draw `j ~ Uniform[0, i + 1)`:

- **Item `i`** ends up in the reservoir iff `j < k`, with probability
  `k / (i + 1)`. ✓
- **An item `x < i`** ends up in the reservoir iff it *was* in the
  reservoir and was *not* evicted in this step:

  ```
  Pr[x in reservoir after step i]
    =  Pr[x was in reservoir]  *  Pr[x not evicted]
    =  (k / i)  *  (1 - (k / (i + 1)) * (1 / k))
    =  (k / i)  *  (i / (i + 1))
    =  k / (i + 1).  ✓
  ```

  (The eviction probability is `k/(i+1) · 1/k` because item `i` only
  enters with prob `k/(i+1)`, and once in, picks an incumbent
  uniformly at random.)

By induction the claim holds at every `i`. So after processing
`N` items, **the reservoir is a uniformly random subset of size
`min(k, N)`**.

---

## Reservoir vs sort-and-pick

If you knew `N` in advance you could:

1. Generate a random permutation of `[0, N)` and pick the first `k`.
   - Memory: O(N) (to build the permutation).
   - Time: O(N).

Reservoir sampling matches the time bound but uses only O(k) memory
and works without knowing `N`. The whole point is that you don't need
to know `N` in advance — useful for log streams, network traces,
infinite generators.

---

## Reference implementation

```
pub struct Reservoir
pub fn new(capacity~ : Int, seed~ : Int64) -> Reservoir
pub fn Reservoir::add(self, item : Int64) -> Unit
pub fn Reservoir::add_many(self, items : ArrayView[Int64]) -> Unit
pub fn Reservoir::sample(self) -> Array[Int64]
pub fn Reservoir::items_seen(self) -> Int
pub fn Reservoir::capacity_of(self) -> Int
```

---

## Tests and examples

### Tiny streams fit entirely in the reservoir

```mbt check
///|
test "reservoir small stream" {
  let r = @reservoir_sampling.new(capacity=5, seed=1L)
  for x in 100L..<105L {
    r.add(x)
  }
  debug_inspect(r.sample(), content="[100, 101, 102, 103, 104]")
}
```

### Larger streams are sampled to capacity

```mbt check
///|
test "reservoir 1000 items" {
  let r = @reservoir_sampling.new(capacity=5, seed=42L)
  for x in 0L..<1000L {
    r.add(x)
  }
  debug_inspect(r.sample().length(), content="5")
  debug_inspect(r.items_seen(), content="1000")
}
```

### Determinism: same seed → same sample

```mbt check
///|
test "reservoir seeded determinism" {
  let r1 = @reservoir_sampling.new(capacity=3, seed=99L)
  let r2 = @reservoir_sampling.new(capacity=3, seed=99L)
  for x in 0L..<200L {
    r1.add(x)
    r2.add(x)
  }
  debug_inspect(r1.sample() == r2.sample(), content="true")
}
```

### Capacity zero is degenerate but supported

```mbt check
///|
test "reservoir zero capacity" {
  let r = @reservoir_sampling.new(capacity=0, seed=1L)
  for x in 1L..<10L {
    r.add(x)
  }
  debug_inspect(r.sample(), content="[]")
  debug_inspect(r.items_seen(), content="9")
}
```

---

## Complexity

| Operation       | Time | Space        |
|-----------------|------|--------------|
| `new(k, seed)`  | O(k) | O(k)         |
| `add(x)`        | O(1) | O(1) extra   |
| `add_many(xs)`  | O(\|xs\|) | O(1) extra |
| `sample()`      | O(k) | O(k) output  |
| `items_seen()`  | O(1) | O(1)         |

Each `add` does one LCG step, one modulo, and at most one array
write. There is no allocation in the steady state.

---

## When to reach for it

- **Random sampling from log streams**: pick `k` lines uniformly from
  an Apache access log being tailed in real time, without buffering
  the whole log.
- **Distributed sampling**: each shard maintains a local reservoir;
  to combine `M` shards into a global size-`k` sample, generate keys
  for each item and merge by minimum key (this is *not* Algorithm R
  any more; it is "weighted random sampling without replacement"
  per Efraimidis-Spirakis 2006).
- **A/B test enrollment**: pick `k` users uniformly from a streaming
  signup feed.
- **Sketching as a pre-stage**: a reservoir gives an unbiased estimate
  of any sum or average over the stream by computing it on the sample.

---

## Variants and follow-ups

- **Algorithm L (Vitter 1987)**: a faster reservoir-sampling variant
  that *skips* a geometric number of items between updates. Same
  uniformity guarantee but `O(k(1 + log(N / k)))` total RNG calls
  instead of `O(N)`. Worth doing as a follow-up.
- **Algorithm A-Res (Efraimidis-Spirakis 2006)**: weighted random
  sampling without replacement using a min-heap of keyed items.
- **Resilient reservoir sampling**: extensions that support
  out-of-order arrival, deletion, or sliding windows.

---

## Common pitfalls

- **Uniform within the stream, not uniform across streams**: with a
  single deterministic seed the reservoir is determined by the
  stream. To get statistically independent samples, vary the seed
  across runs.
- **`Int64` items only**: the public API is monomorphic on `Int64`
  for clarity. Sample `(key, payload)` pairs by hashing or by using
  the item index as a key and looking up the payload externally.
- **No support for removal**: reservoir sampling is `add`-only. A
  sliding-window variant is a separate (harder) algorithm.

---

## Related concepts

```
Reservoir Sampling (this)        Vitter Algorithm R, O(N) RNG calls
Algorithm L                      faster: O(k(1 + log(N / k))) RNG calls
A-Res / A-ExpJ                   Efraimidis-Spirakis weighted variants
Random shuffle (Fisher-Yates)    O(N) memory; requires N in advance
Bernoulli sampling               keeps each item with fixed prob p
Importance sampling              biased reservoirs with re-weighting
```
