// ============================================================================
// Challenge: Persistent Segment Tree (GCD)
// Point updates with range gcd queries
// ============================================================================

///|
fn abs_int(x : Int) -> Int {
  if x < 0 {
    -x
  } else {
    x
  }
}

///|
/// Compute the greatest common divisor of a and b.
pub fn gcd(a : Int, b : Int) -> Int {
  let x = abs_int(a)
  let y = abs_int(b)
  if y == 0 {
    x
  } else {
    gcd(y, x % y)
  }
}

///|
pub enum Node {
  Leaf(g~ : Int)
  Branch(g~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
fn node_gcd(node : Node) -> Int {
  match node {
    Node::Leaf(g~) => g
    Node::Branch(g~, left=_, right=_) => g
  }
}

///|

///|
/// Return the GCD stored at the root.
pub fn gcd_value(node : Node) -> Int {
  node_gcd(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(g=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Node::Branch(g=gcd(node_gcd(left), node_gcd(right)), left~, right~)
  }
}

///|
/// Set index idx to value and return the new tree.
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(g=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(g=_) => Node::Leaf(g=value)
      Node::Branch(left~, right~, g=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          Node::Branch(
            g=gcd(node_gcd(new_left), node_gcd(right)),
            left=new_left,
            right~,
          )
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          Node::Branch(
            g=gcd(node_gcd(left), node_gcd(new_right)),
            left~,
            right=new_right,
          )
        }
    }
  }
}

///|
/// Query the GCD over [ql, qr).
pub fn range_gcd(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_gcd(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(g=_) => node_gcd(node)
      Node::Branch(left~, right~, g=_) =>
        gcd(range_gcd(left, l, mid, ql, qr), range_gcd(right, mid, r, ql, qr))
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
  let mut tree = root
  for update in updates {
    let (idx, value) = update
    tree = set_value(tree, 0, n, idx, value)
  }
  tree
}

///|
test "persistent_segment_tree_gcd" {
  let arr = [6, 10, 15, 25][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 5), (0, 9)][:])
  assert_eq(range_gcd(root, 0, arr.length(), 0, 4), 1)
  assert_eq(range_gcd(updated, 0, arr.length(), 0, 4), 1)
  assert_eq(range_gcd(updated, 0, arr.length(), 0, 2), 1)
}
