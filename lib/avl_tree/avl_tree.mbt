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
/// A single node in an arena-allocated AVL tree.
///
/// Nodes are stored in a flat array (`AVLTree.nodes`) and referenced by integer
/// index. The sentinel index -1 represents the absence of a child (i.e., nil).
///
/// Fields:
/// - `key`    : the value stored at this node
/// - `height` : cached height of the subtree rooted here (leaf = 1)
/// - `left`   : index of the left child, or -1 if none
/// - `right`  : index of the right child, or -1 if none
priv struct AVLNode[T] {
  mut key : T
  mut height : Int
  mut left : Int
  mut right : Int
}

///|
/// Creates a fresh leaf node with the given key.
/// The new node has height 1 and no children.
fn[T] AVLNode::AVLNode(key : T) -> AVLNode[T] {
  { key, height: 1, left: -1, right: -1 }
}

///|
/// Arena-allocated AVL tree.
///
/// All nodes live in the `nodes` array. The tree is navigated through integer
/// indices rather than pointers; -1 is the nil sentinel.
///
/// A `free_list` threads deleted nodes together so their slots can be reused
/// on the next allocation, keeping the arena compact.
///
/// Fields:
/// - `nodes`     : flat array holding every allocated node
/// - `root`      : index of the root node, or -1 for an empty tree
/// - `free_list` : head of the singly-linked list of free slots (linked via
///                 the `left` field of each freed node), or -1 when empty
priv struct AVLTree[T] {
  nodes : Array[AVLNode[T]]
  mut root : Int
  mut free_list : Int
}

///|
/// Creates an empty AVL tree with no nodes allocated.
fn[T] AVLTree::AVLTree() -> AVLTree[T] {
  { nodes: [], root: -1, free_list: -1 }
}

///|
/// Returns the cached height of the subtree rooted at `node`.
/// Returns 0 for the nil sentinel (-1), matching the convention that an empty
/// subtree has height 0.
fn[T] AVLTree::height(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    0
  } else {
    self.nodes[node].height
  }
}

///|
/// Recomputes and stores the height of `node` from its children's heights.
/// Height is defined as `1 + max(height(left), height(right))`.
/// Does nothing for the nil sentinel.
fn[T] AVLTree::update_height(self : AVLTree[T], node : Int) -> Unit {
  if node < 0 {
    return
  }
  let lh = self.height(self.nodes[node].left)
  let rh = self.height(self.nodes[node].right)
  self.nodes[node].height = 1 + (if lh > rh { lh } else { rh })
}

///|
/// Returns the balance factor of `node`:
/// `balance_factor = height(right) - height(left)`.
///
/// A value of -1, 0, or +1 means the node is balanced.
/// -2 means the left subtree is too tall; +2 means the right subtree is too
/// tall. Both cases require a rotation.
/// Returns 0 for the nil sentinel.
fn[T] AVLTree::balance_factor(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    return 0
  }
  self.height(self.nodes[node].right) - self.height(self.nodes[node].left)
}

///|
/// Performs a right rotation rooted at `y` and returns the new root index.
///
/// Used when the left subtree of `y` is too tall (balance factor <= -2).
/// The left child `x` becomes the new root; `y` becomes `x`'s right child;
/// `x`'s former right subtree becomes `y`'s new left subtree.
///
/// ```
///     y                 x
///    / \               / \
///   x   C   --->      A   y
///  / \                   / \
/// A   B                 B   C
/// ```
///
/// In-order traversal is preserved: A, x, B, y, C.
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
/// Performs a left rotation rooted at `x` and returns the new root index.
///
/// Used when the right subtree of `x` is too tall (balance factor >= +2).
/// The right child `y` becomes the new root; `x` becomes `y`'s left child;
/// `y`'s former left subtree becomes `x`'s new right subtree.
///
/// ```
///   x                     y
///  / \                   / \
/// A   y      --->        x   C
///    / \               / \
///   B   C             A   B
/// ```
///
/// In-order traversal is preserved: A, x, B, y, C.
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
/// Restores the AVL balance invariant at `node` after an insertion or deletion,
/// and returns the (possibly new) root of this subtree.
///
/// The four rebalancing cases are:
///
/// - `bf = -2, bf(left) <= 0`  : left-left   -> single right rotation
/// - `bf = -2, bf(left)  > 0`  : left-right  -> left rotation on child, then
///                                              right rotation on node
/// - `bf = +2, bf(right) >= 0` : right-right -> single left rotation
/// - `bf = +2, bf(right)  < 0` : right-left  -> right rotation on child, then
///                                              left rotation on node
///
/// Returns `node` unchanged when the balance factor is already in {-1, 0, +1}.
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
/// Allocates a new node for `key`, reusing a slot from the free list when one
/// is available, or appending a fresh slot to the arena otherwise.
/// Returns the index of the allocated node.
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
  self.nodes.push(AVLNode(key))
  idx
}

