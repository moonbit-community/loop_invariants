// ============================================================================
// Challenge: Persistent Li Chao Tree
// Line container for minimum queries on a fixed domain
// ============================================================================

///|
/// A line `y = m * x + b` stored in the Li Chao tree.
///
/// `m` is the slope and `b` is the y-intercept. The tree compares lines
/// by their value at a fixed `x`, so each `Line` is evaluated as
/// `m * x + b` during `insert` and `query`. Construct with a struct
/// literal `{ m: ..., b: ... }`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let line : @challenge_persistent_li_chao_tree.Line = { m: 2, b: -5 }
///   let t = @challenge_persistent_li_chao_tree.insert(
///     @challenge_persistent_li_chao_tree.empty(),
///     line,
///     0,
///     10,
///   )
///   @debug.assert_eq(@challenge_persistent_li_chao_tree.query(t, 0, 0, 10), -5)
/// }
/// ```
pub(all) struct Line {
  m : Int
  b : Int
} derive(Debug)

///|
/// Persistent Li Chao segment tree for minimum-of-lines queries.
///
/// Over a fixed integer domain `[l, r)`, each segment tree node holds
/// the line that achieves the minimum value at the midpoint of its
/// range. `insert` walks down the tree, swapping the stored line with
/// a new candidate when the candidate is better at the midpoint and
/// recursing into the side where the lines cross, in `O(log (r - l))`
/// time. `query` returns the minimum value at a given `x` in
/// `O(log (r - l))`. Inserts are persistent: only the path is copied,
/// other subtrees are shared. See `empty`, `size`, `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let lines : Array[@challenge_persistent_li_chao_tree.Line] = [
///     { m: 1, b: 0 },
///     { m: -1, b: 10 },
///     { m: 2, b: -5 },
///   ]
///   let t = @challenge_persistent_li_chao_tree.from_array(lines, 0, 10)
///   @debug.assert_eq(@challenge_persistent_li_chao_tree.query(t, 5, 0, 10), 5)
/// }
/// ```
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
  @debug.assert_eq(query(tree, 0, 0, 10), -5)
  @debug.assert_eq(query(tree, 5, 0, 10), 5)
  @debug.assert_eq(query(tree, 9, 0, 10), 1)
}
