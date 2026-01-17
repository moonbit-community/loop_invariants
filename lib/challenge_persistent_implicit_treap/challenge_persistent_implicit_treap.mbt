// ============================================================================
// Challenge: Persistent Implicit Treap
// Sequence treap indexed by subtree sizes
// ============================================================================

///|
pub enum Treap[T] {
  Empty
  Node(
    value~ : T,
    priority~ : Int,
    size~ : Int,
    left~ : Treap[T],
    right~ : Treap[T]
  )
} derive(Show)

///|
/// Return the number of elements in the treap.
pub fn[T] size(t : Treap[T]) -> Int {
  match t {
    Treap::Empty => 0
    Treap::Node(value=_, priority=_, size~, left=_, right=_) => size
  }
}

///|

///|
fn[T : Hash] priority_for(value : T, salt : Int) -> Int {
  value.hash() + salt * 12345
}

///|
fn[T] make_node(
  value : T,
  priority : Int,
  left : Treap[T],
  right : Treap[T],
) -> Treap[T] {
  let sz = 1 + size(left) + size(right)
  Treap::Node(value~, priority~, size=sz, left~, right~)
}

///|
/// Create an empty implicit treap.
pub fn[T] empty() -> Treap[T] {
  Treap::Empty
}

///|
/// Split by position k into (prefix, suffix).
pub fn[T] split(t : Treap[T], k : Int) -> (Treap[T], Treap[T]) {
  match t {
    Treap::Empty => (Treap::Empty, Treap::Empty)
    Treap::Node(value=v, priority=p, size=_, left=l, right=r) => {
      let left_size = size(l)
      if k <= left_size {
        let (l1, l2) = split(l, k)
        (l1, make_node(v, p, l2, r))
      } else {
        let (r1, r2) = split(r, k - left_size - 1)
        (make_node(v, p, l, r1), r2)
      }
    }
  }
}

///|
/// Merge two treaps assuming all elements in a precede b.
pub fn[T] merge(a : Treap[T], b : Treap[T]) -> Treap[T] {
  match (a, b) {
    (Treap::Empty, _) => b
    (_, Treap::Empty) => a
    (
      Treap::Node(value=va, priority=pa, size=_, left=la, right=ra),
      Treap::Node(value=vb, priority=pb, size=_, left=lb, right=rb),
    ) =>
      if pa >= pb {
        make_node(va, pa, la, merge(ra, b))
      } else {
        make_node(vb, pb, merge(a, lb), rb)
      }
  }
}

///|
/// Insert a value at index idx and return the new treap.
pub fn[T : Hash] insert_at(t : Treap[T], idx : Int, value : T) -> Treap[T] {
  let (l, r) = split(t, idx)
  let node = make_node(
    value,
    priority_for(value, idx),
    Treap::Empty,
    Treap::Empty,
  )
  merge(merge(l, node), r)
}

///|
/// Get the value at index idx, or None if out of range.
pub fn[T] get(t : Treap[T], idx : Int) -> T? {
  match t {
    Treap::Empty => None
    Treap::Node(value=v, priority=_, size=_, left=l, right=r) => {
      let left_size = size(l)
      if idx == left_size {
        Some(v)
      } else if idx < left_size {
        get(l, idx)
      } else {
        get(r, idx - left_size - 1)
      }
    }
  }
}

///|
/// Convert the treap into an array in order.
pub fn[T] to_array(t : Treap[T]) -> Array[T] {
  match t {
    Treap::Empty => []
    Treap::Node(value=v, priority=_, size=_, left=l, right=r) =>
      to_array(l) + [v] + to_array(r)
  }
}

///|
/// Build a treap by appending elements in order.
pub fn[T : Hash] from_array(arr : ArrayView[T]) -> Treap[T] {
  let mut tree = Treap::Empty
  let mut idx = 0
  for value in arr {
    tree = insert_at(tree, idx, value)
    idx = idx + 1
  }
  tree
}

///|
test "persistent_implicit_treap" {
  let t0 : Treap[Int] = Treap::Empty
  let t1 = insert_at(t0, 0, 10)
  let t2 = insert_at(t1, 1, 20)
  let t3 = insert_at(t2, 1, 15)
  assert_eq(to_array(t3), [10, 15, 20])
  assert_eq(get(t3, 2), Some(20))
  let built = from_array([1, 2, 3][:])
  assert_eq(to_array(built), [1, 2, 3])
}
