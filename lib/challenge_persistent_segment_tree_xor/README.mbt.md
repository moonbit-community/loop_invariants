# Challenge: Persistent Segment Tree (Xor)

This package explains and implements a **persistent segment tree** that supports
**point updates** and **range xor queries**.

The problem it solves is the following:

- You have an array of integers.
- You want to update one index at a time: `arr[idx] = value`.
- You want to query the xor of a range `[l, r)`.
- You want every update to create a new version, while old versions remain
  usable (persistence).

If you ever need a history of updates, branching states, or time travel queries,
this is the right tool.

---

## Core idea

A segment tree stores information about array segments. For xor queries, each
node stores the **xor of its segment**.

Because xor is associative:

```
(a ^ b) ^ c == a ^ (b ^ c)
```

we can combine left and right children by xor-ing their values.

Since the tree is **persistent**, we never mutate existing nodes. Every update
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

Each node stores `xor` for its segment.

---

## How persistence works (path copying)

Only the nodes on the update path are copied. The rest are shared:

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     update idx     B'  C
  / \                      / \
 D   E                    D   E
```

`A'` and `B'` are new nodes; `C`, `D`, `E` are reused from the old version.

This gives persistence with only `O(log n)` new nodes per update.

---

## API summary

The package exports the following functions:

- `build(arr, l, r)`
- `set_value(node, l, r, idx, value)`
- `range_xor(node, l, r, ql, qr)`
- `apply_updates(root, n, updates)`
- `xor_value(node)`

---

## Example 1: Two updates, different versions

We create a tree, update two indices, and compare range xors on the original
and updated versions.

```mbt check
///|
test "xor basic" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_xor.build(arr, 0, arr.length())

  // Version 1: set index 2 to 1
  let v1 = @challenge_persistent_segment_tree_xor.set_value(
    root,
    0,
    arr.length(),
    2,
    1,
  )

  // Version 2: set index 0 to 6
  let v2 = @challenge_persistent_segment_tree_xor.set_value(
    v1,
    0,
    arr.length(),
    0,
    6,
  )

  // Original xor stays the same.
  inspect(
    @challenge_persistent_segment_tree_xor.range_xor(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="4",
  )

  // After updates, xor changes.
  inspect(
    @challenge_persistent_segment_tree_xor.range_xor(v2, 0, arr.length(), 0, 4),
    content="1",
  )
}
```

### What happened to the array?

Original:

```
index: 0  1  2  3
value: 5  2  7  4
xor:   5 ^ 2 ^ 7 ^ 4 = 4
```

After setting index 2 to 1:

```
value: 5  2  1  4
xor:   5 ^ 2 ^ 1 ^ 4 = 2
```

After setting index 0 to 6:

```
value: 6  2  1  4
xor:   6 ^ 2 ^ 1 ^ 4 = 1
```

The original version remains unchanged, and we can query both histories.

---

## Example 2: Using apply_updates

`apply_updates` applies a list of `(idx, value)` updates to produce a new
version. Internally it uses a `fold`, so it is short and does not need
invariants.

```mbt check
///|
test "xor apply updates" {
  let arr = [1, 3, 2][:]
  let root = @challenge_persistent_segment_tree_xor.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_xor.apply_updates(
    root,
    arr.length(),
    [(0, 7), (2, 5)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_xor.range_xor(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="0",
  )
  inspect(
    @challenge_persistent_segment_tree_xor.range_xor(
      updated,
      0,
      arr.length(),
      0,
      3,
    ),
    content="1",
  )
}
```

---

## Example 3: Reading the root xor

The root always contains the xor of the entire array. That is what `xor_value`
returns.

```mbt check
///|
test "xor root" {
  let arr = [4, 6, 1, 2][:]
  let root = @challenge_persistent_segment_tree_xor.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_xor.set_value(
    root,
    0,
    arr.length(),
    1,
    3,
  )
  inspect(@challenge_persistent_segment_tree_xor.xor_value(root), content="1")
  inspect(
    @challenge_persistent_segment_tree_xor.xor_value(updated),
    content="4",
  )
}
```

---

## Complexity

Let `n` be the array length.

- Build: `O(n)`
- Point update: `O(log n)` time, `O(log n)` new nodes
- Range xor query: `O(log n)` time
- Memory after `k` updates: `O(n + k log n)`

---

## When to use this structure

Use this package when you need:

- history (old versions must stay valid)
- fast point updates
- fast range xor queries
- non-destructive edits (functional style)

If you do not need historical versions, a normal segment tree is simpler.

---

## Reference implementation

```mbt
///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn set_value(

///|   node : Node,

///|   l : Int,

///|   r : Int,

///|   idx : Int,

///|   value : Int,

///| ) -> Node

///| pub fn range_xor(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(

///|   root : Node,

///|   n : Int,

///|   updates : ArrayView[(Int, Int)],

///| ) -> Node

///| pub fn xor_value(node : Node) -> Int
```
