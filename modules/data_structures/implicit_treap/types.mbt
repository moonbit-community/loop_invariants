// ============================================================================
// IMPLICIT TREAP - Type Definitions
// ============================================================================
//
// A Treap with Implicit Keys is a balanced BST that maintains a sequence where
// positions are determined implicitly by subtree sizes rather than stored keys.
//
// KEY INSIGHT:
// ```
//   Instead of storing keys, each node's "key" is its position in the
//   in-order traversal. This position is computed dynamically as:
//
//     position(node) = size(left_subtree) + positions from ancestors going right
//
//   This means:
//   - No keys need to be stored or updated
//   - Insert/delete at any position is O(log n)
//   - Split/merge preserve positions automatically
// ```
//
// STRUCTURE:
// ```
//   BST Property: Left subtree contains elements with smaller positions
//   Heap Property: Parent priority > children priorities
//
//   Example: Sequence [A, B, C, D, E]
//
//            C(0.8)         BST order by implicit position
//           / \             Heap order by priority
//         B(0.5) D(0.6)
//         /       \
//       A(0.2)   E(0.3)
//
//   Position of C = size(left) = 2 → C is at index 2
//   Position of A = 0 (leftmost)
//   Position of E = 2 + 1 + 1 = 4 (rightmost)
// ```
//
// WHY TREAP?
// ```
//   Random priorities ensure expected O(log n) height.
//   Unlike AVL/Red-Black trees:
//   - No complex rebalancing rules
//   - Split/merge naturally preserve balance
//   - Simpler implementation
// ```
//
// OPERATIONS (all O(log n) expected):
// ```
//   split(k):     Split into [0..k) and [k..n)
//   merge(t1,t2): Merge sequences (all t1 positions < t2 positions)
//   insert(pos):  Insert at position via split + merge
//   delete(pos):  Delete at position via split + merge
//   reverse(l,r): Reverse range [l,r) with lazy propagation
// ```
//
// APPLICATIONS:
//   - Rope data structure (text editors)
//   - Ordered list with fast insert/delete
//   - Range queries with modifications

///|
/// A single node in the implicit treap's arena-allocated node pool.
///
/// Nodes are stored in a flat array (`ImplicitTreap.nodes`) and reference
/// their children by integer index rather than by pointer. The sentinel value
/// `-1` represents the absence of a child (analogous to `null`).
///
/// Each node caches three aggregate values (`sum`, `min_val`, `max_val`) that
/// cover its entire subtree. These are refreshed by `update` after every
/// structural change and are used to answer range queries in O(1) once the
/// range is isolated by split/merge.
///
/// The `rev` field is a *lazy reversal flag*. Setting it to `true` marks the
/// subtree as logically reversed without physically moving any nodes. The flag
/// is pushed down to children by `push_down` before any traversal into them.
///
/// FIELDS:
/// ```
///   val:      Value stored at this position
///   priority: Random priority for heap property (higher = closer to root)
///   size:     Size of subtree (for implicit key computation)
///   sum:      Sum of values in subtree (for range sum queries)
///   min_val:  Minimum value in subtree
///   max_val:  Maximum value in subtree
///   rev:      Lazy reversal flag (children should be swapped on next access)
///   left:     Index of left child in nodes array (-1 if none)
///   right:    Index of right child in nodes array (-1 if none)
/// ```
///
/// IMPLICIT KEY COMPUTATION:
/// ```
///   The key (position) of a node is:
///     size(left_subtree) + sum of (size(left_subtree) + 1)
///     for each ancestor where we went right
///
///   This is computed dynamically during traversal; nothing is stored here.
/// ```
pub(all) struct ImplicitNode {
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
/// An implicit treap that represents a mutable sequence of `Int64` values.
///
/// The treap maintains the following invariants at all times:
///
/// - **BST order**: in-order traversal of the tree produces the sequence in
///   its current logical order.
/// - **Heap order**: every node's `priority` is greater than its children's
///   priorities, ensuring O(log n) expected height.
/// - **Aggregate validity**: each node's `size`, `sum`, `min_val`, and
///   `max_val` correctly describe its entire subtree (after any pending
///   `push_down` operations have been applied).
///
/// All structural operations (insert, delete, reverse, range queries) are
/// implemented via `split` and `merge` and run in **O(log n) expected time**.
///
/// COMPONENTS:
/// ```
///   nodes:      Array-based node storage (indices instead of pointers)
///   root:       Index of root node (-1 if empty)
///   rand_state: State for the LCG random priority generator
///   free_list:  Recycled node indices for O(1) amortized allocation
/// ```
///
/// MEMORY MANAGEMENT:
/// ```
///   Nodes are stored in a flat array with index-based references.
///   When a node is deleted, its index is pushed onto free_list.
///   Allocation checks free_list first, then appends to the array.
///   This keeps allocation O(1) amortized and avoids GC pressure.
/// ```
pub(all) struct ImplicitTreap {
  nodes : Array[ImplicitNode]
  mut root : Int
  mut rand_state : Int
  free_list : Array[Int]
}

///|
/// Create a new, empty implicit treap.
///
/// The treap starts with no elements (`root = -1`). The LCG random number
/// generator is seeded with a fixed value so that priority generation is
/// deterministic across runs.
///
/// Example:
/// ```
/// let treap = ImplicitTreap()
/// treap.push_back(42L)
/// debug_inspect(treap.size(), content="1")
/// ```
pub fn ImplicitTreap::ImplicitTreap() -> ImplicitTreap {
  { nodes: [], root: -1, rand_state: 12345, free_list: [] }
}

///|
/// Return the number of elements currently stored in the treap.
///
/// This is an O(1) operation: the count is read directly from the root
/// node's cached `size` field (or returns 0 for an empty treap).
///
/// Example:
/// ```
/// let treap = ImplicitTreap::from_array([1L, 2L, 3L])
/// debug_inspect(treap.size(), content="3")
/// ```
pub fn ImplicitTreap::size(self : ImplicitTreap) -> Int {
  self.get_size(self.root)
}
