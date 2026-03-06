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
    Empty => 0
    Node(count~, left=_, right=_) => count
  }
}

///|

///|
fn insert(node : Node, l : Int, r : Int, value : Int) -> Node {
  if value < l || value >= r {
    node
  } else if r - l == 1 {
    let new_count = count(node) + 1
    Node(count=new_count, left=Empty, right=Empty)
  } else {
    let mid = (l + r) / 2
    match node {
      Empty => {
        let left = insert(Empty, l, mid, value)
        let right = insert(Empty, mid, r, value)
        Node(count=count(left) + count(right), left~, right~)
      }
      Node(count=_, left~, right~) =>
        if value < mid {
          let new_left = insert(left, l, mid, value)
          Node(count=count(new_left) + count(right), left=new_left, right~)
        } else {
          let new_right = insert(right, mid, r, value)
          Node(count=count(left) + count(new_right), left~, right=new_right)
        }
    }
  }
}

///|
/// Create an empty multiset for values in [lo, hi).
pub fn make(lo : Int, hi : Int) -> OrderStat {
  { root: Empty, lo, hi }
}

///|
/// Return the total number of elements in the multiset.
pub fn size(os : OrderStat) -> Int {
  count(os.root)
}

///|
/// Insert value and return a new order-statistic structure.
pub fn add(os : OrderStat, value : Int) -> OrderStat {
  { root: insert(os.root, os.lo, os.hi, value), lo: os.lo, hi: os.hi }
}

///|
/// kth element (0-based) within the multiset.
pub fn kth(os : OrderStat, k : Int) -> Int? {
  if k < 0 || k >= count(os.root) {
    return None
  }
  match os.root {
    Empty => None
    _ => kth_node(os.root, os.lo, os.hi, k)
  }
}

///|
fn kth_node(node : Node, l : Int, r : Int, k : Int) -> Int? {
  match node {
    Empty => None
    Node(left~, right~, count=_) =>
      if r - l == 1 {
        Some(l)
      } else {
        let mid = (l + r) / 2
        let left_count = count(left)
        if k < left_count {
          kth_node(left, l, mid, k)
        } else {
          kth_node(right, mid, r, k - left_count)
        }
      }
  }
}
