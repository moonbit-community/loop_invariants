# Challenge: Sparse Table RMQ

Static range minimum queries in O(1) after O(n log n) preprocessing.

## Core Idea

Precompute `st[k][i]` = minimum of the range `[i, i + 2^k)`.

For a query [l, r], let `k = floor(log2(r - l))`. Then:

```
min(range) = min(st[k][l], st[k][r - 2^k])
```

Because min is idempotent, overlapping ranges are fine.

## Example

```mbt check
///|
test "sparse table example" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
  inspect(@challenge_sparse_table_rmq.range_min(st, 1, 5), content="1")
}
```

## Another Example

```mbt check
///|
test "sparse table short range" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
  inspect(@challenge_sparse_table_rmq.range_min(st, 2, 4), content="4")
}
```

## Notes

- Query time is O(1).
- Update time is O(n) (static structure).
