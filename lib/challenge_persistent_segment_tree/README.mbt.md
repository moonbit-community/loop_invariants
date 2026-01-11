# Persistent Segment Tree (Sum)

Path-copying segment tree with point updates and range sum queries.

## Example

```mbt check
///|
test "persistent segment tree" {
  let arr = [1, 2, 3, 4][:]
  let root = @challenge_persistent_segment_tree.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree.apply_updates(
    root,
    arr.length(),
    [(1, 3), (3, -1)][:],
  )
  inspect(
    @challenge_persistent_segment_tree.query(root, 0, arr.length(), 0, 4),
    content="10",
  )
  inspect(
    @challenge_persistent_segment_tree.query(updated, 0, arr.length(), 0, 4),
    content="12",
  )
  inspect(@challenge_persistent_segment_tree.total(updated), content="12")
}
```
