// ============================================================================
// Challenge: Persistent Treap (Map)
// Key-value treap with immutable updates and bounded search
// ============================================================================

///|
pub enum TreapMap {
  Empty
  Node(
    key~ : Int,
    value~ : Int,
    priority~ : Int,
    size~ : Int,
    left~ : TreapMap,
    right~ : TreapMap
  )
} derive(Show)

///|
/// Return the number of entries in the map.
pub fn size(t : TreapMap) -> Int {
  match t {
    TreapMap::Empty => 0
    TreapMap::Node(key=_, value=_, priority=_, size~, left=_, right=_) => size
  }
}

///|
fn within_bounds(value : Int, lo : Int?, hi : Int?) -> Bool {
  let lo_ok = match lo {
    None => true
    Some(l) => value > l
  }
  let hi_ok = match hi {
    None => true
    Some(h) => value < h
  }
  lo_ok && hi_ok
}

///|
fn treap_valid(t : TreapMap, lo : Int?, hi : Int?) -> Bool {
  match t {
    TreapMap::Empty => true
    TreapMap::Node(key~, value=_, priority~, size=sz, left~, right~) => {
      let bounds_ok = within_bounds(key, lo, hi)
      let left_ok = match left {
        TreapMap::Empty => true
        TreapMap::Node(key=_, value=_, priority=p, size=_, left=_, right=_) =>
          priority >= p
      }
      let right_ok = match right {
        TreapMap::Empty => true
        TreapMap::Node(key=_, value=_, priority=p, size=_, left=_, right=_) =>
          priority >= p
      }
      let size_ok = sz == 1 + size(left) + size(right)
      bounds_ok &&
      left_ok &&
      right_ok &&
      size_ok &&
      treap_valid(left, lo, Some(key)) &&
      treap_valid(right, Some(key), hi)
    }
  }
}

///|
fn priority_for(key : Int) -> Int {
  key * 1103515245 + 12345
}

///|
fn make_node(
  key : Int,
  value : Int,
  priority : Int,
  left : TreapMap,
  right : TreapMap,
) -> TreapMap {
  let sz = 1 + size(left) + size(right)
  TreapMap::Node(key~, value~, priority~, size=sz, left~, right~)
}

///|
/// Create an empty treap map.
pub fn empty() -> TreapMap {
  TreapMap::Empty
}

///|
/// Split the map into (< key) and (>= key).
pub fn split(t : TreapMap, key : Int) -> (TreapMap, TreapMap) {
  match t {
    TreapMap::Empty => (TreapMap::Empty, TreapMap::Empty)
    TreapMap::Node(key=k, value=v, priority=p, size=_, left=l, right=r) =>
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
pub fn merge(a : TreapMap, b : TreapMap) -> TreapMap {
  match (a, b) {
    (TreapMap::Empty, _) => b
    (_, TreapMap::Empty) => a
    (
      TreapMap::Node(key=ka, value=va, priority=pa, size=_, left=la, right=ra),
      TreapMap::Node(key=kb, value=vb, priority=pb, size=_, left=lb, right=rb),
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
pub fn contains(t : TreapMap, key : Int) -> Bool {
  match t {
    TreapMap::Empty => false
    TreapMap::Node(key=k, value=_, priority=_, size=_, left=l, right=r) =>
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
fn update_value(t : TreapMap, key : Int, value : Int) -> TreapMap {
  match t {
    TreapMap::Empty => TreapMap::Empty
    TreapMap::Node(key=k, value=v, priority=p, size=_, left=l, right=r) =>
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
pub fn insert_or_update(t : TreapMap, key : Int, value : Int) -> TreapMap {
  if contains(t, key) {
    update_value(t, key, value)
  } else {
    let (l, r) = split(t, key)
    let node = make_node(
      key,
      value,
      priority_for(key),
      TreapMap::Empty,
      TreapMap::Empty,
    )
    merge(merge(l, node), r)
  }
}

///|
/// Lookup a key and return its value if present.
#warnings("+missing_invariant+missing_reasoning")
pub fn get(t : TreapMap, key : Int) -> Int? {
  let none : Int? = None
  for cur = t, lo = none, hi = none {
    match cur {
      TreapMap::Empty => break None
      TreapMap::Node(key=k, value=v, priority=_, size=_, left=l, right=r) =>
        if key == k {
          break Some(v)
        } else if key < k {
          continue l, lo, Some(k)
        } else {
          continue r, Some(k), hi
        }
    }
  } where {
    invariant: treap_valid(cur, lo, hi),
    invariant: within_bounds(key, lo, hi),
    reasoning: (
      #|INVARIANT (Treap map search):
      #|cur is a valid treap restricted to bounds (lo, hi), and key respects
      #|those bounds. A match must be inside cur.
      #|MAINTENANCE:
      #|Comparisons refine bounds as we descend left or right.
      #|TERMINATION:
      #|If cur is empty, key is absent; otherwise we return its value.
    ),
  }
}

///|
/// Build a treap map by inserting elements in order.
#warnings("+missing_invariant+missing_reasoning")
pub fn from_array(arr : ArrayView[(Int, Int)]) -> TreapMap {
  let n = arr.length()
  for i = 0, tree = TreapMap::Empty {
    if i >= n {
      break tree
    } else {
      let (k, v) = arr[i]
      continue i + 1, insert_or_update(tree, k, v)
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) <= i,
    invariant: treap_valid(tree, None, None),
    reasoning: (
      #|INVARIANT (Treap map build):
      #|tree holds all processed key-value pairs and respects treap invariants.
      #|MAINTENANCE:
      #|Insert or update (k, v), preserving treap validity.
      #|TERMINATION:
      #|At i = n, all pairs are present.
    ),
  }
}
