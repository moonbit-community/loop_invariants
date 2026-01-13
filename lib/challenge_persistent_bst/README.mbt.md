# Persistent BST

Immutable binary search tree with path-copying inserts.

## Core Idea

Insertion returns a new tree, copying only the nodes on the path from root
to the insertion point. All other nodes are shared between versions.

## Example

```mbt check
///|
test "persistent bst" {
  let t0 = @challenge_persistent_bst.empty()
  let t1 = @challenge_persistent_bst.insert(t0, 4)
  let t2 = @challenge_persistent_bst.insert(t1, 2)
  let t3 = @challenge_persistent_bst.insert(t2, 6)
  inspect(@challenge_persistent_bst.contains(t3, 2), content="true")
  inspect(@challenge_persistent_bst.contains(t3, 3), content="false")
  inspect(@challenge_persistent_bst.inorder(t3), content="[2, 4, 6]")
  inspect(@challenge_persistent_bst.size(t3), content="3")
}
```

## Another Example

```mbt check
///|
test "persistent bst from array" {
  let t = @challenge_persistent_bst.from_array([3, 1, 4, 2][:])
  inspect(@challenge_persistent_bst.contains(t, 4), content="true")
  inspect(@challenge_persistent_bst.inorder(t), content="[1, 2, 3, 4]")
}
```

## Notes

- Operations are O(height).
- Since this is a BST without rebalancing, worst-case is O(n).
