// ============================================================================
// Challenge: Persistent AA Tree
// Balanced BST with skew/split operations
// ============================================================================

///|
pub enum Aa {
  Empty
  Node(key~ : Int, level~ : Int, left~ : Aa, right~ : Aa)
} derive(Show)

///|
fn level(t : Aa) -> Int {
  match t {
    Aa::Empty => 0
    Aa::Node(key=_, level~, left=_, right=_) => level
  }
}

///|
/// Return the number of keys in the AA tree.
pub fn size(t : Aa) -> Int {
  match t {
    Aa::Empty => 0
    Aa::Node(key=_, level=_, left~, right~) => 1 + size(left) + size(right)
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
fn aa_valid(t : Aa, lo : Int?, hi : Int?) -> Bool {
  match t {
    Aa::Empty => true
    Aa::Node(key=k, level=lv, left=l, right=r) => {
      let left_ok = level(l) < lv
      let right_ok = level(r) <= lv
      let rr_ok = match r {
        Aa::Empty => true
        Aa::Node(key=_, level=rv, left=_, right=rr) =>
          level(rr) < lv && rv <= lv
      }
      within_bounds(k, lo, hi) &&
      left_ok &&
      right_ok &&
      rr_ok &&
      aa_valid(l, lo, Some(k)) &&
      aa_valid(r, Some(k), hi)
    }
  }
}

///|
fn make_node(key : Int, lv : Int, left : Aa, right : Aa) -> Aa {
  Aa::Node(key~, level=lv, left~, right~)
}

///|
fn skew(t : Aa) -> Aa {
  match t {
    Aa::Node(
      key=k,
      level=lv,
      left=Aa::Node(key=lk, level=llv, left=ll, right=lr),
      right=r
    ) =>
      if llv == lv {
        make_node(lk, llv, ll, make_node(k, lv, lr, r))
      } else {
        t
      }
    _ => t
  }
}

///|
fn split(t : Aa) -> Aa {
  match t {
    Aa::Node(
      key=k,
      level=lv,
      left=l,
      right=Aa::Node(key=rk, level=_, left=rl, right=rr)
    ) =>
      match rr {
        Aa::Node(key=rrk, level=rrlv, left=rrl, right=rrr) =>
          if rrlv == lv {
            make_node(
              rk,
              lv + 1,
              make_node(k, lv, l, rl),
              make_node(rrk, rrlv, rrl, rrr),
            )
          } else {
            t
          }
        Aa::Empty => t
      }
    _ => t
  }
}

///|
/// Create an empty AA tree.
pub fn empty() -> Aa {
  Aa::Empty
}

///|
/// Insert key and return the new AA tree.
pub fn insert(t : Aa, key : Int) -> Aa {
  match t {
    Aa::Empty => Aa::Node(key~, level=1, left=Aa::Empty, right=Aa::Empty)
    Aa::Node(key=k, level=lv, left=l, right=r) =>
      if key == k {
        t
      } else if key < k {
        let updated = make_node(k, lv, insert(l, key), r)
        split(skew(updated))
      } else {
        let updated = make_node(k, lv, l, insert(r, key))
        split(skew(updated))
      }
  }
}

///|
/// Check whether key exists in the tree.
#warnings("+missing_invariant+missing_reasoning")
pub fn contains(t : Aa, key : Int) -> Bool {
  let none : Int? = None
  for cur = t, lo = none, hi = none {
    match cur {
      Aa::Empty => break false
      Aa::Node(key=k, level=_, left=l, right=r) =>
        if key == k {
          break true
        } else if key < k {
          continue l, lo, Some(k)
        } else {
          continue r, Some(k), hi
        }
    }
  } where {
    invariant: aa_valid(cur, lo, hi),
    invariant: within_bounds(key, lo, hi),
    reasoning: (
      #|INVARIANT (AA tree search):
      #|cur is a valid AA subtree within bounds (lo, hi) and key respects bounds.
      #|MAINTENANCE:
      #|Descend left/right while tightening bounds.
      #|TERMINATION:
      #|Empty subtree means absent; matching key returns true.
    ),
  }
}

///|
/// Return an in-order traversal (sorted keys).
pub fn inorder(t : Aa) -> Array[Int] {
  match t {
    Aa::Empty => []
    Aa::Node(key=k, level=_, left=l, right=r) => inorder(l) + [k] + inorder(r)
  }
}

///|
/// Build an AA tree by inserting elements in order.
#warnings("+missing_invariant+missing_reasoning")
pub fn from_array(arr : ArrayView[Int]) -> Aa {
  let n = arr.length()
  for i = 0, tree = Aa::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) == i,
    invariant: aa_valid(tree, None, None),
    reasoning: (
      #|INVARIANT (AA tree build):
      #|tree contains the first i elements and maintains AA invariants.
      #|MAINTENANCE:
      #|Insert arr[i], preserving invariants and increasing size by one.
      #|TERMINATION:
      #|At i = n, all elements are inserted.
    ),
  }
}

///|
test "persistent_aa_tree" {
  let t0 = Aa::Empty
  let t1 = insert(t0, 5)
  let t2 = insert(t1, 2)
  let t3 = insert(t2, 8)
  let t4 = insert(t3, 6)
  assert_eq(contains(t4, 2), true)
  assert_eq(contains(t4, 7), false)
  let built = from_array([5, 2, 8, 6][:])
  assert_eq(inorder(built), [2, 5, 6, 8])
}