///|
/// Recursively inserts `key` into the subtree rooted at `node`, rebalancing on
/// the way back up. Returns the (possibly new) root index of the subtree.
///
/// Duplicates are allowed: a key equal to the current node's key is inserted
/// into the right subtree.
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
/// Inserts `key` into the tree, updating the root if necessary.
/// Runs in O(log n) time. Duplicates are preserved.
fn[T : Compare] AVLTree::insert(self : AVLTree[T], key : T) -> Unit {
  self.root = self.insert_rec(self.root, key)
}

///|
/// Appends the keys in the subtree rooted at `node` to `out` in ascending
/// (in-order) order. This is a standard recursive in-order traversal:
/// visit left, emit key, visit right.
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
/// Returns all keys in the tree as a new array in nondecreasing order.
/// Runs in O(n) time (one visit per node).
fn[T] AVLTree::to_sorted_array(self : AVLTree[T]) -> Array[T] {
  let out : Array[T] = []
  self.inorder_collect(self.root, out)
  out
}

///|
/// Inserts every key from `keys` into a fresh AVL tree and returns the keys
/// in nondecreasing (sorted) order.
///
/// Duplicates are preserved: if `keys` contains the same value k times, the
/// result also contains it k times.
///
/// Time complexity: O(n log n) for n keys.
/// Space complexity: O(n).
///
/// # Example
///
/// ```moonbit nocheck
/// let sorted = avl_sorted([3L, 1L, 4L, 1L, 5L][:])
/// // sorted == [1, 1, 3, 4, 5]
/// ```
pub fn[T : Compare] avl_sorted(keys : ArrayView[T]) -> Array[T] {
  let tree = AVLTree()
  for key in keys {
    tree.insert(key)
  }
  tree.to_sorted_array()
}

