# Challenge: Persistent 2-3 Tree

A **persistent 2-3 tree** is a balanced search tree where every insertion
returns a **new version** of the tree, while older versions remain valid.

This package supports:

- `empty()` to create a tree
- `insert(tree, key)` to insert a key (persistent)
- `contains(tree, key)` to search
- `size(tree)` to count keys
- `from_array(arr)` to build by repeated inserts

The key type must implement `Compare`.

---

## What is a 2-3 tree?

A 2-3 tree is a balanced search tree with two kinds of internal nodes:

```
Two-node:   [k]            Three-node: [k1 | k2]
           /   \                     /   |   \
         L     R                   L    M    R
```

Rules:

- Keys in left subtree are `< k`.
- Keys in middle subtree are between `k1` and `k2`.
- Keys in right subtree are `> k2`.
- All leaves are at the **same depth** (perfectly balanced).

This guarantees `O(log n)` search and insertion.

---

## What does "persistent" mean?

When you insert a key, you **do not modify** the old tree.
Instead, you create a new tree that shares unchanged parts with the old one.
Only the path from the root to the modified leaf is copied.

```
Version T0:         Version T1 (after insert)

      A                      A'   (new)
     / \                    / \
    B   C      ==>         B'  C  (C is shared)
   / \                    / \
  D   E                  D   E   (D,E shared)
```

This is great for time-traveling or undo-style data structures.

---

## Insertion (high level)

Insertion returns one of two results:

- `Done(tree)` : the subtree was updated without overflow
- `Split(key, left, right)` : a node became too large and must be split

Splits can propagate upward. If the root splits, we create a new root:

```
Before split (a 3-node overflows):

    [k1 | k2 | k3]   (conceptually)

After split:

        [k2]
       /    \
    [k1]   [k3]
```

In the real implementation, we never store 4 keys in a node. Instead, the
split result is bubbled up to the parent immediately.

---

## Worked insertion example

Insert keys in this order: `1, 2, 3`

1) Insert 1:

```
[1]
```

2) Insert 2:

```
[1 | 2]
```

3) Insert 3:

The 3-node would overflow, so we split:

```
        [2]
       /   \
     [1]  [3]
```

Tree remains balanced, height increased by 1.

---

## Search (`contains`)

Search walks down the tree like a binary search, guided by node keys:

- Compare with `k` (or `k1`, `k2`) and choose left/middle/right.
- If you reach `Empty`, the key is not present.
- If you match a key, the key is present.

This is `O(log n)` because the tree is balanced.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Tree[T]

///| pub fn[T : Compare] insert(t : Tree[T], key : T) -> Tree[T]

///| pub fn[T : Compare] contains(t : Tree[T], key : T) -> Bool

///| pub fn[T] size(t : Tree[T]) -> Int

///| pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T]
```

---

## Tests and examples

### Persistence example

```mbt check
///|
test "persistent versions" {
  let t0 = @challenge_persistent_23_tree.empty()
  let t1 = @challenge_persistent_23_tree.insert(t0, 5)
  let t2 = @challenge_persistent_23_tree.insert(t1, 2)
  let t3 = @challenge_persistent_23_tree.insert(t2, 8)
  debug_inspect(@challenge_persistent_23_tree.contains(t0, 5), content="false")
  debug_inspect(@challenge_persistent_23_tree.contains(t1, 5), content="true")
  debug_inspect(@challenge_persistent_23_tree.contains(t2, 2), content="true")
  debug_inspect(@challenge_persistent_23_tree.contains(t3, 8), content="true")
  debug_inspect(@challenge_persistent_23_tree.size(t3), content="3")
}
```

### Build from array

```mbt check
///|
test "persistent 2-3 tree from array" {
  let t = @challenge_persistent_23_tree.from_array([7, 1, 5])
  debug_inspect(@challenge_persistent_23_tree.contains(t, 1), content="true")
  debug_inspect(@challenge_persistent_23_tree.contains(t, 9), content="false")
  debug_inspect(@challenge_persistent_23_tree.size(t), content="3")
}
```

### Duplicates are ignored

```mbt check
///|
test "persistent duplicates" {
  let t0 = @challenge_persistent_23_tree.empty()
  let t1 = @challenge_persistent_23_tree.insert(t0, 4)
  let t2 = @challenge_persistent_23_tree.insert(t1, 4)
  debug_inspect(@challenge_persistent_23_tree.size(t1), content="1")
  debug_inspect(@challenge_persistent_23_tree.size(t2), content="1")
}
```

---

## Complexity

For `n` keys:

- Search: `O(log n)`
- Insert: `O(log n)` time, `O(log n)` extra memory (path copying)
- Size: `O(n)` for each call (it walks the tree)

---

## Takeaways

- 2-3 trees stay perfectly balanced and guarantee `O(log n)` operations.
- Persistence means **old versions remain usable** after insertions.
- Only the path to the updated leaf is copied, so memory overhead is small.
