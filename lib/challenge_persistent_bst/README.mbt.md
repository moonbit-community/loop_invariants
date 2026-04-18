# Challenge: Persistent Binary Search Tree (BST)

A **persistent BST** is an immutable binary search tree. Every insertion returns
a new tree, while old versions remain valid and share unchanged structure.

This package provides:

- `empty()` to create an empty tree
- `insert(tree, value)` to insert a value (persistent)
- `contains(tree, value)` to search
- `inorder(tree)` to list values in sorted order
- `size(tree)` to count nodes
- `from_array(arr)` to build by repeated inserts

---

## BST property (the ordering rule)

For every node with value `v`:

- all values in the left subtree are `< v`
- all values in the right subtree are `> v`

This makes search fast when the tree is balanced.

---

## Persistence (path copying)

When inserting, we do not modify old nodes. We only copy the path from the
root to the insertion point, and reuse the rest.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert x       B'  C
  / \                      / \
 D   E                    D   E
```

Only the nodes on the path (`A`, `B`) are copied. Everything else is shared.

---

## Worked insertion example

Insert values `4, 2, 6, 1, 3`:

```
        4
       / \
      2   6
     / \
    1   3
```

In-order traversal gives `[1, 2, 3, 4, 6]`.

---

## Important limitation: no balancing

This BST does **not** rebalance. If you insert values in sorted order,
the tree becomes a chain:

```
Insert 1,2,3,4:

1
 \
  2
   \
    3
     \
      4
```

In that worst case, search and insert become `O(n)`.

If you need guaranteed `O(log n)`, use a balanced persistent tree
(e.g., AVL or 2-3 tree) instead.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Tree[T]

///| pub fn[T : Compare] insert(t : Tree[T], value : T) -> Tree[T]

///| pub fn[T : Compare] contains(t : Tree[T], value : T) -> Bool

///| pub fn[T] inorder(t : Tree[T]) -> Array[T]

///| pub fn[T] size(t : Tree[T]) -> Int

///| pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T]
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "persistent bst" {
  let t0 = @challenge_persistent_bst.empty()
  let t1 = @challenge_persistent_bst.insert(t0, 4)
  let t2 = @challenge_persistent_bst.insert(t1, 2)
  let t3 = @challenge_persistent_bst.insert(t2, 6)
  inspect(@challenge_persistent_bst.contains(t3, 2), content="true")
  inspect(@challenge_persistent_bst.contains(t3, 3), content="false")
  inspect(@challenge_persistent_bst.inorder(t3), content="[2, 4, 6]")
  inspect(@challenge_persistent_bst.size(t3), content="3")
}
```

### Build from array

```mbt check
///|
test "persistent bst from array" {
  let t = @challenge_persistent_bst.from_array([3, 1, 4, 2])
  inspect(@challenge_persistent_bst.contains(t, 4), content="true")
  inspect(@challenge_persistent_bst.inorder(t), content="[1, 2, 3, 4]")
}
```

### Persistence across versions

```mbt check
///|
test "persistent bst versions" {
  let t0 = @challenge_persistent_bst.empty()
  let t1 = @challenge_persistent_bst.insert(t0, 5)
  let t2 = @challenge_persistent_bst.insert(t1, 1)
  inspect(@challenge_persistent_bst.contains(t0, 5), content="false")
  inspect(@challenge_persistent_bst.contains(t1, 5), content="true")
  inspect(@challenge_persistent_bst.contains(t2, 1), content="true")
}
```

### Duplicates are ignored

```mbt check
///|
test "persistent bst duplicates" {
  let t0 = @challenge_persistent_bst.empty()
  let t1 = @challenge_persistent_bst.insert(t0, 4)
  let t2 = @challenge_persistent_bst.insert(t1, 4)
  inspect(@challenge_persistent_bst.size(t1), content="1")
  inspect(@challenge_persistent_bst.size(t2), content="1")
}
```

---

## Complexity

Let `h` be the tree height:

- Search: `O(h)`
- Insert: `O(h)` time, `O(h)` extra memory
- Inorder: `O(n)`
- Size: `O(n)` per call

For balanced trees, `h = O(log n)`. In the worst case, `h = O(n)`.

---

## Takeaways

- Persistent BSTs share structure between versions by path copying.
- In-order traversal is always sorted.
- Without balancing, worst-case performance is linear.
