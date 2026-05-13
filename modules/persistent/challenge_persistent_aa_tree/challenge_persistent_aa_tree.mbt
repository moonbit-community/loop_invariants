// ============================================================================
// Challenge: Persistent AA Tree
// Balanced BST with skew/split operations
// ============================================================================

///|
/// A persistent AA tree (a simplified red-black variant) storing keys of
/// type `T`.
///
/// Each node carries a `level` field; balance is restored after insertion
/// by `skew` (right rotation) and `split` (left rotation that lifts a
/// level), giving `O(log n)` search and insert. The tree is persistent:
/// `insert` returns a new tree that shares unchanged subtrees with the
/// input, copying only the root-to-leaf path. See `empty`, `insert`,
/// `contains`, `inorder`, and `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_aa_tree.from_array([3, 1, 4, 2])
///   assert_eq(@challenge_persistent_aa_tree.contains(t, 1), true)
///   assert_eq(@challenge_persistent_aa_tree.inorder(t), [1, 2, 3, 4])
/// }
/// ```
pub enum Aa[T] {
  Empty
  Node(key~ : T, level~ : Int, left~ : Aa[T], right~ : Aa[T])
} derive(Debug)

///|
fn[T] level(t : Aa[T]) -> Int {
  match t {
    Empty => 0
    Node(key=_, level~, left=_, right=_) => level
  }
}

///|
/// Return the number of keys in the AA tree.
pub fn[T] size(t : Aa[T]) -> Int {
  match t {
    Empty => 0
    Node(key=_, level=_, left~, right~) => 1 + size(left) + size(right)
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
fn[T : Compare] aa_valid(t : Aa[T], lo : T?, hi : T?) -> Bool {
  match t {
    Empty => true
    Node(key=k, level=lv, left=l, right=r) => {
      let left_ok = level(l) < lv
      let right_ok = level(r) <= lv
      let rr_ok = match r {
        Empty => true
        Node(key=_, level=rv, left=_, right=rr) => level(rr) < lv && rv <= lv
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
fn[T] make_node(key : T, lv : Int, left : Aa[T], right : Aa[T]) -> Aa[T] {
  Node(key~, level=lv, left~, right~)
}

///|
fn[T] skew(t : Aa[T]) -> Aa[T] {
  match t {
    Node(
      key=k,
      level=lv,
      left=Node(key=lk, level=llv, left=ll, right=lr),
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
fn[T] split(t : Aa[T]) -> Aa[T] {
  match t {
    Node(
      key=k,
      level=lv,
      left=l,
      right=Node(key=rk, level=_, left=rl, right=rr)
    ) =>
      match rr {
        Node(key=rrk, level=rrlv, left=rrl, right=rrr) =>
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
        Empty => t
      }
    _ => t
  }
}

///|
/// Create an empty AA tree.
pub fn[T] empty() -> Aa[T] {
  Empty
}

///|
/// Insert key and return the new AA tree.
pub fn[T : Compare] insert(t : Aa[T], key : T) -> Aa[T] {
  match t {
    Empty => Node(key~, level=1, left=Empty, right=Empty)
    Node(key=k, level=lv, left=l, right=r) =>
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
pub fn[T : Compare] contains(t : Aa[T], key : T) -> Bool {
  let none : T? = None
  for cur = t, lo = none, hi = none {
    match cur {
      Empty => break false
      Node(key=k, level=_, left=l, right=r) =>
        if key == k {
          break true
        } else if key < k {
          continue l, lo, Some(k)
        } else {
          continue r, Some(k), hi
        }
    }
  } where {
    proof_invariant: aa_valid(cur, lo, hi),
    proof_invariant: within_bounds(key, lo, hi),
    proof_reasoning: (
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
pub fn[T] inorder(t : Aa[T]) -> Array[T] {
  match t {
    Empty => []
    Node(key=k, level=_, left=l, right=r) => inorder(l) + [k] + inorder(r)
  }
}

///|
/// Build an AA tree by inserting elements in order.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Aa[T] {
  let n = arr.length()
  for i in 0..<n; tree = Empty {
    continue insert(tree, arr[i])
  } nobreak {
    tree
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_invariant: size(tree) == i,
    proof_invariant: aa_valid(tree, None, None),
    proof_reasoning: (
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
test "persistent aa tree invariants" {
  let tree = from_array([3, 1, 4, 2])
  let none : Int? = None
  assert_true(aa_valid(tree, none, none))
  assert_true(contains(tree, 1))
}
