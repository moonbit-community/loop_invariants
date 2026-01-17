// ============================================================================
// Challenge: Persistent Segment Tree (Sum)
// Path-copying point updates with range queries
// ============================================================================

///|
pub enum Node {
  Leaf(sum~ : Int)
  Branch(sum~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_sum(node : Node) -> Int {
  match node {
    Node::Leaf(sum~) => sum
    Node::Branch(sum~, left=_, right=_) => sum
  }
}

///|

///|
/// Return the sum stored at the root.
pub fn total(node : Node) -> Int {
  node_sum(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(sum=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Node::Branch(sum=node_sum(left) + node_sum(right), left~, right~)
  }
}

///|
/// Add delta at index idx and return the new tree.
pub fn add(node : Node, l : Int, r : Int, idx : Int, delta : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(sum=node_sum(node) + delta)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(sum=_) => Node::Leaf(sum=node_sum(node) + delta)
      Node::Branch(left~, right~, sum=_) =>
        if idx < mid {
          let new_left = add(left, l, mid, idx, delta)
          Node::Branch(
            sum=node_sum(new_left) + node_sum(right),
            left=new_left,
            right~,
          )
        } else {
          let new_right = add(right, mid, r, idx, delta)
          Node::Branch(
            sum=node_sum(left) + node_sum(new_right),
            left~,
            right=new_right,
          )
        }
    }
  }
}

///|
/// Query the sum over [ql, qr).
pub fn query(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_sum(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(sum=_) => node_sum(node)
      Node::Branch(left~, right~, sum=_) =>
        query(left, l, mid, ql, qr) + query(right, mid, r, ql, qr)
    }
  }
}

///|
/// Apply a list of point updates (index, delta).
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int)],
) -> Node {
  let mut tree = root
  for update in updates {
    let (idx, delta) = update
    tree = add(tree, 0, n, idx, delta)
  }
  tree
}

///|
test "persistent_segment_tree" {
  let arr = [1, 2, 3, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3), (3, -1)][:])
  assert_eq(query(root, 0, arr.length(), 0, 4), 10)
  assert_eq(query(updated, 0, arr.length(), 0, 4), 12)
  assert_eq(query(updated, 0, arr.length(), 1, 3), 8)
}
