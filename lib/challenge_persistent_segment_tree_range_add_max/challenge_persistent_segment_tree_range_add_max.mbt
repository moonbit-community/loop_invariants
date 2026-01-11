// ============================================================================
// Challenge: Persistent Segment Tree (Range Add Max)
// Range add with max queries and lazy tags
// ============================================================================

///|
enum Node {
  Leaf(max~ : Int, tag~ : Int)
  Branch(max~ : Int, tag~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_max(node : Node) -> Int {
  match node {
    Node::Leaf(max~, tag=_) => max
    Node::Branch(max~, tag=_, left=_, right=_) => max
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(max=mv, tag=tv) =>
      len == 1 && mv <= 0x3fffffff && tv >= -0x3fffffff
    Node::Branch(max=mv, tag=tv, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let expected = if node_max(left) > node_max(right) {
          node_max(left)
        } else {
          node_max(right)
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
    Node::Leaf(max=mv, tag=tv) => Node::Leaf(max=mv + delta, tag=tv + delta)
    Node::Branch(max=mv, tag=tv, left~, right~) =>
      Node::Branch(max=mv + delta, tag=tv + delta, left~, right~)
  }
}

///|
fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(max=arr[l], tag=0)
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_max(left) > node_max(right) {
      node_max(left)
    } else {
      node_max(right)
    }
    Node::Branch(max=m, tag=0, left~, right~)
  }
}

///|
fn range_add(
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
      Node::Leaf(max=_, tag=_) => apply_add(node, delta)
      Node::Branch(max=_, tag=tv, left~, right~) => {
        let left0 = if tv == 0 { left } else { apply_add(left, tv) }
        let right0 = if tv == 0 { right } else { apply_add(right, tv) }
        let new_left = range_add(left0, l, mid, ql, qr, delta)
        let new_right = range_add(right0, mid, r, ql, qr, delta)
        let m = if node_max(new_left) > node_max(new_right) {
          node_max(new_left)
        } else {
          node_max(new_right)
        }
        Node::Branch(max=m, tag=0, left=new_left, right=new_right)
      }
    }
  }
}

///|
fn range_max(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    -0x3fffffff
  } else if ql <= l && r <= qr {
    node_max(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(max=_, tag=_) => node_max(node)
      Node::Branch(max=_, tag=tv, left~, right~) => {
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
      let (l, r, delta) = updates[i]
      continue i + 1, range_add(tree, 0, n, l, r, delta)
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: tree_valid(tree, n),
    reasoning: (
      #|INVARIANT (Range add max):
      #|tree reflects the first i range-add updates with correct maxima.
      #|MAINTENANCE:
      #|Apply update i via lazy tags and path-copying.
      #|TERMINATION:
      #|At i = m, all updates are applied.
    ),
  }
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
