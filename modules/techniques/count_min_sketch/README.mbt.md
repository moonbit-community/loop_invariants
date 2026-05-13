# Count-Min Sketch

## Overview

A sublinear-space data structure for estimating item frequencies in a
stream of `(key, count)` updates. Each query returns an **over-estimate**
of the true count, with a tunable additive error bound and failure
probability.

- **Time**: O(d) per update and per query
- **Space**: O(w · d) Int64 counters
- **Signatures**:
  - `new(width~, depth~, seed~) -> CountMinSketch`
  - `from_error_bounds(eps, delta, seed~) -> CountMinSketch`
  - `cms.add(key, count) -> Unit`
  - `cms.estimate(key) -> Int64`
  - `cms.merge(other) -> Unit`

The sketch is the workhorse of streaming aggregation — used in network
traffic analysis, distributed analytics, ML feature counters, and
anywhere you need approximate `top-k` frequencies on data that does not
fit in memory.

---

## Representation

A `d × w` matrix of `Int64` counters, plus `d` independently chosen hash
functions `h_1, ..., h_d` mapping keys to `[0, w)` from a Carter-Wegman
style 2-universal family

```
h_r(x) = ((a_r · x + b_r) mod p) mod w
```

where `p = 2^31 - 1` is a Mersenne prime and `(a_r, b_r)` are derived
deterministically from the user-supplied seed.

```
   col 0  col 1  col 2  ...  col w-1
 ┌───────────────────────────────────┐
0│ 0      0      0      ...    0     │ ← row 0 (hash h_0)
1│ 0      0      0      ...    0     │ ← row 1 (hash h_1)
2│ 0      0      0      ...    0     │
 │ ...                               │
d│ 0      0      0      ...    0     │ ← row d-1 (hash h_{d-1})
 └───────────────────────────────────┘
```

---

## The two operations

### `add(key, c)`

For each row, increment the column at `h_r(key)`:

```
for r in 0..<d:
  counts[r][h_r(key)] += c
```

### `estimate(key)`

Return the **minimum** over rows:

```
return min over r in 0..<d of counts[r][h_r(key)]
```

Why "minimum"? Each row over-estimates by an amount equal to the sum of
collisions with *other* keys in that row. The minimum picks the row that
got luckiest with collisions.

---

## Correctness: the Markov argument

Let `f(key)` be the true count of `key` and `N` the total mass.

Each row r satisfies

```
counts[r][h_r(key)]  =  f(key)  +  sum_{x ≠ key} f(x) · 1[h_r(x) = h_r(key)]
```

The expected value of the collision sum over a random `h_r` from a
2-universal family is `N / w`. By **Markov's inequality**, the collision
sum exceeds `e · N / w` with probability at most `1 / e` for any *one*
row. Because the `d` rows use independent hash functions, the failure
probability of the minimum is at most `(1 / e)^d`.

Picking

```
w = ⌈e / eps⌉,   d = ⌈ln(1 / delta)⌉
```

gives the guarantee

```
Pr[ estimate(key) ≤ f(key) + eps · N ]  ≥  1 - delta.
```

`from_error_bounds(eps, delta, seed~)` sizes the sketch to satisfy
exactly that bound.

---

## Worked example

Take a sketch with `w = 4, d = 2` and (for illustration) the hash
functions

```
h_0(x) = x mod 4
h_1(x) = (x + 1) mod 4
```

After `add(5, 3); add(7, 2); add(11, 4)`:

```
key=5 :  h_0 = 1, h_1 = 2
key=7 :  h_0 = 3, h_1 = 0
key=11:  h_0 = 3, h_1 = 0
```

Counters:

```
row 0:  [0, 3, 0, 6]      ← 5 lands in col 1; 7 and 11 collide in col 3
row 1:  [6, 0, 3, 0]      ← 7 and 11 collide in col 0; 5 lands in col 2
```

Queries:

- `estimate(5)  = min(counts[0][1], counts[1][2])  =  min(3, 3)  =  3`. Exact.
- `estimate(7)  = min(counts[0][3], counts[1][0])  =  min(6, 6)  =  6`. Over by 4 (collision with 11).
- `estimate(11) = min(counts[0][3], counts[1][0])  =  min(6, 6)  =  6`. Over by 2.
- `estimate(99) = min(counts[0][?], counts[1][?])`. Whatever row picks an empty column wins — likely 0.

Wider tables and more rows make collisions exponentially less damaging.

---

## Reference implementation

