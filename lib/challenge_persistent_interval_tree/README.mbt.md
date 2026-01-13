# Persistent Interval Tree

Interval tree with max-end augmentation for overlap queries.

## Core Idea

- Use **path copying** to preserve old versions after each insert.
- Store `max_end` in each node to **prune non-overlapping subtrees**.
- Overlap search descends only where `left.max_end >= query_start`.

## Example

```mbt check
///|
test "persistent interval tree" {
  let t0 = @challenge_persistent_interval_tree.empty()
  let t1 = @challenge_persistent_interval_tree.insert(t0, 1, 3)
  let t2 = @challenge_persistent_interval_tree.insert(t1, 5, 8)
  let t3 = @challenge_persistent_interval_tree.insert(t2, 4, 6)
  inspect(
    @challenge_persistent_interval_tree.find_overlap(t3, 2, 2),
    content="Some((1, 3))",
  )
  inspect(
    @challenge_persistent_interval_tree.find_overlap(t3, 7, 9),
    content="Some((5, 8))",
  )
  inspect(
    @challenge_persistent_interval_tree.find_overlap(t3, 9, 9),
    content="None",
  )
}
```

## Another Example

```mbt check
///|
test "persistent interval tree another" {
  let t0 = @challenge_persistent_interval_tree.empty()
  let t1 = @challenge_persistent_interval_tree.insert(t0, 10, 12)
  let t2 = @challenge_persistent_interval_tree.insert(t1, 14, 15)
  inspect(
    @challenge_persistent_interval_tree.find_overlap(t2, 11, 11),
    content="Some((10, 12))",
  )
  inspect(
    @challenge_persistent_interval_tree.find_overlap(t2, 13, 13),
    content="None",
  )
}
```
