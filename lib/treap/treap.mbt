// ============================================================================
// TREAP - Randomized Binary Search Tree
// ============================================================================
//
// A Treap is a BST where each node has a random priority.
// The tree maintains BST property on keys and heap property on priorities.
//
// KEY INSIGHT: Random priorities ensure O(log n) expected height,
// giving O(log n) expected time for insert/delete/search.
//
// INVARIANTS:
// 1. BST property: left.key < node.key < right.key
// 2. Heap property: node.priority > children.priority (max-heap)
// 3. Expected height: O(log n) due to random priorities
//
// TIME COMPLEXITY: O(log n) expected per operation
// SPACE COMPLEXITY: O(n)

///|
priv struct TreapNode {
  key : Int
  priority : Int
  size : Int
  left : TreapNode?
  right : TreapNode?
}

///|
priv struct Treap {
  root : TreapNode?
  seed : Int
}

///|
/// Simple PRNG for priorities
fn next_random(seed : Int) -> (Int, Int) {
  let new_seed = seed * 1103515245 + 12345
  let priority = (new_seed / 65536) % 32768
  (if priority < 0 { -priority } else { priority }, new_seed)
}

///|
fn node_size(node : TreapNode?) -> Int {
  match node {
    None => 0
    Some(n) => n.size
  }
}

///|
/// Create a new node
fn TreapNode::new(key : Int, priority : Int) -> TreapNode {
  { key, priority, size: 1, left: None, right: None }
}

///|
/// Update size based on children
fn update_size(node : TreapNode) -> TreapNode {
  { ..node, size: 1 + node_size(node.left) + node_size(node.right) }
}

///|
/// Right rotation (functional, returns new root)
fn rotate_right(node : TreapNode) -> TreapNode {
  match node.left {
    None => node
    Some(left) => {
      let new_node = update_size({ ..node, left: left.right })
      update_size({ ..left, right: Some(new_node) })
    }
  }
}

///|
/// Left rotation (functional, returns new root)
fn rotate_left(node : TreapNode) -> TreapNode {
  match node.right {
    None => node
    Some(right) => {
      let new_node = update_size({ ..node, right: right.left })
      update_size({ ..right, left: Some(new_node) })
    }
  }
}

///|
/// Insert key into treap (functional, returns new root)
fn treap_insert(root : TreapNode?, key : Int, priority : Int) -> TreapNode {
  match root {
    None => TreapNode::new(key, priority)
    Some(node) =>
      if key < node.key {
        let new_left = treap_insert(node.left, key, priority)
        let new_node = update_size({ ..node, left: Some(new_left) })
        // Rotate right if heap property violated
        if new_left.priority > node.priority {
          rotate_right(new_node)
        } else {
          new_node
        }
      } else if key > node.key {
        let new_right = treap_insert(node.right, key, priority)
        let new_node = update_size({ ..node, right: Some(new_right) })
        // Rotate left if heap property violated
        if new_right.priority > node.priority {
          rotate_left(new_node)
        } else {
          new_node
        }
      } else {
        // Key exists, no change
        node
      }
  }
}

///|
/// Delete key from treap (functional, returns new root)
fn treap_delete(root : TreapNode?, key : Int) -> TreapNode? {
  match root {
    None => None
    Some(node) =>
      if key < node.key {
        Some(update_size({ ..node, left: treap_delete(node.left, key) }))
      } else if key > node.key {
        Some(update_size({ ..node, right: treap_delete(node.right, key) }))
      } else {
        // Found node to delete
        match (node.left, node.right) {
          (None, None) => None
          (Some(left), None) => Some(left)
          (None, Some(right)) => Some(right)
          (Some(left), Some(right)) =>
            // Rotate to push node down
            if left.priority > right.priority {
              let rotated = rotate_right(node)
              Some(update_size({ ..rotated, right: treap_delete(rotated.right, key) }))
            } else {
              let rotated = rotate_left(node)
              Some(update_size({ ..rotated, left: treap_delete(rotated.left, key) }))
            }
        }
      }
  }
}

