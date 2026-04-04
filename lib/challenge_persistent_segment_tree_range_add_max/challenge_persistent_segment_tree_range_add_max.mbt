// ============================================================================
// Challenge: Persistent Segment Tree (Range Add Max)
// Range add with max queries and lazy tags
// ============================================================================

///|
pub enum Node {
  Leaf(max~ : Int, tag~ : Int)
  Branch(max~ : Int, tag~ : Int, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn node_max(node : Node) -> Int {
  match node {
    Leaf(max~, tag=_) => max
    Branch(max~, tag=_, left=_, right=_) => max
  }
}

///|
fn apply_add(node : Node, delta : Int) -> Node {
  match node {
    Leaf(max=mv, tag=tv) => Leaf(max=mv + delta, tag=tv + delta)
    Branch(max=mv, tag=tv, left~, right~) =>
      Branch(max=mv + delta, tag=tv + delta, left~, right~)
  }
}

///|
/// Return the maximum stored at the root.
pub fn max_value(node : Node) -> Int {
  node_max(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(max=arr[l], tag=0)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_max(left) > node_max(right) {
      node_max(left)
    } else {
      node_max(right)
    }
    Branch(max=m, tag=0, left~, right~)
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
      Leaf(max=_, tag=_) => apply_add(node, delta)
      Branch(max=_, tag=tv, left~, right~) => {
        let left0 = if tv == 0 { left } else { apply_add(left, tv) }
        let right0 = if tv == 0 { right } else { apply_add(right, tv) }
        let new_left = range_add(left0, l, mid, ql, qr, delta)
        let new_right = range_add(right0, mid, r, ql, qr, delta)
        let m = if node_max(new_left) > node_max(new_right) {
          node_max(new_left)
        } else {
          node_max(new_right)
        }
        Branch(max=m, tag=0, left=new_left, right=new_right)
      }
    }
  }
}

///|
/// Query the maximum over [ql, qr).
pub fn range_max(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    -0x3fffffff
  } else if ql <= l && r <= qr {
    node_max(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(max=_, tag=_) => node_max(node)
      Branch(max=_, tag=tv, left~, right~) => {
        let left0 = if tv == 0 { left } else { apply_add(left, tv) }
        let right0 = if tv == 0 { right } else { apply_add(right, tv) }
        let left_max = range_max(left0, l, mid, ql, qr)
        let right_max = range_max(right0, mid, r, ql, qr)
        if left_max > right_max {
          left_max
        } else {
          right_max
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
test "persistent_segment_tree_range_add_max" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3, -1), (0, 2, 2)][:])
  assert_eq(range_max(root, 0, arr.length(), 0, 4), 7)
  assert_eq(range_max(updated, 0, arr.length(), 0, 4), 7)
  assert_eq(range_max(updated, 0, arr.length(), 1, 3), 6)
}
