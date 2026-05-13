# Morris Counter

## Overview

A probabilistic counter that approximates large counts using **O(log log N)
bits**. Morris (1978) showed that by storing the *logarithm* of the count
and updating it stochastically, you can fit any count up to `10^18` into
just **six bits**.

- **Time**: O(1) per increment, O(1) per query
- **Space**: O(log log N) bits per counter (typically 6-8 bits in practice)
- **Signatures**:
  - `new(base~, seed~) -> MorrisCounter`
  - `mc.increment() -> Unit`
  - `mc.increment_n(n) -> Unit`
  - `mc.estimate() -> Int64`
  - `mc.raw() -> Int`

This is a strange and beautiful little algorithm: it answers "How many
events?" with provable accuracy bounds while storing essentially nothing.
Useful when you have **billions of counters** and only ever need
ballpark figures — e.g. per-IP packet counts on a router, per-key
visit counts on a top-of-funnel cache.

---

## The trick

To increment a Morris counter with parameter `a > 1`:

```
with probability   1 / a^c     do  c := c + 1
otherwise          do nothing
```

where `c` is the small stored integer. The estimated count is

```
estimate = (a^c - 1) / (a - 1)
```

That formula is **unbiased**: averaging over the randomness, the
expected estimate equals the true number of `increment` calls.

### Why it works (one-line proof)

Let `X_N = a^{c_N}` where `c_N` is the counter after `N` increments.
On the (N+1)-th call, with probability `1 / X_N` we bump `c`, so

```
E[X_{N+1} | X_N]  =  X_N + (a - 1) * X_N * 1/X_N  =  X_N + (a - 1)
```

By telescoping from `X_0 = 1`:

```
E[X_N]  =  1 + (a - 1) * N
```

so `E[(X_N - 1) / (a - 1)] = N`. Unbiased.

### Variance trade-off

A similar martingale argument gives the relative standard error

```
sigma / N  ≈  sqrt( (a - 1) / 2 )
```

independent of `N`. So:

| `base` | RSE        | Use when…                                |
|--------|------------|------------------------------------------|
| `2.0`  | ~70%       | order-of-magnitude is enough             |
| `1.1`  | ~22%       | within-factor-of-2 monitoring metrics    |
| `1.08` | ~20%       | Flajolet's "approximate counting" sweet spot |
| `1.0078` | ~6%      | HyperLogLog-class accuracy at ~8-bit `c` |

Pick `base` as small as you can afford given the counter range. Smaller
`base` ↔ tighter accuracy ↔ larger `c` for the same true count.

---

## Space

Storing the count `N` exactly needs `ceil(log2(N + 1))` bits. The
Morris counter stores the **log** of the count instead:

```
c  ≈  log_a(1 + (a - 1) * N)
```

so the bits needed to store `c` are

```
ceil(log2(log_a(N) + 1))
```

For `N = 10^18` and `a = 2`: `log_2(10^18) ≈ 60`, so `c ≤ 60`, fitting
in **6 bits**. That's the headline win.

---

## Worked example

Start with `c = 0`. Increment four times with `a = 2`:

```
event 1: threshold = 1/2^0 = 1.0           bump c -> c = 1
event 2: threshold = 1/2^1 = 0.5           coin says yes -> c = 2
event 3: threshold = 1/2^2 = 0.25          coin says no  -> c = 2
event 4: threshold = 1/2^2 = 0.25          coin says yes -> c = 3
```

After these 4 events the estimator is `(2^3 - 1) / (2 - 1) = 7`. On
this single trajectory we over-estimated by 3; another seed might give
0 (if no bumps ever fire after `c = 0` with prob 1/2). In expectation
across seeds, the estimate is 4.

---

## When to reach for it

| Scenario | Why Morris works |
|---|---|
| A million counters, each rarely queried | 8 bits each instead of 64 — 8x memory saved |
| You only need order-of-magnitude figures | `base = 2` is the smallest space at the loosest accuracy |
| Distributed counters that get merged | Merge by averaging estimates from `M` shards; SE shrinks like `1/sqrt(M)` |
| Memory bandwidth is the bottleneck | Tiny counters fit in cache, much faster than `Int64` updates |

It is **not** appropriate when you need exact counts, when one specific
counter dominates the workload (`base = 1.0078` won't fit in 6 bits at
extreme `N`), or for billing-grade accounting.

