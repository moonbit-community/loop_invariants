// ============================================================================
// Challenge: Persistent Binary Search Tree
// Immutable insert and iterative search with bounds invariants
// ============================================================================

///|
pub enum Tree[T] {
  Empty
  Node(value~ : T, left~ : Tree[T], right~ : Tree[T])
} derive(Show)

///|
fn[T] tree_size(t : Tree[T]) -> Int {
  match t {
    Tree::Empty => 0
    Tree::Node(value=_, left~, right~) => 1 + tree_size(left) + tree_size(right)
  }
}

///|
fn[T : Compare] within_bounds(value : T, lo : T?, hi : T?) -> Bool {
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
fn[T : Compare] bst_within(t : Tree[T], lo : T?, hi : T?) -> Bool {
  match t {
    Tree::Empty => true
    Tree::Node(value~, left~, right~) =>
      within_bounds(value, lo, hi) &&
      bst_within(left, lo, Some(value)) &&
      bst_within(right, Some(value), hi)
  }
}

///|
fn[T : Compare] bst_valid(t : Tree[T]) -> Bool {
  bst_within(t, None, None)
}

///|
/// Create an empty persistent BST.
pub fn[T] empty() -> Tree[T] {
  Tree::Empty
}

///|
/// Return number of nodes in the tree.
pub fn[T] size(t : Tree[T]) -> Int {
  tree_size(t)
}

///|
/// Insert a value and return the new tree.
pub fn[T : Compare] insert(t : Tree[T], value : T) -> Tree[T] {
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
/// Check whether value exists in the tree.
#warnings("+missing_invariant+missing_reasoning")
pub fn[T : Compare] contains(t : Tree[T], value : T) -> Bool {
  let none : T? = None
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
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T] {
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
/// Return an in-order traversal (sorted values).
pub fn[T] inorder(t : Tree[T]) -> Array[T] {
  match t {
    Tree::Empty => []
    Tree::Node(value=v, left=l, right=r) => inorder(l) + [v] + inorder(r)
  }
}