///|
/// Search for key in treap
fn treap_search(root : TreapNode?, key : Int) -> Bool {
  match root {
    None => false
    Some(node) =>
      if key < node.key {
        treap_search(node.left, key)
      } else if key > node.key {
        treap_search(node.right, key)
      } else {
        true
      }
  }
}

///|
/// Find k-th smallest element (1-indexed)
fn treap_kth(root : TreapNode?, k : Int) -> Int? {
  match root {
    None => None
    Some(node) => {
      let left_size = node_size(node.left)
      if k <= left_size {
        treap_kth(node.left, k)
      } else if k == left_size + 1 {
        Some(node.key)
      } else {
        treap_kth(node.right, k - left_size - 1)
      }
    }
  }
}

///|
/// Count elements less than key
fn treap_count_less(root : TreapNode?, key : Int) -> Int {
  match root {
    None => 0
    Some(node) =>
      if key <= node.key {
        treap_count_less(node.left, key)
      } else {
        node_size(node.left) + 1 + treap_count_less(node.right, key)
      }
  }
}

///|
/// Get rank of key (1-indexed position if key exists)
fn treap_rank(root : TreapNode?, key : Int) -> Int {
  treap_count_less(root, key) + 1
}

///|
fn Treap::new() -> Treap {
  { root: None, seed: 42 }
}

///|
fn Treap::insert(self : Treap, key : Int) -> Treap {
  let (priority, new_seed) = next_random(self.seed)
  let new_root = treap_insert(self.root, key, priority)
  { root: Some(new_root), seed: new_seed }
}

///|
fn Treap::delete(self : Treap, key : Int) -> Treap {
  { root: treap_delete(self.root, key), seed: self.seed }
}

///|
fn Treap::contains(self : Treap, key : Int) -> Bool {
  treap_search(self.root, key)
}

///|
fn Treap::kth(self : Treap, k : Int) -> Int? {
  treap_kth(self.root, k)
}

///|
fn Treap::size(self : Treap) -> Int {
  node_size(self.root)
}

///|
fn Treap::rank(self : Treap, key : Int) -> Int {
  treap_rank(self.root, key)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "treap insert and search" {
  let t = Treap::new()
    .insert(5)
    .insert(3)
    .insert(7)
    .insert(1)

  inspect(t.contains(5), content="true")
  inspect(t.contains(3), content="true")
  inspect(t.contains(10), content="false")
}

///|
test "treap size" {
  let t = Treap::new()
    .insert(5)
    .insert(3)
    .insert(7)

  inspect(t.size(), content="3")
}

///|
test "treap delete" {
  let t = Treap::new()
    .insert(5)
    .insert(3)
    .insert(7)
    .delete(5)

  inspect(t.contains(5), content="false")
  inspect(t.contains(3), content="true")
  inspect(t.size(), content="2")
}

///|
test "treap kth" {
  let t = Treap::new()
    .insert(5)
    .insert(3)
    .insert(7)
    .insert(1)
    .insert(9)

  // Sorted: 1, 3, 5, 7, 9
  inspect(t.kth(1), content="Some(1)")
  inspect(t.kth(3), content="Some(5)")
  inspect(t.kth(5), content="Some(9)")
}

///|
test "treap rank" {
  let t = Treap::new()
    .insert(5)
    .insert(3)
    .insert(7)
    .insert(1)

  // Sorted: 1, 3, 5, 7
  inspect(t.rank(1), content="1")
  inspect(t.rank(5), content="3")
  inspect(t.rank(10), content="5")
}

///|
test "treap empty" {
  let t = Treap::new()
  inspect(t.size(), content="0")
  inspect(t.contains(5), content="false")
  inspect(t.kth(1) is None, content="true")
}

///|
test "treap duplicate insert" {
  let t = Treap::new()
    .insert(5)
    .insert(5)
    .insert(5)

  inspect(t.size(), content="1")
}

///|
test "treap delete nonexistent" {
  let t = Treap::new()
    .insert(5)
    .delete(10)

  inspect(t.size(), content="1")
  inspect(t.contains(5), content="true")
}
