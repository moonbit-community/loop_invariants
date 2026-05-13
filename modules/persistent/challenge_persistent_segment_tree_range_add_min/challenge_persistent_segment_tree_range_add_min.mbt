// ============================================================================
// Challenge: Persistent Segment Tree (Range Add Min)
// Range add with min queries and lazy tags
// ============================================================================

///|
/// Persistent segment tree supporting range-add updates and
/// range-minimum queries with lazy propagation.
///
/// Each node caches the minimum of its index range together with an
/// `Int` lazy tag that records a pending `+delta` to be pushed to its
/// children on the next visit. `range_add` bumps every element of a
/// half-open `[ql, qr)` and `range_min` reads the min over `[ql, qr)`,
/// both in `O(log n)`; `build` is `O(n)`. Out-of-range query results
/// fall back to the sentinel `0x3fffffff`. Persistence is achieved
/// by path copying, so each version shares all untouched subtrees
/// with its predecessor.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr = [5, 2, 7, 4][:]
///   let root = build(arr, 0, arr.length())
///   let updated = apply_updates(root, arr.length(), [(1, 3, -1), (0, 2, 2)])
///   assert_eq(range_min(root, 0, arr.length(), 0, 4), 2)
///   assert_eq(range_min(updated, 0, arr.length(), 0, 4), 3)
/// }
/// ```
pub enum Node {
  Leaf(min~ : Int, tag~ : Int)
  Branch(min~ : Int, tag~ : Int, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn node_min(node : Node) -> Int {
  match node {
    Leaf(min~, tag=_) => min
    Branch(min~, tag=_, left=_, right=_) => min
  }
}

///|
fn apply_add(node : Node, delta : Int) -> Node {
  match node {
    Leaf(min=mv, tag=tv) => Leaf(min=mv + delta, tag=tv + delta)
    Branch(min=mv, tag=tv, left~, right~) =>
      Branch(min=mv + delta, tag=tv + delta, left~, right~)
  }
}

///|
/// Return the minimum stored at the root.
pub fn min_value(node : Node) -> Int {
  node_min(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(min=arr[l], tag=0)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_min(left) < node_min(right) {
      node_min(left)
    } else {
      node_min(right)
    }
    Branch(min=m, tag=0, left~, right~)
  }
}

///|
/// Add delta to all elements in [ql, qr) and return the new tree.
pub fn range_add(
  node : Node,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
  delta : Int,
) -> Node {
  if qr <= l || r <= ql {
    node
  } else if ql <= l && r <= qr {
    apply_add(node, delta)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(min=_, tag=_) => apply_add(node, delta)
      Branch(min=_, tag=tv, left~, right~) => {
        let left0 = if tv == 0 { left } else { apply_add(left, tv) }
        let right0 = if tv == 0 { right } else { apply_add(right, tv) }
        let new_left = range_add(left0, l, mid, ql, qr, delta)
        let new_right = range_add(right0, mid, r, ql, qr, delta)
        let m = if node_min(new_left) < node_min(new_right) {
          node_min(new_left)
        } else {
          node_min(new_right)
        }
        Branch(min=m, tag=0, left=new_left, right=new_right)
      }
    }
  }
}

///|
/// Query the minimum over [ql, qr).
pub fn range_min(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0x3fffffff
  } else if ql <= l && r <= qr {
    node_min(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(min=_, tag=_) => node_min(node)
      Branch(min=_, tag=tv, left~, right~) => {
        let left0 = if tv == 0 { left } else { apply_add(left, tv) }
        let right0 = if tv == 0 { right } else { apply_add(right, tv) }
        let left_min = range_min(left0, l, mid, ql, qr)
        let right_min = range_min(right0, mid, r, ql, qr)
        if left_min < right_min {
          left_min
        } else {
          right_min
        }
      }
    }
  }
}

///|
/// Apply range adds (l, r, delta) where r is exclusive.
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int, Int)],
) -> Node {
  updates.fold(init=root, (tree, update) => {
    let (l, r, delta) = update
    range_add(tree, 0, n, l, r, delta)
  })
}

///|
test "persistent_segment_tree_range_add_min" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3, -1), (0, 2, 2)])
  assert_eq(range_min(root, 0, arr.length(), 0, 4), 2)
  assert_eq(range_min(updated, 0, arr.length(), 0, 4), 3)
  assert_eq(range_min(updated, 0, arr.length(), 1, 3), 3)
}
