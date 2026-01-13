# Persistent AVL Set

Self-balancing BST with path-copying insertions.

## Core Idea

AVL trees enforce a balance factor in {-1, 0, 1}. Persistence is implemented
by copying nodes along the insertion path and rebalancing with rotations.

## Example

```mbt check
///|
test "persistent avl set" {
  let t0 = @challenge_persistent_avl_set.empty()
  let t1 = @challenge_persistent_avl_set.insert(t0, 3)
  let t2 = @challenge_persistent_avl_set.insert(t1, 1)
  let t3 = @challenge_persistent_avl_set.insert(t2, 4)
  inspect(@challenge_persistent_avl_set.contains(t3, 1), content="true")
  inspect(@challenge_persistent_avl_set.contains(t3, 2), content="false")
  inspect(@challenge_persistent_avl_set.inorder(t3), content="[1, 3, 4]")
}
```

## Another Example

```mbt check
///|
test "persistent avl set from array" {
  let t = @challenge_persistent_avl_set.from_array([5, 2, 8, 2][:])
  inspect(@challenge_persistent_avl_set.inorder(t), content="[2, 5, 8]")
  inspect(@challenge_persistent_avl_set.size(t), content="3")
}
```

## Notes

- Duplicates are ignored in the set.
- All previous versions remain available.
