# Challenge: Disjoint Sparse Table

O(1) range minimum queries with disjoint block preprocessing.

## Example

```mbt check
///|
test "disjoint sparse example" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let dst = @challenge_disjoint_sparse_table.build_disjoint_sparse_table(arr[:])
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 1, 5), content="1")
}
```
