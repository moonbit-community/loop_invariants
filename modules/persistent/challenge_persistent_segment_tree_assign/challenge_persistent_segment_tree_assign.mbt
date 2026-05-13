// ============================================================================
// Challenge: Persistent Segment Tree (Range Assign)
// Range assignment with lazy tags
// ============================================================================

///|
/// Persistent segment tree supporting range-assign updates and
/// range-sum queries with lazy propagation.
///
/// Each node stores the sum of its index range together with an
/// optional `Int?` assignment tag: `Some(v)` means "every element in
/// this subtree has been assigned `v`, but the children have not yet
/// been rewritten". `range_assign` overwrites a half-open `[ql, qr)`
/// in `O(log n)` and `range_sum` reads in `O(log n)`; `build` is
/// `O(n)`. Persistence is achieved by path copying, so each version
/// shares all untouched subtrees with its predecessor.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr = [1, 2, 3, 4][:]
///   let root = build(arr, 0, arr.length())
///   let updated = apply_updates(root, arr.length(), [(1, 3, 5), (0, 2, 0)])
///   assert_eq(range_sum(root, 0, arr.length(), 0, 4), 10)
///   assert_eq(range_sum(updated, 0, arr.length(), 0, 4), 9)
/// }
/// ```
pub enum Node {
  Leaf(sum~ : Int, tag~ : Int?)
  Branch(sum~ : Int, tag~ : Int?, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn node_sum(node : Node) -> Int {
  match node {
    Leaf(sum~, tag=_) => sum
    Branch(sum~, tag=_, left=_, right=_) => sum
  }
}

///|

///|
fn apply_assign(node : Node, len : Int, value : Int) -> Node {
  match node {
    Leaf(sum=_, tag=_) => Leaf(sum=value * len, tag=Some(value))
    Branch(sum=_, tag=_, left~, right~) =>
      Branch(sum=value * len, tag=Some(value), left~, right~)
  }
}

///|
/// Return the sum stored at the root.
pub fn total(node : Node) -> Int {
  node_sum(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(sum=arr[l], tag=None)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Branch(sum=node_sum(left) + node_sum(right), tag=None, left~, right~)
  }
}

///|
/// Assign value to all elements in [ql, qr) and return the new tree.
pub fn range_assign(
  node : Node,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
  value : Int,
) -> Node {
  if qr <= l || r <= ql {
    node
  } else if ql <= l && r <= qr {
    apply_assign(node, r - l, value)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(sum=_, tag=_) => apply_assign(node, r - l, value)
      Branch(sum=_, tag=tagv, left~, right~) => {
        let left_len = mid - l
        let right_len = r - mid
        let left0 = match tagv {
          None => left
          Some(v) => apply_assign(left, left_len, v)
        }
        let right0 = match tagv {
          None => right
          Some(v) => apply_assign(right, right_len, v)
        }
        let new_left = range_assign(left0, l, mid, ql, qr, value)
        let new_right = range_assign(right0, mid, r, ql, qr, value)
        Branch(
          sum=node_sum(new_left) + node_sum(new_right),
          tag=None,
          left=new_left,
          right=new_right,
        )
      }
    }
  }
}

///|
/// Query the sum over [ql, qr).
pub fn range_sum(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_sum(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(sum=_, tag=_) => node_sum(node)
      Branch(sum=_, tag=tagv, left~, right~) => {
        let left_len = mid - l
        let right_len = r - mid
        let left0 = match tagv {
          None => left
          Some(v) => apply_assign(left, left_len, v)
        }
        let right0 = match tagv {
          None => right
          Some(v) => apply_assign(right, right_len, v)
        }
        range_sum(left0, l, mid, ql, qr) + range_sum(right0, mid, r, ql, qr)
      }
    }
  }
}

///|
/// Apply range assignments (l, r, value), where r is exclusive.
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int, Int)],
) -> Node {
  for update in updates; tree = root {
    let (l, r, v) = update
    continue range_assign(tree, 0, n, l, r, v)
  } nobreak {
    tree
  }
}

///|
test "persistent_segment_tree_assign" {
  let arr = [1, 2, 3, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3, 5), (0, 2, 0)])
  assert_eq(range_sum(root, 0, arr.length(), 0, 4), 10)
  assert_eq(range_sum(updated, 0, arr.length(), 0, 4), 9)
  assert_eq(range_sum(updated, 0, arr.length(), 1, 3), 5)
}
