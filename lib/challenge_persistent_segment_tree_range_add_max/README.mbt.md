# Persistent Segment Tree (Range Add Max)

Range add updates with range max queries using lazy tags.

## Example

```mbt check
///|
test "persistent segment tree range add max" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_range_add_max.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_max.apply_updates(
    root,
    arr.length(),
    [(1, 3, -1), (0, 2, 2)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="7",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      updated,
      0,
      arr.length(),
      1,
      3,
    ),
    content="6",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.max_value(updated),
    content="7",
  )
}
```

## Another Example

```mbt check
///|
test "persistent segment tree range add max another" {
  let arr = [1, 3, 2][:]
  let root = @challenge_persistent_segment_tree_range_add_max.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_max.apply_updates(
    root,
    arr.length(),
    [(0, 3, 4)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="3",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_max.range_max(
      updated,
      0,
      arr.length(),
      0,
      3,
    ),
    content="7",
  )
}
```
