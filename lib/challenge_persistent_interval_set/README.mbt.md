# Challenge: Persistent Interval Set

A **persistent interval set** stores disjoint integer intervals. Each insertion
returns a new version; old versions remain valid and share structure.

This implementation keeps intervals **merged and non-overlapping**, and treats
adjacent intervals as mergeable (because it merges when `s <= end + 1`).

This package provides:

- `empty()` to create a set
- `insert_interval(t, start, end)` to add a closed interval `[start, end]`
- `contains_point(t, x)` to test membership
- `to_array(t)` to list intervals in sorted order

---

## Interval model

Intervals are **inclusive**:

```
[start, end] means start <= x <= end
```

If you insert `(end, start)` with `start > end`, it is normalized to
`[end, start]` automatically.

Adjacent intervals merge:

```
[1, 3] and [4, 6]  ->  [1, 6]
```

---

## Core idea

Insertion works in three steps:

1) Convert the tree to a sorted list of intervals.
2) Insert the new interval into the sorted list.
3) Merge overlapping/adjacent intervals.
4) Rebuild a balanced tree from the merged list.

This is persistent because each step constructs **new** arrays and nodes,
leaving old versions unchanged.

---

## Visual example

Start empty. Insert intervals one by one:

```
insert [2, 5] -> [2, 5]
insert [8, 9] -> [2, 5] [8, 9]
insert [4, 7] -> [2, 9]    (overlaps both)
```

ASCII line:

```
2----5   8-9
   4-----7
=> 2---------9
```

---

## Example with adjacency

```
insert [1, 2]
insert [3, 5]
```

Because `3 <= 2 + 1`, they merge into `[1, 5]`.

---

## Reference implementation

```mbt nocheck
///| pub fn empty() -> Tree

///| pub fn insert_interval(t : Tree, start : Int, end : Int) -> Tree

///| pub fn contains_point(t : Tree, x : Int) -> Bool

///| pub fn to_array(t : Tree) -> Array[(Int, Int)]
```

---

## Tests and examples

### Basic merging

```mbt check
///|
test "interval set basic" {
  let t0 = @challenge_persistent_interval_set.empty()
  let t1 = @challenge_persistent_interval_set.insert_interval(t0, 2, 5)
  let t2 = @challenge_persistent_interval_set.insert_interval(t1, 8, 9)
  let t3 = @challenge_persistent_interval_set.insert_interval(t2, 4, 7)
  inspect(@challenge_persistent_interval_set.to_array(t3), content="[(2, 9)]")
  inspect(
    @challenge_persistent_interval_set.contains_point(t3, 6),
    content="true",
  )
  inspect(
    @challenge_persistent_interval_set.contains_point(t3, 10),
    content="false",
  )
}
```

### Adjacent intervals merge

```mbt check
///|
test "interval set adjacency" {
  let t0 = @challenge_persistent_interval_set.empty()
  let t1 = @challenge_persistent_interval_set.insert_interval(t0, 1, 2)
  let t2 = @challenge_persistent_interval_set.insert_interval(t1, 3, 5)
  inspect(@challenge_persistent_interval_set.to_array(t2), content="[(1, 5)]")
}
```

### Reversed endpoints

```mbt check
///|
test "interval set normalize" {
  let t0 = @challenge_persistent_interval_set.empty()
  let t1 = @challenge_persistent_interval_set.insert_interval(t0, 9, 4)
  inspect(@challenge_persistent_interval_set.to_array(t1), content="[(4, 9)]")
}
```

### Persistence across versions

```mbt check
///|
test "interval set persistence" {
  let t0 = @challenge_persistent_interval_set.empty()
  let t1 = @challenge_persistent_interval_set.insert_interval(t0, 0, 1)
  let t2 = @challenge_persistent_interval_set.insert_interval(t1, 5, 6)
  inspect(@challenge_persistent_interval_set.to_array(t0), content="[]")
  inspect(@challenge_persistent_interval_set.to_array(t1), content="[(0, 1)]")
  inspect(
    @challenge_persistent_interval_set.to_array(t2),
    content="[(0, 1), (5, 6)]",
  )
}
```

---

## Complexity

Let `n` be the number of intervals.

- `insert_interval`: `O(n)` (convert to list, insert, merge, rebuild)
- `contains_point`: `O(log n)` average (binary tree search)
- `to_array`: `O(n)`

This implementation prioritizes clarity and persistence over update speed.

---

## Takeaways

- Intervals are always stored merged and sorted.
- Insertions rebuild from a list, which is easy to reason about.
- Persistence keeps all past versions available.
