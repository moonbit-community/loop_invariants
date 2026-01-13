# Persistent Fenwick Range Add

Two persistent BITs supporting range add and range sum queries.

## Core Idea

Use two BITs to convert range add into prefix sums, and make each update
persistent by copying only the affected nodes.

## Example

```mbt check
///|
test "persistent fenwick range add" {
  let rf0 = @challenge_persistent_fenwick_range_add.make(5)
  let rf1 = @challenge_persistent_fenwick_range_add.range_add(rf0, 1, 3, 2)
  let rf2 = @challenge_persistent_fenwick_range_add.range_add(rf1, 0, 2, -1)
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 0, 4),
    content="3",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 2, 3),
    content="3",
  )
  inspect(@challenge_persistent_fenwick_range_add.length(rf2), content="5")
}
```

## Another Example

```mbt check
///|
test "persistent fenwick range add another" {
  let rf0 = @challenge_persistent_fenwick_range_add.make(4)
  let rf1 = @challenge_persistent_fenwick_range_add.range_add(rf0, 0, 1, 3)
  let rf2 = @challenge_persistent_fenwick_range_add.range_add(rf1, 2, 3, 2)
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 0, 3),
    content="10",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 1, 2),
    content="5",
  )
}
```

## Notes

- Range indices are inclusive.
- Each update/query is O(log n).
