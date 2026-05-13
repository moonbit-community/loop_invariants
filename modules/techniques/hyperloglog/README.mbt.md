# HyperLogLog

## Overview

Estimate the **distinct count** of a stream — how many unique items
you've seen — in `O(log log N)` bits per register. With `m = 2^14`
registers (about 12 KB total), HyperLogLog (HLL) estimates
cardinalities up to `10^9` within ~1% standard error.

- **Time**: O(1) per `add`, O(m) per `estimate`
- **Space**: O(m) registers; in practice 6 bits each
- **Standard error**: ~`1.04 / sqrt(m)`
- **Signatures**:
  - `new(precision) -> HyperLogLog`
  - `h.add(x) -> Unit`
  - `h.estimate() -> Int64`
  - `h.merge(other) -> Unit`

This is the third major streaming sketch in the repo, completing the
trio:

```
@count_min_sketch       per-item frequency estimates
@misra_gries_heavy_hitters  candidates for frequent items
@hyperloglog (this)     count of DISTINCT items
```

It is the algorithm behind Redis's `PFCOUNT`, the Postgres `hll`
extension, BigQuery's `APPROX_COUNT_DISTINCT`, and basically every
production-grade approximate-distinct-count system.

---

## The idea

Hash each item to a uniformly random 64-bit string. Split the hash:

```
high `precision` bits    -> bucket index j in [0, m)
low (64 - precision) bits -> "tail" we observe
```

For each item, count `rho(tail)` = position of the leftmost 1-bit
in the tail (1-indexed). Update `register[j] = max(register[j], rho(tail))`.

For uniform hashes, the probability of seeing `rho >= k` from `n`
items in one bucket is `1 - (1 - 2^{-k})^n`, so the *maximum* `rho` in
a bucket of `n` items tracks `log2(n)` quite tightly.

### The estimator

```
E_raw  =  alpha_m · m²  /  sum_{j=0..m-1} 2^{-register[j]}
```

The denominator is the **harmonic mean** of `2^register[j]`. The
harmonic mean dampens outliers (one register that happened to see a
long run of zeros), which is exactly the volatility HLL needs to
control. The constant `alpha_m` corrects for a small bias from the
"expectation of max" approximation:

| m   | alpha_m |
|-----|---------|
| 16  | 0.673   |
| 32  | 0.697   |
| 64  | 0.709   |
| ≥128 | 0.7213 / (1 + 1.079 / m) |

### Small-range correction (linear counting)

When `E_raw <= 2.5 · m`, the variance is dominated by buckets that
saw zero hits. Substitute the *linear-counting* estimator

```
E_lin  =  m · ln(m / V)
```

where `V` is the number of empty registers. This is exact for the
"random throws into m buckets" model and much more accurate at small
cardinalities.

---

## Why the harmonic mean

The geometric mean would also work; the arithmetic mean is too
sensitive to outliers. The harmonic mean of `2^register[j]` has two
nice properties for this setting:

1. **Bias correction by `alpha_m`** is small and closed-form.
2. **Insensitive to high-tail registers**. A single register that
   happened to see `rho = 30` (probability `2^{-30}` per hashed item)
   contributes only `2^{-30}` to the harmonic-mean denominator — its
   damage is bounded.

---

## Worked example

`precision = 4` (`m = 16` registers). Add three items:

```
hash(7)  = 0xa3...   -> high 4 bits = 0xa (= 10),   tail = 0x3...
                       leading zeros + 1 in tail's 60 bits = depends
register[10] = max(0, rho)
```

After many items, registers fill with `rho`-values. For 1000 distinct
items into 16 buckets, average register value ~`log2(1000/16) ≈ 6`,
and the formula gives `E ≈ alpha_16 · 16² / (16 · 2^{-6}) ≈ 689`.
Linear counting probably kicks in for small `m` and gives a tighter
estimate.

---

## Tests and examples

