# Challenge: Persistent Segment Tree (Sum)

A **persistent segment tree** supports range sum queries and point updates while
keeping old versions intact. Each update returns a new root, sharing all
unchanged nodes with previous versions.

This package provides:

- `build(arr, l, r)` to build a tree over `arr[l..r)`
- `add(node, l, r, idx, delta)` to update one index (persistent)
- `query(node, l, r, ql, qr)` to query range sum
- `apply_updates(root, n, updates)` to apply many point updates
- `total(node)` to read the root sum

---

## Segment tree recap

A segment tree is a binary tree where each node covers a range `[l, r)` and
stores the sum of that range.

Example for `arr = [1, 2, 3, 4]`:

```
range [0,4) sum=10
          /      \
   [0,2) sum=3   [2,4) sum=7
     / \           / \
 [0,1)1 [1,2)2  [2,3)3 [3,4)4
```

---

## Persistence (path copying)

When you update one index, only the nodes on the path from the root to that
leaf are copied. The rest of the tree is shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     add at idx     B'  C
  / \                      / \
 D   E                    D   E
```

This is why each update costs `O(log n)` time and memory.

---

## Range sum query

To query sum in `[ql, qr)`:

- If node range is outside, contribute 0
- If node range is fully inside, contribute node.sum
- Otherwise, split into left and right children

This is `O(log n)`.

---

## Reference implementation

```mbt
///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn add(node : Node, l : Int, r : Int, idx : Int, delta : Int) -> Node

///| pub fn query(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int)]) -> Node

///| pub fn total(node : Node) -> Int
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "persistent segment tree" {
  let arr = [1, 2, 3, 4][:]
  let root = @challenge_persistent_segment_tree.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree.apply_updates(
    root,
    arr.length(),
    [(1, 3), (3, -1)][:],
  )
  inspect(
    @challenge_persistent_segment_tree.query(root, 0, arr.length(), 0, 4),
    content="10",
  )
  inspect(
    @challenge_persistent_segment_tree.query(updated, 0, arr.length(), 0, 4),
    content="12",
  )
  inspect(
    @challenge_persistent_segment_tree.query(updated, 0, arr.length(), 1, 3),
    content="8",
  )
}
```

### Persistence across versions

```mbt check
///|
test "segment tree persistence" {
  let arr = [5, 0, 2][:]
  let root = @challenge_persistent_segment_tree.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree.add(root, 0, arr.length(), 1, 4)
  inspect(
    @challenge_persistent_segment_tree.query(root, 0, arr.length(), 0, 3),
    content="7",
  )
  inspect(
    @challenge_persistent_segment_tree.query(t1, 0, arr.length(), 0, 3),
    content="11",
  )
}
```

### Single-element update

```mbt check
///|
test "segment tree single" {
  let arr = [1, 1, 1][:]
  let root = @challenge_persistent_segment_tree.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree.add(root, 0, arr.length(), 2, 5)
  inspect(
    @challenge_persistent_segment_tree.query(t1, 0, arr.length(), 2, 3),
    content="6",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Build: `O(n)`
- Point update: `O(log n)` time, `O(log n)` extra memory
- Range sum query: `O(log n)`

---

## Takeaways

- Segment trees give fast range sums with point updates.
- Persistence keeps every historical version of the array.
- Path copying ensures updates are efficient and share structure.
