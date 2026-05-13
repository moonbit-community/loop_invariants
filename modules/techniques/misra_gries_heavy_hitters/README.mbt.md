# Misra-Gries Heavy Hitters

## Overview

Given a stream of `N` items and a parameter `k`, the **heavy hitters**
problem is to find every item whose true frequency exceeds `N / k`.
Misra-Gries (1982) solves this in **one pass** using only `k - 1`
counters — independent of `N` and of the alphabet size.

A pigeonhole argument shows that at most `k - 1` items can simultaneously
exceed the `N / k` threshold, so a tiny structure is *information-
theoretically* sufficient to maintain a *superset* of the heavy hitters.
What's surprising is that you don't need to know `N` in advance and that
you only need one pass.

- **Time**: O(capacity) worst-case per `add`, O(1) amortised typical
- **Space**: O(capacity) Int counters
- **Signatures**:
  - `new(capacity~) -> MisraGries[K]`
  - `mg.add(item) -> Unit`
  - `mg.candidates() -> Array[K]`
  - `mg.estimate(item) -> Int` *(lower bound on true count)*
  - `mg.merge(other) -> Unit`

This is the streaming-aggregation cousin of `@count_min_sketch`: where
Count-Min over-estimates *every* frequency, Misra-Gries gives a small
candidate set in which the heavy hitters definitely live.

---

## The algorithm

```
maintain a dict (item -> counter), at most `capacity` entries

for x in stream:
  if x already in dict:
    dict[x] += 1
  elif dict.size() < capacity:
    dict[x] = 1
  else:
    # full -- one "cancellation event" removes `capacity + 1 = k` items
    # at once: x itself plus one occurrence from each existing bucket.
    for key in dict:
      dict[key] -= 1
      if dict[key] == 0: dict.remove(key)
```

The third branch is the load-bearing one. It looks wasteful (decrementing
every counter), but each decrement is amortised against an item being
"cancelled" — an item that does not appear often enough to overcome
these cancellations gets evicted.

---

## Correctness

### The "cancellation" accounting argument

Call an item *cancelled* whenever it contributes to a decrement-all
step. Each such step cancels `capacity + 1 = k` items at once: the
incoming `x` and one notional occurrence from each of the `capacity`
items currently in the dict.

The total number of decrement-all steps is at most `N / k`, because
each step accounts for `k` items in the stream.

So an item with true count `c` has been decremented at most `N / k`
times in the dict. Therefore the **recorded counter is at least
`c - N / k`**. In particular, if `c > N / k` the recorded counter is
strictly positive — the item survives in the dict.

### Two formal claims

Let `cnt(x)` be the recorded counter for `x` (or 0 if absent), and
`f(x)` the true frequency.

1. **Lower bound**: `cnt(x) >= f(x) - N / k`.
2. **Upper bound**: `cnt(x) <= f(x)`.

Together: every heavy hitter (`f(x) > N / k`) lies in `candidates()`,
and every recorded count is sandwiched in `[f(x) - N/k, f(x)]`.

If you need *exact* frequencies, run a second pass over the stream and
count only the candidates returned by Misra-Gries. This reduces the
exact-counting problem from O(distinct items) memory to O(k) memory.

---

## Worked example

Stream `1, 1, 2, 1, 3, 1, 4, 1, 5, 1` with `capacity = 2` (i.e. `k = 3`,
finding items with `f > 10 / 3 ≈ 3.33`):

```
after 1     :  {1: 1}
after 1 1   :  {1: 2}
after ...2  :  {1: 2, 2: 1}            # second slot fills
after 1     :  {1: 3, 2: 1}
after 3     :  full -- decrement all
              :  {1: 2}                  # 2's counter hit 0, evicted
              #  (3 cancelled against 2 and "in spirit" against one 1)
after 1     :  {1: 3}
after 4     :  {1: 3, 4: 1}
after 1     :  {1: 4, 4: 1}
after 5     :  full -- decrement all
              :  {1: 3}                  # 4 evicted
after 1     :  {1: 4}
```

Final candidates: `{1}`. True frequency of `1` is `6 / 10 = 60%`,
comfortably above the `33%` threshold. Recorded `cnt(1) = 4`, while
true `f(1) = 6`; the gap of 2 is within the `N / k = 10 / 3 ≈ 3.33`
guarantee.

---

## When to reach for it

| Scenario | Why Misra-Gries works |
|---|---|
| Single-pass top-`k` candidates from a giant log | O(k) memory, O(1) amortised per item. |
| Distributed aggregation (each shard summarises) | `merge` combines summaries with the same capacity. |
| First stage before exact counting | Cuts the candidate set from "everything seen" to ≤ `k - 1`. |
| Memory-bound stream processing | Works in space independent of `N` and of the alphabet size. |

