# Challenge: Persistent Bitset

A **persistent bitset** stores a vector of bits (0/1), and every update returns
a new version while old versions remain usable.

This implementation uses a **path-copying segment tree** so updates and queries
are `O(log n)`.

This package provides:

- `make(n)` to build a length-`n` bitset of zeros
- `set(bs, idx, value)` to set a bit (persistent)
- `get(bs, idx)` to read a bit
- `count_range(bs, ql, qr)` to count ones in a range
- `from_indices(n, idxs)` to build by setting indices to 1
- `length(bs)` to read the size

---

## Important precondition

`make(n)` assumes **n > 0**. A zero-length bitset is not supported because the
internal tree has no empty-node variant.

---

## Core idea: segment tree with counts

Each node stores the count of ones in its range.

```
Range [0,4)

           (count)
           /     \
       [0,2)     [2,4)
       /   \      /   \
    [0,1) [1,2) [2,3) [3,4)
```

Leaf nodes store a single bit (0 or 1). Internal nodes store the sum of their
children's counts.

---

## Persistence (path copying)

When you update one index, you only copy the nodes along the path to that
leaf. Everything else is shared with the old version.

```
Old version:               New version:

    root                     root'
    /  \                     /   \
   A    B     set idx       A'    B
  / \                       / \
 C   D                     C   D
```

So each update costs `O(log n)` time and memory.

---

## Range count

To count ones in `[ql, qr)`, we walk the tree just like a segment tree query:

- If the node range is fully outside, contribute 0
- If fully inside, contribute node.count
- Otherwise, split into left and right children

---

## Reference implementation

```mbt nocheck
///| pub fn make(n : Int) -> Bitset

///| pub fn set(bs : Bitset, idx : Int, value : Int) -> Bitset

///| pub fn get(bs : Bitset, idx : Int) -> Int

///| pub fn count_range(bs : Bitset, ql : Int, qr : Int) -> Int

///| pub fn from_indices(n : Int, idxs : ArrayView[Int]) -> Bitset

///| pub fn length(bs : Bitset) -> Int
```

---

## Tests and examples

### Basic set/get

```mbt check
///|
test "persistent bitset basic" {
  let bs0 = @challenge_persistent_bitset.make(5)
  let bs1 = @challenge_persistent_bitset.set(bs0, 2, 1)
  let bs2 = @challenge_persistent_bitset.set(bs1, 4, 1)
  debug_inspect(@challenge_persistent_bitset.get(bs0, 2), content="0")
  debug_inspect(@challenge_persistent_bitset.get(bs1, 2), content="1")
  debug_inspect(@challenge_persistent_bitset.get(bs2, 4), content="1")
}
```

### Count in a range

```mbt check
///|
test "persistent bitset count range" {
  let bs = @challenge_persistent_bitset.from_indices(6, [1, 3, 4])
  debug_inspect(@challenge_persistent_bitset.count_range(bs, 0, 6), content="3")
  debug_inspect(@challenge_persistent_bitset.count_range(bs, 2, 5), content="2")
}
```

### Persistence across versions

```mbt check
///|
test "persistent bitset versions" {
  let bs0 = @challenge_persistent_bitset.make(4)
  let bs1 = @challenge_persistent_bitset.set(bs0, 0, 1)
  let bs2 = @challenge_persistent_bitset.set(bs1, 3, 1)
  debug_inspect(
    @challenge_persistent_bitset.count_range(bs0, 0, 4),
    content="0",
  )
  debug_inspect(
    @challenge_persistent_bitset.count_range(bs1, 0, 4),
    content="1",
  )
  debug_inspect(
    @challenge_persistent_bitset.count_range(bs2, 0, 4),
    content="2",
  )
}
```

### Out-of-range set/get

```mbt check
///|
test "persistent bitset bounds" {
  let bs = @challenge_persistent_bitset.make(3)
  let bs2 = @challenge_persistent_bitset.set(bs, 99, 1)
  debug_inspect(@challenge_persistent_bitset.get(bs2, -1), content="0")
  debug_inspect(@challenge_persistent_bitset.get(bs2, 3), content="0")
  debug_inspect(
    @challenge_persistent_bitset.count_range(bs2, 0, 3),
    content="0",
  )
}
```

---

## Complexity

Let `n = length`:

- `set` and `get`: `O(log n)`
- `count_range`: `O(log n)`
- `from_indices`: `O(k log n)` for `k` indices

---

## Takeaways

- A persistent bitset keeps every version after updates.
- Path copying only touches `O(log n)` nodes per update.
- The segment tree stores counts so range queries are fast.
