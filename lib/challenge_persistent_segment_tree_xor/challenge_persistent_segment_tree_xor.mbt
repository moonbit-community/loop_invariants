// ============================================================================
// Challenge: Persistent Segment Tree (Xor)
// Point updates with range xor queries
// ============================================================================

///|
pub enum Node {
  Leaf(xor~ : Int)
  Branch(xor~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_xor(node : Node) -> Int {
  match node {
    Node::Leaf(xor~) => xor
    Node::Branch(xor~, left=_, right=_) => xor
  }
}

///|

///|
/// Return the xor value stored at the root.
pub fn xor_value(node : Node) -> Int {
  node_xor(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(xor=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Node::Branch(xor=node_xor(left) ^ node_xor(right), left~, right~)
  }
}

///|
/// Set index idx to value and return the new tree.
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(xor=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(xor=_) => Node::Leaf(xor=value)
      Node::Branch(left~, right~, xor=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          Node::Branch(
            xor=node_xor(new_left) ^ node_xor(right),
            left=new_left,
            right~,
          )
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          Node::Branch(
            xor=node_xor(left) ^ node_xor(new_right),
            left~,
            right=new_right,
          )
        }
    }
  }
}

///|
/// Query the xor over [ql, qr).
pub fn range_xor(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_xor(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(xor=_) => node_xor(node)
      Node::Branch(left~, right~, xor=_) =>
        range_xor(left, l, mid, ql, qr) ^ range_xor(right, mid, r, ql, qr)
    }
  }
}

///|
/// Apply point updates (idx, value).
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int)],
) -> Node {
  updates.fold(init=root, (tree, update) => {
    let (idx, value) = update
    set_value(tree, 0, n, idx, value)
  })
}

///|
test "persistent_segment_tree_xor" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)][:])
  assert_eq(range_xor(root, 0, arr.length(), 0, 4), 5 ^ 2 ^ 7 ^ 4)
  assert_eq(range_xor(updated, 0, arr.length(), 0, 4), 6 ^ 2 ^ 1 ^ 4)
}
