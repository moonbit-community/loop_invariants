# Persistent Segment Tree (Lazy Range Add)

Range add updates with lazy propagation and range sum queries.

## Example

```mbt check
///|
test "persistent segment tree lazy" {
  let arr = [1, 2, 3, 4][:]
  let root = @challenge_persistent_segment_tree_lazy.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_lazy.apply_updates(
    root,
    arr.length(),
    [(1, 3, 2), (0, 2, -1)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      root,
      0,
      arr.length(),
      0,
      4,
    ),
    content="10",
  )
  inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="12",
  )
  inspect(@challenge_persistent_segment_tree_lazy.total(updated), content="12")
}
```

## Another Example

```mbt check
///|
test "persistent segment tree lazy single update" {
  let arr = [1, 1, 1, 1][:]
  let root = @challenge_persistent_segment_tree_lazy.build(arr, 0, arr.length())
  let updated = @challenge_persistent_segment_tree_lazy.apply_updates(
    root,
    arr.length(),
    [(1, 3, 2)][:],
  )
  inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      updated,
      0,
      arr.length(),
      0,
      4,
    ),
    content="8",
  )
  inspect(
    @challenge_persistent_segment_tree_lazy.range_sum(
      updated,
      0,
      arr.length(),
      1,
      3,
    ),
    content="6",
  )
}
```
