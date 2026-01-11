// ============================================================================
// Challenge: Persistent Segment Tree (Sum)
// Path-copying point updates with range queries
// ============================================================================

///|
enum Node {
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
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(sum=_) => len == 1
    Node::Branch(sum~, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        sum == node_sum(left) + node_sum(right)
      }
  }
}

///|
fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
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
fn add(node : Node, l : Int, r : Int, idx : Int, delta : Int) -> Node {
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
fn query(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
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
#warnings("+missing_invariant+missing_reasoning")
fn apply_updates(root : Node, n : Int, updates : ArrayView[(Int, Int)]) -> Node {
  let m = updates.length()
  for i = 0, tree = root {
    if i >= m {
      break tree
    } else {
      let (idx, delta) = updates[i]
      continue i + 1, add(tree, 0, n, idx, delta)
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: tree_valid(tree, n),
    reasoning: (
      #|INVARIANT (Persistent updates):
      #|tree reflects the original root with the first i updates applied.
      #|MAINTENANCE:
      #|Apply update i by path-copying and preserving sum consistency.
      #|TERMINATION:
      #|At i = m, all updates are incorporated.
    ),
  }
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
