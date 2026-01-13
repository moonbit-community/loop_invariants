# Persistent AA Tree

Balanced binary search tree with skew/split rebalancing and path copying.

## Core Idea

AA trees simulate red-black trees using only two operations:

- **skew** (right rotation)
- **split** (left rotation + level increment)

Persistence is achieved by copying nodes along the update path.

## Example

```mbt check
///|
test "persistent aa tree" {
  let t0 = @challenge_persistent_aa_tree.empty()
  let t1 = @challenge_persistent_aa_tree.insert(t0, 5)
  let t2 = @challenge_persistent_aa_tree.insert(t1, 2)
  let t3 = @challenge_persistent_aa_tree.insert(t2, 8)
  inspect(@challenge_persistent_aa_tree.contains(t3, 2), content="true")
  inspect(@challenge_persistent_aa_tree.contains(t3, 7), content="false")
  inspect(@challenge_persistent_aa_tree.inorder(t3), content="[2, 5, 8]")
}
```

## Another Example

```mbt check
///|
test "persistent aa tree from array" {
  let t = @challenge_persistent_aa_tree.from_array([4, 1, 3][:])
  inspect(@challenge_persistent_aa_tree.inorder(t), content="[1, 3, 4]")
  inspect(@challenge_persistent_aa_tree.size(t), content="3")
}
```

## Notes

- Each insert returns a new version.
- `inorder` returns the keys in sorted order.
