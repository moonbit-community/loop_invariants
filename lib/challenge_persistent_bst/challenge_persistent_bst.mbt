// ============================================================================
// Challenge: Persistent Binary Search Tree
// Immutable insert and iterative search with bounds invariants
// ============================================================================

///|
pub enum Tree {
  Empty
  Node(value~ : Int, left~ : Tree, right~ : Tree)
} derive(Show)

///|
fn tree_size(t : Tree) -> Int {
  match t {
    Tree::Empty => 0
    Tree::Node(value=_, left~, right~) => 1 + tree_size(left) + tree_size(right)
  }
}

///|
fn within_bounds(value : Int, lo : Int?, hi : Int?) -> Bool {
  let lo_ok = match lo {
    None => true
    Some(l) => value > l
  }
  let hi_ok = match hi {
    None => true
    Some(h) => value < h
  }
  lo_ok && hi_ok
}

///|
fn bst_within(t : Tree, lo : Int?, hi : Int?) -> Bool {
  match t {
    Tree::Empty => true
    Tree::Node(value~, left~, right~) =>
      within_bounds(value, lo, hi) &&
      bst_within(left, lo, Some(value)) &&
      bst_within(right, Some(value), hi)
  }
}

///|
fn bst_valid(t : Tree) -> Bool {
  bst_within(t, None, None)
}

///|
pub fn empty() -> Tree {
  Tree::Empty
}

///|
pub fn size(t : Tree) -> Int {
  tree_size(t)
}

///|
pub fn insert(t : Tree, value : Int) -> Tree {
  match t {
    Tree::Empty => Tree::Node(value~, left=Tree::Empty, right=Tree::Empty)
    Tree::Node(value=v, left=l, right=r) =>
      if value == v {
        t
      } else if value < v {
        Tree::Node(value=v, left=insert(l, value), right=r)
      } else {
        Tree::Node(value=v, left=l, right=insert(r, value))
      }
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn contains(t : Tree, value : Int) -> Bool {
  let none : Int? = None
  for cur = t, lo = none, hi = none {
    match cur {
      Tree::Empty => break false
      Tree::Node(value=v, left=l, right=r) =>
        if value == v {
          break true
        } else if value < v {
          continue l, lo, Some(v)
        } else {
          continue r, Some(v), hi
        }
    }
  } where {
    invariant: bst_within(cur, lo, hi),
    invariant: within_bounds(value, lo, hi),
    reasoning: (
      #|INVARIANT (BST search bounds):
      #|cur is a subtree whose keys stay within (lo, hi), and value respects
      #|the same bounds. Any match must occur inside cur.
      #|MAINTENANCE:
      #|On value < v, restrict to left and set hi=v; on value > v, restrict to
      #|right and set lo=v, preserving the bounds.
      #|TERMINATION:
      #|If cur is empty, value is not in the tree; otherwise a match is found.
    ),
  }
}

///|
/// Build a BST by inserting elements in order.
#warnings("+missing_invariant+missing_reasoning")
pub fn from_array(arr : ArrayView[Int]) -> Tree {
  let n = arr.length()
  for i = 0, tree = Tree::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: tree_size(tree) == i,
    invariant: bst_valid(tree),
    reasoning: (
      #|INVARIANT (BST build):
      #|tree contains the first i elements and satisfies BST ordering.
      #|MAINTENANCE:
      #|Insert arr[i], preserving ordering and increasing size by one.
      #|TERMINATION:
      #|At i = n, all elements are inserted.
    ),
  }
}

///|
pub fn inorder(t : Tree) -> Array[Int] {
  match t {
    Tree::Empty => []
    Tree::Node(value=v, left=l, right=r) => inorder(l) + [v] + inorder(r)
  }
}

///|
test "persistent_bst" {
  let t0 = Tree::Empty
  let t1 = insert(t0, 4)
  let t2 = insert(t1, 2)
  let t3 = insert(t2, 6)
  let t4 = insert(t3, 5)
  assert_eq(contains(t4, 2), true)
  assert_eq(contains(t4, 3), false)
  let built = from_array([4, 2, 6, 5][:])
  assert_eq(inorder(built), [2, 4, 5, 6])
}
