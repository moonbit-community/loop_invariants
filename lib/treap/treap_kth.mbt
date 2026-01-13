///|
/// Get the k-th smallest element (0-indexed).
pub fn Treap::kth_element(self : Treap, k : Int) -> Int64? {
  kth_helper(self.root, k)
}

///|
/// Walk by subtree sizes to locate the k-th element.
fn kth_helper(node : TreapNode?, k : Int) -> Int64? {
  loop (node, k) {
    (None, _) => None
    (Some(n), k) => {
      let left_size = get_size(n.left)
      if k < left_size {
        continue (n.left, k)
      } else if k == left_size {
        Some(n.key)
      } else {
        continue (n.right, k - left_size - 1)
      }
    }
  }
}
