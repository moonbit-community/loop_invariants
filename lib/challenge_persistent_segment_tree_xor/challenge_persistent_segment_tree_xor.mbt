// ============================================================================
// Challenge: Persistent Segment Tree (Xor)
// Point updates with range xor queries
// ============================================================================

///|
enum Node {
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
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(xor=_) => len == 1
    Node::Branch(xor=xv, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        xv == (node_xor(left) ^ node_xor(right))
      }
  }
}

///|
fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
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
fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
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
fn range_xor(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
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
#warnings("+missing_invariant+missing_reasoning")
fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int)]) -> Node {
  let m = updates.length()
  for i = 0, tree = root {
    if i >= m {
      break tree
    } else {
      let (idx, value) = updates[i]
      continue i + 1, set_value(tree, 0, n, idx, value)
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: tree_valid(tree, n),
    reasoning: (
      #|INVARIANT (Xor updates):
      #|tree reflects the first i point updates with correct xor values.
      #|MAINTENANCE:
      #|Update index i by path-copying while recomputing xor values.
      #|TERMINATION:
      #|At i = m, all updates are applied.
    ),
  }
}

///|
test "persistent_segment_tree_xor" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)][:])
  assert_eq(range_xor(root, 0, arr.length(), 0, 4), 5 ^ 2 ^ 7 ^ 4)
  assert_eq(range_xor(updated, 0, arr.length(), 0, 4), 6 ^ 2 ^ 1 ^ 4)
}
