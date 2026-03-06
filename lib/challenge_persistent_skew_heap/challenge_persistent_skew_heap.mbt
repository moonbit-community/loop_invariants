// ============================================================================
// Challenge: Persistent Skew Heap
// Self-adjusting meldable heap with subtree swaps
// ============================================================================

///|
pub enum Heap[T] {
  Empty
  Node(value~ : T, left~ : Heap[T], right~ : Heap[T])
} derive(Show)

///|
fn[T] heap_size(h : Heap[T]) -> Int {
  match h {
    Empty => 0
    Node(value=_, left~, right~) => 1 + heap_size(left) + heap_size(right)
  }
}

///|

///|
/// Create an empty skew heap.
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
    (Node(value=va, left=la, right=ra), Node(value=vb, left=lb, right=rb)) =>
      if va <= vb {
        let merged = merge(ra, b)
        Node(value=va, left=merged, right=la)
      } else {
        let merged = merge(a, rb)
        Node(value=vb, left=merged, right=lb)
      }
  }
}

///|
fn[T] singleton(value : T) -> Heap[T] {
  Node(value~, left=Empty, right=Empty)
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
    Node(value~, left=_, right=_) => Some(value)
  }
}

///|
/// Delete the minimum element and return the new heap.
pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]? {
  match h {
    Empty => None
    Node(value=_, left~, right~) => Some(merge(left, right))
  }
}

///|
/// Build a skew heap by inserting elements in sequence.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Heap[T] {
  arr.fold(init=Empty, (heap, value) => insert(heap, value))
}
