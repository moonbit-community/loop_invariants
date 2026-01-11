# Challenge: Sparse Table RMQ

Static range minimum queries in O(1) after O(n log n) preprocessing.

## Example

```mbt check
///|
test "sparse table example" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
  inspect(@challenge_sparse_table_rmq.range_min(st, 1, 5), content="1")
}
```
