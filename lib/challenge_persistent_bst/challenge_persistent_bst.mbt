// ============================================================================
// Challenge: Persistent Binary Search Tree
// Immutable insert and iterative search with bounds invariants
// ============================================================================

///|
pub enum Tree[T] {
  Empty
  Node(value~ : T, left~ : Tree[T], right~ : Tree[T])
} derive(Debug)

///|
fn[T] tree_size(t : Tree[T]) -> Int {
  match t {
    Empty => 0
    Node(value=_, left~, right~) => 1 + tree_size(left) + tree_size(right)
  }
}

///|

///|
/// Create an empty persistent BST.
pub fn[T] empty() -> Tree[T] {
  Empty
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
    Empty => Node(value~, left=Empty, right=Empty)
    Node(value=v, left=l, right=r) =>
      if value == v {
        t
      } else if value < v {
        Node(value=v, left=insert(l, value), right=r)
      } else {
        Node(value=v, left=l, right=insert(r, value))
      }
  }
}

///|
/// Check whether value exists in the tree.
pub fn[T : Compare] contains(t : Tree[T], value : T) -> Bool {
  match t {
    Empty => false
    Node(value=v, left=l, right=r) =>
      if value == v {
        true
      } else if value < v {
        contains(l, value)
      } else {
        contains(r, value)
      }
  }
}

///|
/// Build a BST by inserting elements in order.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T] {
  for value in arr; tree = Empty {
    continue insert(tree, value)
  } nobreak {
    tree
  }
}

///|
/// Return an in-order traversal (sorted values).
pub fn[T] inorder(t : Tree[T]) -> Array[T] {
  match t {
    Empty => []
    Node(value=v, left=l, right=r) => inorder(l) + [v] + inorder(r)
  }
}
