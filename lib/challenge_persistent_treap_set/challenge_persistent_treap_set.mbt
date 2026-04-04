// ============================================================================
// Challenge: Persistent Treap (Set)
// Random-priority BST with immutable insertions
// ============================================================================

///|
pub enum Treap[T] {
  Empty
  Node(
    key~ : T,
    priority~ : Int,
    size~ : Int,
    left~ : Treap[T],
    right~ : Treap[T]
  )
} derive(Debug)

///|
/// Return the number of keys in the treap.
pub fn[T] size(t : Treap[T]) -> Int {
  match t {
    Empty => 0
    Node(key=_, priority=_, size~, left=_, right=_) => size
  }
}

///|

///|
fn[T : Hash] priority_for(key : T) -> Int {
  key.hash()
}

///|
fn[T] make_node(
  key : T,
  priority : Int,
  left : Treap[T],
  right : Treap[T],
) -> Treap[T] {
  let sz = 1 + size(left) + size(right)
  Node(key~, priority~, size=sz, left~, right~)
}

///|
/// Create an empty treap.
pub fn[T] empty() -> Treap[T] {
  Empty
}

///|
/// Split the treap into (< key) and (>= key).
pub fn[T : Compare] split(t : Treap[T], key : T) -> (Treap[T], Treap[T]) {
  match t {
    Empty => (Empty, Empty)
    Node(key=k, priority=p, size=_, left=l, right=r) =>
      if key <= k {
        let (l1, l2) = split(l, key)
        (l1, make_node(k, p, l2, r))
      } else {
        let (r1, r2) = split(r, key)
        (make_node(k, p, l, r1), r2)
      }
  }
}

///|
/// Merge two treaps assuming all keys in a are < keys in b.
pub fn[T] merge(a : Treap[T], b : Treap[T]) -> Treap[T] {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    (
      Node(key=ka, priority=pa, size=_, left=la, right=ra),
      Node(key=kb, priority=pb, size=_, left=lb, right=rb),
    ) =>
      if pa >= pb {
        make_node(ka, pa, la, merge(ra, b))
      } else {
        make_node(kb, pb, merge(a, lb), rb)
      }
  }
}

///|
/// Check whether key exists in the treap.
pub fn[T : Compare] contains(t : Treap[T], key : T) -> Bool {
  match t {
    Empty => false
    Node(key=k, priority=_, size=_, left=l, right=r) =>
      if key == k {
        true
      } else if key < k {
        contains(l, key)
      } else {
        contains(r, key)
      }
  }
}

///|
/// Insert key and return the new treap (no duplicates).
pub fn[T : Compare + Hash] insert(t : Treap[T], key : T) -> Treap[T] {
  if contains(t, key) {
    t
  } else {
    let (l, r) = split(t, key)
    let node = make_node(key, priority_for(key), Empty, Empty)
    merge(merge(l, node), r)
  }
}

///|
/// Build a treap by inserting elements in order.
pub fn[T : Compare + Hash] from_array(arr : ArrayView[T]) -> Treap[T] {
  arr.fold(init=Empty, (tree, key) => insert(tree, key))
}
