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
priv struct AVLNode {
  mut key : Int64
  mut height : Int
  mut left : Int
  mut right : Int
}

///|
fn AVLNode::new(key : Int64) -> AVLNode {
  { key, height: 1, left: -1, right: -1 }
}

///|
priv struct AVLTree {
  nodes : Array[AVLNode]
  mut root : Int
  mut free_list : Int
}

///|
fn AVLTree::new() -> AVLTree {
  { nodes: [], root: -1, free_list: -1 }
}

///|
fn AVLTree::height(self : AVLTree, node : Int) -> Int {
  if node < 0 { 0 } else { self.nodes[node].height }
}

///|
fn AVLTree::update_height(self : AVLTree, node : Int) -> Unit {
  if node < 0 {
    return
  }
  let lh = self.height(self.nodes[node].left)
  let rh = self.height(self.nodes[node].right)
  self.nodes[node].height = 1 + (if lh > rh { lh } else { rh })
}

///|
fn AVLTree::balance_factor(self : AVLTree, node : Int) -> Int {
  if node < 0 {
    return 0
  }
  self.height(self.nodes[node].right) - self.height(self.nodes[node].left)
}

///|
/// Right rotation
fn AVLTree::rotate_right(self : AVLTree, y : Int) -> Int {
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
fn AVLTree::rotate_left(self : AVLTree, x : Int) -> Int {
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
fn AVLTree::balance(self : AVLTree, node : Int) -> Int {
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
fn AVLTree::alloc_node(self : AVLTree, key : Int64) -> Int {
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
fn AVLTree::insert_rec(self : AVLTree, node : Int, key : Int64) -> Int {
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
fn AVLTree::insert(self : AVLTree, key : Int64) -> Unit {
  self.root = self.insert_rec(self.root, key)
}

///|
fn AVLTree::find_min(self : AVLTree, node : Int) -> Int {
  if node < 0 {
    return -1
  }
  let mut cur = node
  while self.nodes[cur].left >= 0 {
    cur = self.nodes[cur].left
  }
  cur
}

///|
fn AVLTree::delete_rec(self : AVLTree, node : Int, key : Int64) -> Int {
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
fn AVLTree::delete(self : AVLTree, key : Int64) -> Bool {
  let old_root = self.root
  self.root = self.delete_rec(self.root, key)
  old_root != self.root || self.root >= 0
}

///|
fn AVLTree::search(self : AVLTree, key : Int64) -> Bool {
  let mut node = self.root
  while node >= 0 {
    if key == self.nodes[node].key {
      return true
    } else if key < self.nodes[node].key {
      node = self.nodes[node].left
    } else {
      node = self.nodes[node].right
    }
  }
  false
}

///|
fn AVLTree::min(self : AVLTree) -> Int64? {
  let m = self.find_min(self.root)
  if m < 0 { None } else { Some(self.nodes[m].key) }
}

///|
fn AVLTree::max(self : AVLTree) -> Int64? {
  if self.root < 0 {
    return None
  }
  let mut cur = self.root
  while self.nodes[cur].right >= 0 {
    cur = self.nodes[cur].right
  }
  Some(self.nodes[cur].key)
}

///|
/// Check if tree is balanced (for testing)
fn AVLTree::is_balanced(self : AVLTree) -> Bool {
  fn check(tree : AVLTree, node : Int) -> Bool {
    if node < 0 {
      return true
    }
    let bf = tree.balance_factor(node)
    if bf < -1 || bf > 1 {
      return false
    }
    check(tree, tree.nodes[node].left) && check(tree, tree.nodes[node].right)
  }
  check(self, self.root)
}

///|
fn AVLTree::size(self : AVLTree) -> Int {
  fn count(tree : AVLTree, node : Int) -> Int {
    if node < 0 {
      return 0
    }
    1 + count(tree, tree.nodes[node].left) + count(tree, tree.nodes[node].right)
  }
  count(self, self.root)
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
  let tree = AVLTree::new()
  inspect(tree.size(), content="0")

  tree.insert(1L)
  tree.insert(2L)
  tree.insert(3L)
  inspect(tree.size(), content="3")
}

///|
test "avl many insertions" {
  let tree = AVLTree::new()
  for i = 0; i < 100; i = i + 1 {
    tree.insert(i.to_int64())
  }
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
