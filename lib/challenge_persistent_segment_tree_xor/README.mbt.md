# Persistent Segment Tree (Xor)

Point updates with range xor queries.

## Example

```mbt check
///|
test "persistent segment tree xor" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_xor.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_xor.apply_updates(
    root,
    arr.length(),
    [(2, 1), (0, 6)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_xor.range_xor(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="4",
  )
  inspect(
    @challenge_persistent_segment_tree_xor.range_xor(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="1",
  )
  inspect(
    @challenge_persistent_segment_tree_xor.xor_value(updated),
    content="1",
  )
}
```
