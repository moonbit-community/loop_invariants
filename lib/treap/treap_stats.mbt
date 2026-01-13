///|
/// Count elements strictly less than key.
pub fn Treap::count_less_than(self : Treap, key : Int64) -> Int {
  count_less_helper(self.root, key)
}

///|
/// Accumulate counts by skipping whole subtrees when possible.
fn count_less_helper(node : TreapNode?, key : Int64) -> Int {
  loop (node, 0) {
    (None, acc) => acc
    (Some(n), acc) =>
      if n.key < key {
        continue (n.right, acc + 1 + get_size(n.left))
      } else {
        continue (n.left, acc)
      }
  }
}

///|
/// Total number of keys in the treap.
pub fn Treap::size(self : Treap) -> Int {
  get_size(self.root)
}

///|
/// Get the minimum key in the treap.
pub fn Treap::min(self : Treap) -> Int64? {
  min_helper(self.root)
}

///|
/// Descend left until the smallest key is found.
fn min_helper(node : TreapNode?) -> Int64? {
  loop node {
    None => None
    Some(n) =>
      match n.left {
        None => Some(n.key)
        Some(left) => continue Some(left)
      }
  }
}

///|
/// Get the maximum key in the treap.
pub fn Treap::max(self : Treap) -> Int64? {
  max_helper(self.root)
}

///|
/// Descend right until the largest key is found.
fn max_helper(node : TreapNode?) -> Int64? {
  loop node {
    None => None
    Some(n) =>
      match n.right {
        None => Some(n.key)
        Some(right) => continue Some(right)
      }
  }
}

///|
/// Get elements in sorted order.
pub fn Treap::to_array(self : Treap) -> Array[Int64] {
  let result : Array[Int64] = []
  inorder(self.root, result)
  result
}

///|
/// Inorder traversal to collect sorted keys.
fn inorder(node : TreapNode?, result : Array[Int64]) -> Unit {
  match node {
    None => ()
    Some(n) => {
      inorder(n.left, result)
      result.push(n.key)
      inorder(n.right, result)
    }
  }
}
