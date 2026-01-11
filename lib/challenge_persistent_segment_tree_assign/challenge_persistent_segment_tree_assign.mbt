// ============================================================================
// Challenge: Persistent Segment Tree (Range Assign)
// Range assignment with lazy tags
// ============================================================================

///|
enum Node {
  Leaf(sum~ : Int, tag~ : Int?)
  Branch(sum~ : Int, tag~ : Int?, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_sum(node : Node) -> Int {
  match node {
    Node::Leaf(sum~, tag=_) => sum
    Node::Branch(sum~, tag=_, left=_, right=_) => sum
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(sum=sv, tag=tagv) =>
      len == 1 &&
      (match tagv {
        None => true
        Some(v) => sv == v * len
      })
    Node::Branch(sum=sv, tag=tagv, left~, right~) =>
      if len <= 1 {
        false
      } else {
        match tagv {
          None =>
            tree_valid(left, len / 2) &&
            tree_valid(right, len - len / 2) &&
            sv == node_sum(left) + node_sum(right)
          Some(v) => sv == v * len
        }
      }
  }
}

///|
fn apply_assign(node : Node, len : Int, value : Int) -> Node {
  match node {
    Node::Leaf(sum=_, tag=_) => Node::Leaf(sum=value * len, tag=Some(value))
    Node::Branch(sum=_, tag=_, left~, right~) =>
      Node::Branch(sum=value * len, tag=Some(value), left~, right~)
  }
}

///|
fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(sum=arr[l], tag=None)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Node::Branch(sum=node_sum(left) + node_sum(right), tag=None, left~, right~)
  }
}

///|
fn range_assign(
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
      Node::Leaf(sum=_, tag=_) => apply_assign(node, r - l, value)
      Node::Branch(sum=_, tag=tagv, left~, right~) => {
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
        Node::Branch(
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
fn range_sum(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_sum(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(sum=_, tag=_) => node_sum(node)
      Node::Branch(sum=_, tag=tagv, left~, right~) => {
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
#warnings("+missing_invariant+missing_reasoning")
fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int, Int)],
) -> Node {
  let m = updates.length()
  for i = 0, tree = root {
    if i >= m {
      break tree
    } else {
      let (l, r, v) = updates[i]
      continue i + 1, range_assign(tree, 0, n, l, r, v)
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: tree_valid(tree, n),
    reasoning: (
      #|INVARIANT (Assign updates):
      #|tree reflects the first i range assignments with consistent sums.
      #|MAINTENANCE:
      #|Apply assignment i with lazy tags and path-copying.
      #|TERMINATION:
      #|At i = m, all assignments are applied.
    ),
  }
}

///|
test "persistent_segment_tree_assign" {
  let arr = [1, 2, 3, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3, 5), (0, 2, 0)][:])
  assert_eq(range_sum(root, 0, arr.length(), 0, 4), 10)
  assert_eq(range_sum(updated, 0, arr.length(), 0, 4), 9)
  assert_eq(range_sum(updated, 0, arr.length(), 1, 3), 5)
}
