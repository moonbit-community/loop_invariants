// ============================================================================
// Challenge: Persistent Segment Tree (Min)
// Point updates with range minimum queries
// ============================================================================

///|
pub enum Node {
  Leaf(min~ : Int)
  Branch(min~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_min(node : Node) -> Int {
  match node {
    Node::Leaf(min~) => min
    Node::Branch(min~, left=_, right=_) => min
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(min=_) => len == 1
    Node::Branch(min=min_val, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        let expected = if node_min(left) < node_min(right) {
          node_min(left)
        } else {
          node_min(right)
        }
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        min_val == expected
      }
  }
}

///|
pub fn min_value(node : Node) -> Int {
  node_min(node)
}

///|
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(min=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_min(left) < node_min(right) {
      node_min(left)
    } else {
      node_min(right)
    }
    Node::Branch(min=m, left~, right~)
  }
}

///|
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(min=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(min=_) => Node::Leaf(min=value)
      Node::Branch(left~, right~, min=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          let m = if node_min(new_left) < node_min(right) {
            node_min(new_left)
          } else {
            node_min(right)
          }
          Node::Branch(min=m, left=new_left, right~)
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          let m = if node_min(left) < node_min(new_right) {
            node_min(left)
          } else {
            node_min(new_right)
          }
          Node::Branch(min=m, left~, right=new_right)
        }
    }
  }
}

///|
pub fn range_min(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0x3fffffff
  } else if ql <= l && r <= qr {
    node_min(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(min=_) => node_min(node)
      Node::Branch(left~, right~, min=_) => {
        let left_min = range_min(left, l, mid, ql, qr)
        let right_min = range_min(right, mid, r, ql, qr)
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
      #|INVARIANT (Min updates):
      #|tree reflects the first i point updates with correct min values.
      #|MAINTENANCE:
      #|Update index i by path-copying while recomputing mins.
      #|TERMINATION:
      #|At i = m, all updates are applied.
    ),
  }
}

///|
test "persistent_segment_tree_min" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)][:])
  assert_eq(range_min(root, 0, arr.length(), 0, 4), 2)
  assert_eq(range_min(updated, 0, arr.length(), 0, 4), 1)
  assert_eq(range_min(updated, 0, arr.length(), 1, 3), 1)
}
