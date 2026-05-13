# Challenge: Persistent Interval Tree

An **interval tree** stores intervals and can quickly find an interval that
overlaps a query range. This version is **persistent**: every insert returns a
new version, while old versions remain valid.

This package provides:

- `empty()` to create a tree
- `insert(t, start, end)` to add an interval (persistent)
- `find_overlap(t, qs, qe)` to find any overlapping interval
- `size(t)` to count intervals

---

## Interval model

Intervals are **inclusive**:

```
[start, end] overlaps [qs, qe] if start <= qe and qs <= end
```

If you insert another interval with the **same start**, this implementation
keeps the larger end.

---

## Augmentation with max_end

Each node stores:

- `start`, `end` of its interval
- `max_end` = maximum end value in its subtree

Example:

```
            [5,8] max=12
           /             \
      [1,3] max=6      [10,12] max=12
        \
       [4,6] max=6
```

The `max_end` value lets us skip subtrees that cannot possibly overlap.

---

## Overlap search idea

Suppose we search for overlap with `[qs, qe]`.
At a node:

1) If current interval overlaps, return it.
2) Otherwise, check the left subtree:
   - If `left.max_end >= qs`, there **might** be an overlap on the left.
3) Otherwise, go right.

This prunes large parts of the tree.

---

## Persistence (path copying)

When inserting, only the path from the root to the inserted position is copied.
All other nodes are shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert x       B'  C
  / \                      / \
 D   E                    D   E
```

---

## Important limitation

This tree is a **BST by start**, but it is not self-balancing. If you insert
intervals in sorted order, the height can degrade to `O(n)`, making queries
slow. For guaranteed `O(log n)`, you would need a balanced BST.

---

## Reference implementation

```mbt nocheck
///| pub fn empty() -> Tree

///| pub fn insert(t : Tree, start : Int, end : Int) -> Tree

///| pub fn find_overlap(t : Tree, qs : Int, qe : Int) -> (Int, Int)?

///| pub fn size(t : Tree) -> Int
```

---

## Tests and examples

### Basic overlap search

```mbt check
///|
test "interval tree basic" {
  let t0 = @challenge_persistent_interval_tree.empty()
  let t1 = @challenge_persistent_interval_tree.insert(t0, 1, 3)
  let t2 = @challenge_persistent_interval_tree.insert(t1, 5, 8)
  let t3 = @challenge_persistent_interval_tree.insert(t2, 4, 6)
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t3, 2, 2),
    content="Some((1, 3))",
  )
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t3, 7, 9),
    content="Some((5, 8))",
  )
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t3, 9, 9),
    content="None",
  )
}
```

### Disjoint intervals

```mbt check
///|
test "interval tree disjoint" {
  let t0 = @challenge_persistent_interval_tree.empty()
  let t1 = @challenge_persistent_interval_tree.insert(t0, 10, 12)
  let t2 = @challenge_persistent_interval_tree.insert(t1, 14, 15)
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t2, 11, 11),
    content="Some((10, 12))",
  )
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t2, 13, 13),
    content="None",
  )
}
```

### Same start merges end

```mbt check
///|
test "interval tree same start" {
  let t0 = @challenge_persistent_interval_tree.empty()
  let t1 = @challenge_persistent_interval_tree.insert(t0, 2, 4)
  let t2 = @challenge_persistent_interval_tree.insert(t1, 2, 7)
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t2, 6, 6),
    content="Some((2, 7))",
  )
  debug_inspect(@challenge_persistent_interval_tree.size(t2), content="1")
}
```

### Persistence across versions

```mbt check
///|
test "interval tree persistence" {
  let t0 = @challenge_persistent_interval_tree.empty()
  let t1 = @challenge_persistent_interval_tree.insert(t0, 0, 2)
  let t2 = @challenge_persistent_interval_tree.insert(t1, 5, 6)
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t0, 1, 1),
    content="None",
  )
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t1, 1, 1),
    content="Some((0, 2))",
  )
  debug_inspect(
    @challenge_persistent_interval_tree.find_overlap(t2, 5, 5),
    content="Some((5, 6))",
  )
}
```

---

## Complexity

Let `h` be the tree height:

- Insert: `O(h)` time, `O(h)` extra memory
- Overlap query: `O(h)` average with pruning

Without balancing, worst-case `h = O(n)`.

---

## Takeaways

- `max_end` allows fast overlap queries by pruning subtrees.
- Persistence keeps every version after updates.
- For worst-case guarantees, pair this with a balanced BST.
