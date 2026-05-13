// ============================================================================
// Challenge: Persistent Pairing Heap
// Pairwise merging of subheaps after delete-min
// ============================================================================

///|
enum ChildList[T] {
  Nil
  Cons(head~ : Heap[T], tail~ : ChildList[T])
} derive(Debug)

///|
/// Persistent pairing min-heap.
///
/// A multiway tree where each node holds a `value` smaller than every
/// value in its `children` list. `merge` makes the heap with the
/// larger root a new child of the other in `O(1)`, so `insert` (merge
/// with a singleton) is `O(1)` as well. `delete_min` removes the root
/// and merges its children with a two-pass pairing strategy
/// (`merge_pairs_list` then `merge_all`), giving `O(log n)` amortized
/// time. `find_min` is `O(1)`. All operations are persistent: nodes
/// are never mutated; new heaps share substructure with the old ones.
/// See `empty` and `size`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let h : @challenge_persistent_pairing_heap.Heap[Int] = @challenge_persistent_pairing_heap.empty()
///   let h = @challenge_persistent_pairing_heap.insert(h, 8)
///   let h = @challenge_persistent_pairing_heap.insert(h, 3)
///   let h = @challenge_persistent_pairing_heap.insert(h, 6)
///   debug_inspect(
///     @challenge_persistent_pairing_heap.find_min(h),
///     content="Some(3)",
///   )
/// }
/// ```
pub enum Heap[T] {
  Empty
  Node(value~ : T, children~ : ChildList[T])
} derive(Debug)

///|
fn[T] heap_size(h : Heap[T]) -> Int {
  match h {
    Empty => 0
    Node(value=_, children~) => 1 + children_size(children)
  }
}

///|
fn[T] children_size(children : ChildList[T]) -> Int {
  match children {
    Nil => 0
    Cons(head~, tail~) => heap_size(head) + children_size(tail)
  }
}

///|

///|
/// Create an empty pairing heap.
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
    (Node(value=va, children=ca), Node(value=vb, children=cb)) =>
      if va <= vb {
        Node(value=va, children=Cons(head=b, tail=ca))
      } else {
        Node(value=vb, children=Cons(head=a, tail=cb))
      }
  }
}

///|
fn[T] singleton(value : T) -> Heap[T] {
  Node(value~, children=Nil)
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
    Node(value~, children=_) => Some(value)
  }
}

///|
fn[T : Compare] merge_pairs(children : ChildList[T]) -> Heap[T] {
  let pairs = merge_pairs_list(children)
  merge_all(pairs)
}

///|
fn[T : Compare] merge_pairs_list(children : ChildList[T]) -> ChildList[T] {
  match children {
    Nil => Nil
    Cons(head~, tail~) =>
      match tail {
        Nil => Cons(head~, tail=Nil)
        Cons(head=second, tail=rest) =>
          Cons(head=merge(head, second), tail=merge_pairs_list(rest))
      }
  }
}

///|
fn[T : Compare] merge_all(children : ChildList[T]) -> Heap[T] {
  match children {
    Nil => Empty
    Cons(head~, tail~) => merge(head, merge_all(tail))
  }
}

///|
/// Delete the minimum element and return the new heap.
pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]? {
  match h {
    Empty => None
    Node(value=_, children~) => Some(merge_pairs(children))
  }
}

///|
test "persistent_pairing_heap" {
  let h0 : Heap[Int] = Empty
  let h1 = insert(h0, 8)
  let h2 = insert(h1, 3)
  let h3 = insert(h2, 6)
  debug_inspect(find_min(h3), content="Some(3)")
  guard delete_min(h3) is Some(h4) else { fail("expected delete_min") }
  debug_inspect(find_min(h4), content="Some(6)")
}
