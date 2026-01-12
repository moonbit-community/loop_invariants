# Persistent Interval Set

Stores disjoint intervals by rebuilding from a merged list.

## Example

```mbt check
///|
test "persistent interval set" {
  let t0 = @challenge_persistent_interval_set.empty()
  let t1 = @challenge_persistent_interval_set.insert_interval(t0, 2, 5)
  let t2 = @challenge_persistent_interval_set.insert_interval(t1, 8, 9)
  let t3 = @challenge_persistent_interval_set.insert_interval(t2, 4, 7)
  inspect(
    @challenge_persistent_interval_set.contains_point(t3, 3),
    content="true",
  )
  inspect(
    @challenge_persistent_interval_set.contains_point(t3, 6),
    content="true",
  )
  inspect(
    @challenge_persistent_interval_set.contains_point(t3, 10),
    content="false",
  )
  inspect(@challenge_persistent_interval_set.to_array(t3), content="[(2, 9)]")
}
```

## Another Example

```mbt check
///|
test "persistent interval set disjoint" {
  let t0 = @challenge_persistent_interval_set.empty()
  let t1 = @challenge_persistent_interval_set.insert_interval(t0, 1, 2)
  let t2 = @challenge_persistent_interval_set.insert_interval(t1, 5, 6)
  inspect(
    @challenge_persistent_interval_set.to_array(t2),
    content="[(1, 2), (5, 6)]",
  )
  inspect(
    @challenge_persistent_interval_set.contains_point(t2, 4),
    content="false",
  )
}
```
