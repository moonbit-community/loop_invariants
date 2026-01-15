// ============================================================================
// AVL TREE - Self-Balancing Binary Search Tree
// ============================================================================
//
// AVL tree maintains height balance: for every node, heights of left and right
// subtrees differ by at most 1. This guarantees O(log n) height.
//
// BALANCE FACTOR: bf(node) = height(right) - height(left)
// Valid values: -1, 0, +1
//
// ROTATIONS:
// - Left rotation: when right subtree is too tall
// - Right rotation: when left subtree is too tall
// - Left-Right: left child is right-heavy
// - Right-Left: right child is left-heavy
//
// INVARIANTS:
// 1. BST property: left < node < right
// 2. Balance: |height(left) - height(right)| <= 1 for all nodes
// 3. Height of tree is O(log n)
//
// TIME COMPLEXITY: O(log n) for insert/delete/search
// SPACE COMPLEXITY: O(n)

///|
priv struct AVLNode[T] {
  mut key : T
  mut height : Int
  mut left : Int
  mut right : Int
}

///|
fn[T] AVLNode::new(key : T) -> AVLNode[T] {
  { key, height: 1, left: -1, right: -1 }
}

///|
priv struct AVLTree[T] {
  nodes : Array[AVLNode[T]]
  mut root : Int
  mut free_list : Int
}

///|
fn[T] AVLTree::new() -> AVLTree[T] {
  { nodes: [], root: -1, free_list: -1 }
}

///|
fn[T] AVLTree::height(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    0
  } else {
    self.nodes[node].height
  }
}

///|
fn[T] AVLTree::update_height(self : AVLTree[T], node : Int) -> Unit {
  if node < 0 {
    return
  }
  let lh = self.height(self.nodes[node].left)
  let rh = self.height(self.nodes[node].right)
  self.nodes[node].height = 1 + (if lh > rh { lh } else { rh })
}

///|
fn[T] AVLTree::balance_factor(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    return 0
  }
  self.height(self.nodes[node].right) - self.height(self.nodes[node].left)
}

///|
/// Right rotation
fn[T] AVLTree::rotate_right(self : AVLTree[T], y : Int) -> Int {
  let x = self.nodes[y].left
  let t2 = self.nodes[x].right
  self.nodes[x].right = y
  self.nodes[y].left = t2
  self.update_height(y)
  self.update_height(x)
  x
}

///|
/// Left rotation
fn[T] AVLTree::rotate_left(self : AVLTree[T], x : Int) -> Int {
  let y = self.nodes[x].right
  let t2 = self.nodes[y].left
  self.nodes[y].left = x
  self.nodes[x].right = t2
  self.update_height(x)
  self.update_height(y)
  y
}

///|
/// Balance node after insertion/deletion
fn[T] AVLTree::balance(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    return node
  }
  self.update_height(node)
  let bf = self.balance_factor(node)

  // Left heavy
  if bf < -1 {
    if self.balance_factor(self.nodes[node].left) > 0 {
      // Left-Right case
      self.nodes[node].left = self.rotate_left(self.nodes[node].left)
    }
    return self.rotate_right(node)
  }

  // Right heavy
  if bf > 1 {
    if self.balance_factor(self.nodes[node].right) < 0 {
      // Right-Left case
      self.nodes[node].right = self.rotate_right(self.nodes[node].right)
    }
    return self.rotate_left(node)
  }
  node
}

///|
fn[T] AVLTree::alloc_node(self : AVLTree[T], key : T) -> Int {
  if self.free_list >= 0 {
    let idx = self.free_list
    self.free_list = self.nodes[idx].left
    self.nodes[idx].key = key
    self.nodes[idx].height = 1
    self.nodes[idx].left = -1
    self.nodes[idx].right = -1
    return idx
  }
  let idx = self.nodes.length()
  self.nodes.push(AVLNode::new(key))
  idx
}

///|
fn[T : Compare] AVLTree::insert_rec(
  self : AVLTree[T],
  node : Int,
  key : T,
) -> Int {
  if node < 0 {
    return self.alloc_node(key)
  }
  if key < self.nodes[node].key {
    self.nodes[node].left = self.insert_rec(self.nodes[node].left, key)
  } else {
    self.nodes[node].right = self.insert_rec(self.nodes[node].right, key)
  }
  self.balance(node)
}

