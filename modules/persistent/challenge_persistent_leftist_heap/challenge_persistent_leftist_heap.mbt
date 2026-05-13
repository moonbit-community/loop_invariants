// ============================================================================
// Challenge: Persistent Leftist Heap
// Meldable priority queue with rank (null-path length)
// ============================================================================

///|
/// Persistent leftist min-heap.
///
/// Each node stores a `value`, its left/right children, and a `rank`
/// (null-path length to the nearest empty descendant). The leftist
/// invariant — left rank greater than or equal to right rank —
/// guarantees that the right spine has length `O(log n)`, so `merge`
/// runs in `O(log n)` time by recursing down the smaller right
/// spines. `insert` and `delete_min` are defined in terms of `merge`,
/// each also `O(log n)`. `find_min` is `O(1)`. Updates are persistent:
/// merging copies only spine nodes and reuses the rest. See `empty`,
/// `size`, `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let h = @challenge_persistent_leftist_heap.from_array([5, 3, 7, 1])
///   inspect(@challenge_persistent_leftist_heap.find_min(h), content="Some(1)")
/// }
/// ```
pub enum Heap[T] {
  Empty
  Node(value~ : T, rank~ : Int, left~ : Heap[T], right~ : Heap[T])
} derive(Debug)

///|
fn[T] rank(h : Heap[T]) -> Int {
  match h {
    Empty => 0
    Node(value=_, rank~, left=_, right=_) => rank
  }
}

///|
fn[T] heap_size(h : Heap[T]) -> Int {
  match h {
    Empty => 0
    Node(value=_, rank=_, left~, right~) =>
      1 + heap_size(left) + heap_size(right)
  }
}

///|

///|
fn[T] make_node(value : T, left : Heap[T], right : Heap[T]) -> Heap[T] {
  let left_rank = rank(left)
  let right_rank = rank(right)
  if left_rank < right_rank {
    Node(value~, rank=left_rank + 1, left=right, right=left)
  } else {
    Node(value~, rank=right_rank + 1, left~, right~)
  }
}

///|
/// Create an empty leftist heap.
pub fn[T] empty() -> Heap[T] {
  Empty
}

///|
/// Return number of elements in the heap.
pub fn[T] size(h : Heap[T]) -> Int {
  heap_size(h)
}

///|
/// Merge two heaps and return the result.
pub fn[T : Compare] merge(a : Heap[T], b : Heap[T]) -> Heap[T] {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    (
      Node(value=va, rank=_, left=la, right=ra),
      Node(value=vb, rank=_, left=lb, right=rb),
    ) =>
      if va <= vb {
        let merged = merge(ra, b)
        make_node(va, la, merged)
      } else {
        let merged = merge(a, rb)
        make_node(vb, lb, merged)
      }
  }
}

///|
fn[T] singleton(value : T) -> Heap[T] {
  Node(value~, rank=1, left=Empty, right=Empty)
}

///|
/// Insert a value and return the new heap.
pub fn[T : Compare] insert(h : Heap[T], value : T) -> Heap[T] {
  merge(h, singleton(value))
}

///|
/// Return the minimum value, or None if empty.
pub fn[T] find_min(h : Heap[T]) -> T? {
  match h {
    Empty => None
    Node(value~, rank=_, left=_, right=_) => Some(value)
  }
}

///|
/// Delete the minimum element and return the new heap.
pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]? {
  match h {
    Empty => None
    Node(value=_, rank=_, left~, right~) => Some(merge(left, right))
  }
}

///|
/// Build a heap by inserting elements in sequence.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Heap[T] {
  for value in arr; heap = Empty {
    continue insert(heap, value)
  } nobreak {
    heap
  }
}

///|
test "persistent_leftist_heap" {
  let h0 : Heap[Int] = Empty
  let h1 = insert(h0, 5)
  let h2 = insert(h1, 3)
  let h3 = insert(h2, 7)
  debug_inspect(find_min(h3), content="Some(3)")
  guard delete_min(h3) is Some(h4) else { fail("expected delete_min") }
  debug_inspect(find_min(h4), content="Some(5)")
  let built = from_array([5, 3, 7, 1])
  debug_inspect(find_min(built), content="Some(1)")
}