---

## Reference implementation

```
pub struct MorrisCounter
pub fn new(base~ : Double, seed~ : Int64) -> MorrisCounter
pub fn MorrisCounter::increment(self) -> Unit
pub fn MorrisCounter::increment_n(self, n : Int) -> Unit
pub fn MorrisCounter::estimate(self) -> Int64
pub fn MorrisCounter::raw(self) -> Int
pub fn MorrisCounter::base_of(self) -> Double
```

---

## Tests and examples

### First increment is guaranteed

With `c = 0`, the threshold `1 / 2^0 = 1.0` makes the first increment
*always* bump:

```mbt check
///|
test "morris first increment certain" {
  let mc = @morris_counter.new(base=2.0, seed=1L)
  mc.increment()
  debug_inspect(mc.raw(), content="1")
  debug_inspect(mc.estimate(), content="1")
}
```

### Order-of-magnitude correctness for moderate counts

```mbt check
///|
test "morris ballpark" {
  let mc = @morris_counter.new(base=2.0, seed=12345L)
  for _ in 0..<1000 {
    mc.increment()
  }
  let est = mc.estimate()
  debug_inspect(est >= 200L, content="true")
  debug_inspect(est <= 5000L, content="true")
}
```

### `increment_n` matches a manual loop with the same seed

The two should produce identical trajectories. This is what makes
deterministic seeding useful for parallel sharded counts.

```mbt check
///|
test "morris increment_n reproducible" {
  let m1 = @morris_counter.new(base=2.0, seed=99L)
  let m2 = @morris_counter.new(base=2.0, seed=99L)
  for _ in 0..<500 {
    m1.increment()
  }
  m2.increment_n(500)
  debug_inspect(m1.raw() == m2.raw(), content="true")
}
```

### Counter is monotonically non-decreasing

```mbt check
///|
test "morris monotonic" {
  let mc = @morris_counter.new(base=2.0, seed=7L)
  let mut prev = 0
  for _ in 0..<100 {
    mc.increment()
    debug_inspect(mc.raw() >= prev, content="true")
    prev = mc.raw()
  }
}
```

---

## Complexity

| Operation        | Time      | Space |
|------------------|-----------|-------|
| `new(...)`       | O(1)      | O(1)  |
| `increment()`    | O(1)      | O(1)  |
| `increment_n(n)` | O(n)      | O(1)  |
| `estimate()`     | O(1)      | O(1)  |
| `raw()`          | O(1)      | O(1)  |

The per-operation cost is a constant: one LCG step, one
floating-point comparison, one `pow` call. The `pow` is the slow part
on architectures without a fast `pow` intrinsic — if performance
matters, cache `1 / base^c` and update it lazily when `c` changes.

---

## Merging Morris counters

Two counters `M_1, M_2` with the same `base` can be combined as

```
est_combined  =  est(M_1) + est(M_2)
```

because the estimator is unbiased and linearity of expectation applies.
This is **not** the same as setting `c_combined = c_1 + c_2` — that
would correspond to multiplying the underlying counts. Use the estimate
sums.

For `M` parallel shards, averaging the estimates reduces the relative
standard error by a factor of `sqrt(M)`. This is the easiest way to
extract better accuracy without changing `base`.

---

## Common pitfalls

- **The estimator is unbiased; the *median* is not**. For applications
  that need a most-likely value, take many shards and average — not
  median.
- **`base` near 1 is fragile**. At `base = 1.01` the increment
  threshold is essentially always > 1 for small `c`, so the first
  hundred increments deterministically bump `c`. The "approximate"
  regime starts only after `c` is large.
- **Don't subtract**. Morris counters do not support `decrement`. For
  signed updates, use a different family (e.g. linear counting).
- **Seed quality**. The internal LCG is small. For privacy-sensitive
  or adversarial settings (someone can pick events to push your
  counter up or down), use a cryptographically strong PRNG fed into
  `morris_uniform`'s contract.

---

## Related concepts

```
Morris counter (this)       O(log log N) bits, ~70% RSE
Approximate counting        Flajolet '85; reparameterised Morris
HyperLogLog                 cardinality (distinct items), not total count
Count-Min sketch            per-item frequencies, not total count
Reservoir sampling          uniform sample of a stream, not a count
```