///|
/// Returns the index of the node with the smallest key in the subtree rooted
/// at `node`. Follows left children until reaching a node with no left child.
/// Returns -1 if the subtree is empty.
fn[T] AVLTree::find_min(self : AVLTree[T], node : Int) -> Int {
  if node < 0 {
    return -1
  }
  for cur = node; self.nodes[cur].left >= 0; {
    continue self.nodes[cur].left
  } nobreak {
    cur
  } where {
    proof_invariant: cur >= 0 && cur < self.nodes.length(),
    proof_reasoning: (
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
/// Recursively deletes the first occurrence of `key` in the subtree rooted at
/// `node`. Returns a pair `(new_root, deleted)` where `new_root` is the
/// (possibly new) root index after rebalancing, and `deleted` indicates whether
/// a node was actually removed.
///
/// When the target node has two children, it is replaced by its in-order
/// successor (the minimum of the right subtree). The freed node's slot is
/// returned to the free list for future reuse.
fn[T : Compare] AVLTree::delete_rec(
  self : AVLTree[T],
  node : Int,
  key : T,
) -> (Int, Bool) {
  if node < 0 {
    return (-1, false)
  }
  if key < self.nodes[node].key {
    let (new_left, deleted) = self.delete_rec(self.nodes[node].left, key)
    if !deleted {
      return (node, false)
    }
    self.nodes[node].left = new_left
    return (self.balance(node), true)
  } else if key > self.nodes[node].key {
    let (new_right, deleted) = self.delete_rec(self.nodes[node].right, key)
    if !deleted {
      return (node, false)
    }
    self.nodes[node].right = new_right
    return (self.balance(node), true)
  }

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
    return (child, true)
  }

  // Node has two children: replace with inorder successor
  let successor = self.find_min(self.nodes[node].right)
  self.nodes[node].key = self.nodes[successor].key
  let (new_right, _) = self.delete_rec(
    self.nodes[node].right,
    self.nodes[successor].key,
  )
  self.nodes[node].right = new_right
  (self.balance(node), true)
}

///|
/// Deletes the first occurrence of `key` from the tree.
/// Returns `true` if a node was found and removed, `false` if `key` was not
/// present. Runs in O(log n) time.
fn[T : Compare] AVLTree::delete(self : AVLTree[T], key : T) -> Bool {
  let (new_root, deleted) = self.delete_rec(self.root, key)
  self.root = new_root
  deleted
}

///|
/// Returns `true` if `key` is present in the tree, `false` otherwise.
///
/// Descends the BST using the standard comparison: go left when `key` is
/// smaller, go right when `key` is larger, return true on equality.
/// Runs in O(log n) time guaranteed by the AVL height bound.
fn[T : Compare] AVLTree::search(self : AVLTree[T], key : T) -> Bool {
  for node = self.root; node >= 0; {
    if key == self.nodes[node].key {
      break true
    } else if key < self.nodes[node].key {
      continue self.nodes[node].left
    } else {
      continue self.nodes[node].right
    }
  } nobreak {
    false
  } where {
    proof_invariant: node >= -1,
    proof_reasoning: (
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
/// Returns `Some(min_key)` if the tree is non-empty, or `None` for an empty
/// tree. Finds the leftmost node in O(log n) time.
fn[T] AVLTree::min(self : AVLTree[T]) -> T? {
  let m = self.find_min(self.root)
  if m < 0 {
    None
  } else {
    Some(self.nodes[m].key)
  }
}

///|
/// Returns `Some(max_key)` if the tree is non-empty, or `None` for an empty
/// tree. Finds the rightmost node by following right children in O(log n) time.
fn[T] AVLTree::max(self : AVLTree[T]) -> T? {
  if self.root < 0 {
    return None
  }
  let cur = for cur = self.root; self.nodes[cur].right >= 0; {
    continue self.nodes[cur].right
  } nobreak {
    cur
  } where {
    proof_invariant: cur >= 0 && cur < self.nodes.length(),
    proof_reasoning: (
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
/// Returns `true` if every node in the tree has a balance factor in {-1, 0, +1}.
/// Used in tests to verify that rotations maintain the AVL invariant.
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
/// Returns the number of keys currently stored in the tree.
/// Counts nodes by a full recursive traversal in O(n) time.
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
  let tree = AVLTree()
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
  let tree = AVLTree()
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
  let tree = AVLTree()
  // Inserting in descending order triggers right rotations
  tree.insert(3L)
  tree.insert(2L)
  tree.insert(1L)
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl left-right rotation" {
  let tree = AVLTree()
  tree.insert(3L)
  tree.insert(1L)
  tree.insert(2L) // Triggers left-right rotation
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl right-left rotation" {
  let tree = AVLTree()
  tree.insert(1L)
  tree.insert(3L)
  tree.insert(2L) // Triggers right-left rotation
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl delete" {
  let tree = AVLTree()
  tree.insert(5L)
  tree.insert(3L)
  tree.insert(7L)
  tree.insert(1L)
  tree.insert(4L)
  inspect(tree.search(3L), content="true")
  inspect(tree.delete(3L), content="true")
  inspect(tree.search(3L), content="false")
  inspect(tree.delete(42L), content="false")
  inspect(tree.is_balanced(), content="true")
}

///|
test "avl min max" {
  let tree = AVLTree()
  tree.insert(5L)
  tree.insert(2L)
  tree.insert(8L)
  tree.insert(1L)
  tree.insert(9L)
  debug_inspect(tree.min(), content="Some(1)")
  debug_inspect(tree.max(), content="Some(9)")
}

///|
test "avl size" {
  let tree : AVLTree[Int64] = AVLTree()
  inspect(tree.size(), content="0")
  tree.insert(1L)
  tree.insert(2L)
  tree.insert(3L)
  inspect(tree.size(), content="3")
}

///|
test "avl many insertions" {
  let tree = AVLTree()
  for i in 0..<100 {
    tree.insert(i.to_int64())
  }
  inspect(tree.is_balanced(), content="true")
  inspect(tree.size(), content="100")
  // Height should be around log2(100) ≈ 7
  inspect(tree.height(tree.root) <= 10, content="true")
}

///|
test "avl empty" {
  let tree = AVLTree()
  inspect(tree.search(1L), content="false")
  debug_inspect(tree.min(), content="None")
  inspect(tree.is_balanced(), content="true")
}
