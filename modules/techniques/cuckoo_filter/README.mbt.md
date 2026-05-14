# Cuckoo Filter

## Overview

The **Cuckoo filter** (Fan, Andersen, Kaminsky, Mitzenmacher 2014) is an
approximate-membership data structure that supports

- `insert(x)`
- `contains(x)` — no false negatives, controlled false-positive rate
- `delete(x)` — restores absence of a previously inserted item

It is a strict **upgrade over a Bloom filter** in two ways:

1. It supports **deletion** without a complex counting variant.
2. At a target false-positive rate, it uses **less space per item** than a
   Bloom filter for FPR below ~3%.

- **Time**: O(1) per insert, contains, delete (amortised; insert may evict)
- **Space**: ~`b · m · f` bits for `m` buckets of `b` fingerprints, each `f` bits
- **Signatures**:
  - `new(m~, b~, seed~) -> CuckooFilter`
  - `cf.insert(key) -> Bool`
  - `cf.contains(key) -> Bool`
  - `cf.delete(key) -> Bool`
  - `cf.count_of() -> Int`
  - `cf.capacity() -> Int`

---

## The data structure

`m` buckets, each holding up to `b` short **fingerprints** (this package
uses 16-bit fingerprints with `0` as the empty-slot sentinel). Each item
`x` has two candidate buckets:

```
h_1(x) = h(x)              mod m
h_2(x) = h_1(x) XOR h(fp)  mod m       where fp = fingerprint(x)
```

The XOR has a beautiful symmetry:

```
h_2(x) XOR h(fp) = h_1(x)
```

So given just a bucket index `i` and a fingerprint `f`, the **other**
bucket is `i XOR h(f)` — independent of which side we started on. That's
why `delete` works without storing the full key.

---

## Insertion (with eviction)

```
insert(x):
  f, b1, b2 = buckets_of(x)
  if table[b1] has room: place f there
  elif table[b2] has room: place f there
  else:
    evict-chain:
      pick a slot in b1 or b2
      swap f with the fingerprint there
      move the evicted fingerprint to its alternate bucket
      repeat up to max_kicks times
    if chain exceeds max_kicks: fail
```

Eviction is the "cuckoo" part — like a cuckoo bird, the new item kicks
out an existing one, which then has to find a new nest. With load
factor below ~95% and `b = 4`, the chain almost always terminates in a
handful of steps.

---

## The invariant

> For every live insert, the item's fingerprint sits in **one of its two
> candidate buckets**.

This is preserved by every insert (the XOR symmetry guarantees that any
relocation lands the fingerprint in a valid alternate). It is what makes
`contains` and `delete` work by looking at only two buckets.

---

## The false-positive rate

With `b` fingerprints per bucket and `f`-bit fingerprints,

```
FP rate  ≈  2 b / 2^f
```

This package uses 16-bit fingerprints (`f = 16`) and the default
`b = 4`:

```
FP rate  ≈  8 / 65536  ≈  0.012%
```

That is competitive with a Bloom filter using ~14 bits per item.

---

## Reference implementation

```
pub struct CuckooFilter
pub fn new(m~ : Int, b~ : Int, seed~ : Int64) -> CuckooFilter
pub fn CuckooFilter::insert(self, key : Int64) -> Bool
pub fn CuckooFilter::contains(self, key : Int64) -> Bool
pub fn CuckooFilter::delete(self, key : Int64) -> Bool
pub fn CuckooFilter::count_of(self) -> Int
pub fn CuckooFilter::capacity(self) -> Int
```

---

## Tests and examples

```mbt check
///|
test "cuckoo filter no false negatives" {
  let cf = @cuckoo_filter.new(m=512, b=4, seed=11L)
  for x in 0L..<300L {
    cf.insert(x) |> ignore
  }
  for x in 0L..<300L {
    debug_inspect(cf.contains(x), content="true")
  }
}
```

```mbt check
///|
test "cuckoo filter deletes" {
  let cf = @cuckoo_filter.new(m=128, b=4, seed=3L)
  cf.insert(7L) |> ignore
  debug_inspect(cf.contains(7L), content="true")
  cf.delete(7L) |> ignore
  debug_inspect(cf.contains(7L), content="false")
}
```

```mbt check
///|
test "cuckoo filter capacity and count" {
  let cf = @cuckoo_filter.new(m=64, b=4, seed=1L)
  debug_inspect(cf.capacity(), content="256")
  for x in 0L..<10L {
    cf.insert(x) |> ignore
  }
  debug_inspect(cf.count_of(), content="10")
}
```

---

## Complexity

| Operation | Time | Notes |
|---|---|---|
| `insert(x)` | O(1) amortised | Up to `max_kicks` (500) evictions in worst case |
| `contains(x)` | O(b) | Always two buckets, constant work |
| `delete(x)` | O(b) | Always two buckets, constant work |
| `space` | `b · m · f` bits | `f = 16` in this package |

---

## Tuning

- **Load factor**: aim for under 95% to keep eviction chains short. If
  inserts start failing, double `m`.
- **`b = 4`**: the sweet spot for fingerprint width vs. bucket count
  (Fan et al. recommend this).
- **`f = 16`**: this package's choice. For lower memory at higher FP,
  swap to an 8-bit fingerprint and reduce `b` to 2.

---

## When to pick Cuckoo over Bloom

| Concern | Bloom filter | Cuckoo filter |
|---|---|---|
| Insert | O(k) hashes | O(1) (amortised) |
| Delete | needs counting variant | native |
| FPR at fixed bits/item | better above ~3% | better below ~3% |
| Worst-case behaviour | always succeeds | insert can fail at high load |

If your workload has lots of deletes or needs tiny FPR per bit, prefer
Cuckoo. If you need a fixed-size structure that always accepts inserts,
prefer Bloom.

---

## Related concepts

```
Cuckoo filter (this)         Fan et al. 2014, deletable approximate-set
Bloom filter                 deletion-free approximate set
Counting Bloom               Bloom + counters for delete; ~4x memory
Quotient filter              divides hash space by remainder
Cuckoo hashing               this filter's parent algorithm
XOR filter                   Graf-Lemire 2019, even smaller, no delete
```
