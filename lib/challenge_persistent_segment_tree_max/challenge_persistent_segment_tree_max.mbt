// ============================================================================
// Challenge: Persistent Segment Tree (Max)
// Point updates with range maximum queries
// ============================================================================

///|
pub enum Node {
  Leaf(max~ : Int)
  Branch(max~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_max(node : Node) -> Int {
  match node {
    Node::Leaf(max~) => max
    Node::Branch(max~, left=_, right=_) => max
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(max=_) => len == 1
    Node::Branch(max=max_val, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        let expected = if node_max(left) > node_max(right) {
          node_max(left)
        } else {
          node_max(right)
        }
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        max_val == expected
      }
  }
}

///|
pub fn max_value(node : Node) -> Int {
  node_max(node)
}

///|
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(max=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_max(left) > node_max(right) {
      node_max(left)
    } else {
      node_max(right)
    }
    Node::Branch(max=m, left~, right~)
  }
}

///|
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(max=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(max=_) => Node::Leaf(max=value)
      Node::Branch(left~, right~, max=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          let m = if node_max(new_left) > node_max(right) {
            node_max(new_left)
          } else {
            node_max(right)
          }
          Node::Branch(max=m, left=new_left, right~)
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          let m = if node_max(left) > node_max(new_right) {
            node_max(left)
          } else {
            node_max(new_right)
          }
          Node::Branch(max=m, left~, right=new_right)
        }
    }
  }
}

///|
pub fn range_max(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    -0x3fffffff
  } else if ql <= l && r <= qr {
    node_max(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(max=_) => node_max(node)
      Node::Branch(left~, right~, max=_) => {
        let left_max = range_max(left, l, mid, ql, qr)
        let right_max = range_max(right, mid, r, ql, qr)
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
/// Apply point updates (idx, value).
#warnings("+missing_invariant+missing_reasoning")
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int)],
) -> Node {
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
      #|INVARIANT (Max updates):
      #|tree reflects the first i point updates with correct max values.
      #|MAINTENANCE:
      #|Update index i by path-copying while recomputing maxima.
      #|TERMINATION:
      #|At i = m, all updates are applied.
    ),
  }
}

///|
test "persistent_segment_tree_max" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)][:])
  assert_eq(range_max(root, 0, arr.length(), 0, 4), 7)
  assert_eq(range_max(updated, 0, arr.length(), 0, 4), 6)
  assert_eq(range_max(updated, 0, arr.length(), 1, 3), 2)
}
