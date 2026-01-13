///|
/// Check if a key exists in the treap.
pub fn Treap::contains(self : Treap, key : Int64) -> Bool {
  find_node(self.root, key) is Some(_)
}

///|
/// Find a node by key using the BST property.
fn find_node(node : TreapNode?, key : Int64) -> TreapNode? {
  loop node {
    None => None
    Some(n) =>
      if key < n.key {
        continue n.left
      } else if key > n.key {
        continue n.right
      } else {
        Some(n)
      }
  }
}
