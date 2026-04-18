# Challenge: Persistent Skew Heap

A **skew heap** is a meldable heap (priority queue) that supports fast merging.
This version is **persistent**: every operation returns a new heap, while older
versions remain usable.

The operations you get:

- `empty()`
- `insert(h, value)`
- `find_min(h)`
- `delete_min(h)`
- `merge(a, b)`
- `from_array(arr)`
- `size(h)`

---

## What problem does it solve?

When you need a priority queue and also want to **merge** two queues often, a
skew heap is a great choice. Examples:

- Merging event streams
- Combining search frontiers
- Branching states where every branch keeps its own heap history

Because this heap is **persistent**, you can keep every version and reuse them
later.

---

## Core idea: meld by swapping subtrees

A skew heap only needs one core operation: **merge**.

Given two heaps, the root with smaller value becomes the new root. Then we
merge the other heap with its right child, and finally **swap children** to keep
it balanced in practice.

Pseudocode (min-heap):

```
merge(a, b):
  if a is empty: return b
  if b is empty: return a
  if a.root <= b.root:
    a.right = merge(a.right, b)
    swap(a.left, a.right)
    return a
  else:
    b.right = merge(a, b.right)
    swap(b.left, b.right)
    return b
```

Because this is persistent, we copy nodes along the merge path instead of
modifying in-place.

---

## Visual intuition

Merging two heaps keeps the smaller root and pushes the other heap down:

```
Heap A:            Heap B:
   2                 5
  / \               / \
 4   7             6   9

merge(A, B) -> root 2
  merge(A.right, B)  then swap children
```

The subtree swaps keep the structure from degrading too far in practice. The
amortized complexity stays good even though the tree is not strictly balanced.

---

## Persistence (path copying)

Every insert or delete is really just a merge. We create new nodes along the
merge path and reuse everything else.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     merge path      B'  C
  / \                      / \
 D   E                    D   E
```

Only `A'` and `B'` are new nodes; the rest is shared.

---

## API summary

- `merge(a, b)` returns a heap that contains all elements from both
- `insert(h, x)` is `merge(h, singleton(x))`
- `find_min(h)` reads the root value
- `delete_min(h)` removes the root and merges its children
- `from_array(arr)` inserts elements in order using `fold`

---

## Example 1: Insert, find, and delete

```mbt check
///|
test "skew heap basic" {
  let h0 = @challenge_persistent_skew_heap.empty()
  let h1 = @challenge_persistent_skew_heap.insert(h0, 4)
  let h2 = @challenge_persistent_skew_heap.insert(h1, 1)
  let h3 = @challenge_persistent_skew_heap.insert(h2, 6)
  inspect(@challenge_persistent_skew_heap.find_min(h3), content="Some(1)")
  guard @challenge_persistent_skew_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_skew_heap.find_min(h4), content="Some(4)")
  inspect(@challenge_persistent_skew_heap.size(h4), content="2")
}
```

### What happened to the heap?

After inserting `[4, 1, 6]`, the minimum is `1`. Deleting the minimum removes
that root and melds its children. The new min becomes `4`.

---

## Example 2: Merging two heaps

```mbt check
///|
test "skew heap merge" {
  let a = @challenge_persistent_skew_heap.from_array([7, 2, 5])
  let b = @challenge_persistent_skew_heap.from_array([4, 1, 9])
  let merged = @challenge_persistent_skew_heap.merge(a, b)
  inspect(@challenge_persistent_skew_heap.find_min(a), content="Some(2)")
  inspect(@challenge_persistent_skew_heap.find_min(b), content="Some(1)")
  inspect(@challenge_persistent_skew_heap.find_min(merged), content="Some(1)")
  inspect(@challenge_persistent_skew_heap.size(merged), content="6")
}
```

Notice that `a` and `b` are unchanged, because `merge` is persistent.

---

## Example 3: Building from array

```mbt check
///|
test "skew heap from array" {
  let h = @challenge_persistent_skew_heap.from_array([7, 1, 5])
  inspect(@challenge_persistent_skew_heap.find_min(h), content="Some(1)")
  inspect(@challenge_persistent_skew_heap.size(h), content="3")
}
```

---

## Complexity

Skew heaps do not guarantee strict balance, but they provide good amortized
performance:

- `merge`: `O(log n)` amortized
- `insert`: `O(log n)` amortized (because it is a merge)
- `delete_min`: `O(log n)` amortized (merge of two subtrees)
- `find_min`: `O(1)`

---

## When to use this structure

Use this package when you need:

- a **meldable** heap (fast merges)
- **persistence** (keep older versions)
- simple, elegant implementation without explicit balancing

If you do not need merging, a binary heap might be simpler. If you need strict
worst-case guarantees, consider a binomial heap or pairing heap.

---

## Reference implementation

```mbt nocheck
///| pub fn empty[T]() -> Heap[T]

///| pub fn size[T](h : Heap[T]) -> Int

///| pub fn merge[T : Compare](a : Heap[T], b : Heap[T]) -> Heap[T]

///| pub fn insert[T : Compare](h : Heap[T], value : T) -> Heap[T]

///| pub fn find_min[T](h : Heap[T]) -> T?

///| pub fn delete_min[T : Compare](h : Heap[T]) -> Heap[T]?

///| pub fn from_array[T : Compare](arr : ArrayView[T]) -> Heap[T]
```
