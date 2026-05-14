# Cuckoo Hashing

## Overview

A hash set with **guaranteed worst-case O(1) lookup** — not just
expected. Each key lives in one of two possible slots; lookup checks
both and returns. The cost is shifted into insertion: when both
candidate slots are occupied, items are "kicked" along chains of
alternate slots until either an empty slot is found or a cycle bound
is hit.

- **Time**: O(1) worst-case `contains`; O(1) amortised `insert` at load < 0.5
- **Space**: O(m) per table (two tables, total `2 · m` slots)
- **Signatures**:
  - `new(m~, seed~) -> CuckooHash`
  - `s.insert(key) -> Bool`
  - `s.contains(key) -> Bool`
  - `s.count_of() -> Int`
  - `s.capacity() -> Int`
  - `s.load_factor() -> Double`

Cuckoo hashing (Pagh-Rodler 2001) is the canonical answer to
"chained hash tables have great average performance but terrible tail
latency." Two-slot lookup is bounded **deterministically**.

---

## The structure

Two tables `T_1, T_2` of size `m`, two hash functions `h_1, h_2`. The
invariant maintained:

```
For every key in the set:
  EITHER  T_1[h_1(key)] == key
  OR      T_2[h_2(key)] == key
```

So **`contains(key)`** just checks both slots: at most two memory
accesses, branch-predictable. Done.

---

## The eviction chain

`insert(key)`:

```
current = key
direction = T_1
for kick in 0..<max_kicks:
  b = bucket of `current` in direction
  if direction[b] is empty:
    direction[b] = current
    return success
  swap: temp = direction[b]; direction[b] = current; current = temp
  flip direction (T_1 ↔ T_2)
return failure  -- rebuild with new seeds
```

The key trick: each iteration **places** one item and **displaces**
another, but the displaced item's *alternate* slot is in the other
table — so the chain bounces between tables. After at most `max_kicks
≈ 6 · log m` bounces, either every step has placed an item (success)
or a cycle has formed (failure: rebuild).

The chain forms a graph in the so-called "cuckoo graph" with one
vertex per item and one edge per insert; the analysis of Pagh-Rodler
shows that, with load factor < 0.5, this graph is a forest with high
probability and the chain terminates in O(log m) expected steps.

---

## The load-factor bound

```
load factor = n / (2 · m)
```

- **load < 0.5**: insertion succeeds in O(log m) expected steps,
  with the failure probability of `O(1/m)`.
- **load → 0.5**: expected insertion time grows quickly; you should
  rebuild with a bigger table.
- **load > 0.5**: insertion failures become routine; basic
  two-table cuckoo hashing tops out here. Variants
  (d-ary cuckoo hashing, blocked cuckoo, etc.) push this further.

This package does *not* auto-rebuild on failure; `insert` returns
`false` and the caller can decide whether to grow the table or pick
a different seed.

---

## Reference implementation

```
pub struct CuckooHash
pub fn new(m~ : Int, seed~ : Int64) -> CuckooHash
pub fn CuckooHash::insert(self, key : Int64) -> Bool
pub fn CuckooHash::contains(self, key : Int64) -> Bool
pub fn CuckooHash::count_of(self) -> Int
pub fn CuckooHash::capacity(self) -> Int
pub fn CuckooHash::load_factor(self) -> Double
```

---

## Tests and examples

```mbt check
///|
test "cuckoo round-trip" {
  let s = @cuckoo_hashing.new(m=128, seed=1L)
  for x in 0L..<60L {
    s.insert(x) |> ignore
  }
  debug_inspect(s.contains(42L), content="true")
  debug_inspect(s.contains(999L), content="false")
}
```

```mbt check
///|
test "cuckoo duplicate insert" {
  let s = @cuckoo_hashing.new(m=64, seed=42L)
  s.insert(42L) |> ignore
  s.insert(42L) |> ignore
  debug_inspect(s.count_of(), content="1")
}
```

```mbt check
///|
test "cuckoo negative keys" {
  let s = @cuckoo_hashing.new(m=64, seed=1L)
  for x in -30L..<30L {
    s.insert(x) |> ignore
  }
  debug_inspect(s.contains(-15L), content="true")
}
```

```mbt check
///|
test "cuckoo load monotonic" {
  let s = @cuckoo_hashing.new(m=128, seed=7L)
  s.insert(1L) |> ignore
  let l1 = s.load_factor()
  s.insert(2L) |> ignore
  debug_inspect(s.load_factor() > l1, content="true")
}
```

---

## Complexity

| Operation       | Time worst case | Time expected | Space      |
|-----------------|-----------------|---------------|------------|
| `new(m, seed)`  | O(m)            | O(m)          | O(m)       |
| `contains(x)`   | **O(1)**        | O(1)          | O(1) extra |
| `insert(x)`     | O(log m)        | O(1) amort.   | O(1) extra |
| `count_of()`    | O(1)            | O(1)          | O(1)       |

The `contains` cost is deterministic: exactly two array accesses.
The `insert` cost is O(log m) worst case at load factor below 0.5,
because the eviction chain is bounded by `max_kicks`.

---

## When to reach for it

- **Tail-latency-critical lookups**. When `contains` must return in a
  fixed number of operations regardless of input — e.g. real-time
  network packet processing, switch lookups, JIT compiler symbol
  tables.
- **Read-heavy workloads**. Cuckoo hashing tolerates many readers
  cheaply; insertion is the expensive operation.
- **Building a perfect hash function** offline. After all keys are
  known, run cuckoo hashing offline (with rebuilds on failure) to
  find a valid placement.

For high-load-factor or insert-heavy workloads, prefer linear
probing or robin-hood hashing.

---

## Common pitfalls

- **Load factor `< 0.5`**. Don't push beyond ~45% load with two
  tables; rebuild or grow first.
- **Insertion may fail**. Always check the `Bool` return from
  `insert`. On failure, the table is unchanged; pick a new seed and
  re-insert, or grow the tables.
- **Hash family quality**. The analysis assumes pairwise independent
  hashes; this package uses MurmurHash3 with two distinct salts
  derived from the seed, which is enough in practice.
- **Same seed across sketches** is essential if you ever want to
  merge or compare two sets bit-for-bit.

---

## Related concepts

```
Cuckoo hashing (this)          guaranteed O(1) lookup, 2 hashes
d-ary cuckoo                   d > 2 tables; higher load factor
Blocked cuckoo                 each slot holds k > 1 items
Cuckoo filter                  approximate membership (replaces Bloom)
Robin-hood hashing             bounded probe distance, single table
Linear probing                 cheap, but worst-case unbounded
Perfect hashing                offline, zero collisions, O(n) memory
```
