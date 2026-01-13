# Challenge: Disjoint Sparse Table

O(1) range minimum queries with disjoint block preprocessing.

## Core Idea

Disjoint sparse tables precompute answers for ranges that cross block midpoints.
For each power-of-two block size, we store:

- Prefix aggregates moving right from the midpoint.
- Prefix aggregates moving left from the midpoint.

Any query [l, r] crosses exactly one midpoint at the highest bit where l and r
differ, so the answer is just combining those two precomputed values.

## Example

```mbt check
///|
test "disjoint sparse example" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let dst = @challenge_disjoint_sparse_table.build_disjoint_sparse_table(arr[:])
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 1, 5), content="1")
}
```

## Another Example

```mbt check
///|
test "disjoint sparse short range" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let dst = @challenge_disjoint_sparse_table.build_disjoint_sparse_table(arr[:])
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 2, 4), content="4")
}
```

## Notes

- Requires an associative operation; here we use minimum.
- Preprocessing is O(n log n), queries are O(1).
