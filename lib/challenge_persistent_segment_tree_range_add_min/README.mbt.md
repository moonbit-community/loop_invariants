# Persistent Segment Tree (Range Add Min)

Range add updates with range min queries using lazy tags.

## Example

```mbt check
///|
test "persistent segment tree range add min" {
  let arr = [5, 2, 7, 4][:]
  let root = @challenge_persistent_segment_tree_range_add_min.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_min.apply_updates(
    root,
    arr.length(),
    [(1, 3, -1), (0, 2, 2)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="2",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="3",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_min.min_value(updated),
    content="3",
  )
}
```

## Another Example

```mbt check
///|
test "persistent segment tree range add min another" {
  let arr = [3, 5, 1][:]
  let root = @challenge_persistent_segment_tree_range_add_min.build(
    arr,
    0,
    arr.length(),
  )
  let updated = @challenge_persistent_segment_tree_range_add_min.apply_updates(
    root,
    arr.length(),
    [(0, 2, 2), (2, 3, 3)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      root,
      0,
      arr.length(),
      0,
      3,
    ),
    content="1",
  )
  inspect(
    @challenge_persistent_segment_tree_range_add_min.range_min(
      updated,
      0,
      arr.length(),
      0,
      3,
    ),
    content="4",
  )
}
```
