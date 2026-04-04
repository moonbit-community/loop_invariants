// ============================================================================
// Challenge: Persistent Interval Tree
// BST by start with max_end augmentation for overlap queries
// ============================================================================

///|
pub enum Tree {
  Empty
  Node(start~ : Int, end~ : Int, max_end~ : Int, left~ : Tree, right~ : Tree)
} derive(Debug)

///|
fn max2(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn max_end(t : Tree) -> Int {
  match t {
    Empty => -0x3fffffff
    Node(start=_, end=_, max_end~, left=_, right=_) => max_end
  }
}

///|
/// Return the number of intervals in the tree.
pub fn size(t : Tree) -> Int {
  match t {
    Empty => 0
    Node(start=_, end=_, max_end=_, left~, right~) =>
      1 + size(left) + size(right)
  }
}

///|

///|
fn make_node(start : Int, end : Int, left : Tree, right : Tree) -> Tree {
  let me = max2(end, max2(max_end(left), max_end(right)))
  Node(start~, end~, max_end=me, left~, right~)
}

///|
/// Create an empty interval tree.
pub fn empty() -> Tree {
  Empty
}

///|
/// Insert an interval and return the new tree.
pub fn insert(t : Tree, start : Int, end : Int) -> Tree {
  match t {
    Empty => Node(start~, end~, max_end=end, left=Empty, right=Empty)
    Node(start=s, end=e, left=l, right=r, max_end=_) =>
      if start == s {
        let new_end = if end > e { end } else { e }
        make_node(s, new_end, l, r)
      } else if start < s {
        make_node(s, e, insert(l, start, end), r)
      } else {
        make_node(s, e, l, insert(r, start, end))
      }
  }
}

///|
fn overlaps(a_start : Int, a_end : Int, b_start : Int, b_end : Int) -> Bool {
  a_start <= b_end && b_start <= a_end
}

///|
/// Find one interval that overlaps [qs, qe] if any.
pub fn find_overlap(t : Tree, qs : Int, qe : Int) -> (Int, Int)? {
  match t {
    Empty => None
    Node(start=s, end=e, left=l, right=r, max_end=_) =>
      if overlaps(s, e, qs, qe) {
        Some((s, e))
      } else if l is Empty {
        find_overlap(r, qs, qe)
      } else if max_end(l) >= qs {
        find_overlap(l, qs, qe)
      } else {
        find_overlap(r, qs, qe)
      }
  }
}

///|
/// Build an interval tree by inserting intervals in order.
pub fn from_array(arr : ArrayView[(Int, Int)]) -> Tree {
  for interval in arr; tree = Empty {
    let (s, e) = interval
    continue insert(tree, s, e)
  } nobreak {
    tree
  }
}

///|
test "persistent_interval_tree" {
  let tree = from_array([(1, 3), (5, 8), (4, 6), (10, 12)][:])
  assert_eq(find_overlap(tree, 2, 2), Some((1, 3)))
  assert_eq(find_overlap(tree, 7, 9), Some((5, 8)))
  assert_eq(find_overlap(tree, 9, 9), None)
}
