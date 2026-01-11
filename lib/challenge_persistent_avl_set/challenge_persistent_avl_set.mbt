// ============================================================================
// Challenge: Persistent AVL Set
// Balanced BST with rotations and path-copying inserts
// ============================================================================

///|
enum Avl {
  Empty
  Node(key~ : Int, height~ : Int, left~ : Avl, right~ : Avl)
} derive(Show)

///|
fn max2(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn height(t : Avl) -> Int {
  match t {
    Avl::Empty => 0
    Avl::Node(key=_, height~, left=_, right=_) => height
  }
}

///|
fn size(t : Avl) -> Int {
  match t {
    Avl::Empty => 0
    Avl::Node(key=_, height=_, left~, right~) => 1 + size(left) + size(right)
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
fn avl_valid(t : Avl, lo : Int?, hi : Int?) -> Bool {
  match t {
    Avl::Empty => true
    Avl::Node(key=k, height=h, left=l, right=r) => {
      let diff = height(l) - height(r)
      within_bounds(k, lo, hi) &&
      avl_valid(l, lo, Some(k)) &&
      avl_valid(r, Some(k), hi) &&
      h == 1 + max2(height(l), height(r)) &&
      diff <= 1 &&
      diff >= -1
    }
  }
}

///|
fn make_node(key : Int, left : Avl, right : Avl) -> Avl {
  let h = 1 + max2(height(left), height(right))
  Avl::Node(key~, height=h, left~, right~)
}

///|
fn rotate_left(t : Avl) -> Avl {
  match t {
    Avl::Node(
      key=k,
      height=_,
      left=l,
      right=Avl::Node(key=rk, height=_, left=rl, right=rr)
    ) => {
      let new_left = make_node(k, l, rl)
      make_node(rk, new_left, rr)
    }
    _ => t
  }
}

///|
fn rotate_right(t : Avl) -> Avl {
  match t {
    Avl::Node(
      key=k,
      height=_,
      left=Avl::Node(key=lk, height=_, left=ll, right=lr),
      right=r
    ) => {
      let new_right = make_node(k, lr, r)
      make_node(lk, ll, new_right)
    }
    _ => t
  }
}

///|
fn balance(t : Avl) -> Avl {
  match t {
    Avl::Empty => t
    Avl::Node(key=k, height=_, left=l, right=r) => {
      let bf = height(l) - height(r)
      if bf > 1 {
        match l {
          Avl::Node(key=_, height=_, left=ll, right=lr) =>
            if height(ll) >= height(lr) {
              rotate_right(t)
            } else {
              rotate_right(make_node(k, rotate_left(l), r))
            }
          Avl::Empty => t
        }
      } else if bf < -1 {
        match r {
          Avl::Node(key=_, height=_, left=rl, right=rr) =>
            if height(rr) >= height(rl) {
              rotate_left(t)
            } else {
              rotate_left(make_node(k, l, rotate_right(r)))
            }
          Avl::Empty => t
        }
      } else {
        t
      }
    }
  }
}

///|
fn insert(t : Avl, key : Int) -> Avl {
  match t {
    Avl::Empty => Avl::Node(key~, height=1, left=Avl::Empty, right=Avl::Empty)
    Avl::Node(key=k, height=_, left=l, right=r) =>
      if key == k {
        t
      } else if key < k {
        balance(make_node(k, insert(l, key), r))
      } else {
        balance(make_node(k, l, insert(r, key)))
      }
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn contains(t : Avl, key : Int) -> Bool {
  let none : Int? = None
  for cur = t, lo = none, hi = none {
    match cur {
      Avl::Empty => break false
      Avl::Node(key=k, height=_, left=l, right=r) =>
        if key == k {
          break true
        } else if key < k {
          continue l, lo, Some(k)
        } else {
          continue r, Some(k), hi
        }
    }
  } where {
    invariant: avl_valid(cur, lo, hi),
    invariant: within_bounds(key, lo, hi),
    reasoning: (
      #|INVARIANT (AVL search bounds):
      #|cur is a valid AVL subtree respecting (lo, hi), and key respects bounds.
      #|MAINTENANCE:
      #|Descending left/right tightens bounds while preserving AVL validity.
      #|TERMINATION:
      #|Empty subtree means key absent; matching key returns true.
    ),
  }
}

///|
fn inorder(t : Avl) -> Array[Int] {
  match t {
    Avl::Empty => []
    Avl::Node(key=k, height=_, left=l, right=r) => inorder(l) + [k] + inorder(r)
  }
}

///|
/// Build an AVL set by inserting elements in order.
#warnings("+missing_invariant+missing_reasoning")
fn from_array(arr : ArrayView[Int]) -> Avl {
  let n = arr.length()
  for i = 0, tree = Avl::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) == i,
    invariant: avl_valid(tree, None, None),
    reasoning: (
      #|INVARIANT (AVL build):
      #|tree contains the first i elements and maintains AVL balance.
      #|MAINTENANCE:
      #|Insert arr[i], preserving balance and increasing size by one.
      #|TERMINATION:
      #|At i = n, all elements are inserted.
    ),
  }
}

///|
test "persistent_avl_set" {
  let t0 = Avl::Empty
  let t1 = insert(t0, 3)
  let t2 = insert(t1, 1)
  let t3 = insert(t2, 4)
  let t4 = insert(t3, 2)
  assert_eq(contains(t4, 2), true)
  assert_eq(contains(t4, 5), false)
  let built = from_array([3, 1, 4, 2][:])
  assert_eq(inorder(built), [1, 2, 3, 4])
}
