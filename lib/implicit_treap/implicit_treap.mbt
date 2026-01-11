// ============================================================================
// TREAP WITH IMPLICIT KEYS - Sequence Operations with Split/Merge
// ============================================================================
//
// A Treap with Implicit Keys is a balanced BST that maintains a sequence where
// positions are determined implicitly by subtree sizes rather than stored keys.
// This enables efficient split, merge, insert, delete, and range operations.
//
// KEY INSIGHT: Instead of storing keys, each node's "key" is its position in
// the in-order traversal. This position is computed dynamically as:
//   position(node) = size(left_subtree) + positions from ancestors going right
//
// WHY IT WORKS:
// - BST property: left subtree contains elements with smaller positions
// - Heap property on priorities: keeps tree balanced (expected height O(log n))
// - Position is implicit: no need to update keys on insert/delete
//
// OPERATIONS (all O(log n) expected):
// - split(k): Split into [0..k) and [k..n) - O(log n)
// - merge(t1, t2): Merge sequences (requires max(t1) < min(t2) positions) - O(log n)
// - insert(pos, val): Insert value at position - split + merge
// - delete(pos): Delete at position - split + merge
// - range_query(l, r): Query aggregate on [l, r) - split + query + merge
// - reverse(l, r): Reverse range [l, r) - O(log n) with lazy reversal
//
// SPACE: O(n)
// TIME: O(log n) expected per operation

///|
/// Node in implicit treap
priv struct ImplicitNode {
  mut val : Int64 // Value stored at this position
  priority : Int // Random priority for heap property
  mut size : Int // Size of subtree (for implicit key computation)
  mut sum : Int64 // Sum of values in subtree (for range queries)
  mut min_val : Int64 // Minimum value in subtree
  mut max_val : Int64 // Maximum value in subtree
  mut rev : Bool // Lazy reversal flag
  mut left : Int // Index of left child (-1 if none)
  mut right : Int // Index of right child (-1 if none)
}

///|
/// Implicit Treap data structure
priv struct ImplicitTreap {
  nodes : Array[ImplicitNode]
  mut root : Int
  mut rand_state : Int
  free_list : Array[Int]
}

///|
fn ImplicitTreap::new() -> ImplicitTreap {
  { nodes: [], root: -1, rand_state: 12345, free_list: [] }
}

///|
/// Generate random priority
fn ImplicitTreap::random_priority(self : ImplicitTreap) -> Int {
  self.rand_state = (self.rand_state * 1103515245 + 12345) % 2147483647
  if self.rand_state < 0 {
    -self.rand_state
  } else {
    self.rand_state
  }
}

///|
/// Allocate new node
fn ImplicitTreap::alloc_node(self : ImplicitTreap, val : Int64) -> Int {
  let priority = self.random_priority()
  if self.free_list.length() > 0 {
    let idx = self.free_list.pop().unwrap()
    self.nodes[idx] = {
      val,
      priority,
      size: 1,
      sum: val,
      min_val: val,
      max_val: val,
      rev: false,
      left: -1,
      right: -1,
    }
    idx
  } else {
    let idx = self.nodes.length()
    self.nodes.push({
      val,
      priority,
      size: 1,
      sum: val,
      min_val: val,
      max_val: val,
      rev: false,
      left: -1,
      right: -1,
    })
    idx
  }
}

///|
/// Get size of subtree (handles -1 for null)
fn ImplicitTreap::get_size(self : ImplicitTreap, node : Int) -> Int {
  if node < 0 {
    0
  } else {
    self.nodes[node].size
  }
}

///|
fn ImplicitTreap::get_sum(self : ImplicitTreap, node : Int) -> Int64 {
  if node < 0 {
    0L
  } else {
    self.nodes[node].sum
  }
}

///|
fn ImplicitTreap::get_min(self : ImplicitTreap, node : Int) -> Int64 {
  if node < 0 {
    9223372036854775807L
  } else {
    self.nodes[node].min_val
  }
}

///|
fn ImplicitTreap::get_max(self : ImplicitTreap, node : Int) -> Int64 {
  if node < 0 {
    -9223372036854775807L
  } else {
    self.nodes[node].max_val
  }
}

