// ============================================================================
// Challenge: Persistent Li Chao Tree
// Line container for minimum queries on a fixed domain
// ============================================================================

///|
pub(all) struct Line {
  m : Int
  b : Int
} derive(Show)

///|
pub enum Node {
  Empty
  Node(line~ : Line, left~ : Node, right~ : Node)
} derive(Show)

///|
fn eval(line : Line, x : Int) -> Int {
  line.m * x + line.b
}

///|
fn line_count(t : Node) -> Int {
  match t {
    Node::Empty => 0
    Node::Node(line=_, left=l, right=r) => 1 + line_count(l) + line_count(r)
  }
}

///|
fn insert_line(node : Node, line : Line, l : Int, r : Int) -> Node {
  match node {
    Node::Empty => Node::Node(line~, left=Node::Empty, right=Node::Empty)
    Node::Node(line=cur, left~, right~) => {
      let mid = (l + r) / 2
      let left_better = eval(line, l) < eval(cur, l)
      let mid_better = eval(line, mid) < eval(cur, mid)
      let best = if mid_better { line } else { cur }
      let other = if mid_better { cur } else { line }
      if r - l == 1 {
        Node::Node(line=best, left~, right~)
      } else if left_better != mid_better {
        let new_left = insert_line(left, other, l, mid)
        Node::Node(line=best, left=new_left, right~)
      } else {
        let new_right = insert_line(right, other, mid, r)
        Node::Node(line=best, left~, right=new_right)
      }
    }
  }
}

///|
pub fn empty() -> Node {
  Node::Empty
}

///|
pub fn size(tree : Node) -> Int {
  line_count(tree)
}

///|
pub fn insert(tree : Node, line : Line, l : Int, r : Int) -> Node {
  insert_line(tree, line, l, r)
}

///|
pub fn query(node : Node, x : Int, l : Int, r : Int) -> Int {
  match node {
    Node::Empty => 0x3fffffff
    Node::Node(line=ln, left~, right~) => {
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
#warnings("+missing_invariant+missing_reasoning")
pub fn from_array(lines : ArrayView[Line], l : Int, r : Int) -> Node {
  let n = lines.length()
  for i = 0, tree = Node::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, lines[i], l, r)
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: line_count(tree) == i,
    reasoning: (
      #|INVARIANT (Li Chao build):
      #|tree contains the first i lines over domain [l, r).
      #|MAINTENANCE:
      #|Insert lines[i], preserving the Li Chao structure.
      #|TERMINATION:
      #|At i = n, all lines are inserted.
    ),
  }
}

///|
test "persistent_li_chao_tree" {
  let lines = [
    Line::{ m: 1, b: 0 },
    Line::{ m: -1, b: 10 },
    Line::{ m: 2, b: -5 },
  ]
  let tree = from_array(lines[:], 0, 10)
  assert_eq(query(tree, 0, 0, 10), -5)
  assert_eq(query(tree, 5, 0, 10), 5)
  assert_eq(query(tree, 9, 0, 10), 1)
}
