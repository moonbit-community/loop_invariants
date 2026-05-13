// ============================================================================
// Challenge: Persistent 2-3 Tree
// Balanced search tree with node splitting
// ============================================================================

///|
/// A persistent 2-3 search tree of keys of type `T`.
///
/// Every internal node holds one key (`Two`) or two keys (`Three`); all
/// leaves sit at the same depth, so the tree is perfectly height-balanced
/// and search/insert run in `O(log n)`. Because the tree is persistent,
/// `insert` returns a fresh tree that shares every untouched subtree with
/// the input, copying only the path from the root to the modified leaf.
/// Use `empty`, `insert`, `contains`, `size`, and `from_array` to build
/// and query versions.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t0 = @challenge_persistent_23_tree.empty()
///   let t1 = @challenge_persistent_23_tree.insert(t0, 5)
///   let t2 = @challenge_persistent_23_tree.insert(t1, 2)
///   @debug.assert_eq(@challenge_persistent_23_tree.contains(t2, 5), true)
///   @debug.assert_eq(@challenge_persistent_23_tree.contains(t0, 5), false)
/// }
/// ```
pub enum Tree[T] {
  Empty
  Two(key~ : T, left~ : Tree[T], right~ : Tree[T])
  Three(
    key1~ : T,
    key2~ : T,
    left~ : Tree[T],
    middle~ : Tree[T],
    right~ : Tree[T]
  )
} derive(Debug)

///|
enum InsertResult[T] {
  Done(tree~ : Tree[T])
  Split(key~ : T, left~ : Tree[T], right~ : Tree[T])
} derive(Debug)

///|
/// Return the number of keys in the tree.
pub fn[T] size(t : Tree[T]) -> Int {
  match t {
    Empty => 0
    Two(key=_, left~, right~) => 1 + size(left) + size(right)
    Three(key1=_, key2=_, left~, middle~, right~) =>
      2 + size(left) + size(middle) + size(right)
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
fn[T : Compare] tree_valid(t : Tree[T], lo : T?, hi : T?) -> Bool {
  match t {
    Empty => true
    Two(key=k, left=l, right=r) =>
      within_bounds(k, lo, hi) &&
      tree_valid(l, lo, Some(k)) &&
      tree_valid(r, Some(k), hi)
    Three(key1=k1, key2=k2, left=l, middle=m, right=r) =>
      k1 < k2 &&
      within_bounds(k1, lo, hi) &&
      within_bounds(k2, lo, hi) &&
      tree_valid(l, lo, Some(k1)) &&
      tree_valid(m, Some(k1), Some(k2)) &&
      tree_valid(r, Some(k2), hi)
  }
}

///|
fn[T : Compare] insert_inner(t : Tree[T], key : T) -> InsertResult[T] {
  match t {
    Empty => Done(tree=Two(key~, left=Empty, right=Empty))
    Two(key=k, left=l, right=r) =>
      if key == k {
        Done(tree=t)
      } else if key < k {
        match insert_inner(l, key) {
          Done(tree=new_left) => Done(tree=Two(key=k, left=new_left, right=r))
          Split(key=pk, left=pl, right=pr) =>
            Done(tree=Three(key1=pk, key2=k, left=pl, middle=pr, right=r))
        }
      } else {
        match insert_inner(r, key) {
          Done(tree=new_right) => Done(tree=Two(key=k, left=l, right=new_right))
          Split(key=pk, left=pl, right=pr) =>
            Done(tree=Three(key1=k, key2=pk, left=l, middle=pl, right=pr))
        }
      }
    Three(key1=k1, key2=k2, left=l, middle=m, right=r) =>
      if key == k1 || key == k2 {
        Done(tree=t)
      } else if key < k1 {
        match insert_inner(l, key) {
          Done(tree=new_left) =>
            Done(tree=Three(key1=k1, key2=k2, left=new_left, middle=m, right=r))
          Split(key=pk, left=pl, right=pr) => {
            let left_node = Two(key=pk, left=pl, right=pr)
            let right_node = Two(key=k2, left=m, right=r)
            Split(key=k1, left=left_node, right=right_node)
          }
        }
      } else if key < k2 {
        match insert_inner(m, key) {
          Done(tree=new_mid) =>
            Done(tree=Three(key1=k1, key2=k2, left=l, middle=new_mid, right=r))
          Split(key=pk, left=pl, right=pr) => {
            let left_node = Two(key=k1, left=l, right=pl)
            let right_node = Two(key=k2, left=pr, right=r)
            Split(key=pk, left=left_node, right=right_node)
          }
        }
      } else {
        match insert_inner(r, key) {
          Done(tree=new_right) =>
            Done(
              tree=Three(key1=k1, key2=k2, left=l, middle=m, right=new_right),
            )
          Split(key=pk, left=pl, right=pr) => {
            let left_node = Two(key=k1, left=l, right=m)
            let right_node = Two(key=pk, left=pl, right=pr)
            Split(key=k2, left=left_node, right=right_node)
          }
        }
      }
  }
}

///|
/// Create an empty 2-3 tree.
pub fn[T] empty() -> Tree[T] {
  Empty
}

///|
/// Insert key and return the new tree.
pub fn[T : Compare] insert(t : Tree[T], key : T) -> Tree[T] {
  match insert_inner(t, key) {
    Done(tree~) => tree
    Split(key=k, left=l, right=r) => Two(key=k, left=l, right=r)
  }
}

///|
/// Check whether key exists in the tree.
pub fn[T : Compare] contains(t : Tree[T], key : T) -> Bool {
  let none : T? = None
  for cur = t, lo = none, hi = none {
    match cur {
      Empty => break false
      Two(key=k, left=l, right=r) =>
        if key == k {
          break true
        } else if key < k {
          continue l, lo, Some(k)
        } else {
          continue r, Some(k), hi
        }
      Three(key1=k1, key2=k2, left=l, middle=m, right=r) =>
        if key == k1 || key == k2 {
          break true
        } else if key < k1 {
          continue l, lo, Some(k1)
        } else if key < k2 {
          continue m, Some(k1), Some(k2)
        } else {
          continue r, Some(k2), hi
        }
    }
  } where {
    proof_invariant: tree_valid(cur, lo, hi),
    proof_invariant: within_bounds(key, lo, hi),
    proof_reasoning: (
      #|INVARIANT (2-3 search bounds):
      #|cur is a valid subtree constrained by (lo, hi); key respects bounds.
      #|MAINTENANCE:
      #|Choose the correct child interval, tightening bounds accordingly.
      #|TERMINATION:
      #|Empty subtree means absent; matching key returns true.
    ),
  }
}

///|
/// Build a 2-3 tree by inserting elements in order.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T] {
  let n = arr.length()
  for i in 0..<n; tree = Empty {
    continue insert(tree, arr[i])
  } nobreak {
    tree
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_invariant: size(tree) == i,
    proof_invariant: tree_valid(tree, None, None),
    proof_reasoning: (
      #|INVARIANT (2-3 build):
      #|tree contains the first i keys and preserves 2-3 ordering.
      #|MAINTENANCE:
      #|Insert arr[i], preserving balance via splits.
      #|TERMINATION:
      #|At i = n, all keys are inserted.
    ),
  }
}

///|
test "persistent 2-3 tree invariants" {
  let tree = from_array([3, 1, 4, 2])
  let none : Int? = None
  assert_true(tree_valid(tree, none, none))
  assert_true(contains(tree, 4))
}
