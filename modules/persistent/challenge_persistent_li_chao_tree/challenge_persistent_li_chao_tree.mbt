// ============================================================================
// Challenge: Persistent Li Chao Tree
// Line container for minimum queries on a fixed domain
// ============================================================================

///|
pub(all) struct Line {
  m : Int
  b : Int
} derive(Debug)

///|
pub enum Node {
  Empty
  Node(line~ : Line, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn eval(line : Line, x : Int) -> Int {
  line.m * x + line.b
}

///|
fn line_count(t : Node) -> Int {
  match t {
    Empty => 0
    Node(line=_, left=l, right=r) => 1 + line_count(l) + line_count(r)
  }
}

///|
fn insert_line(node : Node, line : Line, l : Int, r : Int) -> Node {
  match node {
    Empty => Node(line~, left=Empty, right=Empty)
    Node(line=cur, left~, right~) => {
      let mid = (l + r) / 2
      let left_better = eval(line, l) < eval(cur, l)
      let mid_better = eval(line, mid) < eval(cur, mid)
      let best = if mid_better { line } else { cur }
      let other = if mid_better { cur } else { line }
      if r - l == 1 {
        Node(line=best, left~, right~)
      } else if left_better != mid_better {
        let new_left = insert_line(left, other, l, mid)
        Node(line=best, left=new_left, right~)
      } else {
        let new_right = insert_line(right, other, mid, r)
        Node(line=best, left~, right=new_right)
      }
    }
  }
}

///|
/// Create an empty Li Chao tree.
pub fn empty() -> Node {
  Empty
}

///|
/// Return the number of lines stored in the tree.
pub fn size(tree : Node) -> Int {
  line_count(tree)
}

///|
/// Insert a line over domain [l, r) and return the new tree.
pub fn insert(tree : Node, line : Line, l : Int, r : Int) -> Node {
  insert_line(tree, line, l, r)
}

///|
/// Query the minimum value at x over domain [l, r).
pub fn query(node : Node, x : Int, l : Int, r : Int) -> Int {
  match node {
    Empty => 0x3fffffff
    Node(line=ln, left~, right~) => {
      let mid = (l + r) / 2
      let best = eval(ln, x)
      if r - l == 1 {
        best
      } else if x < mid {
        let left_best = query(left, x, l, mid)
        if left_best < best {
          left_best
        } else {
          best
        }
      } else {
        let right_best = query(right, x, mid, r)
        if right_best < best {
          right_best
        } else {
          best
        }
      }
    }
  }
}

///|
/// Build a Li Chao tree by inserting lines in order.
pub fn from_array(lines : ArrayView[Line], l : Int, r : Int) -> Node {
  for line in lines; tree = Empty {
    continue insert(tree, line, l, r)
  } nobreak {
    tree
  }
}

///|
test "persistent_li_chao_tree" {
  let lines : ReadOnlyArray[Line] = [
    { m: 1, b: 0 },
    { m: -1, b: 10 },
    { m: 2, b: -5 },
  ]
  let tree = from_array(lines, 0, 10)
  assert_eq(query(tree, 0, 0, 10), -5)
  assert_eq(query(tree, 5, 0, 10), 5)
  assert_eq(query(tree, 9, 0, 10), 1)
}
