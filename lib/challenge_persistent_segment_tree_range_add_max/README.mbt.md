# Challenge: Persistent Segment Tree (Range Add Max)

This package explains and implements a **persistent segment tree** that supports
**range add updates** and **range maximum queries**.

The problem it solves is the following:

- You have an array of numbers.
- You want to add `delta` to every element in a range `[l, r)`.
- You want to ask for the maximum value in a range `[l, r)`.
- You want every update to create a new version, while old versions are still
  usable (persistence).

This is a common pattern when you need history, branching, or rollback. Think
of it as "versioned arrays with fast range updates and fast queries".

---

## Core idea

A segment tree stores information about array segments. For max queries, each
node stores the **maximum value** inside its segment. For range-add updates, we
also store a **lazy tag** at each node:

- `max` is the maximum value **after all applied updates** on that segment.
- `tag` is a pending add that has been applied to the node's `max`, but not yet
  pushed down to its children.

Because this tree is persistent, we never mutate existing nodes. Every update
creates new nodes on the path we touch, and reuses all other nodes.

---

## Small picture of the tree

For an array of length 8, the segment tree splits the range `[0,8)`:

```
[0,8)
  /     \
[0,4)  [4,8)
 /  \     /  \
[0,2)[2,4)[4,6)[6,8)
```

Each node stores `max` and `tag` for its segment.

---

## How persistence works (path copying)

Only the nodes on the update path are copied. The rest are shared:

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     update range   B'  C
  / \                      / \
 D   E                    D   E
```

Here, `A'` and `B'` are new nodes, while `C`, `D`, `E` are reused from the
previous version.

This gives persistence with only `O(log n)` new nodes per update.

---

## Lazy tag intuition

Suppose a node covers `[l, r)`. If we add `delta` to the entire range, then:

- `node.max` increases by `delta`
- `node.tag` increases by `delta`
- we do **not** touch children yet

Later, if a query or update needs to go into the children, we "push" the tag by
creating new children with the tag applied. Because this is persistent, the
original children remain unchanged.

A small tag diagram looks like this:

```
Node [0,4) with tag = +3
max = 10

Children (not yet updated):
[0,2) max = 7
[2,4) max = 9

If we push the tag:
[0,2) max = 10
[2,4) max = 12
```

The parent always keeps the correct `max` for its segment.

---

## API summary

The package exports the following functions:

- `build(arr, l, r)`
- `range_add(node, l, r, ql, qr, delta)`
- `range_max(node, l, r, ql, qr)`
- `apply_updates(root, n, updates)`
- `max_value(node)`

---

## Example 1: Two updates, different versions

We create a tree, apply two range adds, and then compare max queries on the
original and updated versions.

```mbt check
///|
test "range add max basic" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_range_add_max.build(
    arr,
    0,
    arr.length(),
  )

  // Version 1: add -1 to [1,3)
  let v1 = @challenge_persistent_segment_tree_range_add_max.range_add(
    root,
    0,
    arr.length(),
    1,
    3,
    -1,
  )

  // Version 2: add +2 to [0,2)
  let v2 = @challenge_persistent_segment_tree_range_add_max.range_add(
    v1,
    0,
    arr.length(),
    0,
    2,
    2,
  )

  // Max in the original version stays the same.
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="7",
  )

  // After both updates, the max is still 7, but in a different place.
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      v2,
      0,
      arr.length(),
      0,
      4,
    ),
    content="7",
  )

  // A smaller range shows the updated values.
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      v2,
      0,
      arr.length(),
      1,
      3,
    ),
    content="6",
  )
}
```

### What happened to the array?

Original:

```
index: 0  1  2  3
value: 5  2  7  4
```

After add -1 on [1,3):

```
value: 5  1  6  4
```

After add +2 on [0,2):

```
value: 7  3  6  4
```

The maximum is still 7, but the structure keeps every historical version.

---

## Example 2: Using apply_updates

`apply_updates` applies a list of `(l, r, delta)` updates to produce a new
version. Internally it uses a `fold`, so it is short and does not need
invariants.

```mbt check
///|
test "range add max apply updates" {
  let arr = [1, 3, 2][:]
  let root = @challenge_persistent_segment_tree_range_add_max.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_max.apply_updates(
    root,
    arr.length(),
    [(0, 3, 4)],
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="3",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      updated,
      0,
      arr.length(),
      0,
      3,
    ),
    content="7",
  )
}
```

---

## Example 3: Reading the root max

The root always contains the maximum value of the entire array. That is what
`max_value` returns.

```mbt check
///|
test "range add max root" {
  let arr = [4, 6, 1, 2][:]
  let root = @challenge_persistent_segment_tree_range_add_max.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_max.range_add(
    root,
    0,
    arr.length(),
    2,
    4,
    5,
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.max_value(root),
    content="6",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.max_value(updated),
    content="7",
  )
}
```

---

## Complexity

Let `n` be the array length.

- Build: `O(n)`
- Range add: `O(log n)` time, `O(log n)` new nodes
- Range max query: `O(log n)` time
- Memory after `k` updates: `O(n + k log n)`

This is optimal for persistent range updates with max queries.

---

## When to use this structure

Use this package when you need:

- history (old versions must stay valid)
- fast range add updates
- fast range max queries
- non-destructive edits (functional style)

If you do not need historical versions, a normal lazy segment tree is simpler.

---

## Reference implementation

```mbt nocheck
///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn range_add(

///|   node : Node,

///|   l : Int,

///|   r : Int,

///|   ql : Int,

///|   qr : Int,

///|   delta : Int,

///| ) -> Node

///| pub fn range_max(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(

///|   root : Node,

///|   n : Int,

///|   updates : ArrayView[(Int, Int, Int)],

///| ) -> Node

///| pub fn max_value(node : Node) -> Int
```
