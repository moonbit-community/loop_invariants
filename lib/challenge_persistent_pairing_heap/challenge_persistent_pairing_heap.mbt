// ============================================================================
// Challenge: Persistent Pairing Heap
// Pairwise merging of subheaps after delete-min
// ============================================================================

///|
enum ChildList[T] {
  Nil
  Cons(head~ : Heap[T], tail~ : ChildList[T])
} derive(Show)

///|
pub enum Heap[T] {
  Empty
  Node(value~ : T, children~ : ChildList[T])
} derive(Show)

///|
fn[T] heap_size(h : Heap[T]) -> Int {
  match h {
    Heap::Empty => 0
    Heap::Node(value=_, children~) => 1 + children_size(children)
  }
}

///|
fn[T] children_size(children : ChildList[T]) -> Int {
  match children {
    ChildList::Nil => 0
    ChildList::Cons(head~, tail~) => heap_size(head) + children_size(tail)
  }
}

///|

///|
/// Create an empty pairing heap.
pub fn[T] empty() -> Heap[T] {
  Heap::Empty
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
    (Heap::Empty, _) => b
    (_, Heap::Empty) => a
    (Heap::Node(value=va, children=ca), Heap::Node(value=vb, children=cb)) =>
      if va <= vb {
        Heap::Node(value=va, children=ChildList::Cons(head=b, tail=ca))
      } else {
        Heap::Node(value=vb, children=ChildList::Cons(head=a, tail=cb))
      }
  }
}

///|
fn[T] singleton(value : T) -> Heap[T] {
  Heap::Node(value~, children=ChildList::Nil)
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
    Heap::Empty => None
    Heap::Node(value~, children=_) => Some(value)
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
    ChildList::Nil => ChildList::Nil
    ChildList::Cons(head~, tail~) =>
      match tail {
        ChildList::Nil => ChildList::Cons(head~, tail=ChildList::Nil)
        ChildList::Cons(head=second, tail=rest) =>
          ChildList::Cons(head=merge(head, second), tail=merge_pairs_list(rest))
      }
  }
}

///|
fn[T : Compare] merge_all(children : ChildList[T]) -> Heap[T] {
  match children {
    ChildList::Nil => Heap::Empty
    ChildList::Cons(head~, tail~) => merge(head, merge_all(tail))
  }
}

///|
/// Delete the minimum element and return the new heap.
pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]? {
  match h {
    Heap::Empty => None
    Heap::Node(value=_, children~) => Some(merge_pairs(children))
  }
}

///|
test "persistent_pairing_heap" {
  let h0 : Heap[Int] = Heap::Empty
  let h1 = insert(h0, 8)
  let h2 = insert(h1, 3)
  let h3 = insert(h2, 6)
  assert_eq(find_min(h3), Some(3))
  guard delete_min(h3) is Some(h4) else { fail("expected delete_min") }
  assert_eq(find_min(h4), Some(6))
}
