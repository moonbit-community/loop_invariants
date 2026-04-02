///|
/// Check if a key exists in the treap.
pub fn[T : Compare] Treap::contains(self : Treap[T], key : T) -> Bool {
  find_node(self.root, key) is Some(_)
}

///|
/// Find a node by key using the BST property.
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
