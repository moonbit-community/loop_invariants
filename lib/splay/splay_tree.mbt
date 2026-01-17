// ============================================================================
// SPLAY TREE - Self-Adjusting Binary Search Tree
// ============================================================================
//
// A Splay Tree is a self-adjusting BST that moves recently accessed elements
// to the root through a series of rotations called "splaying".
//
// KEY INSIGHT: Frequently accessed elements naturally migrate toward the root,
// providing excellent performance for non-uniform access patterns.
//
// OPERATIONS (all O(log n) amortized):
// - splay(x): Move x to root using zig, zig-zig, zig-zag rotations
// - insert(key): Insert and splay to root
// - delete(key): Delete by splaying, then joining subtrees
// - search(key): Search and splay result to root
// - split(key): Split tree into <= key and > key
// - join(t1, t2): Join two trees where max(t1) < min(t2)
//
// AMORTIZED ANALYSIS:
// Using potential function Φ = Σ log(size(x)) for all nodes x
// Each splay operation costs O(log n) amortized
//
// ADVANTAGES:
// - No balance information stored (simpler than AVL/Red-Black)
// - Excellent cache locality for repeated accesses
// - Supports efficient split and join operations

///|
/// Node in splay tree
priv struct SplayNode[T] {
  mut key : T
  mut left : Int // Index of left child (-1 if none)
  mut right : Int // Index of right child (-1 if none)
  mut parent : Int // Index of parent (-1 if root)
  mut size : Int // Subtree size for order statistics
}

///|
fn[T] SplayNode::new(key : T) -> SplayNode[T] {
  { key, left: -1, right: -1, parent: -1, size: 1 }
}

///|
/// Splay Tree data structure using array-based nodes
priv struct SplayTree[T] {
  nodes : Array[SplayNode[T]]
  mut root : Int // Index of root (-1 if empty)
  // Free list for deleted nodes (simple recycling)
  free_list : Array[Int]
}

