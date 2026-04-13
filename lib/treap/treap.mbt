// ============================================================================
// TREAP - Randomized Binary Search Tree
// ============================================================================
//
// A Treap is a randomized BST that combines properties of:
// 1. Binary Search Tree: keys satisfy BST property
// 2. Heap: priorities satisfy heap property (max-heap)
//
// KEY INSIGHT: Random priorities ensure expected O(log n) height,
// giving O(log n) expected time for all operations.
//
// STRUCTURE:
// Each node has:
// - key: satisfies BST property (left < key <= right for duplicates)
// - priority: random value, satisfies max-heap property (parent >= children)
// - size: cached subtree count for O(log n) order statistics
//
// OPERATIONS via SPLIT and MERGE:
// - split(t, key): split tree t into (keys < key, keys >= key)
// - merge(l, r): merge two trees where all keys in l < all keys in r
//
// SPLIT(t, key):
// If t is empty: return (null, null)
// If t.key < key: (l, r) = split(t.right, key); return (t with right=l, r)
// Else: (l, r) = split(t.left, key); return (l, t with left=r)
//
// MERGE(l, r):
// If l or r is empty: return the other
// If l.priority > r.priority: return l with right = merge(l.right, r)
// Else: return r with left = merge(l, r.left)
//
// INVARIANTS:
// 1. BST property: for each node, all keys in left subtree < node.key
//    and node.key <= all keys in right subtree
// 2. Heap property: for each node, node.priority >= children's priorities
// 3. Random priorities give expected O(log n) height
// 4. size(node) = 1 + size(left) + size(right)
//
// EXPECTED TIME COMPLEXITY: O(log n) for insert, delete, find
// SPACE COMPLEXITY: O(n)

///|
/// A single node in the treap, combining a BST key with a heap priority.
///
/// Each node also caches the size of its subtree so that order-statistic
/// queries (`kth_element`, `count_less_than`) run in O(log n) without an
/// extra traversal.
///
/// The `size` field must be kept consistent: `size = 1 + size(left) +
/// size(right)`.  Call `update_size` after any structural change.
pub struct TreapNode[T] {
  key : T
  priority : Int // Random priority; satisfies max-heap: parent.priority >= child.priority
  mut left : TreapNode[T]?
  mut right : TreapNode[T]?
  mut size : Int // Cached subtree size (number of nodes rooted here)
}

///|
/// Allocates a new leaf node with the given key and priority.
/// Both children are absent and the subtree size is 1.
fn[T] TreapNode::new(key : T, priority : Int) -> TreapNode[T] {
  { key, priority, left: None, right: None, size: 1 }
}

///|
/// Returns the subtree size of an optional node.
/// Returns 0 for `None`, matching the convention that an empty subtree has
/// zero elements.
fn[T] get_size(node : TreapNode[T]?) -> Int {
  match node {
    None => 0
    Some(n) => n.size
  }
}

///|
/// Recomputes and stores the subtree size of `node` from its children.
///
/// Must be called after any operation that changes `node.left` or
/// `node.right` to keep the cached size consistent.
fn[T] update_size(node : TreapNode[T]) -> Unit {
  node.size = 1 + get_size(node.left) + get_size(node.right)
}

///|
/// A generic randomized BST that maintains BST order by key and heap order
/// by a random priority.
///
/// The type parameter `T` must implement `Compare` for insert, delete, and
/// search operations.  Duplicate keys are allowed; each duplicate occupies its
/// own node and `delete` removes exactly one copy.
///
/// The internal RNG is a simple LCG seeded at construction time, giving
/// deterministic behaviour for a fixed sequence of insertions.
pub struct Treap[T] {
  mut root : TreapNode[T]?
  mut rng_state : Int // Current LCG state; advances by one step per insertion
}

///|
/// Advances the LCG state by one step and returns `(new_state, abs_value)`.
///
/// The returned `abs_value` is used directly as the priority of a new node.
/// Using a fixed LCG keeps the implementation self-contained and
/// deterministic.
fn next_random(state : Int) -> (Int, Int) {
  // LCG: next = (a * state + c) mod m
  // Using common constants
  let a = 1103515245
  let c = 12345
  let next = a * state + c
  (next, if next < 0 { -next } else { next })
}

