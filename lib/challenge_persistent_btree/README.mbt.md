# Challenge: Persistent B-Tree (Min Degree 2)

This is a **persistent B-tree** of minimum degree 2 (a 2-3-4 tree). It stores
between 1 and 3 keys per node and keeps the tree balanced by splitting full
nodes during insertion.

This package provides:

- `empty()` to create a tree
- `insert(tree, key)` to insert a key (persistent)
- `contains(tree, key)` to search
- `size(tree)` to count keys
- `from_array(arr)` to build by repeated inserts

---

## What is a B-tree (degree 2)?

A B-tree node stores multiple keys and multiple children.
For minimum degree 2, each node holds:

- 1, 2, or 3 keys
- 0, 2, 3, or 4 children

All leaves are at the **same depth**, so the tree stays balanced.

Example node shapes:

```
1 key:    [k]
2 keys:   [k1 | k2]
3 keys:   [k1 | k2 | k3]
```

---

## Searching in a node

Given a node with keys `[k1 | k2 | k3]`, we choose a child based on where the
key fits:

```
< k1     -> child 0
k1..k2   -> child 1
k2..k3   -> child 2
> k3     -> child 3
```

Because each insertion keeps keys sorted inside nodes, this search is correct.

---

## Insertion with splitting

When a node is full (3 keys) and we need to insert another key, we split:

```
Before (4 keys, conceptual):
[k0 | k1 | k2 | k3]

Split into:
  promote k2
  left  = [k0 | k1]
  right = [k3]
```

The promoted key is inserted into the parent. If the parent overflows, we split
again, possibly up to the root. If the root splits, a new root is created.

---

## Persistence (path copying)

Insertion returns a new tree. Only the nodes on the path to the modified leaf
are copied; the rest are shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert key     B'  C
  / \                      / \
 D   E                    D   E
```

This gives `O(log n)` extra memory per insertion.

---

## Reference implementation

```mbt
///| pub fn[T] empty() -> Tree[T]

///| pub fn[T : Compare] insert(t : Tree[T], key : T) -> Tree[T]

///| pub fn[T : Compare] contains(t : Tree[T], key : T) -> Bool

///| pub fn[T] size(t : Tree[T]) -> Int

///| pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T]
```

---

## Tests and examples

### Basic insertion and search

```mbt check
///|
test "btree basic" {
  let t0 = @challenge_persistent_btree.empty()
  let t1 = @challenge_persistent_btree.insert(t0, 10)
  let t2 = @challenge_persistent_btree.insert(t1, 5)
  let t3 = @challenge_persistent_btree.insert(t2, 20)
  inspect(@challenge_persistent_btree.contains(t3, 5), content="true")
  inspect(@challenge_persistent_btree.contains(t3, 7), content="false")
  inspect(@challenge_persistent_btree.size(t3), content="3")
}
```

### Build from array

```mbt check
///|
test "btree from array" {
  let t = @challenge_persistent_btree.from_array([8, 3, 1, 6, 4, 7, 10, 14][:])
  inspect(@challenge_persistent_btree.contains(t, 6), content="true")
  inspect(@challenge_persistent_btree.contains(t, 2), content="false")
  inspect(@challenge_persistent_btree.size(t), content="8")
}
```

### Persistence across versions

```mbt check
///|
test "btree versions" {
  let t0 = @challenge_persistent_btree.empty()
  let t1 = @challenge_persistent_btree.insert(t0, 4)
  let t2 = @challenge_persistent_btree.insert(t1, 9)
  inspect(@challenge_persistent_btree.contains(t0, 4), content="false")
  inspect(@challenge_persistent_btree.contains(t1, 4), content="true")
  inspect(@challenge_persistent_btree.contains(t2, 9), content="true")
}
```

### Duplicates are ignored

```mbt check
///|
test "btree duplicates" {
  let t0 = @challenge_persistent_btree.empty()
  let t1 = @challenge_persistent_btree.insert(t0, 2)
  let t2 = @challenge_persistent_btree.insert(t1, 2)
  inspect(@challenge_persistent_btree.size(t1), content="1")
  inspect(@challenge_persistent_btree.size(t2), content="1")
}
```

---

## Complexity

Let `n` be the number of keys.

- Search: `O(log n)`
- Insert: `O(log n)` time, `O(log n)` extra memory (path copying)
- Size: `O(n)` per call

---

## Takeaways

- B-trees keep all leaves at the same depth.
- Splitting full nodes preserves balance and keeps height small.
- Persistence lets you keep every version after inserts.