///|
fn[T : Compare] AVLTree::insert(self : AVLTree[T], key : T) -> Unit {
  self.root = self.insert_rec(self.root, key)
}

///|
fn[T] AVLTree::inorder_collect(
  self : AVLTree[T],
  node : Int,
  out : Array[T],
) -> Unit {
  if node < 0 {
    return
  }
  self.inorder_collect(self.nodes[node].left, out)
  out.push(self.nodes[node].key)
  self.inorder_collect(self.nodes[node].right, out)
}

///|
fn[T] AVLTree::to_sorted_array(self : AVLTree[T]) -> Array[T] {
  let out : Array[T] = []
  self.inorder_collect(self.root, out)
  out
}

///|
/// Insert all keys into an AVL tree and return the in-order traversal.
/// The result is sorted in nondecreasing order (duplicates preserved).
pub fn[T : Compare] avl_sorted(keys : ArrayView[T]) -> Array[T] {
  let tree = AVLTree::new()
  for key in keys {
    tree.insert(key)
  }
  tree.to_sorted_array()
}

///|
fn[T] AVLTree::find_min(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    return -1
  }
  for cur = node; self.nodes[cur].left >= 0; {
    continue self.nodes[cur].left
  } else {
    cur
  } where {
    invariant: cur >= 0 && cur < self.nodes.length(),
    reasoning: (
      #|INVARIANT (find min):
      #|cur points to a valid node in the left subtree of the original node.
      #|MAINTENANCE:
      #|Follow left child until no more left children exist.
      #|TERMINATION:
      #|Tree is finite; eventually reach a node with no left child.
    ),
  }
}

///|
fn[T : Compare] AVLTree::delete_rec(
  self : AVLTree[T],
  node : Int,
  key : T,
) -> Int {
  if node < 0 {
    return -1
  }
  if key < self.nodes[node].key {
    self.nodes[node].left = self.delete_rec(self.nodes[node].left, key)
  } else if key > self.nodes[node].key {
    self.nodes[node].right = self.delete_rec(self.nodes[node].right, key)
  } else {
    // Found node to delete
    if self.nodes[node].left < 0 || self.nodes[node].right < 0 {
      let child = if self.nodes[node].left >= 0 {
        self.nodes[node].left
      } else {
        self.nodes[node].right
      }
      // Free node
      self.nodes[node].left = self.free_list
      self.free_list = node
      return child
    }

    // Node has two children: replace with inorder successor
    let successor = self.find_min(self.nodes[node].right)
    self.nodes[node].key = self.nodes[successor].key
    self.nodes[node].right = self.delete_rec(
      self.nodes[node].right,
      self.nodes[successor].key,
    )
  }
  self.balance(node)
}

///|
fn[T : Compare] AVLTree::delete(self : AVLTree[T], key : T) -> Bool {
  let old_root = self.root
  self.root = self.delete_rec(self.root, key)
  old_root != self.root || self.root >= 0
}

///|
fn[T : Compare] AVLTree::search(self : AVLTree[T], key : T) -> Bool {
  for node = self.root; node >= 0; {
    if key == self.nodes[node].key {
      break true
    } else if key < self.nodes[node].key {
      continue self.nodes[node].left
    } else {
      continue self.nodes[node].right
    }
  } else {
    false
  } where {
    invariant: node >= -1,
    reasoning: (
      #|INVARIANT (BST search):
      #|If key exists in tree, it must be in subtree rooted at node.
      #|MAINTENANCE:
      #|Compare key and descend left or right preserving BST property.
      #|TERMINATION:
      #|Find key (return true) or reach -1 (return false).
    ),
  }
}

///|
fn[T] AVLTree::min(self : AVLTree[T]) -> T? {
  let m = self.find_min(self.root)
  if m < 0 {
    None
  } else {
    Some(self.nodes[m].key)
  }
}

