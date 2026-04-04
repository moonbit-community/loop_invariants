// ============================================================================
// Challenge: Persistent Treap (Map)
// Key-value treap with immutable updates and bounded search
// ============================================================================

///|
pub enum TreapMap[K, V] {
  Empty
  Node(
    key~ : K,
    value~ : V,
    priority~ : Int,
    size~ : Int,
    left~ : TreapMap[K, V],
    right~ : TreapMap[K, V]
  )
} derive(Debug)

///|
/// Return the number of entries in the map.
pub fn[K, V] size(t : TreapMap[K, V]) -> Int {
  match t {
    Empty => 0
    Node(key=_, value=_, priority=_, size~, left=_, right=_) => size
  }
}

///|

///|
fn[K : Hash] priority_for(key : K) -> Int {
  key.hash()
}

///|
fn[K, V] make_node(
  key : K,
  value : V,
  priority : Int,
  left : TreapMap[K, V],
  right : TreapMap[K, V],
) -> TreapMap[K, V] {
  let sz = 1 + size(left) + size(right)
  Node(key~, value~, priority~, size=sz, left~, right~)
}

///|
/// Create an empty treap map.
pub fn[K, V] empty() -> TreapMap[K, V] {
  Empty
}

///|
/// Split the map into (< key) and (>= key).
pub fn[K : Compare, V] split(
  t : TreapMap[K, V],
  key : K,
) -> (TreapMap[K, V], TreapMap[K, V]) {
  match t {
    Empty => (Empty, Empty)
    Node(key=k, value=v, priority=p, size=_, left=l, right=r) =>
      if key <= k {
        let (l1, l2) = split(l, key)
        (l1, make_node(k, v, p, l2, r))
      } else {
        let (r1, r2) = split(r, key)
        (make_node(k, v, p, l, r1), r2)
      }
  }
}

///|
/// Merge two maps assuming all keys in a are < keys in b.
pub fn[K, V] merge(a : TreapMap[K, V], b : TreapMap[K, V]) -> TreapMap[K, V] {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    (
      Node(key=ka, value=va, priority=pa, size=_, left=la, right=ra),
      Node(key=kb, value=vb, priority=pb, size=_, left=lb, right=rb),
    ) =>
      if pa >= pb {
        make_node(ka, va, pa, la, merge(ra, b))
      } else {
        make_node(kb, vb, pb, merge(a, lb), rb)
      }
  }
}

///|
/// Check whether key exists in the map.
pub fn[K : Compare, V] contains(t : TreapMap[K, V], key : K) -> Bool {
  match t {
    Empty => false
    Node(key=k, value=_, priority=_, size=_, left=l, right=r) =>
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
fn[K : Compare, V] update_value(
  t : TreapMap[K, V],
  key : K,
  value : V,
) -> TreapMap[K, V] {
  match t {
    Empty => Empty
    Node(key=k, value=v, priority=p, size=_, left=l, right=r) =>
      if key == k {
        make_node(k, value, p, l, r)
      } else if key < k {
        make_node(k, v, p, update_value(l, key, value), r)
      } else {
        make_node(k, v, p, l, update_value(r, key, value))
      }
  }
}

///|
/// Insert or update a key/value pair and return the new map.
pub fn[K : Compare + Hash, V] insert_or_update(
  t : TreapMap[K, V],
  key : K,
  value : V,
) -> TreapMap[K, V] {
  if contains(t, key) {
    update_value(t, key, value)
  } else {
    let (l, r) = split(t, key)
    let node = make_node(key, value, priority_for(key), Empty, Empty)
    merge(merge(l, node), r)
  }
}

///|
/// Lookup a key and return its value if present.
pub fn[K : Compare, V] get(t : TreapMap[K, V], key : K) -> V? {
  match t {
    Empty => None
    Node(key=k, value=v, priority=_, size=_, left=l, right=r) =>
      if key == k {
        Some(v)
      } else if key < k {
        get(l, key)
      } else {
        get(r, key)
      }
  }
}

///|
/// Build a treap map by inserting elements in order.
pub fn[K : Compare + Hash, V] from_array(
  arr : ArrayView[(K, V)],
) -> TreapMap[K, V] {
  arr.fold(init=Empty, (tree, pair) => {
    let (k, v) = pair
    insert_or_update(tree, k, v)
  })
}
