# Persistent B-Tree (min degree 2)

Small-degree B-tree with path-copying insertions.

## Core Idea

B-trees keep keys sorted within each node and maintain balance by splitting
full nodes on insert. Persistence is achieved by copying nodes on the insert
path while sharing unchanged subtrees.

## Example

```mbt check
///|
test "persistent btree" {
  let t0 = @challenge_persistent_btree.empty()
  let t1 = @challenge_persistent_btree.insert(t0, 5)
  let t2 = @challenge_persistent_btree.insert(t1, 2)
  let t3 = @challenge_persistent_btree.insert(t2, 8)
  inspect(@challenge_persistent_btree.size(t3), content="3")
  inspect(@challenge_persistent_btree.contains(t3, 2), content="true")
}
```

## Another Example

```mbt check
///|
test "persistent btree versions" {
  let t1 = @challenge_persistent_btree.from_array([1, 4, 6][:])
  let t2 = @challenge_persistent_btree.insert(t1, 9)
  inspect(@challenge_persistent_btree.size(t1), content="3")
  inspect(@challenge_persistent_btree.size(t2), content="4")
}
```

## Notes

- This uses minimum degree 2 (smallest nontrivial B-tree).
- Each insertion returns a new version.
- Search/insert are O(log n) in balanced cases.
