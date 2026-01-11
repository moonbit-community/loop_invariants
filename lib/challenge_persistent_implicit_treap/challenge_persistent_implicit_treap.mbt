// ============================================================================
// Challenge: Persistent Implicit Treap
// Sequence treap indexed by subtree sizes
// ============================================================================

///|
enum Treap {
  Empty
  Node(
    value~ : Int,
    priority~ : Int,
    size~ : Int,
    left~ : Treap,
    right~ : Treap
  )
} derive(Show)

///|
fn size(t : Treap) -> Int {
  match t {
    Treap::Empty => 0
    Treap::Node(value=_, priority=_, size~, left=_, right=_) => size
  }
}

///|
fn treap_valid(t : Treap) -> Bool {
  match t {
    Treap::Empty => true
    Treap::Node(value=_, priority~, size=sz, left~, right~) => {
      let left_ok = match left {
        Treap::Empty => true
        Treap::Node(value=_, priority=p, size=_, left=_, right=_) =>
          priority >= p
      }
      let right_ok = match right {
        Treap::Empty => true
        Treap::Node(value=_, priority=p, size=_, left=_, right=_) =>
          priority >= p
      }
      let size_ok = sz == 1 + size(left) + size(right)
      left_ok && right_ok && size_ok && treap_valid(left) && treap_valid(right)
    }
  }
}

///|
fn priority_for(value : Int, salt : Int) -> Int {
  value * 1103515245 + salt * 12345
}

///|
fn make_node(value : Int, priority : Int, left : Treap, right : Treap) -> Treap {
  let sz = 1 + size(left) + size(right)
  Treap::Node(value~, priority~, size=sz, left~, right~)
}

///|
fn split(t : Treap, k : Int) -> (Treap, Treap) {
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
fn merge(a : Treap, b : Treap) -> Treap {
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
fn insert_at(t : Treap, idx : Int, value : Int) -> Treap {
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
fn get(t : Treap, idx : Int) -> Int? {
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
fn to_array(t : Treap) -> Array[Int] {
  match t {
    Treap::Empty => []
    Treap::Node(value=v, priority=_, size=_, left=l, right=r) =>
      to_array(l) + [v] + to_array(r)
  }
}

///|
/// Build a treap by appending elements in order.
#warnings("+missing_invariant+missing_reasoning")
fn from_array(arr : ArrayView[Int]) -> Treap {
  let n = arr.length()
  for i = 0, tree = Treap::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert_at(tree, i, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) == i,
    invariant: treap_valid(tree),
    reasoning: (
      #|INVARIANT (Implicit treap build):
      #|tree represents the first i elements in order and maintains heap order.
      #|MAINTENANCE:
      #|Insert arr[i] at position i, preserving sequence order and size.
      #|TERMINATION:
      #|At i = n, tree holds the entire array.
    ),
  }
}

///|
test "persistent_implicit_treap" {
  let t0 = Treap::Empty
  let t1 = insert_at(t0, 0, 10)
  let t2 = insert_at(t1, 1, 20)
  let t3 = insert_at(t2, 1, 15)
  assert_eq(to_array(t3), [10, 15, 20])
  assert_eq(get(t3, 2), Some(20))
  let built = from_array([1, 2, 3][:])
  assert_eq(to_array(built), [1, 2, 3])
}
