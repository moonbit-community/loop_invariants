// ============================================================================
// Challenge: Persistent Skew Heap
// Self-adjusting meldable heap with subtree swaps
// ============================================================================

///|
enum Heap {
  Empty
  Node(value~ : Int, left~ : Heap, right~ : Heap)
} derive(Show)

///|
fn heap_size(h : Heap) -> Int {
  match h {
    Heap::Empty => 0
    Heap::Node(value=_, left~, right~) => 1 + heap_size(left) + heap_size(right)
  }
}

///|
fn heap_valid(h : Heap) -> Bool {
  match h {
    Heap::Empty => true
    Heap::Node(value~, left~, right~) => {
      let left_ok = match left {
        Heap::Empty => true
        Heap::Node(value=v, left=_, right=_) => value <= v
      }
      let right_ok = match right {
        Heap::Empty => true
        Heap::Node(value=v, left=_, right=_) => value <= v
      }
      left_ok && right_ok && heap_valid(left) && heap_valid(right)
    }
  }
}

///|
fn merge(a : Heap, b : Heap) -> Heap {
  match (a, b) {
    (Heap::Empty, _) => b
    (_, Heap::Empty) => a
    (
      Heap::Node(value=va, left=la, right=ra),
      Heap::Node(value=vb, left=lb, right=rb),
    ) =>
      if va <= vb {
        let merged = merge(ra, b)
        Heap::Node(value=va, left=merged, right=la)
      } else {
        let merged = merge(a, rb)
        Heap::Node(value=vb, left=merged, right=lb)
      }
  }
}

///|
fn singleton(value : Int) -> Heap {
  Heap::Node(value~, left=Heap::Empty, right=Heap::Empty)
}

///|
fn insert(h : Heap, value : Int) -> Heap {
  merge(h, singleton(value))
}

///|
fn find_min(h : Heap) -> Int? {
  match h {
    Heap::Empty => None
    Heap::Node(value~, left=_, right=_) => Some(value)
  }
}

///|
fn delete_min(h : Heap) -> Heap? {
  match h {
    Heap::Empty => None
    Heap::Node(value=_, left~, right~) => Some(merge(left, right))
  }
}

///|
/// Build a skew heap by inserting elements in sequence.
#warnings("+missing_invariant+missing_reasoning")
fn from_array(arr : ArrayView[Int]) -> Heap {
  let n = arr.length()
  for i = 0, heap = Heap::Empty {
    if i >= n {
      break heap
    } else {
      continue i + 1, insert(heap, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: heap_size(heap) == i,
    invariant: heap_valid(heap),
    reasoning: (
      #|INVARIANT (Skew heap build):
      #|heap holds the first i elements and satisfies the min-heap order.
      #|MAINTENANCE:
      #|Melding in arr[i] preserves heap order and increases size by one.
      #|TERMINATION:
      #|At i = n, all elements are present in the heap.
    ),
  }
}

///|
test "persistent_skew_heap" {
  let h0 = Heap::Empty
  let h1 = insert(h0, 4)
  let h2 = insert(h1, 1)
  let h3 = insert(h2, 6)
  assert_eq(find_min(h3), Some(1))
  guard delete_min(h3) is Some(h4) else { fail("expected delete_min") }
  assert_eq(find_min(h4), Some(4))
  let built = from_array([4, 1, 6, 2][:])
  assert_eq(find_min(built), Some(1))
}
