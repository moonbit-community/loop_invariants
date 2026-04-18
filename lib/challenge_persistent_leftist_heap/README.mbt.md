# Challenge: Persistent Leftist Heap

A **leftist heap** is a mergeable priority queue that supports fast meld
operations. This implementation is **persistent**, so every operation returns a
new heap while old versions remain valid.

This package provides:

- `empty()` to create a heap
- `merge(a, b)` to meld two heaps
- `insert(h, value)` to insert a value
- `find_min(h)` to read the minimum
- `delete_min(h)` to remove the minimum
- `from_array(arr)` to build by repeated inserts
- `size(h)` to count elements

---

## Leftist heap property

A leftist heap is a binary tree with two invariants:

1) **Heap order**: parent value <= child values
2) **Leftist order**: the rank (null-path length) of the left child is
   >= the rank of the right child

The **rank** of a node is the length of the shortest path to an empty child.

This structure makes merging efficient.

---

## Why merge is fast

To merge two heaps:

1) Compare the roots (smaller root stays on top)
2) Recursively merge the right child of the smaller root with the other heap
3) Swap children if needed to preserve leftist order

This works because the **right spine is short** (by the leftist property).

---

## Persistence (path copying)

Merge and insert create new nodes along the path that changes; all other nodes
are shared with old versions.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert x       B'  C
  / \                      / \
 D   E                    D   E
```

---

## Worked example

Insert values `5, 3, 7, 1`:

- Insert 5: heap root is 5
- Insert 3: merge with {3} -> root becomes 3
- Insert 7: 7 goes into the right path
- Insert 1: root becomes 1

The heap always keeps the smallest element at the root.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Heap[T]

///| pub fn[T : Compare] merge(a : Heap[T], b : Heap[T]) -> Heap[T]

///| pub fn[T : Compare] insert(h : Heap[T], value : T) -> Heap[T]

///| pub fn[T] find_min(h : Heap[T]) -> T?

///| pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]?

///| pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Heap[T]

///| pub fn[T] size(h : Heap[T]) -> Int
```

---

## Tests and examples

### Basic insertion and delete

```mbt check
///|
test "leftist heap basic" {
  let h0 = @challenge_persistent_leftist_heap.empty()
  let h1 = @challenge_persistent_leftist_heap.insert(h0, 5)
  let h2 = @challenge_persistent_leftist_heap.insert(h1, 3)
  let h3 = @challenge_persistent_leftist_heap.insert(h2, 7)
  inspect(@challenge_persistent_leftist_heap.find_min(h3), content="Some(3)")
  guard @challenge_persistent_leftist_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_leftist_heap.find_min(h4), content="Some(5)")
}
```

### Merge two heaps

```mbt check
///|
test "leftist heap merge" {
  let a = @challenge_persistent_leftist_heap.from_array([4, 8])
  let b = @challenge_persistent_leftist_heap.from_array([1, 6])
  let merged = @challenge_persistent_leftist_heap.merge(a, b)
  inspect(
    @challenge_persistent_leftist_heap.find_min(merged),
    content="Some(1)",
  )
  inspect(@challenge_persistent_leftist_heap.size(merged), content="4")
}
```

### Persistence across versions

```mbt check
///|
test "leftist heap persistence" {
  let h0 = @challenge_persistent_leftist_heap.empty()
  let h1 = @challenge_persistent_leftist_heap.insert(h0, 10)
  let h2 = @challenge_persistent_leftist_heap.insert(h1, 2)
  inspect(@challenge_persistent_leftist_heap.find_min(h0), content="None")
  inspect(@challenge_persistent_leftist_heap.find_min(h1), content="Some(10)")
  inspect(@challenge_persistent_leftist_heap.find_min(h2), content="Some(2)")
}
```

---

## Complexity

Let `n` be the number of elements.

- `merge`: `O(log n)`
- `insert`: `O(log n)` (merge with singleton)
- `find_min`: `O(1)`
- `delete_min`: `O(log n)`

---

## Takeaways

- Leftist heaps make merging fast by keeping the right spine short.
- Persistence keeps all previous versions intact.
- Insert and delete are implemented via merge.
