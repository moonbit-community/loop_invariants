# Challenge: Persistent Union-Find

A **persistent union-find (DSU)** keeps a history of merges. Every union returns
a new version, and older versions remain usable.

This implementation stores the parent and size arrays in a **persistent segment
tree**, so updates are `O(log n)` while sharing most of the structure.

This package provides:

- `make(n)`
- `find(dsu, x)`
- `union(dsu, a, b)`
- `same(dsu, a, b)`

---

## Core idea

Union-find stores two arrays:

- `parent[i]` = parent of node `i`
- `size[i]` = size of the component rooted at `i`

A node is a root if `parent[i] == i`.

### Union by size

When you union two roots, you attach the smaller tree under the bigger root:

```
root A (size 3)      root B (size 5)

attach A under B

new root B (size 8)
```

This keeps the trees shallow.

### No path compression

Path compression mutates parent pointers. In a persistent setting, that would
break older versions. So this implementation avoids compression and keeps
`find` purely functional.

---

## Persistent arrays with segment trees

Each `array_set` creates a new version of the parent/size array by path-copying
nodes in a segment tree. Only `O(log n)` nodes are new, the rest are shared.

```
Old array tree:          New array tree:

     A                        A'
    / \                      / \
   B   C    update path      B'  C
  / \                      / \
 D   E                    D   E
```

This allows every union to be persistent without copying the full array.

---

## API summary

- `find`: `O(log n * log n)` in the worst case (tree height times array lookup)
- `union`: `O(log n * log n)`
- `same`: `O(log n * log n)`

The extra `log n` factor comes from the persistent array access.

---

## Example 1: Basic unions

```mbt check
///|
test "persistent union find basic" {
  let d0 = @challenge_persistent_union_find.make(5)
  let d1 = @challenge_persistent_union_find.union(d0, 0, 1)
  let d2 = @challenge_persistent_union_find.union(d1, 1, 2)
  let d3 = @challenge_persistent_union_find.union(d2, 3, 4)
  inspect(@challenge_persistent_union_find.same(d2, 0, 2), content="true")
  inspect(@challenge_persistent_union_find.same(d2, 0, 3), content="false")
  inspect(@challenge_persistent_union_find.same(d3, 3, 4), content="true")
}
```

---

## Example 2: Versions stay alive

```mbt check
///|
test "persistent union find versions" {
  let d0 = @challenge_persistent_union_find.make(4)
  let d1 = @challenge_persistent_union_find.union(d0, 0, 1)
  let d2 = @challenge_persistent_union_find.union(d1, 2, 3)
  inspect(@challenge_persistent_union_find.same(d1, 2, 3), content="false")
  inspect(@challenge_persistent_union_find.same(d2, 2, 3), content="true")
}
```

---

## Example 3: Two branches

```mbt check
///|
test "persistent union find branching" {
  let d0 = @challenge_persistent_union_find.make(3)
  let d1 = @challenge_persistent_union_find.union(d0, 0, 1)
  let d2 = @challenge_persistent_union_find.union(d0, 1, 2)
  inspect(@challenge_persistent_union_find.same(d1, 0, 1), content="true")
  inspect(@challenge_persistent_union_find.same(d1, 1, 2), content="false")
  inspect(@challenge_persistent_union_find.same(d2, 1, 2), content="true")
  inspect(@challenge_persistent_union_find.same(d2, 0, 1), content="false")
}
```

---

## Complexity

Let `n` be the number of elements.

- `find`: `O(log n * log n)`
- `union`: `O(log n * log n)`
- `same`: `O(log n * log n)`
- Space per union: `O(log n)` new nodes per array

---

## When to use this structure

Use this package when you need:

- persistent connectivity queries
- branching or time-travel states
- immutable versions of DSU

If you do not need persistence, a normal union-find with path compression is
faster.

---

## Reference implementation

```mbt
///| pub fn make(n : Int) -> DSU

///| pub fn find(dsu : DSU, x : Int) -> Int

///| pub fn union(dsu : DSU, a : Int, b : Int) -> DSU

///| pub fn same(dsu : DSU, a : Int, b : Int) -> Bool
```
