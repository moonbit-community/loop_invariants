# Persistent BST

Immutable binary search tree with path-copying inserts.

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
