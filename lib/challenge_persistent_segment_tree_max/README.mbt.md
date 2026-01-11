# Persistent Segment Tree (Max)

Point updates with range maximum queries.

## Example

```mbt check
///|
test "persistent segment tree max" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_max.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_max.apply_updates(
    root,
    arr.length(),
    [(2, 1), (0, 6)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="7",
  )
  inspect(
    @challenge_persistent_segment_tree_max.range_max(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="6",
  )
  inspect(
    @challenge_persistent_segment_tree_max.max_value(updated),
    content="6",
  )
}
```
