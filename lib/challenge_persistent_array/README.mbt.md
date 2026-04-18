# Challenge: Persistent Array

A **persistent array** gives you immutable versions of an array after each
update. Every update returns a new version, while older versions remain valid.

This implementation uses a **path-copying segment tree** under the hood.

---

## What you can do

- `from_array(arr)` build the first version
- `get_at(arr, idx)` read a value (returns `None` if out of range)
- `set_at(arr, idx, value)` create a new version with one index updated
- `length(arr)` get the array size
- `to_array(arr)` materialize into a normal array

---

## Important precondition

This implementation assumes the initial array is **non-empty**.
A persistent array of length 0 is not supported because the internal tree has
no empty-node variant.

---

## Core idea: path-copying segment tree

Represent the array in a full binary tree:

- Each leaf holds one element.
- Each internal node represents a range `[l, r)`.

Example for 4 elements `[a, b, c, d]`:

```
                [0,4)
               /     \
           [0,2)     [2,4)
           /   \      /   \
        [0,1) [1,2) [2,3) [3,4)
          a      b     c     d
```

To update index 1 (value `b`), we only copy the nodes on the path:

```
Old tree:                     New tree:

    [0,4)                        [0,4)'
     /  \                         /   \
 [0,2) [2,4)                 [0,2)'  [2,4)
  /  \    / \                  /  \     / \
 a    b  c   d                a    b'  c   d
```

Only the left side is copied. The right side is **shared**.

This gives persistence with only `O(log n)` extra memory per update.

---

## Access and update

- `get_at` follows the path down the tree to the leaf (like binary search).
- `set_at` copies nodes along the path and reuses the rest.

Both cost `O(log n)` time.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] from_array(arr : ArrayView[T]) -> PArray[T]

///| pub fn[T] get_at(arr : PArray[T], idx : Int) -> T?

///| pub fn[T] set_at(arr : PArray[T], idx : Int, value : T) -> PArray[T]

///| pub fn[T] length(arr : PArray[T]) -> Int

///| pub fn[T] to_array(arr : PArray[T]) -> Array[T]
```

---

## Tests and examples

### Basic persistence

```mbt check
///|
test "persistent array" {
  let arr = @challenge_persistent_array.from_array([1, 2, 3, 4])
  inspect(@challenge_persistent_array.get_at(arr, 2), content="Some(3)")
  let arr2 = @challenge_persistent_array.set_at(arr, 1, 10)
  inspect(@challenge_persistent_array.get_at(arr, 1), content="Some(2)")
  inspect(@challenge_persistent_array.get_at(arr2, 1), content="Some(10)")
  inspect(@challenge_persistent_array.to_array(arr2), content="[1, 10, 3, 4]")
  inspect(@challenge_persistent_array.length(arr2), content="4")
}
```

### Multiple versions

```mbt check
///|
test "persistent array versions" {
  let arr0 = @challenge_persistent_array.from_array([5, 6, 7])
  let arr1 = @challenge_persistent_array.set_at(arr0, 0, 9)
  let arr2 = @challenge_persistent_array.set_at(arr1, 2, 1)
  inspect(@challenge_persistent_array.to_array(arr0), content="[5, 6, 7]")
  inspect(@challenge_persistent_array.to_array(arr1), content="[9, 6, 7]")
  inspect(@challenge_persistent_array.to_array(arr2), content="[9, 6, 1]")
}
```

### Out-of-range access and update

```mbt check
///|
test "persistent array bounds" {
  let arr = @challenge_persistent_array.from_array([1, 2, 3])
  inspect(@challenge_persistent_array.get_at(arr, -1), content="None")
  inspect(@challenge_persistent_array.get_at(arr, 3), content="None")
  let arr2 = @challenge_persistent_array.set_at(arr, 99, 10)
  inspect(@challenge_persistent_array.to_array(arr2), content="[1, 2, 3]")
}
```

---

## Complexity

Let `n = length`:

- `get_at`: `O(log n)`
- `set_at`: `O(log n)` time, `O(log n)` extra memory
- `to_array`: `O(n log n)` (it calls `get_at` for each index)

---

## Takeaways

- Persistence means old versions remain valid forever.
- Path copying makes updates cheap and safe.
- This structure is great for time-traveling or undo features.
