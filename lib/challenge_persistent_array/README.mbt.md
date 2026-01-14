# Persistent Array

Path-copying segment tree that supports point updates and immutable versions.

## Core Idea

Each update creates a new root by copying the path from root to the updated
leaf. All other nodes are shared, so old versions remain available.

## Example

```mbt check
///|
test "persistent array" {
  let arr = @challenge_persistent_array.from_array([1, 2, 3, 4][:])
  inspect(@challenge_persistent_array.get_at(arr, 2), content="Some(3)")
  let arr2 = @challenge_persistent_array.set_at(arr, 1, 10)
  inspect(@challenge_persistent_array.get_at(arr, 1), content="Some(2)")
  inspect(@challenge_persistent_array.get_at(arr2, 1), content="Some(10)")
  inspect(@challenge_persistent_array.to_array(arr2), content="[1, 10, 3, 4]")
  inspect(@challenge_persistent_array.length(arr2), content="4")
}
```

## Another Example

```mbt check
///|
test "persistent array versions" {
  let arr0 = @challenge_persistent_array.from_array([5, 6, 7][:])
  let arr1 = @challenge_persistent_array.set_at(arr0, 0, 9)
  inspect(@challenge_persistent_array.to_array(arr0), content="[5, 6, 7]")
  inspect(@challenge_persistent_array.to_array(arr1), content="[9, 6, 7]")
}
```

## Notes

- Access is O(log n).
- Updates are O(log n) with structural sharing.
- The array is generic over element type `T`.
