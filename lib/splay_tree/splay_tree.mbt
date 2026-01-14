// ============================================================================
// SPLAY TREE - Self-Adjusting Binary Search Tree
// ============================================================================
//
// A Splay Tree is a self-adjusting BST that moves recently accessed elements
// to the root through rotations (splaying). Provides O(log n) amortized time.
//
// KEY INSIGHT: After accessing any node, splay it to the root. This gives
// excellent cache locality and amortized O(log n) per operation.
//
// SPLAY OPERATION:
// Three cases based on node position relative to grandparent:
// 1. Zig: Node is child of root - single rotation
// 2. Zig-Zig: Node and parent are both left (or both right) children - rotate parent first
// 3. Zig-Zag: Node is left child of right child (or vice versa) - rotate node twice
//
// INVARIANTS:
// 1. BST property maintained through all rotations
// 2. Splaying moves accessed node to root
// 3. Amortized cost uses potential function: Φ = Σ log(size(v))
//
// TIME COMPLEXITY: O(log n) amortized per operation
// SPACE COMPLEXITY: O(n)

///|
priv struct SplayNode[T] {
  mut key : T
  mut left : Int
  mut right : Int
  mut parent : Int
  mut size : Int // Subtree size for order statistics
}

///|
fn[T] SplayNode::new(key : T) -> SplayNode[T] {
  { key, left: -1, right: -1, parent: -1, size: 1 }
}

///|
priv struct SplayTree[T] {
  nodes : Array[SplayNode[T]]
  mut root : Int
  mut free_list : Int // Head of free list for deleted nodes
}

///|
fn[T] SplayTree::new() -> SplayTree[T] {
  { nodes: [], root: -1, free_list: -1 }
}

///|
fn[T] SplayTree::alloc_node(self : SplayTree[T], key : T) -> Int {
  if self.free_list >= 0 {
    let idx = self.free_list
    self.free_list = self.nodes[idx].left
    self.nodes[idx].key = key
    self.nodes[idx].left = -1
    self.nodes[idx].right = -1
    self.nodes[idx].parent = -1
    self.nodes[idx].size = 1
    return idx
  }
  let idx = self.nodes.length()
  self.nodes.push(SplayNode::new(key))
  idx
}

///|
fn[T] SplayTree::update_size(self : SplayTree[T], x : Int) -> Unit {
  if x < 0 {
    return
  }
  let left_size = if self.nodes[x].left >= 0 {
    self.nodes[self.nodes[x].left].size
  } else {
    0
  }
  let right_size = if self.nodes[x].right >= 0 {
    self.nodes[self.nodes[x].right].size
  } else {
    0
  }
  self.nodes[x].size = 1 + left_size + right_size
}

///|
/// Right rotation: x becomes parent of its parent p
fn[T] SplayTree::rotate_right(self : SplayTree[T], x : Int) -> Unit {
  let p = self.nodes[x].parent
  if p < 0 {
    return
  }
  let b = self.nodes[x].right
  let g = self.nodes[p].parent

  // x becomes parent of p
  self.nodes[x].right = p
  self.nodes[p].parent = x

  // b becomes left child of p
  self.nodes[p].left = b
  if b >= 0 {
    self.nodes[b].parent = p
  }

  // x connects to grandparent
  self.nodes[x].parent = g
  if g >= 0 {
    if self.nodes[g].left == p {
      self.nodes[g].left = x
    } else {
      self.nodes[g].right = x
    }
  }
  self.update_size(p)
  self.update_size(x)
}

///|
/// Left rotation
fn[T] SplayTree::rotate_left(self : SplayTree[T], x : Int) -> Unit {
  let p = self.nodes[x].parent
  if p < 0 {
    return
  }
  let b = self.nodes[x].left
  let g = self.nodes[p].parent
  self.nodes[x].left = p
  self.nodes[p].parent = x
  self.nodes[p].right = b
  if b >= 0 {
    self.nodes[b].parent = p
  }
  self.nodes[x].parent = g
  if g >= 0 {
    if self.nodes[g].left == p {
      self.nodes[g].left = x
    } else {
      self.nodes[g].right = x
    }
  }
  self.update_size(p)
  self.update_size(x)
}

