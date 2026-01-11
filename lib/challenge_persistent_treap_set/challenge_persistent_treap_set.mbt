// ============================================================================
// Challenge: Persistent Treap (Set)
// Random-priority BST with immutable insertions
// ============================================================================

///|
enum Treap {
  Empty
  Node(key~ : Int, priority~ : Int, size~ : Int, left~ : Treap, right~ : Treap)
} derive(Show)

///|
fn size(t : Treap) -> Int {
  match t {
    Treap::Empty => 0
    Treap::Node(key=_, priority=_, size~, left=_, right=_) => size
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
fn treap_valid(t : Treap, lo : Int?, hi : Int?) -> Bool {
  match t {
    Treap::Empty => true
    Treap::Node(key~, priority~, size=sz, left~, right~) => {
      let bounds_ok = within_bounds(key, lo, hi)
      let left_ok = match left {
        Treap::Empty => true
        Treap::Node(key=_, priority=p, size=_, left=_, right=_) => priority >= p
      }
      let right_ok = match right {
        Treap::Empty => true
        Treap::Node(key=_, priority=p, size=_, left=_, right=_) => priority >= p
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
fn make_node(key : Int, priority : Int, left : Treap, right : Treap) -> Treap {
  let sz = 1 + size(left) + size(right)
  Treap::Node(key~, priority~, size=sz, left~, right~)
}

///|
fn split(t : Treap, key : Int) -> (Treap, Treap) {
  match t {
    Treap::Empty => (Treap::Empty, Treap::Empty)
    Treap::Node(key=k, priority=p, size=_, left=l, right=r) =>
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
fn merge(a : Treap, b : Treap) -> Treap {
  match (a, b) {
    (Treap::Empty, _) => b
    (_, Treap::Empty) => a
    (
      Treap::Node(key=ka, priority=pa, size=_, left=la, right=ra),
      Treap::Node(key=kb, priority=pb, size=_, left=lb, right=rb),
    ) =>
      if pa >= pb {
        make_node(ka, pa, la, merge(ra, b))
      } else {
        make_node(kb, pb, merge(a, lb), rb)
      }
  }
}

///|
fn contains(t : Treap, key : Int) -> Bool {
  match t {
    Treap::Empty => false
    Treap::Node(key=k, priority=_, size=_, left=l, right=r) =>
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
fn insert(t : Treap, key : Int) -> Treap {
  if contains(t, key) {
    t
  } else {
    let (l, r) = split(t, key)
    let node = make_node(key, priority_for(key), Treap::Empty, Treap::Empty)
    merge(merge(l, node), r)
  }
}

///|
/// Build a treap by inserting elements in order.
#warnings("+missing_invariant+missing_reasoning")
fn from_array(arr : ArrayView[Int]) -> Treap {
  let n = arr.length()
  for i = 0, tree = Treap::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) == i,
    invariant: treap_valid(tree, None, None),
    reasoning: (
      #|INVARIANT (Treap build):
      #|tree contains the first i keys, satisfying BST order and heap priority.
      #|MAINTENANCE:
      #|Insert arr[i], preserving treap invariants and increasing size by one.
      #|TERMINATION:
      #|At i = n, all keys are inserted.
    ),
  }
}

///|
test "persistent_treap_set" {
  let t0 = Treap::Empty
  let t1 = insert(t0, 5)
  let t2 = insert(t1, 2)
  let t3 = insert(t2, 8)
  assert_eq(contains(t3, 2), true)
  assert_eq(contains(t3, 6), false)
  let built = from_array([5, 2, 8, 2][:])
  assert_eq(contains(built, 2), true)
  assert_eq(size(built), 3)
}
