# Challenge: Persistent Treap Set

A **persistent treap set** is a set structure that combines:

- a **binary search tree** (ordered by key), and
- a **heap** (ordered by priority)

Every update returns a new version, while old versions remain usable.

This package provides:

- `empty()`
- `insert(t, key)`
- `contains(t, key)`
- `split(t, key)`
- `merge(a, b)`
- `from_array(arr)`
- `size(t)`

---

## Core idea: BST by key, heap by priority

Each node stores:

- `key`
- `priority`
- `size` (subtree size)
- `left` and `right`

The treap satisfies two invariants:

1. **BST invariant** (by key): left < key < right
2. **Heap invariant** (by priority): parent priority >= child priority

In this implementation, the priority is derived deterministically from
`hash(key)`. That makes the structure stable across runs while still
maintaining expected balance properties.

---

## Persistence (path copying)

Every insert creates new nodes along the path and reuses the rest:

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C    update path      B'  C
  / \                      / \
 D   E                    D   E
```

Only `A'` and `B'` are new; `C`, `D`, `E` are shared.

---

## Split and merge

Treaps are especially good at split and merge:

- `split(t, key)` returns `(left, right)` where:
  - `left` contains keys `< key`
  - `right` contains keys `>= key`

- `merge(a, b)` assumes all keys in `a` are `<` all keys in `b`.

These operations are the building blocks for insert.

---

## API summary

- `insert`: `O(log n)` expected
- `contains`: `O(log n)` expected
- `split` / `merge`: `O(log n)` expected
- `from_array`: `O(n log n)` expected

---

## Example 1: Insert and search

```mbt check
///|
test "treap set basic" {
  let t0 = @challenge_persistent_treap_set.empty()
  let t1 = @challenge_persistent_treap_set.insert(t0, 3)
  let t2 = @challenge_persistent_treap_set.insert(t1, 1)
  let t3 = @challenge_persistent_treap_set.insert(t2, 5)
  debug_inspect(@challenge_persistent_treap_set.contains(t3, 3), content="true")
  debug_inspect(
    @challenge_persistent_treap_set.contains(t3, 2),
    content="false",
  )
  debug_inspect(@challenge_persistent_treap_set.size(t3), content="3")
}
```

Each insert returns a new version, while older versions remain unchanged.

---

## Example 2: Split and merge

```mbt check
///|
test "treap set split merge" {
  let t = @challenge_persistent_treap_set.from_array([1, 3, 5, 7])
  let (left, right) = @challenge_persistent_treap_set.split(t, 4)
  debug_inspect(
    @challenge_persistent_treap_set.contains(left, 1),
    content="true",
  )
  debug_inspect(
    @challenge_persistent_treap_set.contains(left, 5),
    content="false",
  )
  debug_inspect(
    @challenge_persistent_treap_set.contains(right, 7),
    content="true",
  )
  let merged = @challenge_persistent_treap_set.merge(left, right)
  debug_inspect(@challenge_persistent_treap_set.size(merged), content="4")
}
```

---

## Example 3: Build from array

```mbt check
///|
test "treap set from array" {
  let t = @challenge_persistent_treap_set.from_array([2, 5, 2, 8])
  debug_inspect(@challenge_persistent_treap_set.contains(t, 2), content="true")
  debug_inspect(@challenge_persistent_treap_set.contains(t, 8), content="true")
  debug_inspect(@challenge_persistent_treap_set.size(t), content="3")
}
```

Duplicates are ignored, because this is a set.

---

## Complexity

Expected time bounds (hash-based priorities):

- Insert: `O(log n)`
- Search: `O(log n)`
- Split/merge: `O(log n)`
- Space per insert: `O(log n)` new nodes

---

## When to use this structure

Use this package when you need:

- a persistent set
- ordered keys (BST property)
- fast split/merge

If you do not need persistence, a mutable tree set may be simpler.

---

## Reference implementation

```mbt nocheck
///| pub fn empty[T]() -> Treap[T]

///| pub fn size[T](t : Treap[T]) -> Int

///| pub fn split[T : Compare](t : Treap[T], key : T) -> (Treap[T], Treap[T])

///| pub fn merge[T](a : Treap[T], b : Treap[T]) -> Treap[T]

///| pub fn contains[T : Compare](t : Treap[T], key : T) -> Bool

///| pub fn insert[T : Compare + Hash](t : Treap[T], key : T) -> Treap[T]

///| pub fn from_array[T : Compare + Hash](arr : ArrayView[T]) -> Treap[T]
```
