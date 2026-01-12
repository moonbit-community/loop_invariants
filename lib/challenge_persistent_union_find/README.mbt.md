# Persistent Union-Find

Persistent DSU with path-copying arrays for parents and sizes.

## Example

```mbt check
///|
test "persistent union find" {
  let d0 = @challenge_persistent_union_find.make(5)
  let d1 = @challenge_persistent_union_find.union(d0, 0, 1)
  let d2 = @challenge_persistent_union_find.union(d1, 1, 2)
  let d3 = @challenge_persistent_union_find.union(d2, 3, 4)
  inspect(@challenge_persistent_union_find.same(d2, 0, 2), content="true")
  inspect(@challenge_persistent_union_find.same(d2, 0, 3), content="false")
  inspect(@challenge_persistent_union_find.same(d3, 3, 4), content="true")
}
```

## Another Example

```mbt check
///|
test "persistent union find versions" {
  let d0 = @challenge_persistent_union_find.make(4)
  let d1 = @challenge_persistent_union_find.union(d0, 0, 1)
  let d2 = @challenge_persistent_union_find.union(d1, 2, 3)
  inspect(@challenge_persistent_union_find.same(d1, 2, 3), content="false")
  inspect(@challenge_persistent_union_find.same(d2, 2, 3), content="true")
}
```
