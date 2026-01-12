// ============================================================================
// Challenge: Persistent Segment Tree (Range Add Min)
// Range add with min queries and lazy tags
// ============================================================================

///|
pub enum Node {
  Leaf(min~ : Int, tag~ : Int)
  Branch(min~ : Int, tag~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_min(node : Node) -> Int {
  match node {
    Node::Leaf(min~, tag=_) => min
    Node::Branch(min~, tag=_, left=_, right=_) => min
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(min=mv, tag=tv) => len == 1 && mv >= 0 && tv >= -0x3fffffff
    Node::Branch(min=mv, tag=tv, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let expected = if node_min(left) < node_min(right) {
          node_min(left)
        } else {
          node_min(right)
        }
        tree_valid(left, len / 2) &&
        tree_valid(right, len - len / 2) &&
        mv == expected + tv
      }
  }
}

///|
fn apply_add(node : Node, delta : Int) -> Node {
  match node {
    Node::Leaf(min=mv, tag=tv) => Node::Leaf(min=mv + delta, tag=tv + delta)
    Node::Branch(min=mv, tag=tv, left~, right~) =>
      Node::Branch(min=mv + delta, tag=tv + delta, left~, right~)
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
    Node::Leaf(min=arr[l], tag=0)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_min(left) < node_min(right) {
      node_min(left)
    } else {
      node_min(right)
    }
    Node::Branch(min=m, tag=0, left~, right~)
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
      Node::Leaf(min=_, tag=_) => apply_add(node, delta)
      Node::Branch(min=_, tag=tv, left~, right~) => {
        let left0 = if tv == 0 { left } else { apply_add(left, tv) }
        let right0 = if tv == 0 { right } else { apply_add(right, tv) }
        let new_left = range_add(left0, l, mid, ql, qr, delta)
        let new_right = range_add(right0, mid, r, ql, qr, delta)
        let m = if node_min(new_left) < node_min(new_right) {
          node_min(new_left)
        } else {
          node_min(new_right)
        }
        Node::Branch(min=m, tag=0, left=new_left, right=new_right)
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
      Node::Leaf(min=_, tag=_) => node_min(node)
      Node::Branch(min=_, tag=tv, left~, right~) => {
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
#warnings("+missing_invariant+missing_reasoning")
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int, Int)],
) -> Node {
  let m = updates.length()
  for i = 0, tree = root {
    if i >= m {
      break tree
    } else {
      let (l, r, delta) = updates[i]
      continue i + 1, range_add(tree, 0, n, l, r, delta)
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: tree_valid(tree, n),
    reasoning: (
      #|INVARIANT (Range add min):
      #|tree reflects the first i range-add updates with correct mins.
      #|MAINTENANCE:
      #|Apply update i via lazy tags and path-copying.
      #|TERMINATION:
      #|At i = m, all updates are applied.
    ),
  }
}

///|
test "persistent_segment_tree_range_add_min" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3, -1), (0, 2, 2)][:])
  assert_eq(range_min(root, 0, arr.length(), 0, 4), 2)
  assert_eq(range_min(updated, 0, arr.length(), 0, 4), 3)
  assert_eq(range_min(updated, 0, arr.length(), 1, 3), 3)
}