///|
fn[T] AVLTree::max(self : AVLTree[T]) -> T? {
  if self.root < 0 {
    return None
  }
  let cur = for cur = self.root; self.nodes[cur].right >= 0; {
    continue self.nodes[cur].right
  } else {
    cur
  } where {
    invariant: cur >= 0 && cur < self.nodes.length(),
    reasoning: (
      #|INVARIANT (find max):
      #|cur points to a valid node in the right subtree.
      #|MAINTENANCE:
      #|Follow right child until no more right children exist.
      #|TERMINATION:
      #|Tree is finite; eventually reach a node with no right child.
    ),
  }
  Some(self.nodes[cur].key)
}

///|
/// Check if tree is balanced (for testing)
fn[T] AVLTree::is_balanced(self : AVLTree[T]) -> Bool {
  fn check(node : Int, tree : AVLTree[T]) -> Bool {
    if node < 0 {
      return true
    }
    let bf = tree.balance_factor(node)
    if bf < -1 || bf > 1 {
      return false
    }
    check(tree.nodes[node].left, tree) && check(tree.nodes[node].right, tree)
  }

  check(self.root, self)
}

///|
fn[T] AVLTree::size(self : AVLTree[T]) -> Int {
  fn count(node : Int, tree : AVLTree[T]) -> Int {
    if node < 0 {
      return 0
    }
    1 + count(tree.nodes[node].left, tree) + count(tree.nodes[node].right, tree)
  }

  count(self.root, self)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "avl insert and search" {
  let tree = AVLTree::new()
  tree.insert(5L)
  tree.insert(3L)
  tree.insert(7L)
  tree.insert(1L)
  tree.insert(9L)
  inspect(tree.search(5L), content="true")
  inspect(tree.search(3L), content="true")
  inspect(tree.search(9L), content="true")
  inspect(tree.search(4L), content="false")
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl left rotation" {
  let tree = AVLTree::new()
  // Inserting in ascending order triggers left rotations
  tree.insert(1L)
  tree.insert(2L)
  tree.insert(3L)
  inspect(tree.is_balanced(), content="true")
  inspect(tree.search(1L), content="true")
  inspect(tree.search(2L), content="true")
  inspect(tree.search(3L), content="true")
}

///|
test "avl right rotation" {
  let tree = AVLTree::new()
  // Inserting in descending order triggers right rotations
  tree.insert(3L)
  tree.insert(2L)
  tree.insert(1L)
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl left-right rotation" {
  let tree = AVLTree::new()
  tree.insert(3L)
  tree.insert(1L)
  tree.insert(2L) // Triggers left-right rotation
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl right-left rotation" {
  let tree = AVLTree::new()
  tree.insert(1L)
  tree.insert(3L)
  tree.insert(2L) // Triggers right-left rotation
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl delete" {
  let tree = AVLTree::new()
  tree.insert(5L)
  tree.insert(3L)
  tree.insert(7L)
  tree.insert(1L)
  tree.insert(4L)
  inspect(tree.search(3L), content="true")
  let _ = tree.delete(3L)
  inspect(tree.search(3L), content="false")
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl min max" {
  let tree = AVLTree::new()
  tree.insert(5L)
  tree.insert(2L)
  tree.insert(8L)
  tree.insert(1L)
  tree.insert(9L)
  inspect(tree.min(), content="Some(1)")
  inspect(tree.max(), content="Some(9)")
}

///|
test "avl size" {
  let tree : AVLTree[Int64] = AVLTree::new()
  inspect(tree.size(), content="0")
  tree.insert(1L)
  tree.insert(2L)
  tree.insert(3L)
  inspect(tree.size(), content="3")
}

///|
test "avl many insertions" {
  let tree = AVLTree::new()
  Array::makei(100, i => i).each(i => tree.insert(i.to_int64()))
  inspect(tree.is_balanced(), content="true")
  inspect(tree.size(), content="100")
  // Height should be around log2(100) ≈ 7
  inspect(tree.height(tree.root) <= 10, content="true")
}

///|
test "avl empty" {
  let tree = AVLTree::new()
  inspect(tree.search(1L), content="false")
  inspect(tree.min(), content="None")
  inspect(tree.is_balanced(), content="true")
}
