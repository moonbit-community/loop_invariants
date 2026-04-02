# Challenge: Persistent Segment Tree (Max)

This segment tree supports **range maximum queries** with **point updates** and
is **persistent**: each update returns a new tree while old versions remain
valid.

This package provides:

- `build(arr, l, r)` to build from an array
- `set_value(node, l, r, idx, value)` to update one index (persistent)
- `range_max(node, l, r, ql, qr)` to query max in `[ql, qr)`
- `apply_updates(root, n, updates)` to apply many point updates
- `max_value(node)` to read root max

---

## Segment tree for maximum

Each node stores the maximum value in its range:

```
range [0,4)
          max
        /     \
     max       max
```

The parent max is the max of the two children.

---

## Persistence (path copying)

Updating one index copies only the nodes on the root-to-leaf path. The rest is
shared with previous versions.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     update idx     B'  C
  / \                      / \
 D   E                    D   E
```

---

## Reference implementation

```mbt nocheck
///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node

///| pub fn range_max(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int)]) -> Node

///| pub fn max_value(node : Node) -> Int
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "segment tree max basic" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_max.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_max.apply_updates(
    root,
    arr.length(),
    [(2, 1), (0, 6)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="7",
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="6",
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(
      updated,
      0,
      arr.length(),
      1,
      3,
    ),
    content="2",
  )
}
```

### Single update

```mbt check
///|
test "segment tree max single" {
  let arr = [1, 3, 2][:]
  let root = @challenge_persistent_segment_tree_max.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_max.set_value(
    root,
    0,
    arr.length(),
    2,
    10,
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(t1, 0, arr.length(), 0, 3),
    content="10",
  )
}
```

### Persistence across versions

```mbt check
///|
test "segment tree max persistence" {
  let arr = [4, 1, 6][:]
  let root = @challenge_persistent_segment_tree_max.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_max.set_value(
    root,
    0,
    arr.length(),
    0,
    2,
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="6",
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(t1, 0, arr.length(), 0, 3),
    content="6",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Build: `O(n)`
- Point update: `O(log n)` time, `O(log n)` extra memory
- Range max query: `O(log n)`

---

## Takeaways

- Segment trees can store any associative operation; here it's max.
- Persistence keeps every historical version.
- Updates only copy `O(log n)` nodes.
