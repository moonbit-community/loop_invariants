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
#warnings("+missing_invariant+missing_reasoning")
fn gcd(a : Int, b : Int) -> Int {
  let x0 = abs_int(a)
  let y0 = abs_int(b)
  for x = x0, y = y0 {
    if y == 0 {
      break x
    } else {
      continue y, x % y
    }
  } where {
    invariant: x >= 0 && y >= 0,
    reasoning: (
      #|INVARIANT (Euclid):
      #|gcd(x, y) equals gcd(x0, y0) and y decreases by modulus.
      #|MAINTENANCE:
      #|Replace (x, y) with (y, x mod y) without changing gcd.
      #|TERMINATION:
      #|When y = 0, x is the gcd.
    ),
  }
}

///|
enum Node {
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
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(g=_) => len == 1
    Node::Branch(g=gv, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        gv == gcd(node_gcd(left), node_gcd(right))
      }
  }
}

///|
fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
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
fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
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
fn range_gcd(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
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
      #|INVARIANT (GCD updates):
      #|tree reflects the first i point updates with correct gcd values.
      #|MAINTENANCE:
      #|Update index i by path-copying while recomputing gcd values.
      #|TERMINATION:
      #|At i = m, all updates are applied.
    ),
  }
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