///|
/// Splay node x to root
fn[T] SplayTree::splay(self : SplayTree[T], x : Int) -> Unit {
  if x < 0 {
    return
  }
  while self.nodes[x].parent >= 0 {
    let p = self.nodes[x].parent
    let g = self.nodes[p].parent
    if g < 0 {
      // Zig: x is child of root
      if self.nodes[p].left == x {
        self.rotate_right(x)
      } else {
        self.rotate_left(x)
      }
    } else if self.nodes[g].left == p && self.nodes[p].left == x {
      // Zig-Zig (left-left)
      self.rotate_right(p)
      self.rotate_right(x)
    } else if self.nodes[g].right == p && self.nodes[p].right == x {
      // Zig-Zig (right-right)
      self.rotate_left(p)
      self.rotate_left(x)
    } else if self.nodes[g].left == p && self.nodes[p].right == x {
      // Zig-Zag (left-right)
      self.rotate_left(x)
      self.rotate_right(x)
    } else {
      // Zig-Zag (right-left)
      self.rotate_right(x)
      self.rotate_left(x)
    }
  }
  self.root = x
}

///|
/// Insert key into tree
fn[T : Compare] SplayTree::insert(self : SplayTree[T], key : T) -> Unit {
  if self.root < 0 {
    self.root = self.alloc_node(key)
    return
  }
  let mut cur = self.root
  let mut parent = -1
  while cur >= 0 {
    parent = cur
    self.nodes[cur].size = self.nodes[cur].size + 1
    if key < self.nodes[cur].key {
      cur = self.nodes[cur].left
    } else {
      cur = self.nodes[cur].right
    }
  }
  let new_node = self.alloc_node(key)
  self.nodes[new_node].parent = parent
  if key < self.nodes[parent].key {
    self.nodes[parent].left = new_node
  } else {
    self.nodes[parent].right = new_node
  }
  self.splay(new_node)
}

///|
/// Find node with given key (returns -1 if not found)
fn[T : Compare] SplayTree::find_node(self : SplayTree[T], key : T) -> Int {
  let mut cur = self.root
  while cur >= 0 {
    if key == self.nodes[cur].key {
      self.splay(cur)
      return cur
    } else if key < self.nodes[cur].key {
      cur = self.nodes[cur].left
    } else {
      cur = self.nodes[cur].right
    }
  }
  -1
}

///|
/// Check if key exists
fn[T : Compare] SplayTree::contains(self : SplayTree[T], key : T) -> Bool {
  self.find_node(key) >= 0
}

///|
/// Find minimum node in subtree
fn[T] SplayTree::find_min(self : SplayTree[T], x : Int) -> Int {
  if x < 0 {
    return -1
  }
  let mut cur = x
  while self.nodes[cur].left >= 0 {
    cur = self.nodes[cur].left
  }
  cur
}

///|
/// Find maximum node in subtree
fn[T] SplayTree::find_max(self : SplayTree[T], x : Int) -> Int {
  if x < 0 {
    return -1
  }
  let mut cur = x
  while self.nodes[cur].right >= 0 {
    cur = self.nodes[cur].right
  }
  cur
}

///|
/// Delete key from tree
fn[T : Compare] SplayTree::delete(self : SplayTree[T], key : T) -> Bool {
  let node = self.find_node(key)
  if node < 0 {
    return false
  }

  // After splay, node is at root
  let left = self.nodes[node].left
  let right = self.nodes[node].right

  // Free the node
  self.nodes[node].left = self.free_list
  self.free_list = node
  if left < 0 {
    self.root = right
    if right >= 0 {
      self.nodes[right].parent = -1
    }
  } else if right < 0 {
    self.root = left
    self.nodes[left].parent = -1
  } else {
    // Join left and right subtrees
    self.nodes[left].parent = -1
    self.root = left

    // Splay maximum of left subtree
    let max_left = self.find_max(left)
    self.splay(max_left)

    // Attach right subtree
    self.nodes[self.root].right = right
    self.nodes[right].parent = self.root
    self.update_size(self.root)
  }
  true
}

///|
/// Get kth smallest element (1-indexed)
fn[T] SplayTree::kth_element(self : SplayTree[T], k : Int) -> T? {
  if self.root < 0 || k <= 0 {
    return None
  }
  let mut cur = self.root
  let mut remaining = k
  while cur >= 0 {
    let left_size = if self.nodes[cur].left >= 0 {
      self.nodes[self.nodes[cur].left].size
    } else {
      0
    }
    if remaining == left_size + 1 {
      self.splay(cur)
      return Some(self.nodes[cur].key)
    } else if remaining <= left_size {
      cur = self.nodes[cur].left
    } else {
      remaining = remaining - left_size - 1
      cur = self.nodes[cur].right
    }
  }
  None
}