///|
fn[T] SplayTree::new() -> SplayTree[T] {
  { nodes: [], root: -1, free_list: [] }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

///|
/// Update size of node based on children
fn[T] SplayTree::update_size(self : SplayTree[T], x : Int) -> Unit {
  if x < 0 {
    return
  }
  let mut sz = 1
  let l = self.nodes[x].left
  let r = self.nodes[x].right
  if l >= 0 {
    sz = sz + self.nodes[l].size
  }
  if r >= 0 {
    sz = sz + self.nodes[r].size
  }
  self.nodes[x].size = sz
}

///|
/// Check if x is left child of its parent
fn[T] SplayTree::is_left_child(self : SplayTree[T], x : Int) -> Bool {
  let p = self.nodes[x].parent
  p >= 0 && self.nodes[p].left == x
}

///|
/// Allocate a new node (reuse from free list if available)
fn[T] SplayTree::alloc_node(self : SplayTree[T], key : T) -> Int {
  if self.free_list.pop() is Some(idx) {
    self.nodes[idx].key = key
    self.nodes[idx].left = -1
    self.nodes[idx].right = -1
    self.nodes[idx].parent = -1
    self.nodes[idx].size = 1
    idx
  } else {
    let idx = self.nodes.length()
    self.nodes.push(SplayNode::new(key))
    idx
  }
}

// ============================================================================
// ROTATIONS
// ============================================================================

///|
/// Rotate x up (x takes parent's position)
/// Preserves BST property and updates sizes
fn[T] SplayTree::rotate(self : SplayTree[T], x : Int) -> Unit {
  let p = self.nodes[x].parent
  if p < 0 {
    return // x is already root
  }
  let g = self.nodes[p].parent // grandparent
  let is_left = self.is_left_child(x)

  // Update grandparent's child pointer
  if g >= 0 {
    if self.nodes[g].left == p {
      self.nodes[g].left = x
    } else {
      self.nodes[g].right = x
    }
  }

  // Perform rotation
  if is_left {
    // x is left child: right rotation
    //      p          x
    //     / \        / \
    //    x   c  ->  a   p
    //   / \            / \
    //  a   b          b   c
    self.nodes[p].left = self.nodes[x].right
    if self.nodes[x].right >= 0 {
      self.nodes[self.nodes[x].right].parent = p
    }
    self.nodes[x].right = p
  } else {
    // x is right child: left rotation
    //    p              x
    //   / \            / \
    //  a   x    ->    p   c
    //     / \        / \
    //    b   c      a   b
    self.nodes[p].right = self.nodes[x].left
    if self.nodes[x].left >= 0 {
      self.nodes[self.nodes[x].left].parent = p
    }
    self.nodes[x].left = p
  }

  // Update parent pointers
  self.nodes[x].parent = g
  self.nodes[p].parent = x

  // Update sizes (p first since x is now p's parent)
  self.update_size(p)
  self.update_size(x)

  // Update root if needed
  if g < 0 {
    self.root = x
  }
}

// ============================================================================
// SPLAY OPERATION - The Core
// ============================================================================

///|
/// Splay node x to root using zig, zig-zig, zig-zag rotations
///
/// CASES:
/// 1. Zig: x's parent is root → one rotation
/// 2. Zig-zig: x and parent are both left (or both right) children → rotate parent, then x
/// 3. Zig-zag: x and parent are different types → rotate x twice
fn[T] SplayTree::splay(self : SplayTree[T], x : Int) -> Unit {
  if x < 0 {
    return
  }
  for ; self.nodes[x].parent >= 0; {
    let p = self.nodes[x].parent
    let g = self.nodes[p].parent
    if g < 0 {
      // Zig case: parent is root
      self.rotate(x)
    } else {
      let x_is_left = self.is_left_child(x)
      let p_is_left = self.is_left_child(p)
      if x_is_left == p_is_left {
        // Zig-zig: same direction
        // Rotate parent first, then x
        self.rotate(p)
        self.rotate(x)
      } else {
        // Zig-zag: different directions
        // Rotate x twice
        self.rotate(x)
        self.rotate(x)
      }
    }
  } where {
    invariant: x >= 0 && x < self.nodes.length(),
    reasoning: (
      #|SPLAY INVARIANT:
      #|
      #|1. Each iteration moves x closer to root:
      #|   - Zig: x becomes root (terminates)
      #|   - Zig-zig: x's depth decreases by 2
      #|   - Zig-zag: x's depth decreases by 2
      #|
      #|2. BST property preserved: rotations maintain in-order
      #|
      #|3. Amortized O(log n): Sleator-Tarjan analysis shows that
      #|   the amortized cost of splay is O(log n) using potential:
      #|   Φ = Σ log(size(v)) for all nodes v
      #|
      #|   Key insight: Zig-zig rotation is crucial - it straightens
      #|   the access path, reducing future access costs.
      #|
      #|4. Termination: parent pointer becomes -1 when x reaches root
      #|MAINTENANCE:
      #|Each rotation preserves BST order while moving x upward toward root.
      #|TERMINATION:
      #|x's depth strictly decreases, so it reaches the root.
    ),
  }
}

// ============================================================================
// SEARCH OPERATIONS
// ============================================================================

///|
/// Search for key, splay the result (or last visited node) to root
/// Returns true if key is found
fn[T : Compare] SplayTree::search(self : SplayTree[T], key : T) -> Bool {
  if self.root < 0 {
    return false
  }
  let last = for node = self.root {
    if key == self.nodes[node].key {
      break node
    } else if key < self.nodes[node].key {
      if self.nodes[node].left >= 0 {
        continue self.nodes[node].left
      } else {
        break node
      }
    } else if self.nodes[node].right >= 0 {
      continue self.nodes[node].right
    } else {
      break node
    }
  } where {
    invariant: node >= 0,
    reasoning: (
      #|SEARCH INVARIANT:
      #|
      #|1. If key exists, it must be in subtree rooted at node
      #|2. Each step follows BST property: left if key < node.key, right otherwise
      #|3. Loop terminates when key found or no appropriate child exists
      #|4. We track 'last' to splay even on failed search (important for amortization)
      #|MAINTENANCE:
      #|Following the BST rule keeps the target (if any) within the subtree.
      #|TERMINATION:
      #|The search descends until it finds key or a missing child.
    ),
  }
  self.splay(last)
  self.nodes[last].key == key
}

///|
/// Find minimum element in subtree rooted at x
fn[T] SplayTree::find_min(self : SplayTree[T], x : Int) -> Int {
  if x < 0 {
    return -1
  }
  for node = x {
    if self.nodes[node].left < 0 {
      break node
    } else {
      continue self.nodes[node].left
    }
  } where {
    invariant: node >= 0,
    reasoning: (
      #|FIND MIN INVARIANT:
      #|node remains on the left spine toward the minimum.
      #|MAINTENANCE:
      #|Move to the left child while it exists.
      #|TERMINATION:
      #|When left is absent, node is the minimum.
    ),
  }
}

///|
/// Find maximum element in subtree rooted at x
fn[T] SplayTree::find_max(self : SplayTree[T], x : Int) -> Int {
  if x < 0 {
    return -1
  }
  for node = x {
    if self.nodes[node].right < 0 {
      break node
    } else {
      continue self.nodes[node].right
    }
  } where {
    invariant: node >= 0,
    reasoning: (
      #|FIND MAX INVARIANT:
      #|node remains on the right spine toward the maximum.
      #|MAINTENANCE:
      #|Move to the right child while it exists.
      #|TERMINATION:
      #|When right is absent, node is the maximum.
    ),
  }
}

// ============================================================================
// INSERT OPERATION
// ============================================================================

///|
/// Insert key into splay tree
/// Returns true if key was inserted (false if already exists)
fn[T : Compare] SplayTree::insert(self : SplayTree[T], key : T) -> Bool {
  if self.root < 0 {
    self.root = self.alloc_node(key)
    return true
  }

  // Search for insertion point
  let insert_point = for node = self.root {
    if key == self.nodes[node].key {
      // Key already exists - splay it and return false
      self.splay(node)
      return false
    } else if key < self.nodes[node].key {
      if self.nodes[node].left >= 0 {
        continue self.nodes[node].left
      } else {
        break node
      }
    } else if self.nodes[node].right >= 0 {
      continue self.nodes[node].right
    } else {
      break node
    }
  } where {
    invariant: node >= 0,
    reasoning: (
      #|INSERT SEARCH INVARIANT:
      #|
      #|Find the node that will become parent of new node.
      #|BST property guides the search.
      #|MAINTENANCE:
      #|Each step descends to the child where the key must belong.
      #|TERMINATION:
      #|The search ends at a leaf where the new node attaches.
    ),
  }

  // Create and attach new node
  let new_node = self.alloc_node(key)
  self.nodes[new_node].parent = insert_point
  if key < self.nodes[insert_point].key {
    self.nodes[insert_point].left = new_node
  } else {
    self.nodes[insert_point].right = new_node
  }

  // Splay new node to root
  self.splay(new_node)
  true
}

// ============================================================================
// DELETE OPERATION
// ============================================================================

///|
/// Delete key from splay tree
/// Returns true if key was found and deleted
fn[T : Compare] SplayTree::delete(self : SplayTree[T], key : T) -> Bool {
  if not(self.search(key)) {
    return false
  }

  // After search, key is at root
  let old_root = self.root
  let l = self.nodes[old_root].left
  let r = self.nodes[old_root].right

  // Add old root to free list
  self.free_list.push(old_root)
  if l < 0 {
    // No left subtree - right becomes root
    self.root = r
    if r >= 0 {
      self.nodes[r].parent = -1
    }
  } else if r < 0 {
    // No right subtree - left becomes root
    self.root = l
    self.nodes[l].parent = -1
  } else {
    // Both subtrees exist
    // Find max in left subtree, splay it to left root
    self.nodes[l].parent = -1
    self.root = l
    let max_left = self.find_max(l)
    self.splay(max_left)

    // Now max_left is root with no right child
    // Attach right subtree
    self.nodes[max_left].right = r
    self.nodes[r].parent = max_left
    self.update_size(max_left)
  }
  true
}

// ============================================================================
// SPLIT AND JOIN
// ============================================================================

///|
/// Split tree into two: one with keys <= key, one with keys > key
/// Returns (left_root, right_root)
fn[T : Compare] SplayTree::split(self : SplayTree[T], key : T) -> (Int, Int) {
  if self.root < 0 {
    return (-1, -1)
  }

  // Search for key (or closest)
  let _ = self.search(key)

  // Root is now closest to key
  if self.nodes[self.root].key <= key {
    // Root goes to left tree
    let r = self.nodes[self.root].right
    self.nodes[self.root].right = -1
    if r >= 0 {
      self.nodes[r].parent = -1
    }
    self.update_size(self.root)
    (self.root, r)
  } else {
    // Root goes to right tree
    let l = self.nodes[self.root].left
    self.nodes[self.root].left = -1
    if l >= 0 {
      self.nodes[l].parent = -1
    }
    self.update_size(self.root)
    (l, self.root)
  }
}

///|
/// Join two trees where all keys in t1 < all keys in t2
/// Result becomes the tree's root
fn[T] SplayTree::join(self : SplayTree[T], t1 : Int, t2 : Int) -> Unit {
  if t1 < 0 {
    self.root = t2
    return
  }
  if t2 < 0 {
    self.root = t1
    return
  }

  // Splay max of t1 to root
  self.root = t1
  let max_t1 = self.find_max(t1)
  self.splay(max_t1)

  // Attach t2 as right child
  self.nodes[max_t1].right = t2
  self.nodes[t2].parent = max_t1
  self.update_size(max_t1)
}

// ============================================================================
// ORDER STATISTICS
// ============================================================================

///|
/// Find k-th smallest element (1-indexed)
fn[T] SplayTree::kth_element(self : SplayTree[T], k : Int) -> T? {
  if self.root < 0 || k <= 0 || k > self.nodes[self.root].size {
    return None
  }
  let result = for node = self.root, remaining = k {
    let left_size = if self.nodes[node].left >= 0 {
      self.nodes[self.nodes[node].left].size
    } else {
      0
    }
    if remaining <= left_size {
      // k-th element is in left subtree
      continue self.nodes[node].left, remaining
    } else if remaining == left_size + 1 {
      // Current node is k-th
      break node
    } else {
      // k-th element is in right subtree
      continue self.nodes[node].right, remaining - left_size - 1
    }
  } where {
    invariant: node >= 0 && remaining > 0,
    reasoning: (
      #|KTH ELEMENT INVARIANT:
      #|
      #|1. remaining = rank of target within current subtree
      #|2. If remaining <= left_size: target is in left subtree
      #|3. If remaining == left_size + 1: current node is target
      #|4. Otherwise: target is in right subtree with adjusted rank
      #|
      #|Correctness: BST property ensures in-order gives sorted sequence
      #|MAINTENANCE:
      #|Updating (node, remaining) preserves the rank within the chosen subtree.
      #|TERMINATION:
      #|remaining decreases toward 1 or a leaf is reached, yielding the target.
    ),
  }
  self.splay(result)
  Some(self.nodes[result].key)
}

///|
/// Count elements less than key
fn[T : Compare] SplayTree::count_less(self : SplayTree[T], key : T) -> Int {
  if self.root < 0 {
    return 0
  }
  for node = self.root, count = 0 {
    if key <= self.nodes[node].key {
      // All elements >= key, go left
      if self.nodes[node].left >= 0 {
        continue self.nodes[node].left, count
      } else {
        break count
      }
    } else {
      // Current node and left subtree are < key
      let left_size = if self.nodes[node].left >= 0 {
        self.nodes[self.nodes[node].left].size
      } else {
        0
      }
      let new_count = count + left_size + 1
      if self.nodes[node].right >= 0 {
        continue self.nodes[node].right, new_count
      } else {
        break new_count
      }
    }
  } where {
    invariant: node >= 0 && count >= 0,
    reasoning: (
      #|COUNT LESS INVARIANT:
      #|
      #|1. count = number of elements less than key in already-visited parts
      #|2. If key <= node.key: only left subtree may contain smaller elements
      #|3. If key > node.key: node and all left subtree are smaller, continue right
      #|MAINTENANCE:
      #|Updating count with left subtree size preserves the total smaller count.
      #|TERMINATION:
      #|The search descends to a leaf, yielding the final count.
    ),
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

///|
fn[T] SplayTree::size(self : SplayTree[T]) -> Int {
  if self.root >= 0 {
    self.nodes[self.root].size
  } else {
    0
  }
}

///|
fn[T] SplayTree::is_empty(self : SplayTree[T]) -> Bool {
  self.root < 0
}

///|
fn[T] SplayTree::min(self : SplayTree[T]) -> T? {
  if self.root < 0 {
    return None
  }
  let min_node = self.find_min(self.root)
  self.splay(min_node)
  Some(self.nodes[min_node].key)
}

///|
fn[T] SplayTree::max(self : SplayTree[T]) -> T? {
  if self.root < 0 {
    return None
  }
  let max_node = self.find_max(self.root)
  self.splay(max_node)
  Some(self.nodes[max_node].key)
}

///|
/// Get in-order traversal (for testing)
fn[T] SplayTree::inorder(self : SplayTree[T]) -> Array[T] {
  let result : Array[T] = []
  fn traverse(tree : SplayTree[T], node : Int, result : Array[T]) -> Unit {
    if node < 0 {
      return
    }
    traverse(tree, tree.nodes[node].left, result)
    result.push(tree.nodes[node].key)
    traverse(tree, tree.nodes[node].right, result)
  }

  traverse(self, self.root, result)
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "splay tree basic operations" {
  let st : SplayTree[Int] = SplayTree::new()

  // Initially empty
  inspect(st.is_empty(), content="true")

  // Insert elements
  inspect(st.insert(5), content="true")
  inspect(st.insert(3), content="true")
  inspect(st.insert(7), content="true")
  inspect(st.insert(1), content="true")
  inspect(st.insert(9), content="true")

  // Duplicate insert should fail
  inspect(st.insert(5), content="false")

  // Not empty after insertions
  inspect(st.is_empty(), content="false")

  // Size check
  inspect(st.size(), content="5")

  // Search
  inspect(st.search(5), content="true")
  inspect(st.search(3), content="true")
  inspect(st.search(100), content="false")
}

///|
test "splay tree delete" {
  let st : SplayTree[Int] = SplayTree::new()
  for i in 1 ..<= 5 {
    let _ = st.insert(i)

  }
  inspect(st.size(), content="5")

  // Delete middle
  inspect(st.delete(3), content="true")
  inspect(st.size(), content="4")
  inspect(st.search(3), content="false")

  // Delete non-existent
  inspect(st.delete(100), content="false")

  // Remaining elements still accessible
  inspect(st.search(1), content="true")
  inspect(st.search(2), content="true")
  inspect(st.search(4), content="true")
  inspect(st.search(5), content="true")
}

///|
test "splay tree min max" {
  let st : SplayTree[Int] = SplayTree::new()
  inspect(st.min(), content="None")
  inspect(st.max(), content="None")
  let _ = st.insert(50)
  let _ = st.insert(30)
  let _ = st.insert(70)
  let _ = st.insert(10)
  let _ = st.insert(90)
  inspect(st.min(), content="Some(10)")
  inspect(st.max(), content="Some(90)")
}

///|
test "splay tree order statistics" {
  let st : SplayTree[Int] = SplayTree::new()

  // Insert 1, 3, 5, 7, 9
  for i in 0..<5 {
    let _ = st.insert(i * 2 + 1)

  }

  // k-th element (1-indexed)
  inspect(st.kth_element(1), content="Some(1)")
  inspect(st.kth_element(3), content="Some(5)")
  inspect(st.kth_element(5), content="Some(9)")
  inspect(st.kth_element(6), content="None")

  // Count less than
  inspect(st.count_less(5), content="2") // 1, 3
  inspect(st.count_less(1), content="0")
  inspect(st.count_less(10), content="5")
}

///|
test "splay tree inorder" {
  let st : SplayTree[Int] = SplayTree::new()
  let _ = st.insert(5)
  let _ = st.insert(3)
  let _ = st.insert(7)
  let _ = st.insert(1)
  let _ = st.insert(9)
  // In-order should be sorted
  inspect(st.inorder(), content="[1, 3, 5, 7, 9]")
}

///|
test "splay tree stress" {
  let st : SplayTree[Int] = SplayTree::new()

  // Insert 100 elements
  for i in 0..<100 {
    let _ = st.insert(i)

  }
  inspect(st.size(), content="100")

  // Search all
  for i in 0..<100 {
    guard st.search(i) else { fail("Element not found") }
  }

  // Delete every other
  for i in 0..<100 {
    if i % 2 == 0 {
      guard st.delete(i) else { fail("Delete failed") }
    }
  }
  inspect(st.size(), content="50")
}

///|
test "splay tree split join" {
  let st : SplayTree[Int] = SplayTree::new()
  for i in 1 ..<= 10 {
    let _ = st.insert(i)

  }

  // Split at 5: left has 1-5, right has 6-10
  let (left, right) = st.split(5)

  // Check sizes
  let left_size = if left >= 0 { st.nodes[left].size } else { 0 }
  let right_size = if right >= 0 { st.nodes[right].size } else { 0 }
  inspect(left_size, content="5")
  inspect(right_size, content="5")

  // Join them back
  st.join(left, right)
  inspect(st.size(), content="10")
  inspect(st.inorder(), content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
}
