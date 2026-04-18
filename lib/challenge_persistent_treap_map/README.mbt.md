# Challenge: Persistent Treap Map

A **persistent treap map** is a key-value map that combines:

- a **binary search tree** (ordered by key), and
- a **heap** (ordered by priority)

Every update returns a new version, while older versions remain usable.

This package provides:

- `empty()`
- `insert_or_update(t, key, value)`
- `get(t, key)`
- `contains(t, key)`
- `split(t, key)`
- `merge(a, b)`
- `from_array(pairs)`
- `size(t)`

---

## Core idea: BST by key, heap by priority

Each node stores:

- `key`
- `value`
- `priority`
- `size` (subtree size)
- `left` and `right`

The tree must satisfy two invariants:

1. **BST invariant** (by key):
   - left subtree keys < node key
   - right subtree keys > node key

2. **Heap invariant** (by priority):
   - node priority >= children priorities

This gives expected `O(log n)` performance for insert, search, split, and merge.

In this package, the priority is derived deterministically from `hash(key)`.

---

## Persistence (path copying)

Every update creates new nodes along the update path and reuses the rest.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C    update path      B'  C
  / \                      / \
 D   E                    D   E
```

Only `A'` and `B'` are new nodes; `C`, `D`, `E` are shared.

---

## Split and merge

Treaps are particularly good at split and merge:

- `split(t, key)` returns `(left, right)` where:
  - `left` contains keys `< key`
  - `right` contains keys `>= key`

- `merge(a, b)` assumes all keys in `a` are `<` all keys in `b`.

These two operations are the foundation of insert and update.

---

## API summary

- `insert_or_update`: `O(log n)` expected
- `get`: `O(log n)` expected
- `contains`: `O(log n)` expected
- `split` / `merge`: `O(log n)` expected
- `from_array`: `O(n log n)` expected

---

## Example 1: Insert and update

```mbt check
///|
test "treap map basic" {
  let t0 = @challenge_persistent_treap_map.empty()
  let t1 = @challenge_persistent_treap_map.insert_or_update(t0, 3, 30)
  let t2 = @challenge_persistent_treap_map.insert_or_update(t1, 1, 10)
  let t3 = @challenge_persistent_treap_map.insert_or_update(t2, 3, 31)
  inspect(@challenge_persistent_treap_map.get(t3, 3), content="Some(31)")
  inspect(@challenge_persistent_treap_map.get(t3, 2), content="None")
  inspect(@challenge_persistent_treap_map.contains(t3, 1), content="true")
  inspect(@challenge_persistent_treap_map.size(t3), content="2")
}
```

Here, `t1` and `t2` are still valid and unchanged even after `t3` is created.

---

## Example 2: Split and merge

```mbt check
///|
test "treap map split merge" {
  let t = @challenge_persistent_treap_map.from_array([
    (1, "a"),
    (3, "c"),
    (5, "e"),
  ])
  let (left, right) = @challenge_persistent_treap_map.split(t, 4)
  inspect(@challenge_persistent_treap_map.contains(left, 1), content="true")
  inspect(@challenge_persistent_treap_map.contains(left, 5), content="false")
  inspect(@challenge_persistent_treap_map.contains(right, 5), content="true")
  let merged = @challenge_persistent_treap_map.merge(left, right)
  inspect(@challenge_persistent_treap_map.size(merged), content="3")
}
```

Split uses the key boundary and returns two persistent treaps. Merge restores
back to a single treap.

---

## Example 3: Build from array

```mbt check
///|
test "treap map from array" {
  let t = @challenge_persistent_treap_map.from_array([(2, 20), (5, 50)])
  inspect(@challenge_persistent_treap_map.get(t, 2), content="Some(20)")
  inspect(@challenge_persistent_treap_map.size(t), content="2")
}
```

---

## Complexity

Expected time bounds (randomized by hash-based priority):

- Insert/update: `O(log n)`
- Search: `O(log n)`
- Split/merge: `O(log n)`
- Space per update: `O(log n)` new nodes

---

## When to use this structure

Use this package when you need:

- a persistent key-value map
- ordered keys (BST property)
- fast split/merge operations

If you do not need persistence, a mutable balanced tree map may be simpler.

---

## Reference implementation

```mbt nocheck
///| pub fn empty[K, V]() -> TreapMap[K, V]

///| pub fn size[K, V](t : TreapMap[K, V]) -> Int

///| pub fn split[K : Compare, V](

///|   t : TreapMap[K, V],

///|   key : K,

///| ) -> (TreapMap[K, V], TreapMap[K, V])

///| pub fn merge[K, V](a : TreapMap[K, V], b : TreapMap[K, V]) -> TreapMap[K, V]

///| pub fn contains[K : Compare, V](t : TreapMap[K, V], key : K) -> Bool

///| pub fn get[K : Compare, V](t : TreapMap[K, V], key : K) -> V?

///| pub fn insert_or_update[K : Compare + Hash, V](

///|   t : TreapMap[K, V],

///|   key : K,

///|   value : V,

///| ) -> TreapMap[K, V]

///| pub fn from_array[K : Compare + Hash, V](

///|   arr : ArrayView[(K, V)],

///| ) -> TreapMap[K, V]
```