///|
/// Update node's aggregate values based on children
fn ImplicitTreap::update(self : ImplicitTreap, node : Int) -> Unit {
  if node < 0 {
    return
  }
  let left = self.nodes[node].left
  let right = self.nodes[node].right
  let val = self.nodes[node].val
  self.nodes[node].size = self.get_size(left) + self.get_size(right) + 1
  self.nodes[node].sum = self.get_sum(left) + self.get_sum(right) + val
  let left_min = self.get_min(left)
  let right_min = self.get_min(right)
  let min1 = if val < left_min { val } else { left_min }
  self.nodes[node].min_val = if min1 < right_min { min1 } else { right_min }
  let left_max = self.get_max(left)
  let right_max = self.get_max(right)
  let max1 = if val > left_max { val } else { left_max }
  self.nodes[node].max_val = if max1 > right_max { max1 } else { right_max }
}

///|
/// Push down lazy reversal flag
fn ImplicitTreap::push_down(self : ImplicitTreap, node : Int) -> Unit {
  if node < 0 || not(self.nodes[node].rev) {
    return
  }

  // Swap children
  let tmp = self.nodes[node].left
  self.nodes[node].left = self.nodes[node].right
  self.nodes[node].right = tmp

  // Propagate reversal to children
  let left = self.nodes[node].left
  let right = self.nodes[node].right
  if left >= 0 {
    self.nodes[left].rev = not(self.nodes[left].rev)
  }
  if right >= 0 {
    self.nodes[right].rev = not(self.nodes[right].rev)
  }
  self.nodes[node].rev = false
}

// ============================================================================
// SPLIT AND MERGE
// ============================================================================

///|
/// Split treap at position k: returns (left, right) where left contains [0, k)
/// REASONING: We traverse down the tree, deciding at each node whether it
/// belongs to left or right part based on implicit key (position).
fn ImplicitTreap::split(
  self : ImplicitTreap,
  node : Int,
  k : Int,
) -> (Int, Int) {
  if node < 0 {
    return (-1, -1)
  }
  self.push_down(node)
  let left_size = self.get_size(self.nodes[node].left)
  if k <= left_size {
    // Current node and its right subtree go to right part
    // Recursively split left subtree
    let (ll, lr) = self.split(self.nodes[node].left, k)
    self.nodes[node].left = lr
    self.update(node)
    (ll, node)
  } else {
    // Current node and its left subtree go to left part
    // Recursively split right subtree
    let (rl, rr) = self.split(self.nodes[node].right, k - left_size - 1)
    self.nodes[node].right = rl
    self.update(node)
    (node, rr)
  }
}

///|
/// Merge two treaps where all positions in left < all positions in right
/// REASONING: We choose the root based on heap property (higher priority wins)
/// and recursively merge the other subtree.
fn ImplicitTreap::merge(self : ImplicitTreap, left : Int, right : Int) -> Int {
  if left < 0 {
    return right
  }
  if right < 0 {
    return left
  }
  self.push_down(left)
  self.push_down(right)
  if self.nodes[left].priority > self.nodes[right].priority {
    // Left becomes root
    self.nodes[left].right = self.merge(self.nodes[left].right, right)
    self.update(left)
    left
  } else {
    // Right becomes root
    self.nodes[right].left = self.merge(left, self.nodes[right].left)
    self.update(right)
    right
  }
}

// ============================================================================
// SEQUENCE OPERATIONS
// ============================================================================

///|
/// Insert value at position pos
fn ImplicitTreap::insert(self : ImplicitTreap, pos : Int, val : Int64) -> Unit {
  let new_node = self.alloc_node(val)
  let (left, right) = self.split(self.root, pos)
  self.root = self.merge(self.merge(left, new_node), right)
}

///|
/// Delete element at position pos
fn ImplicitTreap::delete(self : ImplicitTreap, pos : Int) -> Int64? {
  if pos < 0 || pos >= self.size() {
    return None
  }
  let (left, mid_right) = self.split(self.root, pos)
  let (mid, right) = self.split(mid_right, 1)
  if mid < 0 {
    self.root = self.merge(left, right)
    return None
  }
  let val = self.nodes[mid].val
  self.free_list.push(mid)
  self.root = self.merge(left, right)
  Some(val)
}

