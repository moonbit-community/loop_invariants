# Challenge: Persistent Segment Tree (GCD)

This segment tree stores the **greatest common divisor (GCD)** over ranges and
supports point updates. It is **persistent**, so every update returns a new
root while old versions remain valid.

This package provides:

- `build(arr, l, r)` to build a tree from an array
- `set_value(node, l, r, idx, value)` to update one index (persistent)
- `range_gcd(node, l, r, ql, qr)` to query GCD on `[ql, qr)`
- `apply_updates(root, n, updates)` to apply many point updates
- `gcd(a, b)` the gcd function used internally

---

## GCD recap

The GCD of two numbers is computed by Euclid's algorithm:

```
gcd(a, b) = gcd(b, a mod b)
```

This is fast and handles negative inputs by taking absolute values first.

---

## Segment tree for GCD

Each node stores the gcd of its range:

```
range [0,4)
         gcd
       /     \
   gcd        gcd
```

The gcd of a parent is the gcd of its two children.

---

## Persistence (path copying)

When you update an index, only nodes on the path are copied. Other nodes are
shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     update idx     B'  C
  / \                      / \
 D   E                    D   E
```

---

## Querying range gcd

The range query follows the usual segment tree pattern:

- If node range is outside: return 0 (neutral for gcd)
- If node range is fully inside: return node.gcd
- Otherwise: gcd(left_result, right_result)

---

## Reference implementation

```mbt
///| pub fn gcd(a : Int, b : Int) -> Int

///| pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node

///| pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node

///| pub fn range_gcd(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int

///| pub fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int)]) -> Node
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "segment tree gcd basic" {
  let arr = [6, 10, 15, 25][:]
  let root = @challenge_persistent_segment_tree_gcd.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_gcd.apply_updates(
    root,
    arr.length(),
    [(2, 5), (0, 9)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="1",
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="1",
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(
      updated,
      0,
      arr.length(),
      0,
      2,
    ),
    content="1",
  )
}
```

### Single update

```mbt check
///|
test "segment tree gcd single" {
  let arr = [12, 18, 24][:]
  let root = @challenge_persistent_segment_tree_gcd.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_gcd.set_value(
    root,
    0,
    arr.length(),
    1,
    6,
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="6",
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(t1, 0, arr.length(), 0, 3),
    content="6",
  )
}
```

### Persistence across versions

```mbt check
///|
test "segment tree gcd persistence" {
  let arr = [4, 8, 16][:]
  let root = @challenge_persistent_segment_tree_gcd.build(arr, 0, arr.length())
  let t1 = @challenge_persistent_segment_tree_gcd.set_value(
    root,
    0,
    arr.length(),
    0,
    6,
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="4",
  )
  inspect(
    @challenge_persistent_segment_tree_gcd.range_gcd(t1, 0, arr.length(), 0, 3),
    content="2",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Build: `O(n)`
- Point update: `O(log n)` time, `O(log n)` extra memory
- Range query: `O(log n)`

---

## Takeaways

- GCD queries use a segment tree with gcd as the merge operation.
- Persistence keeps every version after updates.
- Path copying ensures updates are efficient and share structure.
