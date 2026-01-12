# AVL Tree (Reference)

Self-balancing binary search tree that maintains height balance via rotations.

## What it demonstrates

- Height tracking and balance factors
- Single and double rotations
- Insert/delete with rebalancing

## Pseudocode sketch

```mbt nocheck
insert(node, key):
  bst insert
  update height
  rotate if balance out of range
```

## Example

```mbt check
///|
test "avl tree example" {
  let sorted = @avl_tree.avl_sorted([3L, 1L, 4L, 1L][:])
  inspect(sorted, content="[1, 1, 3, 4]")
}
```

## Notes

- Time complexity: O(log n) per operation
- This package is a reference implementation with invariants
