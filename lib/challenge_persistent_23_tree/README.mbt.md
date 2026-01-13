# Persistent 2-3 Tree

Balanced search tree that keeps versions by path copying.

## Core Idea

Each insertion returns a new root. Only the nodes along the update path are
copied, while the rest of the tree is shared. This gives persistence with
O(log n) additional memory per update.

## Example

```mbt check
///|
test "persistent 2-3 tree" {
  let t0 = @challenge_persistent_23_tree.empty()
  let t1 = @challenge_persistent_23_tree.insert(t0, 5)
  let t2 = @challenge_persistent_23_tree.insert(t1, 2)
  let t3 = @challenge_persistent_23_tree.insert(t2, 8)
  inspect(@challenge_persistent_23_tree.contains(t3, 2), content="true")
  inspect(@challenge_persistent_23_tree.contains(t3, 7), content="false")
  inspect(@challenge_persistent_23_tree.size(t3), content="3")
}
```

## Another Example

```mbt check
///|
test "persistent 2-3 tree from array" {
  let t = @challenge_persistent_23_tree.from_array([7, 1, 5][:])
  inspect(@challenge_persistent_23_tree.contains(t, 1), content="true")
  inspect(@challenge_persistent_23_tree.size(t), content="3")
}
```

## Notes

- Older versions remain valid after updates.
- 2-3 trees maintain balance with nodes of 2 or 3 children.
- Operations are O(log n).
