///|
/// Count elements strictly less than key.
pub fn[T : Compare] Treap::count_less_than(self : Treap[T], key : T) -> Int {
  count_less_helper(self.root, key)
}

///|
/// Accumulate counts by skipping whole subtrees when possible.
fn[T : Compare] count_less_helper(node : TreapNode[T]?, key : T) -> Int {
  for current = node, acc = 0 {
    match current {
      None => break acc
      Some(n) =>
        if n.key < key {
          continue n.right, acc + 1 + get_size(n.left)
        } else {
          continue n.left, acc
        }
    }
  }
}

///|
/// Total number of keys in the treap.
pub fn[T] Treap::size(self : Treap[T]) -> Int {
  get_size(self.root)
}

///|
/// Get the minimum key in the treap.
pub fn[T] Treap::min(self : Treap[T]) -> T? {
  min_helper(self.root)
}

///|
/// Descend left until the smallest key is found.
fn[T] min_helper(node : TreapNode[T]?) -> T? {
  for current = node {
    match current {
      None => break None
      Some(n) =>
        match n.left {
          None => break Some(n.key)
          Some(left) => continue Some(left)
        }
    }
  }
}

///|
/// Get the maximum key in the treap.
pub fn[T] Treap::max(self : Treap[T]) -> T? {
  max_helper(self.root)
}

///|
/// Descend right until the largest key is found.
fn[T] max_helper(node : TreapNode[T]?) -> T? {
  for current = node {
    match current {
      None => break None
      Some(n) =>
        match n.right {
          None => break Some(n.key)
          Some(right) => continue Some(right)
        }
    }
  }
}

///|
/// Get elements in sorted order.
pub fn[T] Treap::to_array(self : Treap[T]) -> Array[T] {
  let result : Array[T] = []
  inorder(self.root, result)
  result
}

///|
/// Inorder traversal to collect sorted keys.
fn[T] inorder(node : TreapNode[T]?, result : Array[T]) -> Unit {
  match node {
    None => ()
    Some(n) => {
      inorder(n.left, result)
      result.push(n.key)
      inorder(n.right, result)
    }
  }
}