///|
/// Get value at position pos
fn ImplicitTreap::get(self : ImplicitTreap, pos : Int) -> Int64? {
  if pos < 0 || pos >= self.size() {
    return None
  }

  // LOOP INVARIANT: target position relative to current node decreases
  for node = self.root, target = pos; node >= 0; {
    self.push_down(node)
    let left_size = self.get_size(self.nodes[node].left)
    if target < left_size {
      continue self.nodes[node].left, target
    } else if target == left_size {
      break Some(self.nodes[node].val)
    } else {
      continue self.nodes[node].right, target - left_size - 1
    }
  } else {
    None
  } where {
    invariant: node >= 0 && node < self.nodes.length(),
    invariant: target >= 0 && target < self.get_size(node),
    reasoning: (
      #|SEARCH INVARIANT:
      #|At each step, (node, target) describes the target position inside the
      #|subtree rooted at node. If target < left_size we move left; if
      #|target > left_size we move right and subtract left_size + 1.
      #|
      #|Thus target always stays within the new subtree size, and each step
      #|moves down one level toward the requested index.
      #|MAINTENANCE:
      #|Updating (node, target) according to left_size preserves the mapping
      #|between target and its position in the chosen child subtree.
      #|TERMINATION:
      #|Each iteration descends one level; the loop ends when the node is
      #|found or a null child is reached.
    ),
  }
}

///|
/// Set value at position pos
fn ImplicitTreap::set(self : ImplicitTreap, pos : Int, val : Int64) -> Unit {
  if pos < 0 || pos >= self.size() {
    return
  }

  // Find and update node
  for node = self.root, target = pos; node >= 0; {
    self.push_down(node)
    let left_size = self.get_size(self.nodes[node].left)
    if target < left_size {
      continue self.nodes[node].left, target
    } else if target == left_size {
      self.nodes[node].val = val
      // Need to rebuild path - for simplicity, rebuild whole tree's aggregates
      self.rebuild_aggregates(self.root)
      break
    } else {
      continue self.nodes[node].right, target - left_size - 1
    }
  } where {
    invariant: node == -1 || (node >= 0 && node < self.nodes.length()),
    reasoning: (
      #|INVARIANT (implicit index walk):
      #|target is the index within the current subtree rooted at node.
      #|MAINTENANCE:
      #|Move left if target < left_size; move right otherwise, adjusting target.
      #|TERMINATION:
      #|When target equals left_size, node is the desired position.
    ),
  }
}

///|
/// Helper to rebuild aggregates after update
fn ImplicitTreap::rebuild_aggregates(self : ImplicitTreap, node : Int) -> Unit {
  if node < 0 {
    return
  }
  self.rebuild_aggregates(self.nodes[node].left)
  self.rebuild_aggregates(self.nodes[node].right)
  self.update(node)
}

///|
fn ImplicitTreap::size(self : ImplicitTreap) -> Int {
  self.get_size(self.root)
}

// ============================================================================
// RANGE QUERIES
// ============================================================================

///|
/// Query sum in range [l, r)
fn ImplicitTreap::range_sum(self : ImplicitTreap, l : Int, r : Int) -> Int64 {
  if l >= r || l < 0 || r > self.size() {
    return 0L
  }

  // Split into [0, l) + [l, r) + [r, n)
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)
  let result = self.get_sum(mid)

  // Merge back
  self.root = self.merge(left, self.merge(mid, right))
  result
}

///|
/// Query minimum in range [l, r)
fn ImplicitTreap::range_min(self : ImplicitTreap, l : Int, r : Int) -> Int64? {
  if l >= r || l < 0 || r > self.size() {
    return None
  }
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)
  let result = if mid >= 0 { Some(self.nodes[mid].min_val) } else { None }
  self.root = self.merge(left, self.merge(mid, right))
  result
}

