# Challenge: Persistent Segment Tree (Lazy Range Add)

This structure supports **range add** and **range sum** queries with lazy
propagation, and is **persistent**: every update returns a new tree while old
versions remain valid.

This package provides:

- `build(arr, l, r)` to build from an array
- `range_add(node, l, r, ql, qr, delta)` to add on `[ql, qr)`
- `range_sum(node, l, r, ql, qr)` to query sum on `[ql, qr)`
- `apply_updates(root, n, updates)` to apply many updates
- `total(node)` to read root sum

---

## Lazy propagation idea

Each node stores:

- `sum`: total sum of its range
- `tag`: a lazy value to add to all elements in the range

If `tag` is non-zero, it means **all children should be considered as having
that extra value**, but we delay pushing it until we need to go deeper.

---

## Range add

To add `delta` on `[ql, qr)`:

- If node range is outside: return node
- If node range is fully inside: add `delta` to node.tag and update sum
- Otherwise: push tag to children, recurse, rebuild node

Persistence means each update creates new nodes along the path.

---

## Range sum

When querying `[ql, qr)`:

- Outside: contribute 0
- Fully inside: return node.sum
- Partial: push tag to children and combine results

---

## Reference implementation

```mbt nocheck
///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn range_add(node : Node, l : Int, r : Int, ql : Int, qr : Int, delta : Int) -> Node

///| pub fn range_sum(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int, Int)]) -> Node

///| pub fn total(node : Node) -> Int
```

---

## Tests and examples

### Basic updates

```mbt check
///|
test "segment tree lazy basic" {
  let arr = [1, 2, 3, 4][:]
  let root = @challenge_persistent_segment_tree_lazy.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_lazy.apply_updates(
    root,
    arr.length(),
    [(1, 3, 2), (0, 2, -1)],
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="10",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="12",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      updated,
      0,
      arr.length(),
      1,
      3,
    ),
    content="8",
  )
}
```

### Overlapping range adds

```mbt check
///|
test "segment tree lazy overlap" {
  let arr = [0, 0, 0, 0][:]
  let root = @challenge_persistent_segment_tree_lazy.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_lazy.range_add(
    root,
    0,
    arr.length(),
    0,
    3,
    5,
  )
  let t2 = @challenge_persistent_segment_tree_lazy.range_add(
    t1,
    0,
    arr.length(),
    2,
    4,
    2,
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(t2, 0, arr.length(), 0, 4),
    content="19",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(t2, 0, arr.length(), 2, 3),
    content="7",
  )
}
```

### Persistence across versions

```mbt check
///|
test "segment tree lazy persistence" {
  let arr = [1, 1, 1][:]
  let root = @challenge_persistent_segment_tree_lazy.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_lazy.range_add(
    root,
    0,
    arr.length(),
    0,
    2,
    3,
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="3",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(t1, 0, arr.length(), 0, 3),
    content="9",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Range add: `O(log n)` time, `O(log n)` extra memory
- Range sum: `O(log n)`
- Build: `O(n)`

---

## Takeaways

- Lazy tags allow fast range updates.
- Persistence keeps historical versions intact.
- Path copying updates only `O(log n)` nodes per operation.
