# Challenge: 2D Fenwick Tree

A 2D Fenwick tree (Binary Indexed Tree) supports:

- point updates
- rectangle sum queries

in O(log^2 n) time.

## Problem statement

Maintain a 2D grid of numbers with these operations:

1. `add(r, c, delta)`
2. `sum over rectangle [r1, r2) x [c1, c2)`

## Core idea

A 1D Fenwick tree stores prefix sums using lowbit jumps. The 2D version applies
that idea twice: each update affects all Fenwick blocks in both row and column.

Prefix sum:

```
prefix_sum(r, c) = sum of grid cells in [0, r) x [0, c)
```

Rectangle sum via inclusion-exclusion:

```
range_sum(r1, c1, r2, c2) =
  pref(r2, c2) - pref(r1, c2) - pref(r2, c1) + pref(r1, c1)
```

## Diagram: inclusion-exclusion

```
+-------------------+
|         A         |
|    +---------+    |
|    |    B    |    |
|    +---------+    |
+-------------------+

sum(A) - sum(B) cancels the inner rectangle.
```

## Examples

### Example 1: basic updates

```mbt check
///|
test "fenwick2d example" {
  let fw = @challenge_fenwick_2d.Fenwick2D::new(3, 3)
  fw.add(0, 0, 5)
  fw.add(1, 2, 3)
  inspect(fw.range_sum(0, 0, 3, 3), content="8")
}
```

### Example 2: partial rectangles

```mbt check
///|
test "fenwick2d partial sum" {
  let fw = @challenge_fenwick_2d.Fenwick2D::new(4, 4)
  fw.add(1, 1, 2)
  fw.add(2, 3, 4)
  inspect(fw.range_sum(0, 0, 2, 2), content="2")
  inspect(fw.range_sum(0, 0, 4, 4), content="6")
}
```

### Example 3: multiple points

```mbt check
///|
test "fenwick2d multiple points" {
  let fw = @challenge_fenwick_2d.Fenwick2D::new(4, 4)
  fw.add(0, 0, 1)
  fw.add(1, 1, 2)
  fw.add(2, 3, 4)
  fw.add(3, 0, 5)
  inspect(fw.range_sum(0, 0, 4, 4), content="12")
  inspect(fw.range_sum(1, 1, 3, 4), content="6")
}
```

## Complexity

- Update: O(log rows * log cols)
- Query: O(log rows * log cols)
- Space: O(rows * cols)

## Practical notes and pitfalls

- This implementation uses **0-based input**, but stores data internally as
  1-based indices (standard for Fenwick trees).
- Ranges are **half-open**: `[r1, r2)` and `[c1, c2)`.
- Negative updates are allowed.

## When to use it

Use a 2D Fenwick tree when you need many point updates and rectangle sum
queries on a static grid size.
