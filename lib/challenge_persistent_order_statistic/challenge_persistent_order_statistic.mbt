// ============================================================================
// Challenge: Persistent Order Statistics Tree
// Persistent segment tree for kth-order queries
// ============================================================================

///|
enum Node {
  Empty
  Node(count~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
pub struct OrderStat {
  root : Node
  lo : Int
  hi : Int
} derive(Show)

///|
fn count(node : Node) -> Int {
  match node {
    Node::Empty => 0
    Node::Node(count~, left=_, right=_) => count
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Empty => true
    Node::Node(count=c, left=l, right=r) =>
      if len <= 1 {
        c >= 0 && l is Node::Empty && r is Node::Empty
      } else {
        let mid = len / 2
        tree_valid(l, mid) &&
        tree_valid(r, len - mid) &&
        c == count(l) + count(r)
      }
  }
}

///|
fn insert(node : Node, l : Int, r : Int, value : Int) -> Node {
  if value < l || value >= r {
    node
  } else if r - l == 1 {
    let new_count = count(node) + 1
    Node::Node(count=new_count, left=Node::Empty, right=Node::Empty)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Empty => {
        let left = insert(Node::Empty, l, mid, value)
        let right = insert(Node::Empty, mid, r, value)
        Node::Node(count=count(left) + count(right), left~, right~)
      }
      Node::Node(count=_, left~, right~) =>
        if value < mid {
          let new_left = insert(left, l, mid, value)
          Node::Node(
            count=count(new_left) + count(right),
            left=new_left,
            right~,
          )
        } else {
          let new_right = insert(right, mid, r, value)
          Node::Node(
            count=count(left) + count(new_right),
            left~,
            right=new_right,
          )
        }
    }
  }
}

///|
pub fn make(lo : Int, hi : Int) -> OrderStat {
  { root: Node::Empty, lo, hi }
}

///|
pub fn size(os : OrderStat) -> Int {
  count(os.root)
}

///|
pub fn add(os : OrderStat, value : Int) -> OrderStat {
  { root: insert(os.root, os.lo, os.hi, value), lo: os.lo, hi: os.hi }
}

///|
/// kth element (0-based) within the multiset.
#warnings("+missing_invariant+missing_reasoning")
pub fn kth(os : OrderStat, k : Int) -> Int? {
  if k < 0 || k >= count(os.root) {
    return None
  }
  for node = os.root, l = os.lo, r = os.hi, rank = k {
    match node {
      Node::Empty => break None
      Node::Node(left~, right~, count=_) =>
        if r - l == 1 {
          break Some(l)
        } else {
          let mid = (l + r) / 2
          let left_count = count(left)
          if rank < left_count {
            continue left, l, mid, rank
          } else {
            continue right, mid, r, rank - left_count
          }
        }
    }
  } where {
    invariant: rank >= 0 && rank < count(node),
    invariant: l < r,
    invariant: tree_valid(node, r - l),
    reasoning: (
      #|INVARIANT (Order-statistic walk):
      #|rank is the desired index within the subtree node spanning [l, r).
      #|MAINTENANCE:
      #|Use left subtree size to decide which side contains the rank.
      #|TERMINATION:
      #|When the segment is a single value, return its coordinate.
    ),
  }
}

///|
test "persistent_order_statistic" {
  let os0 = { root: Node::Empty, lo: 0, hi: 10 }
  let os1 = add(os0, 5)
  let os2 = add(os1, 2)
  let os3 = add(os2, 7)
  let os4 = add(os3, 2)
  assert_eq(kth(os4, 0), Some(2))
  assert_eq(kth(os4, 1), Some(2))
  assert_eq(kth(os4, 2), Some(5))
  assert_eq(kth(os4, 3), Some(7))
}
