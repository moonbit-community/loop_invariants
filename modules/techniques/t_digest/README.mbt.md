# t-digest

## Overview

Dunning's t-digest (2014) is a **streaming quantile sketch** designed
to give very accurate tail estimates (p99, p999) with bounded memory.
It is the algorithm behind Datadog's quantile aggregation, Apache
Druid's `quantilesDoublesSketch`, and many production-grade
percentile pipelines.

- **Time**: O(log n) per `add`, O(centroids) per `quantile`
- **Space**: O(compression) centroids, ~100-1000 in practice
- **Signatures**:
  - `new(compression~) -> TDigest`
  - `t.add(x) -> Unit`
  - `t.quantile(q) -> Double`
  - `t.compress() -> Unit`
  - `t.count() -> Int`
  - `t.centroid_count() -> Int`

The trick: keep small centroids near the tails (q ≈ 0, q ≈ 1) for
high accuracy where it matters, and let centroids grow near the
median (where we don't need precise rank). The size bound on a
centroid is dictated by a **scale function** k(q) — the centroid
at empirical quantile range `[q_lo, q_hi]` satisfies
`k(q_hi) - k(q_lo) ≤ 1`.

---

## The scale function

```
k(q) = (compression / 2π) · arcsin(2q - 1) + compression / 4
```

This is monotone increasing in q. The crucial property is that
`k(q)` is **shallower** near q = 0.5 (so centroids may grow large
there) and **steep** near q = 0 or q = 1 (so centroids must stay
small in the tails). The "1" budget per centroid translates to
roughly `1/(k'(q)) = 2π / compression · √(q(1-q))` empirical-rank
units — i.e., tail-quantile estimates have absolute rank error
proportional to `√q(1-q) · 2π / compression`.

---

## The invariants

| | After every `add` / `compress` |
|---|---|
| **I1** | Centroids are sorted by `mean`. |
| **I2** | Sum of weights equals `count`. |
| **I3** | For every centroid, `k(q_hi) - k(q_lo) ≤ 1`. |

Invariant I3 is the load-bearing one — it gives the per-quantile
rank-error guarantee.

---

## Reference implementation

```
pub struct TDigest
pub fn new(compression~ : Double) -> TDigest
pub fn TDigest::add(self, x : Double) -> Unit
pub fn TDigest::quantile(self, q : Double) -> Double
pub fn TDigest::compress(self) -> Unit
pub fn TDigest::count(self) -> Int
pub fn TDigest::centroid_count(self) -> Int
```

---

## Tests and examples

```mbt check
///|
test "tdigest median uniform" {
  let t = @t_digest.new(compression=100.0)
  for i in 1..<=1000 {
    t.add(i.to_double())
  }
  let m = t.quantile(0.5)
  // Expected median ~500.5; within 10% is plenty for compression=100.
  debug_inspect(m >= 450.0 && m <= 550.0, content="true")
}
```

```mbt check
///|
test "tdigest p99" {
  let t = @t_digest.new(compression=200.0)
  for i in 1..<=1000 {
    t.add(i.to_double())
  }
  // Expected p99 ≈ 990.
  let p = t.quantile(0.99)
  debug_inspect(p >= 950.0 && p <= 1010.0, content="true")
}
```

```mbt check
///|
test "tdigest min and max" {
  let t = @t_digest.new(compression=100.0)
  for x in [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0] {
    t.add(x)
  }
  debug_inspect(t.quantile(0.0), content="1")
  debug_inspect(t.quantile(1.0), content="9")
}
```

```mbt check
///|
test "tdigest count" {
  let t = @t_digest.new(compression=50.0)
  for _ in 0..<500 {
    t.add(0.0)
  }
  debug_inspect(t.count(), content="500")
}
```

---

## Common pitfalls

- **`compression` ↔ memory ↔ accuracy**: rough rule of thumb is
  `compression = 100` for ~6% rank error at the tails;
  `compression = 1000` for ~0.6%.
- **Adversarial inputs**: sorted or reverse-sorted streams put
  pressure on the compaction schedule. The implementation does
  lazy compaction; if your workload is adversarial, call
  `compress()` periodically.
- **Mergeable across machines**: full t-digest implementations
  support combining two digests by interleaving centroids; this
  package does *not* (yet) expose `merge`.

---

## Related concepts

```
t-digest (this)            Dunning 2014, scale-function quantile sketch
GK quantile summary        Greenwald-Khanna; epsilon-approximate quantile
q-digest                   Shrivastava-Buragohain-Agrawal
Reservoir sampling         exact quantile from a uniform sample
P^2 algorithm              moments-based streaming quantile
Moments-based sketches     for specific quantiles only
```
