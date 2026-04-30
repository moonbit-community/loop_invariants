///|
/// Returns `true` if the treap contains at least one node with the given key.
///
/// Uses the BST property to descend without visiting irrelevant branches.
/// Runs in O(log n) expected time.
pub fn[T : Compare] Treap::contains(self : Treap[T], key : T) -> Bool {
  find_node(self.root, key) is Some(_)
}

///|
/// Searches for a node with the given key using the BST property.
///
/// Starts at the root and, at each node, goes left when `key` is smaller,
/// right when `key` is larger, and returns the node when equal.
///
/// The iterative loop avoids stack growth; the loop variable `current` takes
/// the role of the recursion stack pointer.
///
/// Returns `Some(node)` on success, `None` if `key` is not present.
fn[T : Compare] find_node(node : TreapNode[T]?, key : T) -> TreapNode[T]? {
  for current = node {
    match current {
      None => break None
      Some(n) =>
        if key < n.key {
          continue n.left
        } else if key > n.key {
          continue n.right
        } else {
          break Some(n)
        }
    }
  }
}
