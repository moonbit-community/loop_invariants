// ============================================================================
// Challenge: Persistent Segment Tree (Lazy Range Add)
// Range updates with lazy propagation in a persistent tree
// ============================================================================

///|
pub enum Node {
  Leaf(sum~ : Int, tag~ : Int)
  Branch(sum~ : Int, tag~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_sum(node : Node) -> Int {
  match node {
    Node::Leaf(sum~, tag=_) => sum
    Node::Branch(sum~, tag=_, left=_, right=_) => sum
  }
}

///|
fn node_tag(node : Node) -> Int {
  match node {
    Node::Leaf(sum=_, tag~) => tag
    Node::Branch(sum=_, tag~, left=_, right=_) => tag
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(sum=_, tag=_) => len == 1
    Node::Branch(sum~, tag~, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        sum == node_sum(left) + node_sum(right) + tag * len
      }
  }
}

///|
/// Return the sum stored at the root.
pub fn total(node : Node) -> Int {
  node_sum(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(sum=arr[l], tag=0)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Node::Branch(sum=node_sum(left) + node_sum(right), tag=0, left~, right~)
  }
}

///|
fn apply(node : Node, len : Int, delta : Int) -> Node {
  match node {
    Node::Leaf(sum~, tag~) => Node::Leaf(sum=sum + delta * len, tag=tag + delta)
    Node::Branch(sum~, tag~, left~, right~) =>
      Node::Branch(sum=sum + delta * len, tag=tag + delta, left~, right~)
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
    apply(node, r - l, delta)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(sum=_, tag=_) => apply(node, r - l, delta)
      Node::Branch(left~, right~, sum=_, tag=_) => {
        let left_len = mid - l
        let right_len = r - mid
        let tag = node_tag(node)
        let left0 = apply(left, left_len, tag)
        let right0 = apply(right, right_len, tag)
        let new_left = range_add(left0, l, mid, ql, qr, delta)
        let new_right = range_add(right0, mid, r, ql, qr, delta)
        Node::Branch(
          sum=node_sum(new_left) + node_sum(new_right),
          tag=0,
          left=new_left,
          right=new_right,
        )
      }
    }
  }
}

///|
/// Query the sum over [ql, qr).
pub fn range_sum(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_sum(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(sum=_, tag=_) => node_sum(node)
      Node::Branch(left~, right~, sum=_, tag=_) => {
        let left_len = mid - l
        let right_len = r - mid
        let tag = node_tag(node)
        let left0 = apply(left, left_len, tag)
        let right0 = apply(right, right_len, tag)
        range_sum(left0, l, mid, ql, qr) + range_sum(right0, mid, r, ql, qr)
      }
    }
  }
}

///|
/// Apply a list of range updates (l, r, delta) where r is exclusive.
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
      #|INVARIANT (Lazy updates):
      #|tree applies the first i range updates with sums consistent to lazy tags.
      #|MAINTENANCE:
      #|Apply update i with path-copying, preserving tree validity.
      #|TERMINATION:
      #|At i = m, all updates are incorporated.
    ),
  }
}

///|
test "persistent_segment_tree_lazy" {
  let arr = [1, 2, 3, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(1, 3, 2), (0, 2, -1)][:])
  assert_eq(range_sum(root, 0, arr.length(), 0, 4), 10)
  assert_eq(range_sum(updated, 0, arr.length(), 0, 4), 12)
  assert_eq(range_sum(updated, 0, arr.length(), 1, 3), 8)
}