When you really need approximate *frequencies* for arbitrary items, use
`@count_min_sketch` instead. The two are complementary.

---

## Reference implementation

```
pub struct MisraGries[K]
pub fn[K : Hash + Eq] new(capacity~ : Int) -> MisraGries[K]
pub fn[K : Hash + Eq] MisraGries::add(self, item : K) -> Unit
pub fn[K] MisraGries::candidates(self) -> Array[K]
pub fn[K : Hash + Eq] MisraGries::estimate(self, item : K) -> Int
pub fn[K] MisraGries::size(self) -> Int
pub fn[K : Hash + Eq] MisraGries::merge(self, other : MisraGries[K]) -> Unit
```

---

## Tests and examples

### Majority element (capacity = 1)

Specialising to `capacity = 1` recovers the classical Boyer-Moore
majority-vote algorithm:

```mbt check
///|
test "mg majority" {
  let mg : @misra_gries_heavy_hitters.MisraGries[Int] = @misra_gries_heavy_hitters.new(
    capacity=1,
  )
  for x in [3, 1, 3, 2, 3, 4, 3, 5, 3, 3] {
    mg.add(x)
  }
  // 3 occurs 6/10 -- a strict majority, so it's the sole survivor.
  debug_inspect(mg.candidates(), content="[3]")
}
```

### Top-2 candidates (capacity = 2)

```mbt check
///|
test "mg top 2" {
  let mg : @misra_gries_heavy_hitters.MisraGries[Int] = @misra_gries_heavy_hitters.new(
    capacity=2,
  )
  let stream = [1, 1, 1, 2, 2, 3, 4, 1, 1, 2, 2, 2]
  for x in stream {
    mg.add(x)
  }
  // Both 1 and 2 exceed the n/3 threshold.
  let cands = mg.candidates()
  debug_inspect(cands.contains(1), content="true")
  debug_inspect(cands.contains(2), content="true")
}
```

### Recorded count is a lower bound

```mbt check
///|
test "mg lower bound" {
  let mg : @misra_gries_heavy_hitters.MisraGries[Int] = @misra_gries_heavy_hitters.new(
    capacity=4,
  )
  for _ in 0..<10 {
    mg.add(7)
  }
  for v in 100..<120 {
    mg.add(v)
  }
  // f(7) = 10 over 30 items; threshold N/k = 30/5 = 6; recorded should
  // be >= 10 - 6 = 4.
  debug_inspect(mg.estimate(7) >= 4, content="true")
}
```

### Capacity bound is hard

```mbt check
///|
test "mg capacity hard bound" {
  let mg : @misra_gries_heavy_hitters.MisraGries[Int] = @misra_gries_heavy_hitters.new(
    capacity=3,
  )
  for v in 0..<100 {
    mg.add(v % 7)
  }
  debug_inspect(mg.size() <= 3, content="true")
}
```

---

## Complexity

| Operation       | Time            | Space           |
|-----------------|-----------------|-----------------|
| `new(c)`        | O(c)            | O(c) counters   |
| `add(x)` (hit)  | O(1)            | O(1) extra      |
| `add(x)` (fill) | O(1)            | O(1) extra      |
| `add(x)` (full) | O(c) worst case | O(c) temp array |
| `estimate(x)`   | O(1) avg.       | O(1) extra      |
| `candidates()`  | O(c)            | O(c) output     |
| `merge(other)`  | O(c log c)      | O(c) temp array |

The full-case work is amortised: each "decrement-all" cancels `k`
stream items, so the total work across an entire stream is O(N).

---

## Common pitfalls

- **`capacity = k - 1`, not `k`**. Pass `capacity = 9` to find items
  appearing more than `N / 10` times — easy to be off by one.
- **No false negatives, but possible false positives**. The candidate
  set is a *superset* of heavy hitters; some non-heavy items may
  survive. A second pass over the stream eliminates them.
- **`merge` requires matching `capacity`**. The function silently
  no-ops on a shape mismatch.
- **Estimates are *lower* bounds, not over-estimates** (unlike Count-Min).
  Don't confuse the two when picking a sketch.
- **Order of `candidates()` is unspecified**: backed by `Map`, which
  preserves insertion order in MoonBit but you should not rely on a
  particular ordering for downstream sorting.

---

## Related concepts

```
Misra-Gries (this)        candidate set, single pass, O(k) space
Boyer-Moore majority      specialisation with k = 2
Space-Saving algorithm    Metwally et al.; similar guarantee, simpler bookkeeping
Count-Min sketch          per-item over-estimates with tunable error
Lossy Counting            Manku-Motwani; epsilon-deficient frequencies
CKMS quantile summary     for rank/quantile heavy-hitter generalisations
```
