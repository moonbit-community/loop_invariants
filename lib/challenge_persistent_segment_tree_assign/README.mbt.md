# Challenge: Persistent Segment Tree (Range Assign)

This structure supports **range assignment** and **range sum** queries, while
being **persistent**: every update returns a new tree and old versions remain
valid.

It uses lazy tags to represent full-range assignments without touching every
leaf, and path copying to preserve persistence.

This package provides:

- `build(arr, l, r)` to build from an array
- `range_assign(node, l, r, ql, qr, value)` to assign on `[ql, qr)`
- `range_sum(node, l, r, ql, qr)` to query sum on `[ql, qr)`
- `apply_updates(root, n, updates)` to apply many assignments
- `total(node)` to read total sum

---

## Lazy assignment tags

Each node stores:

- `sum`: sum of its range
- `tag`: optional assigned value for the entire range

If `tag = Some(v)`, then every element in the range equals `v`, and the sum is
`v * length`.

When we need to go deeper (partial overlap), we **push** the tag to children by
rebuilding them with the assigned value.

---

## Persistence (path copying)

Updates only copy nodes on the path that changes, and reuse the rest.
Old versions are still usable.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     assign         B'  C
  / \                      / \
 D   E                    D   E
```

---

## Range assignment

To assign value `v` over `[ql, qr)`:

- If node range is outside -> return node
- If node range fully inside -> replace with tagged node
- Otherwise -> push tag, recurse into children, rebuild node

This is `O(log n)` per update.

---

## Reference implementation

```mbt
///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn range_assign(node : Node, l : Int, r : Int, ql : Int, qr : Int, value : Int) -> Node

///| pub fn range_sum(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int, Int)]) -> Node

///| pub fn total(node : Node) -> Int
```

---

## Tests and examples

### Basic assignments

```mbt check
///|
test "segment tree assign basic" {
  let arr = [1, 2, 3, 4][:]
  let root = @challenge_persistent_segment_tree_assign.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_assign.apply_updates(
    root,
    arr.length(),
    [(1, 3, 5), (0, 2, 0)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="10",
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="9",
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      updated,
      0,
      arr.length(),
      1,
      3,
    ),
    content="5",
  )
}
```

### Overlapping assignments

```mbt check
///|
test "segment tree assign overlap" {
  let arr = [2, 2, 2, 2][:]
  let root = @challenge_persistent_segment_tree_assign.build(
    arr,
    0,
    arr.length(),
  )
  let t1 = @challenge_persistent_segment_tree_assign.range_assign(
    root,
    0,
    arr.length(),
    1,
    4,
    3,
  )
  let t2 = @challenge_persistent_segment_tree_assign.range_assign(
    t1,
    0,
    arr.length(),
    2,
    3,
    10,
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      t2,
      0,
      arr.length(),
      0,
      4,
    ),
    content="18",
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      t2,
      0,
      arr.length(),
      2,
      3,
    ),
    content="10",
  )
}
```

### Persistence across versions

```mbt check
///|
test "segment tree assign persistence" {
  let arr = [1, 1, 1][:]
  let root = @challenge_persistent_segment_tree_assign.build(
    arr,
    0,
    arr.length(),
  )
  let t1 = @challenge_persistent_segment_tree_assign.range_assign(
    root,
    0,
    arr.length(),
    0,
    2,
    5,
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="3",
  )
  inspect(
    @challenge_persistent_segment_tree_assign.range_sum(
      t1,
      0,
      arr.length(),
      0,
      3,
    ),
    content="11",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Range assign: `O(log n)` time, `O(log n)` extra memory
- Range sum: `O(log n)`
- Build: `O(n)`

---

## Takeaways

- Lazy tags make range assignment efficient.
- Persistence keeps every historical version.
- Path copying only touches `O(log n)` nodes per update.
