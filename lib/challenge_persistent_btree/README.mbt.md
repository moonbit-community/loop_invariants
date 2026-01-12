# Persistent B-Tree (min degree 2)

Small-degree B-tree with path-copying insertions.

## Example

```mbt check
///|
test "persistent btree" {
  let t0 = @challenge_persistent_btree.empty()
  let t1 = @challenge_persistent_btree.insert(t0, 5)
  let t2 = @challenge_persistent_btree.insert(t1, 2)
  let t3 = @challenge_persistent_btree.insert(t2, 8)
  inspect(@challenge_persistent_btree.size(t3), content="3")
}
```

## Another Example

```mbt check
///|
test "persistent btree versions" {
  let t0 = @challenge_persistent_btree.empty()
  let t1 = @challenge_persistent_btree.insert(t0, 1)
  let t2 = @challenge_persistent_btree.insert(t1, 4)
  inspect(@challenge_persistent_btree.size(t1), content="1")
  inspect(@challenge_persistent_btree.size(t2), content="2")
}
```
