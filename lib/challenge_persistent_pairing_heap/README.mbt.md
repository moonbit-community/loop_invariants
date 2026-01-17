# Challenge: Persistent Pairing Heap

A **pairing heap** is a meldable priority queue. It supports fast merge and
amortized efficient operations. This implementation is **persistent**, so each
operation returns a new heap and old versions remain valid.

This package provides:

- `empty()` to create a heap
- `merge(a, b)` to meld two heaps
- `insert(h, value)` to add a value
- `find_min(h)` to read the minimum
- `delete_min(h)` to remove the minimum
- `size(h)` to count elements

---

## Pairing heap structure

A pairing heap is a tree:

- The root stores the minimum value.
- Each node has a list of children.
- Heap order: parent value <= child values.

In this implementation, the children are stored as an immutable list.

---

## Merge operation

To merge two heaps:

- Compare roots, keep the smaller one as root.
- Attach the other heap as a **new child** of the smaller root.

This is `O(1)`.

---

## Delete-min (pairwise merging)

To remove the minimum:

1) Remove the root.
2) Pair up the root's children and merge each pair.
3) Merge all resulting heaps into one.

This is where the name **pairing** heap comes from.

---

## Persistence

All heaps are immutable. Merging or inserting creates new nodes that share
existing subtrees where possible.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert x       B'  C
  / \                      / \
 D   E                    D   E
```

---

## Reference implementation

```mbt
///| pub fn[T] empty() -> Heap[T]

///| pub fn[T : Compare] merge(a : Heap[T], b : Heap[T]) -> Heap[T]

///| pub fn[T : Compare] insert(h : Heap[T], value : T) -> Heap[T]

///| pub fn[T] find_min(h : Heap[T]) -> T?

///| pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]?

///| pub fn[T] size(h : Heap[T]) -> Int
```

---

## Tests and examples

### Basic operations

```mbt check
///|
test "pairing heap basic" {
  let h0 = @challenge_persistent_pairing_heap.empty()
  let h1 = @challenge_persistent_pairing_heap.insert(h0, 8)
  let h2 = @challenge_persistent_pairing_heap.insert(h1, 3)
  let h3 = @challenge_persistent_pairing_heap.insert(h2, 6)
  inspect(@challenge_persistent_pairing_heap.find_min(h3), content="Some(3)")
  guard @challenge_persistent_pairing_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_pairing_heap.find_min(h4), content="Some(6)")
}
```

### Merge two heaps

```mbt check
///|
test "pairing heap merge" {
  let a = @challenge_persistent_pairing_heap.insert(
    @challenge_persistent_pairing_heap.empty(),
    4,
  )
  let b = @challenge_persistent_pairing_heap.insert(
    @challenge_persistent_pairing_heap.empty(),
    1,
  )
  let merged = @challenge_persistent_pairing_heap.merge(a, b)
  inspect(
    @challenge_persistent_pairing_heap.find_min(merged),
    content="Some(1)",
  )
}
```

### Persistence across versions

```mbt check
///|
test "pairing heap persistence" {
  let h0 = @challenge_persistent_pairing_heap.empty()
  let h1 = @challenge_persistent_pairing_heap.insert(h0, 10)
  let h2 = @challenge_persistent_pairing_heap.insert(h1, 2)
  inspect(@challenge_persistent_pairing_heap.find_min(h0), content="None")
  inspect(@challenge_persistent_pairing_heap.find_min(h1), content="Some(10)")
  inspect(@challenge_persistent_pairing_heap.find_min(h2), content="Some(2)")
}
```

---

## Complexity

Pairing heaps have good amortized performance:

- `merge`: `O(1)`
- `insert`: `O(1)` (merge with singleton)
- `find_min`: `O(1)`
- `delete_min`: amortized `O(log n)`

---

## Takeaways

- Pairing heaps are simple and efficient meldable priority queues.
- Persistence keeps all previous versions intact.
- Delete-min uses pairwise merging of child heaps.