///|
/// Creates an empty treap.
///
/// The internal RNG is seeded with a fixed value so that two treaps created
/// in the same program produce the same internal structure for identical
/// insertion sequences.  This does not affect correctness: regardless of the
/// priority assignment, `to_array()` always returns keys in sorted order.
///
/// # Example
///
/// ```moonbit nocheck
/// let t : @treap.Treap[Int] = @treap.Treap::new()
/// // t is empty
/// ```
pub fn[T] Treap::new() -> Treap[T] {
  { root: None, rng_state: 42 }
}

///|
/// Splits the subtree rooted at `node` into two treaps:
/// - left result : all keys strictly less than `key`
/// - right result: all keys greater than or equal to `key`
///
/// The split is performed recursively in O(log n) expected time.
/// Both subtrees remain valid treaps (BST + heap properties hold).
///
/// After the split, each affected node's `size` is updated on the way back
/// up the recursion.
fn[T : Compare] split(
  node : TreapNode[T]?,
  key : T,
) -> (TreapNode[T]?, TreapNode[T]?) {
  match node {
    None => (None, None)
    Some(n) =>
      if n.key < key {
        let (l, r) = split(n.right, key)
        n.right = l
        update_size(n)
        (Some(n), r)
      } else {
        let (l, r) = split(n.left, key)
        n.left = r
        update_size(n)
        (l, Some(n))
      }
  }
}

///|
/// Merges two treaps `l` and `r` into a single treap.
///
/// Precondition: every key in `l` must be strictly less than every key in
/// `r`.  This invariant is the caller's responsibility; `merge` does not
/// verify it.
///
/// The node with the higher priority becomes the new root, and the other
/// tree is recursively merged into its appropriate subtree.  This preserves
/// both the BST property (by the precondition) and the heap property (by
/// choosing the higher-priority root).
///
/// Runs in O(log n) expected time.
fn[T] merge(l : TreapNode[T]?, r : TreapNode[T]?) -> TreapNode[T]? {
  match (l, r) {
    (None, r) => r
    (l, None) => l
    (Some(ln), Some(rn)) =>
      if ln.priority > rn.priority {
        ln.right = merge(ln.right, Some(rn))
        update_size(ln)
        Some(ln)
      } else {
        rn.left = merge(Some(ln), rn.left)
        update_size(rn)
        Some(rn)
      }
  }
}

///|
/// Inserts `key` into the treap.
///
/// A new node is created with a random priority drawn from the internal LCG.
/// The tree is split at `key`, the new node is merged between the two halves,
/// and then the halves are merged back together.  This keeps the BST and heap
/// invariants intact.
///
/// Duplicate keys are permitted.  Each duplicate occupies its own node; the
/// new node is placed to the right of all existing copies of the same key.
///
/// Runs in O(log n) expected time.
pub fn[T : Compare] Treap::insert(self : Treap[T], key : T) -> Unit {
  let (next_state, priority) = next_random(self.rng_state)
  self.rng_state = next_state
  let new_node = TreapNode::new(key, priority)
  let (l, r) = split(self.root, key)
  self.root = merge(merge(l, Some(new_node)), r)
}

///|
/// Removes one occurrence of `key` from the treap.
///
/// If `key` is present, exactly one node with that key is removed and `true`
/// is returned.  If `key` is not found, the treap is unchanged and `false` is
/// returned.
///
/// When duplicates exist, `delete` removes an arbitrary one of them (the one
/// encountered first during the recursive descent).
///
/// Runs in O(log n) expected time.
pub fn[T : Compare] Treap::delete(self : Treap[T], key : T) -> Bool {
  let (next_root, deleted) = delete_node(self.root, key)
  self.root = next_root
  deleted
}

///|
/// Recursive helper for `delete`.
///
/// Descends the BST to find a node whose key equals `key`, removes it by
/// merging its two children, and rebalances `size` on the way back up.
///
/// Returns `(new_root, deleted)`:
/// - `new_root` is the root of the modified subtree.
/// - `deleted` is `true` when a node was removed.
fn[T : Compare] delete_node(
  node : TreapNode[T]?,
  key : T,
) -> (TreapNode[T]?, Bool) {
  match node {
    None => (None, false)
    Some(n) =>
      if key < n.key {
        let (new_left, deleted) = delete_node(n.left, key)
        n.left = new_left
        if deleted {
          update_size(n)
        }
        (Some(n), deleted)
      } else if key > n.key {
        let (new_right, deleted) = delete_node(n.right, key)
        n.right = new_right
        if deleted {
          update_size(n)
        }
        (Some(n), deleted)
      } else {
        // Found: remove this node by merging its children
        (merge(n.left, n.right), true)
      }
  }
}
