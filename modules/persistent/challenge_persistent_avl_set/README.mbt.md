# Challenge: Persistent AVL Set

An **AVL tree** is a balanced binary search tree that keeps heights within 1.
This implementation is **persistent**, so every insertion returns a new version
and old versions remain valid and reusable.

This package provides:

- `empty()` to create a tree
- `insert(tree, key)` to insert a key (persistent)
- `contains(tree, key)` to search
- `inorder(tree)` to list keys in sorted order
- `size(tree)` to count keys
- `from_array(arr)` to build by repeated inserts

---

## What is an AVL tree?

A binary search tree (BST) keeps keys in order:

- Left subtree keys are smaller
- Right subtree keys are larger

An AVL tree adds a balance rule:

```
|height(left) - height(right)| <= 1
```

This keeps the tree height at `O(log n)` and guarantees fast operations.

---

## Rotations (the balancing tools)

When insertion makes a node too unbalanced, we fix it using rotations.

### Right rotation (left-heavy)

```
Before:                 After:

      z                     y
     / \                   / \
    y   T4   rotate        x   z
   / \       right        / \ / \
  x   T3               T1 T2 T3 T4
 / \
T1 T2
```

### Left rotation (right-heavy)

```
Before:                 After:

  z                        y
 / \                      / \
T1  y       rotate       z   x
   / \     left          / \ / \
  T2  x                T1 T2 T3 T4
     / \
    T3 T4
```

### Double rotations

If the heavy side is "zig-zag", we rotate twice:

- Left-right case: rotate left on left child, then right on parent
- Right-left case: rotate right on right child, then left on parent

The `balance` function in the implementation chooses the right case by
comparing subtree heights.

---

## Persistence (path copying)

Persistent data structures do not mutate old versions. Instead, insertion
creates a **new path** from the root to the updated leaf, and reuses everything
else.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert key     B'  C
  / \                      / \
 D   E                    D   E
```

Only nodes on the path are copied. This costs `O(log n)` extra memory per
insert, which is small.

---

## Worked insertion example

Insert `3, 2, 1` into an AVL tree.

1) Insert 3:

```
(3)
```

2) Insert 2:

```
  (3)
  /
(2)
```

3) Insert 1 (left-left case, needs right rotation):

```
Before rotation:
    (3)
    /
  (2)
  /
(1)

After right rotation:
    (2)
   /   \
 (1)   (3)
```

Now the tree is balanced.

---

## Search

`contains` walks down the tree like a normal BST search:

- If key matches current node, return true
- If key is smaller, go left
- If key is larger, go right

The AVL balance keeps this in `O(log n)` time.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Avl[T]

///| pub fn[T : Compare] insert(t : Avl[T], key : T) -> Avl[T]

///| pub fn[T : Compare] contains(t : Avl[T], key : T) -> Bool

///| pub fn[T] inorder(t : Avl[T]) -> Array[T]

///| pub fn[T] size(t : Avl[T]) -> Int

///| pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Avl[T]
```

---

## Tests and examples

### Persistence across versions

```mbt check
///|
test "persistent avl versions" {
  let t0 = @challenge_persistent_avl_set.empty()
  let t1 = @challenge_persistent_avl_set.insert(t0, 5)
  let t2 = @challenge_persistent_avl_set.insert(t1, 2)
  let t3 = @challenge_persistent_avl_set.insert(t2, 8)
  inspect(@challenge_persistent_avl_set.contains(t0, 5), content="false")
  inspect(@challenge_persistent_avl_set.contains(t1, 5), content="true")
  inspect(@challenge_persistent_avl_set.contains(t2, 2), content="true")
  inspect(@challenge_persistent_avl_set.contains(t3, 8), content="true")
  inspect(@challenge_persistent_avl_set.size(t3), content="3")
}
```

### In-order traversal is sorted

```mbt check
///|
test "avl inorder sorted" {
  let t = @challenge_persistent_avl_set.from_array([7, 1, 5, 3])
  inspect(@challenge_persistent_avl_set.inorder(t), content="[1, 3, 5, 7]")
}
```

### Duplicates are ignored

```mbt check
///|
test "avl duplicates" {
  let t0 = @challenge_persistent_avl_set.empty()
  let t1 = @challenge_persistent_avl_set.insert(t0, 4)
  let t2 = @challenge_persistent_avl_set.insert(t1, 4)
  inspect(@challenge_persistent_avl_set.size(t1), content="1")
  inspect(@challenge_persistent_avl_set.size(t2), content="1")
}
```

### Negative values

```mbt check
///|
test "avl negatives" {
  let t = @challenge_persistent_avl_set.from_array([-3, 0, -1, 2])
  inspect(@challenge_persistent_avl_set.inorder(t), content="[-3, -1, 0, 2]")
}
```

---

## Complexity

For `n` keys:

- Search: `O(log n)`
- Insert: `O(log n)` time, `O(log n)` extra memory (path copying)
- Inorder: `O(n)`
- Size: `O(n)` per call

---

## Takeaways

- AVL trees keep height balanced using rotations.
- Persistence lets you keep every version after insertions.
- Only the update path is copied, so memory overhead stays small.