///|
/// Query maximum in range [l, r)
fn ImplicitTreap::range_max(self : ImplicitTreap, l : Int, r : Int) -> Int64? {
  if l >= r || l < 0 || r > self.size() {
    return None
  }
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)
  let result = if mid >= 0 { Some(self.nodes[mid].max_val) } else { None }
  self.root = self.merge(left, self.merge(mid, right))
  result
}

///|
/// Reverse range [l, r)
fn ImplicitTreap::reverse(self : ImplicitTreap, l : Int, r : Int) -> Unit {
  if l >= r || l < 0 || r > self.size() {
    return
  }
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)
  if mid >= 0 {
    self.nodes[mid].rev = not(self.nodes[mid].rev)
  }
  self.root = self.merge(left, self.merge(mid, right))
}

// ============================================================================
// SEQUENCE BUILDING
// ============================================================================

///|
/// Build from array
fn ImplicitTreap::from_array(arr : Array[Int64]) -> ImplicitTreap {
  let treap = ImplicitTreap::new()
  for i = 0; i < arr.length(); i = i + 1 {
    treap.insert(i, arr[i])
  } where {
    invariant: i >= 0 && i <= arr.length(),
    reasoning: (
      #|INVARIANT (treap build):
      #|Elements arr[0..i) have been inserted so position j stores arr[j].
      #|MAINTENANCE:
      #|Insert arr[i] at position i, extending the sequence by one.
      #|TERMINATION:
      #|At i = arr.length(), treap order matches the array.
    ),
  }
  treap
}

///|
/// Convert to array
fn ImplicitTreap::to_array(self : ImplicitTreap) -> Array[Int64] {
  let result : Array[Int64] = []
  fn inorder(treap : ImplicitTreap, node : Int, result : Array[Int64]) -> Unit {
    if node < 0 {
      return
    }
    treap.push_down(node)
    inorder(treap, treap.nodes[node].left, result)
    result.push(treap.nodes[node].val)
    inorder(treap, treap.nodes[node].right, result)
  }

  inorder(self, self.root, result)
  result
}

///|
/// Push back a value
fn ImplicitTreap::push_back(self : ImplicitTreap, val : Int64) -> Unit {
  self.insert(self.size(), val)
}

///|
/// Push front a value
fn ImplicitTreap::push_front(self : ImplicitTreap, val : Int64) -> Unit {
  self.insert(0, val)
}

///|
/// Pop back
fn ImplicitTreap::pop_back(self : ImplicitTreap) -> Int64? {
  if self.size() == 0 {
    return None
  }
  self.delete(self.size() - 1)
}

///|
/// Pop front
fn ImplicitTreap::pop_front(self : ImplicitTreap) -> Int64? {
  if self.size() == 0 {
    return None
  }
  self.delete(0)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "implicit treap basic" {
  let treap = ImplicitTreap::new()

  // Insert elements: [10, 20, 30]
  treap.insert(0, 10L)
  treap.insert(1, 20L)
  treap.insert(2, 30L)
  inspect(treap.size(), content="3")
  inspect(treap.get(0), content="Some(10)")
  inspect(treap.get(1), content="Some(20)")
  inspect(treap.get(2), content="Some(30)")
  inspect(treap.get(3), content="None")
}

///|
test "implicit treap insert at position" {
  let treap = ImplicitTreap::new()

  // Build [10, 30]
  treap.insert(0, 10L)
  treap.insert(1, 30L)

  // Insert 20 at position 1: [10, 20, 30]
  treap.insert(1, 20L)
  inspect(treap.to_array(), content="[10, 20, 30]")
}

///|
test "implicit treap delete" {
  let treap = ImplicitTreap::from_array([10L, 20L, 30L, 40L, 50L])
  inspect(treap.size(), content="5")

  // Delete at position 2 (value 30)
  let deleted = treap.delete(2)
  inspect(deleted, content="Some(30)")
  inspect(treap.to_array(), content="[10, 20, 40, 50]")

  // Delete at position 0 (value 10)
  let deleted2 = treap.delete(0)
  inspect(deleted2, content="Some(10)")
  inspect(treap.to_array(), content="[20, 40, 50]")
}

///|
test "implicit treap range sum" {
  let treap = ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L])

  // Sum of full range
  inspect(treap.range_sum(0, 5), content="15")

  // Sum of [1, 4) = 2+3+4 = 9
  inspect(treap.range_sum(1, 4), content="9")

  // Sum of single element
  inspect(treap.range_sum(2, 3), content="3")

  // Empty range
  inspect(treap.range_sum(3, 3), content="0")
}