```mbt check
///|
test "hll 1000 distinct" {
  let h = @hyperloglog.new(14)
  for x in 0L..<1000L {
    h.add(x)
  }
  let est = h.estimate()
  // ~1000 within ~5% (a generous 5-sigma envelope).
  debug_inspect(est >= 950L, content="true")
  debug_inspect(est <= 1050L, content="true")
}
```

```mbt check
///|
test "hll duplicates don't inflate" {
  let h = @hyperloglog.new(12)
  for v in 0L..<50L {
    for _ in 0..<100 {
      h.add(v)
    }
  }
  // 5000 calls, only 50 distinct -- estimate stays small.
  debug_inspect(h.estimate() < 200L, content="true")
}
```

```mbt check
///|
test "hll merge" {
  let a = @hyperloglog.new(10)
  let b = @hyperloglog.new(10)
  for v in 0L..<500L {
    a.add(v)
  }
  for v in 500L..<1000L {
    b.add(v)
  }
  a.merge(b)
  // Combined sketch ~1000 within ~15% envelope.
  debug_inspect(a.estimate() >= 850L, content="true")
  debug_inspect(a.estimate() <= 1150L, content="true")
}
```

```mbt check
///|
test "hll register count" {
  debug_inspect(@hyperloglog.new(14).register_count(), content="16384")
}
```

---

## Mergeability — the killer feature

For a single sketch `s` over a stream `S`, `s.estimate() ≈ |S|`.

For two sketches `s_A, s_B` over streams `S_A, S_B` (same precision,
same hash family), the **elementwise-max** merge `s_A.merge(s_B)`
produces a sketch over `S_A ∪ S_B`. The bound holds without any
double-count subtraction.

This is the property that makes HLL the standard for distributed
analytics: each worker maintains a tiny per-shard sketch, the
coordinator merges them, and the global estimate is computed in one
round trip with `O(m)` total network bandwidth.

---

## Choosing precision

| Precision | m       | Memory | SE      | Use case                       |
|-----------|---------|--------|---------|--------------------------------|
| 8         | 256     | ~200 B | ~6.5%   | Tiny counters, IoT             |
| 10        | 1024    | ~770 B | ~3.25%  | Per-IP counts on a router      |
| 12        | 4096    | ~3 KB  | ~1.6%   | General use                    |
| 14        | 16384   | ~12 KB | ~0.81%  | Database / data-warehouse default |
| 16        | 65536   | ~48 KB | ~0.41%  | High-precision metrics         |

Each step in `precision` doubles `m` and (roughly) halves the SE.

---

## Common pitfalls

- **Cannot count "remove"**: HLL is a `add`-only structure. The
  max-of-registers semantics cannot be undone. For sets with
  removals use `@count_min_sketch` over `(item, count)` updates, or
  a different sketch.
- **Same hash family per merge**. Merging requires the registers were
  populated by the same hash function. If you build sketches on
  different machines, share the precision *and* the hash design
  (this package's `hll_mix` is deterministic given the input).
- **Hash quality matters**. A weak hash can cluster items into a few
  buckets and bias estimates. This package uses the MurmurHash3
  `fmix64` finaliser.
- **Linear counting transition is empirical**. The constant `2.5 · m`
  threshold comes from the HLL paper; it is *not* tight. In practice
  the transition is smooth enough that you can swap in HLL++ or
  HLL-Tail bias correction without rewriting tests.

---

## Related concepts

```
HyperLogLog (this)        counts distinct items in O(log log N) bits
HLL++                     Google's refined HLL with sparse encoding
LogLog                    earlier sibling; HLL is a strict improvement
Linear counting           exact small-cardinality bound, used internally
Flajolet-Martin           the original "probabilistic counting" paper
KMV (k-min-values)        keeps the smallest k hashes; mergeable
Count-Min sketch          frequencies, not cardinalities
Misra-Gries               heavy hitters, not cardinalities
```