```
pub struct CountMinSketch
pub fn new(width~ : Int, depth~ : Int, seed~ : Int64) -> CountMinSketch
pub fn from_error_bounds(eps : Double, delta : Double, seed~ : Int64) -> CountMinSketch
pub fn CountMinSketch::add(self, key : Int64, count : Int64) -> Unit
pub fn CountMinSketch::estimate(self, key : Int64) -> Int64
pub fn CountMinSketch::merge(self, other : CountMinSketch) -> Unit
pub fn CountMinSketch::width_of(self) -> Int
pub fn CountMinSketch::depth_of(self) -> Int
```

---

## Tests and examples

### Estimates over-count by design

```mbt check
///|
test "cms over-estimates" {
  let s = @count_min_sketch.new(width=128, depth=4, seed=42L)
  s.add(1L, 5L)
  s.add(2L, 3L)
  s.add(1L, 2L)
  debug_inspect(s.estimate(1L) >= 7L, content="true")
  debug_inspect(s.estimate(2L) >= 3L, content="true")
}
```

### Wide tables make estimates exact

```mbt check
///|
test "cms wide table" {
  let s = @count_min_sketch.new(width=4096, depth=5, seed=123L)
  s.add(100L, 10L)
  s.add(200L, 20L)
  debug_inspect(s.estimate(100L), content="10")
  debug_inspect(s.estimate(200L), content="20")
}
```

### Two sketches with the same seed merge cleanly

```mbt check
///|
test "cms merge same seed" {
  let s1 = @count_min_sketch.new(width=256, depth=4, seed=7L)
  let s2 = @count_min_sketch.new(width=256, depth=4, seed=7L)
  s1.add(5L, 10L)
  s2.add(5L, 20L)
  s1.merge(s2)
  debug_inspect(s1.estimate(5L), content="30")
}
```

### `from_error_bounds` sizes the sketch automatically

```mbt check
///|
test "cms from error bounds" {
  // Tolerate 1% additive error with 99% confidence.
  let s = @count_min_sketch.from_error_bounds(0.01, 0.01, seed=7L)
  debug_inspect(s.width_of() >= 272, content="true")
  debug_inspect(s.depth_of() >= 5, content="true")
}
```

---

## Complexity

| Operation         | Time            | Space           |
|-------------------|-----------------|-----------------|
| `new(w, d, ...)`  | O(w · d)        | O(w · d) Int64s |
| `add(k, c)`       | O(d)            | O(1) extra      |
| `estimate(k)`     | O(d)            | O(1) extra      |
| `merge(other)`    | O(w · d)        | O(1) extra      |

Choosing `eps = 0.01, delta = 0.01` (1% additive error, 99% confidence)
gives `w ≈ 272, d ≈ 5`, i.e. ~1360 counters per sketch — independent of
the stream length `N`. That is the headline win: **the sketch stays the
same size whether you process a million items or a trillion**.

---

## Common applications

- **Network monitoring**: estimate per-flow byte counts on a 100 Gb/s
  link without keeping a counter per flow.
- **Distributed analytics**: each worker maintains a local sketch with a
  shared seed; merge at a coordinator for a global estimate.
- **Heavy-hitter detection**: combine with a small heap of candidates;
  use the sketch to estimate frequencies for items popped in and out.
- **ML feature counters**: hash a high-cardinality categorical feature
  into a fixed-width sketch; the over-estimate is a safe upper bound on
  feature popularity.

---

## Common pitfalls

- **Decrements break the over-estimate**: passing a negative `count` to
  `add` still type-checks but invalidates the `estimate ≥ truth`
  guarantee. For signed updates, use a Count-Mean-Min or Count-Sketch
  variant instead.
- **Shared seed for `merge`**: two sketches can only be merged if they
  use the same hash family — i.e. same `width`, same `depth`, same
  `seed` at construction time. This package silently no-ops if the
  shapes disagree; it cannot check seeds, so callers are responsible.
- **Skewed streams help, not hurt**: the additive error is `eps · N`, so
  on a Zipfian stream the head items have plenty of true count to
  swamp the noise. Tail items have higher *relative* error.
- **Seed quality**: the LCG-derived `(a, b)` pair gives a 2-universal
  family by construction, but if you want pairwise-independent rows
  across multiple sketches built at different times, derive seeds from
  a single root via a strong hash.

---

## Related concepts

```
Count-Min sketch       (this)         over-estimate, additive error
Count-Mean-Min         improves       handles signed updates
Count Sketch           Charikar       unbiased estimator via random ±1
Bloom filter           membership     over-estimates set membership
Misra-Gries            heavy hitters  finds frequent items in one pass
HyperLogLog            cardinality    counts distinct items in O(log log)
AMS sketch             moments        estimates F_2 (variance)
```
