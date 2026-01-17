# Challenge: Union-Find with Rollback

A **rollback DSU** (disjoint-set union) can undo merges. It is useful for
**offline dynamic connectivity**, divide-and-conquer on time, and any situation
where you need to explore multiple timelines.

This package provides:

- `RollbackDSU::new(n)`
- `union(a, b)`
- `find(x)`
- `same(a, b)`
- `snapshot()`
- `rollback(snap)`

---

## Core idea

A normal DSU stores:

- `parent[i]`
- `size[i]` for union by size

For rollback, every union logs just enough information to undo it. Here we
record:

```
(child, parent_size_before)
```

If a union is a no-op (same component), we push `(-1, 0)` as a marker.

Rollback simply pops history entries until we return to a snapshot.

---

## Why no path compression?

Path compression mutates many parent pointers, which would require logging a
lot of changes for rollback. To keep rollback efficient, we **avoid path
compression** and only use union by size.

---

## Visual intuition

Example union:

```
Before:        After union(0,1):
0 (root)       0 (root)
1 (root)       1 -> 0
```

History stores `(1, size_before)` so we can restore:

```
Rollback:
parent[1] = 1
size[0] = old_size
```

---

## API summary

- `union`: `O(log n)` (tree height)
- `find`: `O(log n)`
- `rollback`: proportional to number of undone unions

---

## Example 1: Basic rollback

```mbt check
///|
test "rollback dsu basic" {
  let dsu = @challenge_union_find_rollback.RollbackDSU::new(4)
  let _ = dsu.union(0, 1)
  let _ = dsu.union(2, 3)
  let snap = dsu.snapshot()
  let _ = dsu.union(1, 2)
  inspect(dsu.same(0, 3), content="true")
  dsu.rollback(snap)
  inspect(dsu.same(0, 3), content="false")
  inspect(dsu.same(0, 1), content="true")
  inspect(dsu.same(2, 3), content="true")
}
```

---

## Example 2: Nested snapshots

```mbt check
///|
test "rollback dsu nested snapshot" {
  let dsu = @challenge_union_find_rollback.RollbackDSU::new(3)
  let snap0 = dsu.snapshot()
  let _ = dsu.union(0, 1)
  let snap1 = dsu.snapshot()
  let _ = dsu.union(1, 2)
  inspect(dsu.same(0, 2), content="true")
  dsu.rollback(snap1)
  inspect(dsu.same(0, 2), content="false")
  dsu.rollback(snap0)
  inspect(dsu.same(0, 1), content="false")
}
```

---

## Example 3: Redundant unions

```mbt check
///|
test "rollback dsu redundant" {
  let dsu = @challenge_union_find_rollback.RollbackDSU::new(2)
  let snap = dsu.snapshot()
  let _ = dsu.union(0, 1)
  let _ = dsu.union(0, 1) // no-op, but logged
  dsu.rollback(snap)
  inspect(dsu.same(0, 1), content="false")
}
```

---

## When to use this structure

Use rollback DSU when you need:

- offline dynamic connectivity
- time-travel queries
- divide-and-conquer over a time axis

If you do not need rollback, a normal DSU with path compression is faster.

---

## Reference implementation

```mbt
///| pub fn RollbackDSU::new(n : Int) -> RollbackDSU

///| pub fn RollbackDSU::find(self : RollbackDSU, x : Int) -> Int

///| pub fn RollbackDSU::union(self : RollbackDSU, a : Int, b : Int) -> Bool

///| pub fn RollbackDSU::snapshot(self : RollbackDSU) -> Int

///| pub fn RollbackDSU::rollback(self : RollbackDSU, snap : Int) -> Unit

///| pub fn RollbackDSU::same(self : RollbackDSU, a : Int, b : Int) -> Bool
```