///|
/// Count elements less than key
fn[T : Compare] SplayTree::count_less(self : SplayTree[T], key : T) -> Int {
  if self.root < 0 {
    return 0
  }
  let mut cur = self.root
  let mut count = 0
  while cur >= 0 {
    let left_size = if self.nodes[cur].left >= 0 {
      self.nodes[self.nodes[cur].left].size
    } else {
      0
    }
    if key <= self.nodes[cur].key {
      cur = self.nodes[cur].left
    } else {
      count = count + left_size + 1
      cur = self.nodes[cur].right
    }
  }
  count
}

///|
/// Get tree size
fn[T] SplayTree::size(self : SplayTree[T]) -> Int {
  if self.root < 0 {
    0
  } else {
    self.nodes[self.root].size
  }
}

///|
/// Get minimum key
fn[T] SplayTree::min(self : SplayTree[T]) -> T? {
  let m = self.find_min(self.root)
  if m < 0 {
    None
  } else {
    self.splay(m)
    Some(self.nodes[m].key)
  }
}

///|
/// Get maximum key
fn[T] SplayTree::max(self : SplayTree[T]) -> T? {
  let m = self.find_max(self.root)
  if m < 0 {
    None
  } else {
    self.splay(m)
    Some(self.nodes[m].key)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "splay insert and contains" {
  let tree = SplayTree::new()
  tree.insert(5L)
  tree.insert(3L)
  tree.insert(7L)
  tree.insert(1L)
  tree.insert(9L)
  inspect(tree.contains(5L), content="true")
  inspect(tree.contains(3L), content="true")
  inspect(tree.contains(7L), content="true")
  inspect(tree.contains(2L), content="false")
}

///|
test "splay delete" {
  let tree = SplayTree::new()
  tree.insert(5L)
  tree.insert(3L)
  tree.insert(7L)
  inspect(tree.delete(3L), content="true")
  inspect(tree.contains(3L), content="false")
  inspect(tree.contains(5L), content="true")
  inspect(tree.contains(7L), content="true")
}

///|
test "splay size" {
  let tree : SplayTree[Int64] = SplayTree::new()
  inspect(tree.size(), content="0")
  tree.insert(1L)
  tree.insert(2L)
  tree.insert(3L)
  inspect(tree.size(), content="3")
  let _ = tree.delete(2L)
  inspect(tree.size(), content="2")
}

///|
test "splay min max" {
  let tree = SplayTree::new()
  tree.insert(5L)
  tree.insert(2L)
  tree.insert(8L)
  tree.insert(1L)
  tree.insert(9L)
  inspect(tree.min(), content="Some(1)")
  inspect(tree.max(), content="Some(9)")
}

///|
test "splay kth element" {
  let tree = SplayTree::new()
  tree.insert(3L)
  tree.insert(1L)
  tree.insert(4L)
  tree.insert(1L) // Duplicate
  tree.insert(5L)

  // Sorted: 1, 1, 3, 4, 5
  inspect(tree.kth_element(1), content="Some(1)")
  inspect(tree.kth_element(3), content="Some(3)")
  inspect(tree.kth_element(5), content="Some(5)")
  inspect(tree.kth_element(6), content="None")
}

///|
test "splay count less" {
  let tree = SplayTree::new()
  tree.insert(1L)
  tree.insert(3L)
  tree.insert(5L)
  tree.insert(7L)
  tree.insert(9L)
  inspect(tree.count_less(5L), content="2") // 1, 3
  inspect(tree.count_less(10L), content="5") // all
  inspect(tree.count_less(1L), content="0") // none
}

///|
test "splay empty" {
  let tree = SplayTree::new()
  inspect(tree.contains(1L), content="false")
  inspect(tree.min(), content="None")
  inspect(tree.max(), content="None")
  inspect(tree.size(), content="0")
}

///|
test "splay delete nonexistent" {
  let tree = SplayTree::new()
  tree.insert(5L)
  inspect(tree.delete(10L), content="false")
  inspect(tree.size(), content="1")
}

///|
test "splay sequential insert" {
  let tree = SplayTree::new()
  for i in 0..<100 {
    tree.insert(i.to_int64())
  }
  inspect(tree.size(), content="100")
  inspect(tree.min(), content="Some(0)")
  inspect(tree.max(), content="Some(99)")
}
