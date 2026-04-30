///|
/// Get the k-th smallest element (0-indexed).
pub fn[T] Treap::kth_element(self : Treap[T], k : Int) -> T? {
  kth_helper(self.root, k)
}

///|
/// Walk by subtree sizes to locate the k-th element.
fn[T] kth_helper(node : TreapNode[T]?, k : Int) -> T? {
  for current = node, remaining = k {
    match current {
      None => break None
      Some(n) => {
        let left_size = get_size(n.left)
        if remaining < left_size {
          continue n.left, remaining
        } else if remaining == left_size {
          break Some(n.key)
        } else {
          continue n.right, remaining - left_size - 1
        }
      }
    }
  }
}