///|
test "implicit treap range min max" {
  let treap = ImplicitTreap::from_array([5L, 2L, 8L, 1L, 9L])
  inspect(treap.range_min(0, 5), content="Some(1)")
  inspect(treap.range_max(0, 5), content="Some(9)")

  // Range [0, 3) = [5, 2, 8]
  inspect(treap.range_min(0, 3), content="Some(2)")
  inspect(treap.range_max(0, 3), content="Some(8)")

  // Range [2, 5) = [8, 1, 9]
  inspect(treap.range_min(2, 5), content="Some(1)")
  inspect(treap.range_max(2, 5), content="Some(9)")
}

///|
test "implicit treap reverse" {
  let treap = ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L])

  // Reverse [1, 4): [1, 4, 3, 2, 5]
  treap.reverse(1, 4)
  inspect(treap.to_array(), content="[1, 4, 3, 2, 5]")

  // Reverse all: [5, 2, 3, 4, 1]
  treap.reverse(0, 5)
  inspect(treap.to_array(), content="[5, 2, 3, 4, 1]")
}

///|
test "implicit treap set" {
  let treap = ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L])
  treap.set(2, 100L)
  inspect(treap.get(2), content="Some(100)")
  inspect(treap.to_array(), content="[1, 2, 100, 4, 5]")

  // Sum should update
  inspect(treap.range_sum(0, 5), content="112") // 1+2+100+4+5
}

///|
test "implicit treap push pop" {
  let treap = ImplicitTreap::new()
  treap.push_back(1L)
  treap.push_back(2L)
  treap.push_front(0L)
  // Now: [0, 1, 2]
  inspect(treap.to_array(), content="[0, 1, 2]")
  inspect(treap.pop_back(), content="Some(2)")
  inspect(treap.pop_front(), content="Some(0)")
  inspect(treap.to_array(), content="[1]")
}

///|
test "implicit treap stress" {
  let treap = ImplicitTreap::new()

  // Build sequence 0..99
  for i in 0..<100 {
    treap.push_back(i.to_int64())
  }
  inspect(treap.size(), content="100")
  inspect(treap.range_sum(0, 100), content="4950") // Sum 0..99

  // Reverse first half
  treap.reverse(0, 50)
  inspect(treap.get(0), content="Some(49)")
  inspect(treap.get(49), content="Some(0)")

  // Sum should be unchanged
  inspect(treap.range_sum(0, 100), content="4950")
}

///|
test "implicit treap multiple reverses" {
  let treap = ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L, 6L])

  // Reverse [0, 3): [3, 2, 1, 4, 5, 6]
  treap.reverse(0, 3)
  inspect(treap.to_array(), content="[3, 2, 1, 4, 5, 6]")

  // Reverse [3, 6): [3, 2, 1, 6, 5, 4]
  treap.reverse(3, 6)
  inspect(treap.to_array(), content="[3, 2, 1, 6, 5, 4]")

  // Reverse all: [4, 5, 6, 1, 2, 3]
  treap.reverse(0, 6)
  inspect(treap.to_array(), content="[4, 5, 6, 1, 2, 3]")
}

///|
test "implicit treap rope operations" {
  // Simulate rope: concatenate two sequences
  let treap1 = ImplicitTreap::from_array([1L, 2L, 3L])
  let treap2 = ImplicitTreap::from_array([4L, 5L, 6L])

  // Manual concatenation by inserting elements
  for i in 0..<treap2.size() {
    match treap2.get(i) {
      Some(v) => treap1.push_back(v)
      None => ()
    }
  }
  inspect(treap1.to_array(), content="[1, 2, 3, 4, 5, 6]")

  // Split simulation: delete elements
  for _ in 0..<3 {
    let _ = treap1.pop_front()

  }
  inspect(treap1.to_array(), content="[4, 5, 6]")
}
