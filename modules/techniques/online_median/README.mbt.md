# Online Median (Two-Heap)

## Overview

Maintain the median of a growing stream of integers, with O(log n)
amortised per insertion and O(1) per query. The trick is to keep the
data split across two heaps and pivot on the larger one to enforce a
size invariant.

- **Time**: O(log n) per `add`, O(1) per `median` / `lower_median` / `upper_median`
- **Space**: O(n) total (one heap slot per item)
- **Signatures**:
  - `new() -> OnlineMedian`
  - `m.add(x) -> Unit`
  - `m.median() -> Double?` — true median (averages on even count)
  - `m.lower_median() -> Int?`
  - `m.upper_median() -> Int?`
  - `m.size() -> Int`

This is a textbook interview problem with a surprisingly subtle
invariant story — perfect for the "rigorous loop invariants" theme.

---

## The two-heap idea

Split the stream into two halves at all times:

```
lo  =  max-heap of the smaller half
hi  =  min-heap of the larger half
```

We use `@priority_queue.PriorityQueue` from the standard library, which
is a max-heap. For the `hi` side we store the **negated** values so
that the max-heap's peek gives the minimum of the original numbers.

### Three invariants

After every `add`, the structure satisfies:

```
I1.  max(lo)  <=  min(hi)                    "lo is entirely below hi"
I2.  | lo.size  -  hi.size |  <=  1          "sizes differ by at most one"
I3.  lo.size  >=  hi.size                    "lo holds the extra when odd"
```

Together these imply that when the count is odd, the median is
`max(lo)`; when even, the two middle elements are `max(lo)` and
`min(hi)` and the true median is their average.

### The two-step insert

```
add(x):
  # Step 1: route.
  if lo empty or x <= max(lo):
    lo.push(x)
  else:
    hi.push(x)

  # Step 2: rebalance with at most one transfer.
  if lo.size > hi.size + 1:
    hi.push(lo.pop())
  elif hi.size > lo.size:
    lo.push(hi.pop())
```

Step 1 preserves **I1** unconditionally: if `x <= max(lo)` then `lo`
already covers `x`; otherwise `x > max(lo) >= max(lo)` and going to
`hi` (whose min is at least `max(lo) + 1` by induction) is also safe.

Step 2 preserves **I2** and **I3**: at most one transfer is ever
needed, because step 1 changed the size of exactly one heap by 1.

Both heaps remain valid after each step, and `max(lo) <= min(hi)`
because the transferred element either came from `lo`'s top (still
`<= the new min(hi)`) or `hi`'s top (still `>= the new max(lo)`).

### Why "two-step" is exactly enough

This is the elegance — at any moment the difference of sizes is at
most one off-by-one event, and one transfer fixes it. There is no
recursion, no resizing, no logarithmic rebalance. The two heaps
provide enough slack that local repair suffices.

---

## Worked example

Stream: `3, 1, 4, 1, 5, 9, 2, 6, 5, 3`.

```
add 3 :  lo=[3]                         hi=[]                median=3
add 1 :  lo=[1]                         hi=[-3]              median=(1+3)/2=2.0
add 4 :  lo=[3, 1]                      hi=[-4]              median=3
add 1 :  lo=[1, 1, 3]    (max=3)        hi=[-4]              -- need transfer
                                                                lo too big: pop 3 -> hi
         lo=[1, 1]                      hi=[-3, -4]          median=(1+3)/2=2.0

         ...
```

At every step, `lower_median()` reports the value at the top of `lo`
(an O(1) heap peek), and the constant-time check `lo.size > hi.size`
decides whether the count is odd.

---

## Reference implementation

```
pub struct OnlineMedian
pub fn new() -> OnlineMedian
pub fn OnlineMedian::add(self, x : Int) -> Unit
pub fn OnlineMedian::median(self) -> Double?
pub fn OnlineMedian::lower_median(self) -> Int?
pub fn OnlineMedian::upper_median(self) -> Int?
pub fn OnlineMedian::size(self) -> Int
```

---

## Tests and examples

### Even-count median averages the two middle values

```mbt check
///|
test "median two values" {
  let m = @online_median.new()
  m.add(1)
  m.add(3)
  debug_inspect(m.median(), content="Some(2)")
  debug_inspect(m.lower_median(), content="Some(1)")
  debug_inspect(m.upper_median(), content="Some(3)")
}
```

### Insertion order does not matter

```mbt check
///|
test "median insertion order" {
  let asc = @online_median.new()
  let desc = @online_median.new()
  for x in [1, 2, 3, 4, 5] {
    asc.add(x)
  }
  for x in [5, 4, 3, 2, 1] {
    desc.add(x)
  }
  debug_inspect(asc.median() == desc.median(), content="true")
}
```

### Mixed stream agrees with the sort-and-pick ground truth

```mbt check
///|
test "median classical example" {
  let m = @online_median.new()
  for x in [3, 1, 4, 1, 5, 9, 2, 6, 5, 3] {
    m.add(x)
  }
  // sorted: [1,1,2,3,3,4,5,5,6,9]; median = (3+4)/2 = 3.5
  debug_inspect(m.median(), content="Some(3.5)")
}
```

### Empty stream

```mbt check
///|
test "median empty" {
  let m = @online_median.new()
  debug_inspect(m.median(), content="None")
}
```

---

## Complexity

| Operation        | Time         | Space      |
|------------------|--------------|------------|
| `new()`          | O(1)         | O(1)       |
| `add(x)`         | O(log n)     | O(1) extra |
| `median()`       | O(1)         | O(1) extra |
| `lower_median()` | O(1)         | O(1) extra |
| `upper_median()` | O(1)         | O(1) extra |
| `size()`         | O(1)         | O(1) extra |

The implementation is allocation-free per `add` (priority-queue pushes
and pops do not allocate new wrapper objects).

---

## When to reach for it

- **Streaming dashboards**: a "p50 latency" line on a Grafana panel,
  updated as each new measurement arrives.
- **Online algorithms problems**: this is the canonical building block
  for sliding-median sketches (combine with a multiset to support
  removals).
- **Robust statistics on streams**: the median is far more
  outlier-resistant than the mean, and Two-Heap maintains it for
  unbounded streams in bounded memory per element.
- **Interview prep**: a tiny but invariant-rich problem; the
  invariant story above is the canonical write-up.

---

## Common pitfalls

- **Sliding window medians need more machinery**. This package only
  supports `add`. To support a `remove(x)` operation efficiently you
  need an indexed priority queue (or a treap, or a hash-map of "lazy
  deletes"); see the `@treap` / `@implicit_treap` packages for set
  data structures that support arbitrary removal.
- **Integer overflow in `upper_median`**. The implementation negates
  values when storing in `hi`, so `Int::MIN_VALUE` cannot round-trip
  (its negation overflows). Use `Int64`-sized inputs and convert at
  the boundary if you need full range; left as a future enhancement.
- **`median()` returns `Double`**; if you only need exact-Int answers,
  reach for `lower_median()` or `upper_median()`.
- **The two heaps share nothing**. Two `OnlineMedian` instances are
  fully independent — there is no global RNG or hash state to keep
  in sync.

---

## Related concepts

```
Two-heap online median  (this)            O(log n) add, O(1) query
Order statistic tree    @implicit_treap   O(log n) k-th element
Quickselect             worst-case O(n) k-th smallest (offline)
P-square algorithm      single-pass approximate median in O(1) space
T-digest, q-digest      streaming quantile sketches
```
