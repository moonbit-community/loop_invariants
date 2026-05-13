# Challenge: Persistent Segment Tree (Range Add Min)

This package explains and implements a **persistent segment tree** that supports
**range add updates** and **range minimum queries**.

The problem it solves is the following:

- You have an array of numbers.
- You want to add `delta` to every element in a range `[l, r)`.
- You want to ask for the minimum value in a range `[l, r)`.
- You want every update to create a new version, while old versions are still
  usable (persistence).

Think of it as a "versioned array" with fast range updates and fast queries.

---

## Core idea

A segment tree stores information about array segments. For minimum queries,
**each node stores the minimum value inside its segment**. For range-add
updates, we also store a **lazy tag** at each node:

- `min` is the minimum value **after all applied updates** on that segment.
- `tag` is a pending add that has been applied to the node's `min`, but not yet
  pushed down to its children.

Because the tree is persistent, we never mutate existing nodes. Every update
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

Each node stores `min` and `tag` for its segment.

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

- `node.min` decreases or increases by `delta`
- `node.tag` increases by `delta`
- we do **not** touch children yet

Later, if a query or update needs to go into the children, we "push" the tag by
creating new children with the tag applied. Because this is persistent, the
original children remain unchanged.

A small tag diagram looks like this:

```
Node [0,4) with tag = -2
min = 5

Children (not yet updated):
[0,2) min = 6
[2,4) min = 7

If we push the tag:
[0,2) min = 4
[2,4) min = 5
```

The parent always keeps the correct `min` for its segment.

---

## API summary

The package exports the following functions:

- `build(arr, l, r)`
- `range_add(node, l, r, ql, qr, delta)`
- `range_min(node, l, r, ql, qr)`
- `apply_updates(root, n, updates)`
- `min_value(node)`

---

## Example 1: Two updates, different versions

We create a tree, apply two range adds, and then compare range minima on the
original and updated versions.

```mbt check
///|
test "range add min basic" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_range_add_min.build(
    arr,
    0,
    arr.length(),
  )

  // Version 1: add -1 to [1,3)
  let v1 = @challenge_persistent_segment_tree_range_add_min.range_add(
    root,
    0,
    arr.length(),
    1,
    3,
    -1,
  )

  // Version 2: add +2 to [0,2)
  let v2 = @challenge_persistent_segment_tree_range_add_min.range_add(
    v1,
    0,
    arr.length(),
    0,
    2,
    2,
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="2",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      v2,
      0,
      arr.length(),
      0,
      4,
    ),
    content="3",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      v2,
      0,
      arr.length(),
      1,
      3,
    ),
    content="3",
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

The minimum changed from `2` to `3`, but the original version still exists.

---

## Example 2: Using apply_updates

`apply_updates` applies a list of `(l, r, delta)` updates to produce a new
version. Internally it uses a `fold`, so it is short and does not need
invariants.

```mbt check
///|
test "range add min apply updates" {
  let arr = [3, 5, 1][:]
  let root = @challenge_persistent_segment_tree_range_add_min.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_min.apply_updates(
    root,
    arr.length(),
    [(0, 2, 2), (2, 3, 3)],
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="1",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      updated,
      0,
      arr.length(),
      0,
      3,
    ),
    content="4",
  )
}
```

---

## Example 3: Reading the root min

The root always contains the minimum value of the entire array. That is what
`min_value` returns.

```mbt check
///|
test "range add min root" {
  let arr = [4, 6, 1, 2][:]
  let root = @challenge_persistent_segment_tree_range_add_min.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_min.range_add(
    root,
    0,
    arr.length(),
    2,
    4,
    5,
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.min_value(root),
    content="1",
  )
  debug_inspect(
    @challenge_persistent_segment_tree_range_add_min.min_value(updated),
    content="4",
  )
}
```

---

## Complexity

Let `n` be the array length.

- Build: `O(n)`
- Range add: `O(log n)` time, `O(log n)` new nodes
- Range min query: `O(log n)` time
- Memory after `k` updates: `O(n + k log n)`

---

## When to use this structure

Use this package when you need:

- history (old versions must stay valid)
- fast range add updates
- fast range min queries
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

///| pub fn range_min(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(

///|   root : Node,

///|   n : Int,

///|   updates : ArrayView[(Int, Int, Int)],

///| ) -> Node

///| pub fn min_value(node : Node) -> Int
```
