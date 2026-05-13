# Challenge: Persistent AA Tree

An **AA tree** is a balanced binary search tree that behaves like a simplified
red-black tree. It stays balanced using only two local fixes: **skew** and
**split**. This implementation is **persistent**, so every insertion returns a
new version while old versions remain valid.

This package provides:

- `empty()` to create a tree
- `insert(tree, key)` to insert a key (persistent)
- `contains(tree, key)` to search
- `inorder(tree)` to list keys in sorted order
- `size(tree)` to count keys
- `from_array(arr)` to build by repeated insertions

---

## What is an AA tree?

Each node stores a **level** (like black height in red-black trees). The
structure is a BST with extra invariants:

1) The left child has **strictly smaller** level.
2) The right child has level **<=** the node.
3) The right-right grandchild has **strictly smaller** level.

These rules guarantee balance, giving `O(log n)` operations.

Node shape:

```
   (key, level)
     /     \
 left     right
```

---

## The two rebalancing operations

### 1) Skew: remove left horizontal links

If a left child has the **same level** as its parent, rotate right:

Before:

```
      (k, lv)
      /     \
 (lk, lv)   R
   /   \
  L    M
```

After skew:

```
     (lk, lv)
     /     \
    L     (k, lv)
          /   \
         M     R
```

### 2) Split: remove consecutive right links

If a right-right grandchild has the **same level** as the node, rotate left and
increase the middle level:

Before:

```
 (k, lv)
   \
  (rk, lv)
     \
    (rrk, lv)
```

After split:

```
     (rk, lv+1)
     /       \
 (k, lv)   (rrk, lv)
```

These two local fixes are enough to maintain balance.

---

## Persistence (path copying)

Insertion does not mutate old nodes. It **rebuilds the path** from the root to
where the key is inserted, and reuses all other nodes.

```
Old version:          New version:

     A                     A'
    / \                   / \
   B   C    insert x     B'  C
  / \                   / \
 D   E                 D   E
```

Only the nodes on the path are copied (`A`, `B`). The rest (`C`, `D`, `E`) are
shared. This keeps extra memory per insert at `O(log n)`.

---

## Worked insertion example

Insert keys in order: `3, 2, 1`

Start:

```
Empty
```

Insert 3:

```
(3,1)
```

Insert 2 (go left, then skew):

```
Before skew:
    (3,1)
    /
 (2,1)

After skew:
   (2,1)
     \
     (3,1)
```

Insert 1 (go left, then skew at root):

```
Before skew:
    (2,1)
    /
 (1,1)
   \
  (3,1)

After skew:
   (1,1)
     \
     (2,1)
       \
      (3,1)
```

Now there is a right-right chain at level 1, so we split:

```
After split:
     (2,2)
     /   \
 (1,1) (3,1)
```

Tree remains balanced.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Aa[T]

///| pub fn[T : Compare] insert(t : Aa[T], key : T) -> Aa[T]

///| pub fn[T : Compare] contains(t : Aa[T], key : T) -> Bool

///| pub fn[T] inorder(t : Aa[T]) -> Array[T]

///| pub fn[T] size(t : Aa[T]) -> Int

///| pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Aa[T]
```

---

## Tests and examples

### Persistence across versions

```mbt check
///|
test "aa tree persistent versions" {
  let t0 = @challenge_persistent_aa_tree.empty()
  let t1 = @challenge_persistent_aa_tree.insert(t0, 5)
  let t2 = @challenge_persistent_aa_tree.insert(t1, 2)
  let t3 = @challenge_persistent_aa_tree.insert(t2, 8)
  debug_inspect(@challenge_persistent_aa_tree.contains(t0, 5), content="false")
  debug_inspect(@challenge_persistent_aa_tree.contains(t1, 5), content="true")
  debug_inspect(@challenge_persistent_aa_tree.contains(t2, 2), content="true")
  debug_inspect(@challenge_persistent_aa_tree.contains(t3, 8), content="true")
  debug_inspect(@challenge_persistent_aa_tree.size(t3), content="3")
}
```

### Build from array

```mbt check
///|
test "aa tree from array" {
  let t = @challenge_persistent_aa_tree.from_array([7, 1, 5])
  debug_inspect(@challenge_persistent_aa_tree.contains(t, 1), content="true")
  debug_inspect(@challenge_persistent_aa_tree.contains(t, 9), content="false")
  debug_inspect(@challenge_persistent_aa_tree.inorder(t), content="[1, 5, 7]")
}
```

### Duplicates are ignored

```mbt check
///|
test "aa tree duplicates" {
  let t0 = @challenge_persistent_aa_tree.empty()
  let t1 = @challenge_persistent_aa_tree.insert(t0, 4)
  let t2 = @challenge_persistent_aa_tree.insert(t1, 4)
  debug_inspect(@challenge_persistent_aa_tree.size(t1), content="1")
  debug_inspect(@challenge_persistent_aa_tree.size(t2), content="1")
}
```

---

## Complexity

For `n` keys:

- Search: `O(log n)`
- Insert: `O(log n)` time, `O(log n)` extra memory (path copying)
- Size: `O(n)` per call (walks the tree)

---

## Takeaways

- AA trees are balanced BSTs with only two fixes: skew and split.
- Persistence makes old versions available after insertions.
- The structure is simple but still gives `O(log n)` operations.
