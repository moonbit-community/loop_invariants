// ============================================================================
// Challenge: Persistent Interval Tree
// BST by start with max_end augmentation for overlap queries
// ============================================================================

///|
enum Tree {
  Empty
  Node(start~ : Int, end~ : Int, max_end~ : Int, left~ : Tree, right~ : Tree)
} derive(Show)

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
    Tree::Empty => -0x3fffffff
    Tree::Node(start=_, end=_, max_end~, left=_, right=_) => max_end
  }
}

///|
fn size(t : Tree) -> Int {
  match t {
    Tree::Empty => 0
    Tree::Node(start=_, end=_, max_end=_, left~, right~) =>
      1 + size(left) + size(right)
  }
}

///|
fn tree_valid(t : Tree, lo : Int?, hi : Int?) -> Bool {
  match t {
    Tree::Empty => true
    Tree::Node(start=s, end=e, max_end=me, left=l, right=r) => {
      let lo_ok = match lo {
        None => true
        Some(v) => s > v
      }
      let hi_ok = match hi {
        None => true
        Some(v) => s < v
      }
      let computed = max2(e, max2(max_end(l), max_end(r)))
      lo_ok &&
      hi_ok &&
      me == computed &&
      tree_valid(l, lo, Some(s)) &&
      tree_valid(r, Some(s), hi)
    }
  }
}

///|
fn make_node(start : Int, end : Int, left : Tree, right : Tree) -> Tree {
  let me = max2(end, max2(max_end(left), max_end(right)))
  Tree::Node(start~, end~, max_end=me, left~, right~)
}

///|
fn insert(t : Tree, start : Int, end : Int) -> Tree {
  match t {
    Tree::Empty =>
      Tree::Node(start~, end~, max_end=end, left=Tree::Empty, right=Tree::Empty)
    Tree::Node(start=s, end=e, left=l, right=r, max_end=_) =>
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
#warnings("+missing_invariant+missing_reasoning")
fn find_overlap(t : Tree, qs : Int, qe : Int) -> (Int, Int)? {
  for cur = t {
    match cur {
      Tree::Empty => break None
      Tree::Node(start=s, end=e, left=l, right=r, max_end=_) =>
        if overlaps(s, e, qs, qe) {
          break Some((s, e))
        } else if l is Tree::Empty {
          continue r
        } else if max_end(l) >= qs {
          continue l
        } else {
          continue r
        }
    }
  } where {
    invariant: tree_valid(cur, None, None) || cur is Tree::Empty,
    reasoning: (
      #|INVARIANT (Interval search):
      #|If an overlap exists in the original tree, it lies within cur.
      #|MAINTENANCE:
      #|Use max_end(left) to decide whether an overlap can exist in left.
      #|TERMINATION:
      #|Empty subtree means no overlap; otherwise return the first match.
    ),
  }
}

///|
/// Build an interval tree by inserting intervals in order.
#warnings("+missing_invariant+missing_reasoning")
fn from_array(arr : ArrayView[(Int, Int)]) -> Tree {
  let n = arr.length()
  for i = 0, tree = Tree::Empty {
    if i >= n {
      break tree
    } else {
      let (s, e) = arr[i]
      continue i + 1, insert(tree, s, e)
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) <= i,
    invariant: tree_valid(tree, None, None),
    reasoning: (
      #|INVARIANT (Interval tree build):
      #|tree contains the first i intervals and correct max_end values.
      #|MAINTENANCE:
      #|Insert the next interval, recomputing max_end along the path.
      #|TERMINATION:
      #|At i = n, all intervals are inserted.
    ),
  }
}

///|
test "persistent_interval_tree" {
  let tree = from_array([(1, 3), (5, 8), (4, 6), (10, 12)][:])
  assert_eq(find_overlap(tree, 2, 2), Some((1, 3)))
  assert_eq(find_overlap(tree, 7, 9), Some((5, 8)))
  assert_eq(find_overlap(tree, 9, 9), None)
}
