// ============================================================================
// Challenge: Persistent AVL Set
// Balanced BST with rotations and path-copying inserts
// ============================================================================

///|
pub enum Avl[T] {
  Empty
  Node(key~ : T, height~ : Int, left~ : Avl[T], right~ : Avl[T])
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
fn[T] height(t : Avl[T]) -> Int {
  match t {
    Avl::Empty => 0
    Avl::Node(key=_, height~, left=_, right=_) => height
  }
}

///|
/// Return the number of keys in the AVL set.
pub fn[T] size(t : Avl[T]) -> Int {
  match t {
    Avl::Empty => 0
    Avl::Node(key=_, height=_, left~, right~) => 1 + size(left) + size(right)
  }
}

///|
fn[T : Compare] within_bounds(value : T, lo : T?, hi : T?) -> Bool {
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
fn[T : Compare] avl_valid(t : Avl[T], lo : T?, hi : T?) -> Bool {
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
fn[T] make_node(key : T, left : Avl[T], right : Avl[T]) -> Avl[T] {
  let h = 1 + max2(height(left), height(right))
  Avl::Node(key~, height=h, left~, right~)
}

///|
fn[T] rotate_left(t : Avl[T]) -> Avl[T] {
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
fn[T] rotate_right(t : Avl[T]) -> Avl[T] {
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
fn[T] balance(t : Avl[T]) -> Avl[T] {
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
/// Create an empty AVL set.
pub fn[T] empty() -> Avl[T] {
  Avl::Empty
}

///|
/// Insert key and return the new AVL set.
pub fn[T : Compare] insert(t : Avl[T], key : T) -> Avl[T] {
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
/// Check whether key exists in the set.
#warnings("+missing_invariant+missing_reasoning")
pub fn[T : Compare] contains(t : Avl[T], key : T) -> Bool {
  let none : T? = None
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
/// Return an in-order traversal (sorted keys).
pub fn[T] inorder(t : Avl[T]) -> Array[T] {
  match t {
    Avl::Empty => []
    Avl::Node(key=k, height=_, left=l, right=r) => inorder(l) + [k] + inorder(r)
  }
}

///|
/// Build an AVL set by inserting elements in order.
#warnings("+missing_invariant+missing_reasoning")
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Avl[T] {
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
