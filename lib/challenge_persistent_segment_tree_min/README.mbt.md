# Challenge: Persistent Segment Tree (Min)

This segment tree supports **range minimum queries** with **point updates** and
is **persistent**: each update returns a new tree, while old versions remain
valid.

This package provides:

- `build(arr, l, r)` to build from an array
- `set_value(node, l, r, idx, value)` to update one index (persistent)
- `range_min(node, l, r, ql, qr)` to query min in `[ql, qr)`
- `apply_updates(root, n, updates)` to apply many point updates
- `min_value(node)` to read root min

---

## Segment tree for minimum

Each node stores the minimum value in its range:

```
range [0,4)
          min
        /     \
     min       min
```

The parent min is the min of the two children.

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

///| pub fn range_min(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int)]) -> Node

///| pub fn min_value(node : Node) -> Int
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "segment tree min basic" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_min.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_min.apply_updates(
    root,
    arr.length(),
    [(2, 1), (0, 6)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_min.range_min(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="2",
  )
  inspect(
    @challenge_persistent_segment_tree_min.range_min(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="1",
  )
  inspect(
    @challenge_persistent_segment_tree_min.range_min(
      updated,
      0,
      arr.length(),
      1,
      3,
    ),
    content="1",
  )
}
```

### Single update

```mbt check
///|
test "segment tree min single" {
  let arr = [3, 8, 2][:]
  let root = @challenge_persistent_segment_tree_min.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_min.set_value(
    root,
    0,
    arr.length(),
    1,
    1,
  )
  inspect(
    @challenge_persistent_segment_tree_min.range_min(t1, 0, arr.length(), 0, 3),
    content="1",
  )
}
```

### Persistence across versions

```mbt check
///|
test "segment tree min persistence" {
  let arr = [4, 1, 6][:]
  let root = @challenge_persistent_segment_tree_min.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_min.set_value(
    root,
    0,
    arr.length(),
    2,
    0,
  )
  inspect(
    @challenge_persistent_segment_tree_min.range_min(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="1",
  )
  inspect(
    @challenge_persistent_segment_tree_min.range_min(t1, 0, arr.length(), 0, 3),
    content="0",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Build: `O(n)`
- Point update: `O(log n)` time, `O(log n)` extra memory
- Range min query: `O(log n)`

---

## Takeaways

- Segment trees can store any associative operation; here it's min.
- Persistence keeps every historical version.
- Updates only copy `O(log n)` nodes.
