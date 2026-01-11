///|
/// Segment Tree with Lazy Propagation Examples
///
/// This file demonstrates segment tree data structures with lazy propagation,
/// showcasing loop invariants that capture the subtle correctness properties
/// of deferred updates and range operations.
///
/// Key Insight: Lazy propagation maintains the invariant that the "true" value
/// at any node equals the stored value plus all pending lazy updates from ancestors.

///|
/// Segment Tree with Lazy Propagation for Range Sum Queries
///
/// MATHEMATICAL FOUNDATION:
/// The segment tree represents a partition of [0, n) into O(n) canonical intervals.
/// Each node covers an interval and stores:
///   - sum: the sum of all elements in the interval (with all lazy updates applied)
///   - lazy: pending "add" operation to apply to all elements in the subtree
///
/// INVARIANT: For node i covering interval [l, r):
///   true_sum[i] = sum[i] + lazy[i] * (r - l)
/// where true_sum[i] is what the sum would be if all lazy values were pushed down.
priv struct LazySegmentTree {
  n : Int
  tree : Array[Int64] // sum values
  lazy_add : Array[Int64] // pending range-add values
}

///|
fn LazySegmentTree::new(arr : ArrayView[Int]) -> LazySegmentTree {
  let n = arr.length()
  let tree = Array::make(4 * n, 0L)
  let lazy_add = Array::make(4 * n, 0L)
  let st : LazySegmentTree = { n, tree, lazy_add }
  if n > 0 {
    st.build(arr, 1, 0, n)
  }
  st
}

///|
/// Build the segment tree from an array.
///
/// INVARIANT: After build(arr, node, l, r), tree[node] = sum(arr[l..r])
fn LazySegmentTree::build(
  self : LazySegmentTree,
  arr : ArrayView[Int],
  node : Int,
  l : Int,
  r : Int,
) -> Unit {
  if r - l == 1 {
    // Leaf node
    self.tree[node] = arr[l].to_int64()
  } else {
    let mid = (l + r) / 2
    self.build(arr, 2 * node, l, mid)
    self.build(arr, 2 * node + 1, mid, r)
    self.tree[node] = self.tree[2 * node] + self.tree[2 * node + 1]
  }
}

///|
/// Push lazy value down to children.
///
/// INVARIANT MAINTENANCE:
/// Before push: true_sum[node] = sum[node] + lazy[node] * (r - l)
/// After push:  true_sum[node] = sum[node] (lazy cleared)
///              Children have their lazy values updated
fn LazySegmentTree::push_down(
  self : LazySegmentTree,
  node : Int,
  l : Int,
  r : Int,
) -> Unit {
  if self.lazy_add[node] != 0L {
    let mid = (l + r) / 2
    // Left child covers [l, mid), so (mid - l) elements
    self.tree[2 * node] = self.tree[2 * node] +
      self.lazy_add[node] * (mid - l).to_int64()
    self.lazy_add[2 * node] = self.lazy_add[2 * node] + self.lazy_add[node]
    // Right child covers [mid, r), so (r - mid) elements
    self.tree[2 * node + 1] = self.tree[2 * node + 1] +
      self.lazy_add[node] * (r - mid).to_int64()
    self.lazy_add[2 * node + 1] = self.lazy_add[2 * node + 1] +
      self.lazy_add[node]
    // Clear lazy value at current node
    self.lazy_add[node] = 0L
  }
}

///|
/// Range update: add `val` to all elements in [ql, qr).
///
/// LOOP INVARIANT (recursive descent):
/// At each node covering [l, r):
///   - If [l, r) ⊆ [ql, qr): update node and return (lazy propagation)
///   - If [l, r) ∩ [ql, qr) = ∅: return unchanged
///   - Otherwise: recurse to children
///
/// CORRECTNESS: Each element in [ql, qr) receives exactly one update of `val`.
fn LazySegmentTree::range_update(
  self : LazySegmentTree,
  ql : Int,
  qr : Int,
  val : Int64,
) -> Unit {
  self.update_helper(1, 0, self.n, ql, qr, val)
}

///|
fn LazySegmentTree::update_helper(
  self : LazySegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
  val : Int64,
) -> Unit {
  if qr <= l || r <= ql {
    // No overlap - nothing to do
    return
  }
  if ql <= l && r <= qr {
    // Complete overlap - apply lazy update
    // This node covers (r - l) elements, each increased by val
    self.tree[node] = self.tree[node] + val * (r - l).to_int64()
    self.lazy_add[node] = self.lazy_add[node] + val
    return
  }
  // Partial overlap - push down and recurse
  self.push_down(node, l, r)
  let mid = (l + r) / 2
  self.update_helper(2 * node, l, mid, ql, qr, val)
  self.update_helper(2 * node + 1, mid, r, ql, qr, val)
  self.tree[node] = self.tree[2 * node] + self.tree[2 * node + 1]
}

///|
/// Range query: sum of elements in [ql, qr).
///
/// INVARIANT: The returned sum accounts for all lazy updates along the path.
fn LazySegmentTree::range_sum(
  self : LazySegmentTree,
  ql : Int,
  qr : Int,
) -> Int64 {
  self.query_helper(1, 0, self.n, ql, qr)
}

///|
fn LazySegmentTree::query_helper(
  self : LazySegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  if qr <= l || r <= ql {
    return 0L
  }
  if ql <= l && r <= qr {
    return self.tree[node]
  }
  self.push_down(node, l, r)
  let mid = (l + r) / 2
  self.query_helper(2 * node, l, mid, ql, qr) +
  self.query_helper(2 * node + 1, mid, r, ql, qr)
}

///|
test "lazy segment tree basic" {
  let arr = [1, 2, 3, 4, 5]
  let st = LazySegmentTree::new(arr[:])

  // Initial sums
  assert_eq(st.range_sum(0, 5), 15L) // 1+2+3+4+5
  assert_eq(st.range_sum(0, 3), 6L) // 1+2+3
  assert_eq(st.range_sum(2, 5), 12L) // 3+4+5

  // Add 10 to range [1, 4)
  st.range_update(1, 4, 10L)
  // Now: [1, 12, 13, 14, 5]
  assert_eq(st.range_sum(0, 5), 45L) // 1+12+13+14+5
  assert_eq(st.range_sum(1, 4), 39L) // 12+13+14
  assert_eq(st.range_sum(0, 1), 1L) // unchanged
}

///|
/// Segment Tree with Range Set (Assignment) Operation
///
/// MATHEMATICAL INSIGHT:
/// Unlike additive updates, assignment requires special handling:
/// - A lazy "set" value completely overwrites the subtree
/// - We use a sentinel (Int64::min_value()) to indicate "no pending set"
///
/// INVARIANT: If lazy[node] != sentinel, then all elements in the subtree
/// should be set to lazy[node], overriding any previous values.
priv struct SetSegmentTree {
  n : Int
  tree : Array[Int64] // sum values
  lazy_set : Array[Int64] // pending "set" values (sentinel = no pending)
}

///|
let set_sentinel : Int64 = -9223372036854775808L // Int64::min_value()

///|
fn SetSegmentTree::new(arr : ArrayView[Int]) -> SetSegmentTree {
  let n = arr.length()
  let tree = Array::make(4 * n, 0L)
  let lazy_set = Array::make(4 * n, set_sentinel)
  let st : SetSegmentTree = { n, tree, lazy_set }
  if n > 0 {
    st.build(arr, 1, 0, n)
  }
  st
}

///|
fn SetSegmentTree::build(
  self : SetSegmentTree,
  arr : ArrayView[Int],
  node : Int,
  l : Int,
  r : Int,
) -> Unit {
  if r - l == 1 {
    self.tree[node] = arr[l].to_int64()
  } else {
    let mid = (l + r) / 2
    self.build(arr, 2 * node, l, mid)
    self.build(arr, 2 * node + 1, mid, r)
    self.tree[node] = self.tree[2 * node] + self.tree[2 * node + 1]
  }
}

///|
fn SetSegmentTree::push_down(
  self : SetSegmentTree,
  node : Int,
  l : Int,
  r : Int,
) -> Unit {
  if self.lazy_set[node] != set_sentinel {
    let mid = (l + r) / 2
    let val = self.lazy_set[node]
    // Set all elements in left child to val
    self.tree[2 * node] = val * (mid - l).to_int64()
    self.lazy_set[2 * node] = val
    // Set all elements in right child to val
    self.tree[2 * node + 1] = val * (r - mid).to_int64()
    self.lazy_set[2 * node + 1] = val
    self.lazy_set[node] = set_sentinel
  }
}

///|
/// Set all elements in [ql, qr) to val.
fn SetSegmentTree::range_set(
  self : SetSegmentTree,
  ql : Int,
  qr : Int,
  val : Int64,
) -> Unit {
  self.set_helper(1, 0, self.n, ql, qr, val)
}

///|
fn SetSegmentTree::set_helper(
  self : SetSegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
  val : Int64,
) -> Unit {
  if qr <= l || r <= ql {
    return
  }
  if ql <= l && r <= qr {
    self.tree[node] = val * (r - l).to_int64()
    self.lazy_set[node] = val
    return
  }
  self.push_down(node, l, r)
  let mid = (l + r) / 2
  self.set_helper(2 * node, l, mid, ql, qr, val)
  self.set_helper(2 * node + 1, mid, r, ql, qr, val)
  self.tree[node] = self.tree[2 * node] + self.tree[2 * node + 1]
}

///|
fn SetSegmentTree::range_sum(
  self : SetSegmentTree,
  ql : Int,
  qr : Int,
) -> Int64 {
  self.query_helper(1, 0, self.n, ql, qr)
}

///|
fn SetSegmentTree::query_helper(
  self : SetSegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  if qr <= l || r <= ql {
    return 0L
  }
  if ql <= l && r <= qr {
    return self.tree[node]
  }
  self.push_down(node, l, r)
  let mid = (l + r) / 2
  self.query_helper(2 * node, l, mid, ql, qr) +
  self.query_helper(2 * node + 1, mid, r, ql, qr)
}

///|
test "set segment tree" {
  let arr = [1, 2, 3, 4, 5]
  let st = SetSegmentTree::new(arr[:])
  assert_eq(st.range_sum(0, 5), 15L)

  // Set [1, 4) to 10
  st.range_set(1, 4, 10L)
  // Now: [1, 10, 10, 10, 5]
  assert_eq(st.range_sum(0, 5), 36L)
  assert_eq(st.range_sum(1, 4), 30L)

  // Set [0, 3) to 0
  st.range_set(0, 3, 0L)
  // Now: [0, 0, 0, 10, 5]
  assert_eq(st.range_sum(0, 5), 15L)
}

///|
/// Segment Tree for Range Minimum Query with Updates
///
/// MATHEMATICAL FOUNDATION:
/// For RMQ, the combining operation is min() instead of sum.
/// Lazy propagation works differently:
///   - For "set" operations: lazy value directly sets the minimum
///   - For "add" operations: minimum shifts by the added value
///
/// INVARIANT: tree[node] = min(arr[l..r]) + (accumulated lazy additions)
priv struct RMQSegmentTree {
  n : Int
  tree : Array[Int64] // min values
  lazy_add : Array[Int64] // pending "add" values
}

///|
fn RMQSegmentTree::new(arr : ArrayView[Int]) -> RMQSegmentTree {
  let n = arr.length()
  let tree = Array::make(4 * n, 0L)
  let lazy_add = Array::make(4 * n, 0L)
  let st : RMQSegmentTree = { n, tree, lazy_add }
  if n > 0 {
    st.build(arr, 1, 0, n)
  }
  st
}

///|
fn RMQSegmentTree::build(
  self : RMQSegmentTree,
  arr : ArrayView[Int],
  node : Int,
  l : Int,
  r : Int,
) -> Unit {
  if r - l == 1 {
    self.tree[node] = arr[l].to_int64()
  } else {
    let mid = (l + r) / 2
    self.build(arr, 2 * node, l, mid)
    self.build(arr, 2 * node + 1, mid, r)
    self.tree[node] = if self.tree[2 * node] < self.tree[2 * node + 1] {
      self.tree[2 * node]
    } else {
      self.tree[2 * node + 1]
    }
  }
}

///|
fn RMQSegmentTree::push_down(self : RMQSegmentTree, node : Int) -> Unit {
  if self.lazy_add[node] != 0L {
    // Propagate addition to children
    self.tree[2 * node] = self.tree[2 * node] + self.lazy_add[node]
    self.lazy_add[2 * node] = self.lazy_add[2 * node] + self.lazy_add[node]
    self.tree[2 * node + 1] = self.tree[2 * node + 1] + self.lazy_add[node]
    self.lazy_add[2 * node + 1] = self.lazy_add[2 * node + 1] +
      self.lazy_add[node]
    self.lazy_add[node] = 0L
  }
}

///|
/// Add val to all elements in [ql, qr).
fn RMQSegmentTree::range_add(
  self : RMQSegmentTree,
  ql : Int,
  qr : Int,
  val : Int64,
) -> Unit {
  self.add_helper(1, 0, self.n, ql, qr, val)
}

///|
fn RMQSegmentTree::add_helper(
  self : RMQSegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
  val : Int64,
) -> Unit {
  if qr <= l || r <= ql {
    return
  }
  if ql <= l && r <= qr {
    self.tree[node] = self.tree[node] + val
    self.lazy_add[node] = self.lazy_add[node] + val
    return
  }
  self.push_down(node)
  let mid = (l + r) / 2
  self.add_helper(2 * node, l, mid, ql, qr, val)
  self.add_helper(2 * node + 1, mid, r, ql, qr, val)
  self.tree[node] = if self.tree[2 * node] < self.tree[2 * node + 1] {
    self.tree[2 * node]
  } else {
    self.tree[2 * node + 1]
  }
}

///|
/// Query minimum in [ql, qr).
fn RMQSegmentTree::range_min(
  self : RMQSegmentTree,
  ql : Int,
  qr : Int,
) -> Int64 {
  self.min_helper(1, 0, self.n, ql, qr)
}

///|
fn RMQSegmentTree::min_helper(
  self : RMQSegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  if qr <= l || r <= ql {
    return 9223372036854775807L // Int64::max_value()
  }
  if ql <= l && r <= qr {
    return self.tree[node]
  }
  self.push_down(node)
  let mid = (l + r) / 2
  let left_min = self.min_helper(2 * node, l, mid, ql, qr)
  let right_min = self.min_helper(2 * node + 1, mid, r, ql, qr)
  if left_min < right_min {
    left_min
  } else {
    right_min
  }
}

///|
test "RMQ segment tree" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]
  let st = RMQSegmentTree::new(arr[:])
  assert_eq(st.range_min(0, 8), 1L) // min of all
  assert_eq(st.range_min(0, 4), 1L) // min of [3,1,4,1]
  assert_eq(st.range_min(4, 8), 2L) // min of [5,9,2,6]

  // Add 10 to range [0, 4)
  st.range_add(0, 4, 10L)
  // Now: [13, 11, 14, 11, 5, 9, 2, 6]
  assert_eq(st.range_min(0, 8), 2L) // min is now 2
  assert_eq(st.range_min(0, 4), 11L) // min of first 4
}

///|
/// Persistent Segment Tree (Functional Updates)
///
/// MATHEMATICAL INSIGHT:
/// Instead of modifying nodes in place, we create new nodes for the path
/// from root to the updated leaf. This allows us to keep all historical versions.
///
/// INVARIANT: Each version is an immutable tree. After update(v, i, x),
/// version v+1 shares O(n - log n) nodes with version v.
///
/// SPACE COMPLEXITY: O(n + q log n) for n elements and q updates.
priv struct PersistentNode {
  sum : Int64
  left : Int // index into node pool, 0 = null
  right : Int // index into node pool, 0 = null
}

///|
priv struct PersistentSegmentTree {
  n : Int
  nodes : Array[PersistentNode]
  roots : Array[Int] // root index for each version
  mut node_count : Int
}

///|
fn PersistentSegmentTree::new(n : Int) -> PersistentSegmentTree {
  // Pre-allocate space for nodes (initial tree + updates)
  let max_nodes = 4 * n + 1
  let nodes = Array::make(max_nodes, { sum: 0L, left: 0, right: 0 })
  let roots = Array::make(n + 1, 0)
  let pst = { n, nodes, roots, node_count: 1 }
  // Build initial empty tree
  roots[0] = pst.build_empty(0, n)
  pst
}

///|
fn PersistentSegmentTree::alloc_node(
  self : PersistentSegmentTree,
  sum : Int64,
  left : Int,
  right : Int,
) -> Int {
  let idx = self.node_count
  self.node_count = self.node_count + 1
  self.nodes[idx] = { sum, left, right }
  idx
}

///|
fn PersistentSegmentTree::build_empty(
  self : PersistentSegmentTree,
  l : Int,
  r : Int,
) -> Int {
  if r - l == 1 {
    self.alloc_node(0L, 0, 0)
  } else {
    let mid = (l + r) / 2
    let left_child = self.build_empty(l, mid)
    let right_child = self.build_empty(mid, r)
    self.alloc_node(0L, left_child, right_child)
  }
}

///|
/// Update position pos to value val, creating a new version.
/// Returns the new version number.
///
/// INVARIANT: The new tree shares all nodes except O(log n) on the path to pos.
fn PersistentSegmentTree::update(
  self : PersistentSegmentTree,
  version : Int,
  pos : Int,
  val : Int64,
) -> Int {
  let new_root = self.update_helper(self.roots[version], 0, self.n, pos, val)
  let new_version = version + 1
  self.roots[new_version] = new_root
  new_version
}

///|
fn PersistentSegmentTree::update_helper(
  self : PersistentSegmentTree,
  node : Int,
  l : Int,
  r : Int,
  pos : Int,
  val : Int64,
) -> Int {
  if r - l == 1 {
    // Leaf node - create new node with updated value
    self.alloc_node(val, 0, 0)
  } else {
    let mid = (l + r) / 2
    let old_node = self.nodes[node]
    if pos < mid {
      // Update left subtree, reuse right subtree
      let new_left = self.update_helper(old_node.left, l, mid, pos, val)
      let new_sum = self.nodes[new_left].sum + self.nodes[old_node.right].sum
      self.alloc_node(new_sum, new_left, old_node.right)
    } else {
      // Update right subtree, reuse left subtree
      let new_right = self.update_helper(old_node.right, mid, r, pos, val)
      let new_sum = self.nodes[old_node.left].sum + self.nodes[new_right].sum
      self.alloc_node(new_sum, old_node.left, new_right)
    }
  }
}

///|
/// Query sum in [ql, qr) for a specific version.
fn PersistentSegmentTree::range_sum(
  self : PersistentSegmentTree,
  version : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  self.query_helper(self.roots[version], 0, self.n, ql, qr)
}

///|
fn PersistentSegmentTree::query_helper(
  self : PersistentSegmentTree,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  if qr <= l || r <= ql {
    return 0L
  }
  if ql <= l && r <= qr {
    return self.nodes[node].sum
  }
  let mid = (l + r) / 2
  let nd = self.nodes[node]
  self.query_helper(nd.left, l, mid, ql, qr) +
  self.query_helper(nd.right, mid, r, ql, qr)
}

///|
test "persistent segment tree" {
  let pst = PersistentSegmentTree::new(5)

  // Version 0: all zeros
  assert_eq(pst.range_sum(0, 0, 5), 0L)

  // Version 1: set position 2 to 10
  let v1 = pst.update(0, 2, 10L)
  assert_eq(pst.range_sum(v1, 0, 5), 10L)
  assert_eq(pst.range_sum(0, 0, 5), 0L) // Version 0 unchanged!

  // Version 2: set position 4 to 20
  let v2 = pst.update(v1, 4, 20L)
  assert_eq(pst.range_sum(v2, 0, 5), 30L)
  assert_eq(pst.range_sum(v1, 0, 5), 10L) // Version 1 unchanged!
}

///|
/// Iterative Segment Tree (Efficient Implementation)
///
/// MATHEMATICAL INSIGHT:
/// For a segment tree of size n, we use array indices [1, 2n).
/// - tree[i] for i >= n represents leaf nodes (arr[i-n])
/// - tree[i] for i < n represents internal nodes (combines tree[2i] and tree[2i+1])
///
/// INVARIANT: tree[i] = tree[2i] op tree[2i+1] for all i in [1, n)
/// where op is the combining operation (sum, min, max, etc.)
priv struct IterativeSegmentTree {
  n : Int
  tree : Array[Int64]
}

///|
/// Build iterative segment tree for range sum queries.
///
/// LOOP INVARIANT (building):
/// After processing position i:
///   - tree[n+j] = arr[j] for j in [0, i]
///   - tree[k] for k < n not yet valid
fn iterative_segment_tree_build(arr : ArrayView[Int]) -> IterativeSegmentTree {
  let n = arr.length()
  let tree = Array::make(2 * n, 0L)

  // Copy leaves
  for i = 0; i < n; i = i + 1 {
    tree[n + i] = arr[i].to_int64()
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|LOOP INVARIANT: tree[n..n+i] contains arr[0..i]
      #|
      #|BASE CASE (i = 0):
      #|  - No elements copied yet, trivially true
      #|
      #|INDUCTIVE STEP (i → i + 1):
      #|  - We set tree[n + i] = arr[i]
      #|  - Now tree[n..n+i+1] contains arr[0..i+1]
      #|
      #|TERMINATION (i = n):
      #|  - All leaves tree[n..2n] contain arr[0..n]
    ),
  }

  // Build internal nodes bottom-up
  for i = n - 1; i >= 1; i = i - 1 {
    tree[i] = tree[2 * i] + tree[2 * i + 1]
  } where {
    invariant: i >= 0 && i < n,
    reasoning: (
      #|LOOP INVARIANT: tree[i+1..n] are correctly computed internal nodes
      #|
      #|BASE CASE (i = n - 1):
      #|  - tree[n..2n] are leaves (correct by construction)
      #|  - tree[n-1] not yet computed
      #|
      #|INDUCTIVE STEP (i → i - 1):
      #|  - tree[2i] and tree[2i+1] are already correct
      #|  - We set tree[i] = tree[2i] + tree[2i+1]
      #|  - By induction, tree[i..n] are now correct
      #|
      #|TERMINATION (i = 0):
      #|  - All internal nodes tree[1..n] are computed
      #|  - tree[1] is the root (sum of entire array)
    ),
  }
  { n, tree }
}

///|
/// Point update: set arr[pos] to val.
///
/// LOOP INVARIANT:
/// At each step, i is on the path from leaf to root.
/// After updating tree[i], we move to parent i/2.
fn IterativeSegmentTree::update(
  self : IterativeSegmentTree,
  pos : Int,
  val : Int64,
) -> Unit {
  let leaf_idx = pos + self.n
  self.tree[leaf_idx] = val

  // Update ancestors
  for i = leaf_idx / 2; i >= 1; i = i / 2 {
    self.tree[i] = self.tree[2 * i] + self.tree[2 * i + 1]
  } where {
    invariant: i >= 0,
    reasoning: (
      #|LOOP INVARIANT: All nodes from leaf to tree[2i] have been updated
      #|
      #|The path from leaf to root has O(log n) nodes.
      #|Each iteration updates one internal node and moves to its parent.
    ),
  }
}

///|
/// Range query: sum of arr[l..r).
///
/// MATHEMATICAL INSIGHT (Iterative Range Query):
/// We maintain two pointers l and r starting at the leaf level.
/// - If l is a right child (odd), include tree[l] and move l right
/// - If r is a left child (even), include tree[r] and move r left
/// - Move both pointers to their parents
///
/// INVARIANT: At each level, we've accounted for all elements in the query range
/// that are in subtrees we won't visit again.
fn IterativeSegmentTree::range_sum(
  self : IterativeSegmentTree,
  ql : Int,
  qr : Int,
) -> Int64 {
  // Process level by level, handling boundary nodes
  for l = ql + self.n, r = qr + self.n, result = 0L; l < r; {
    // Handle left boundary
    let (l2, result2) = if l % 2 == 1 {
      (l + 1, result + self.tree[l])
    } else {
      (l, result)
    }
    // Handle right boundary
    let (r2, result3) = if r % 2 == 1 {
      (r - 1, result2 + self.tree[r - 1])
    } else {
      (r, result2)
    }
    // Move to parent level
    continue l2 / 2, r2 / 2, result3
  } else {
    result
  } where {
    invariant: l >= 0 && r >= 0 && l <= r + 1,
    reasoning: (
      #|LOOP INVARIANT: result contains the sum of all processed leaves in [ql, qr)
      #|
      #|INSIGHT: At each level, l and r bracket the unprocessed query range.
      #|We process "exposed" nodes (those that won't be covered by a parent).
      #|
      #|If l is odd (right child): l's parent covers elements outside [ql, qr),
      #|  so we must include tree[l] separately and move to l+1.
      #|If r is odd (right child): tree[r-1] is a left child inside the range,
      #|  so we include it.
      #|
      #|TERMINATION: l and r converge as they move up the tree.
      #|When l >= r, we've processed the entire range.
    ),
  }
}

///|
test "iterative segment tree" {
  let arr = [1, 2, 3, 4, 5]
  let st = iterative_segment_tree_build(arr[:])
  assert_eq(st.range_sum(0, 5), 15L)
  assert_eq(st.range_sum(0, 3), 6L)
  assert_eq(st.range_sum(2, 5), 12L)
  assert_eq(st.range_sum(1, 4), 9L)

  // Update position 2 to 10
  st.update(2, 10L)
  // Now: [1, 2, 10, 4, 5]
  assert_eq(st.range_sum(0, 5), 22L)
  assert_eq(st.range_sum(0, 3), 13L)
}

///|
/// Segment Tree with Maximum and Count
///
/// A more complex combining operation: track both the maximum value
/// and the count of elements achieving that maximum.
///
/// INVARIANT: For each node covering [l, r):
///   - max_val = max(arr[l..r])
///   - count = |{i in [l,r) : arr[i] = max_val}|
priv struct MaxCountNode {
  max_val : Int64
  count : Int
}

///|
fn max_count_combine(a : MaxCountNode, b : MaxCountNode) -> MaxCountNode {
  if a.max_val > b.max_val {
    a
  } else if b.max_val > a.max_val {
    b
  } else {
    // Equal maxima - combine counts
    { max_val: a.max_val, count: a.count + b.count }
  }
}

///|
priv struct MaxCountSegmentTree {
  n : Int
  tree : Array[MaxCountNode]
}

///|
fn max_count_segment_tree_build(arr : ArrayView[Int]) -> MaxCountSegmentTree {
  let n = arr.length()
  let tree = Array::make(2 * n, { max_val: -9223372036854775808L, count: 0 })

  // Copy leaves
  for i = 0; i < n; i = i + 1 {
    tree[n + i] = { max_val: arr[i].to_int64(), count: 1 }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (build leaves):
      #|tree[n..n+i) contains leaf nodes for arr[0..i); each has count=1 because
      #|it represents exactly one element.
      #|MAINTENANCE:
      #|Store arr[i] at tree[n+i], extending the leaf range by one.
      #|TERMINATION:
      #|At i == n, all leaves for arr[0..n) are initialized.
    ),
  }

  // Build internal nodes
  for i = n - 1; i >= 1; i = i - 1 {
    tree[i] = max_count_combine(tree[2 * i], tree[2 * i + 1])
  } where {
    invariant: i >= 0 && i < n,
    reasoning: (
      #|INVARIANT (build internal):
      #|Nodes tree[i+1..n) have been computed from their children.
      #|MAINTENANCE:
      #|Compute tree[i] from children 2*i and 2*i+1, extending the built range.
      #|TERMINATION:
      #|At i == 0, all internal nodes (including root) are computed.
    ),
  }
  { n, tree }
}

///|
fn MaxCountSegmentTree::range_query(
  self : MaxCountSegmentTree,
  ql : Int,
  qr : Int,
) -> MaxCountNode {
  let init_result : MaxCountNode = { max_val: -9223372036854775808L, count: 0 }
  for l = ql + self.n, r = qr + self.n, result = init_result; l < r; {
    // Handle left boundary
    let (l2, result2) = if l % 2 == 1 {
      (l + 1, max_count_combine(result, self.tree[l]))
    } else {
      (l, result)
    }
    // Handle right boundary
    let (r2, result3) = if r % 2 == 1 {
      (r - 1, max_count_combine(result2, self.tree[r - 1]))
    } else {
      (r, result2)
    }
    continue l2 / 2, r2 / 2, result3
  } else {
    result
  } where {
    invariant: l >= 0 && r >= 0,
    reasoning: (
      #|INVARIANT (range query):
      #|result combines all segments fully processed so far; [l, r) encodes the
      #|remaining range in the implicit tree.
      #|MAINTENANCE:
      #|If l is a right child, merge tree[l] and increment l; if r is a right
      #|boundary, decrement r and merge tree[r-1], then move to parents.
      #|TERMINATION:
      #|When l >= r, result covers the entire query range [ql, qr).
    ),
  }
}

///|
test "max count segment tree" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]
  let st = max_count_segment_tree_build(arr[:])
  let result = st.range_query(0, 8)
  assert_eq(result.max_val, 9L)
  assert_eq(result.count, 1) // Only one 9

  // Query [0, 4) which is [3, 1, 4, 1]
  let result2 = st.range_query(0, 4)
  assert_eq(result2.max_val, 4L)
  assert_eq(result2.count, 1)

  // Test with duplicates
  let arr2 = [3, 5, 5, 2, 5, 1]
  let st2 = max_count_segment_tree_build(arr2[:])
  let result3 = st2.range_query(0, 6)
  assert_eq(result3.max_val, 5L)
  assert_eq(result3.count, 3) // Three 5s
}

///|
/// 2D Segment Tree (Segment Tree of Segment Trees)
///
/// For range sum queries on a 2D matrix.
/// Outer tree handles rows, inner trees handle columns.
///
/// INVARIANT: For outer node covering rows [r1, r2):
///   inner[c] = sum of matrix[r][c] for r in [r1, r2)
priv struct SegmentTree2D {
  rows : Int
  cols : Int
  tree : Array[Array[Int64]] // tree[outer][inner]
}

///|
fn SegmentTree2D::new(matrix : Array[Array[Int]]) -> SegmentTree2D {
  let rows = matrix.length()
  if rows == 0 {
    return { rows: 0, cols: 0, tree: [] }
  }
  let cols = matrix[0].length()
  let tree = Array::make(2 * rows, Array::make(2 * cols, 0L))
  // Initialize each row's tree array
  for i in 0..<(2 * rows) {
    tree[i] = Array::make(2 * cols, 0L)
  }
  let st = { rows, cols, tree }

  // Build leaf rows
  for i = 0; i < rows; i = i + 1 {
    for j = 0; j < cols; j = j + 1 {
      st.tree[rows + i][cols + j] = matrix[i][j].to_int64()
    } where {
      invariant: j >= 0 && j <= cols,
      reasoning: (
        #|INVARIANT (row leaves):
        #|For row i, leaves for columns [0, j) are set from matrix[i].
        #|MAINTENANCE:
        #|Assign leaf at column j with matrix[i][j].
        #|TERMINATION:
        #|At j = cols, all leaves for row i are set.
      ),
    }
    // Build inner tree for this row
    for j = cols - 1; j >= 1; j = j - 1 {
      st.tree[rows + i][j] = st.tree[rows + i][2 * j] +
        st.tree[rows + i][2 * j + 1]
    } where {
      invariant: j >= 0 && j <= cols - 1,
      reasoning: (
        #|INVARIANT (row build):
        #|For row i, inner nodes in (j, cols) have been computed.
        #|MAINTENANCE:
        #|Compute node j from its two children.
        #|TERMINATION:
        #|After j = 0, the row's inner tree is complete.
      ),
    }
  } where {
    invariant: i >= 0 && i <= rows,
    reasoning: (
      #|INVARIANT (leaf rows):
      #|Rows in [0, i) have their leaf values filled and inner trees built.
      #|MAINTENANCE:
      #|Fill leaves and build the inner tree for row i.
      #|TERMINATION:
      #|At i = rows, all leaf rows are built.
    ),
  }

  // Build internal rows
  for i = rows - 1; i >= 1; i = i - 1 {
    for j = 0; j < 2 * cols; j = j + 1 {
      st.tree[i][j] = st.tree[2 * i][j] + st.tree[2 * i + 1][j]
    } where {
      invariant: j >= 0 && j <= 2 * cols,
      reasoning: (
        #|INVARIANT (row combine):
        #|For row i, columns [0, j) have been updated from child rows.
        #|MAINTENANCE:
        #|Combine column j from the two child rows.
        #|TERMINATION:
        #|At j = 2 * cols, row i is fully updated.
      ),
    }
  } where {
    invariant: i >= 0 && i <= rows - 1,
    reasoning: (
      #|INVARIANT (internal rows):
      #|All rows with index > i have been combined from their children.
      #|MAINTENANCE:
      #|Combine row i from its two child rows.
      #|TERMINATION:
      #|At i = 0, all internal rows are built.
    ),
  }
  st
}

///|
/// Point update: set matrix[row][col] to val.
fn SegmentTree2D::update(
  self : SegmentTree2D,
  row : Int,
  col : Int,
  val : Int64,
) -> Unit {
  let c = col + self.cols
  let init_r = row + self.rows

  // Update the leaf cell
  self.tree[init_r][c] = val

  // Update inner tree for this row
  for j = c / 2; j >= 1; j = j / 2 {
    self.tree[init_r][j] = self.tree[init_r][2 * j] +
      self.tree[init_r][2 * j + 1]
  } where {
    invariant: j >= 1 && j <= c / 2,
    reasoning: (
      #|INVARIANT (update row):
      #|Nodes below j on the column path in row init_r reflect the updated leaf.
      #|MAINTENANCE:
      #|Recompute node j from its two children.
      #|TERMINATION:
      #|At j = 0, the row's column aggregates are updated to the root.
    ),
  }

  // Update outer tree
  for r = init_r / 2; r >= 1; r = r / 2 {
    self.tree[r][c] = self.tree[2 * r][c] + self.tree[2 * r + 1][c]
    // Also update inner tree for this combined row
    for j = c / 2; j >= 1; j = j / 2 {
      self.tree[r][j] = self.tree[r][2 * j] + self.tree[r][2 * j + 1]
    } where {
      invariant: j >= 1 && j <= c / 2,
      reasoning: (
        #|INVARIANT (update inner tree):
        #|For row r, nodes below j on the column path are updated.
        #|MAINTENANCE:
        #|Recompute node j from its children.
        #|TERMINATION:
        #|At j = 0, row r's inner tree is consistent.
      ),
    }
  } where {
    invariant: r >= 1 && r <= init_r / 2,
    reasoning: (
      #|INVARIANT (update outer tree):
      #|Rows below r on the path to the root reflect the updated column c.
      #|MAINTENANCE:
      #|Recompute column c at row r and update its inner-tree ancestors.
      #|TERMINATION:
      #|At r = 0, all ancestors reflect the updated cell.
    ),
  }
}

///|
/// Range sum query for matrix[r1..r2)[c1..c2).
fn SegmentTree2D::range_sum(
  self : SegmentTree2D,
  r1 : Int,
  r2 : Int,
  c1 : Int,
  c2 : Int,
) -> Int64 {
  for row_l = r1 + self.rows, row_r = r2 + self.rows, result = 0L; row_l < row_r; {
    // Handle left boundary
    let (row_l2, result2) = if row_l % 2 == 1 {
      (row_l + 1, result + self.col_sum(row_l, c1, c2))
    } else {
      (row_l, result)
    }
    // Handle right boundary
    let (row_r2, result3) = if row_r % 2 == 1 {
      (row_r - 1, result2 + self.col_sum(row_r - 1, c1, c2))
    } else {
      (row_r, result2)
    }
    continue row_l2 / 2, row_r2 / 2, result3
  } else {
    result
  } where {
    invariant: row_l >= 0 && row_r >= 0,
    reasoning: (
      #|INVARIANT (2D row query):
      #|result is the sum of processed row segments; [row_l, row_r) represents
      #|the remaining rows in the implicit tree.
      #|MAINTENANCE:
      #|Add col_sum for row_l or row_r-1 when they are right boundaries, then
      #|move to parent indices.
      #|TERMINATION:
      #|When row_l >= row_r, result is the sum over rows [r1, r2).
    ),
  }
}

///|
fn SegmentTree2D::col_sum(
  self : SegmentTree2D,
  row : Int,
  c1 : Int,
  c2 : Int,
) -> Int64 {
  for l = c1 + self.cols, r = c2 + self.cols, result = 0L; l < r; {
    // Handle left boundary
    let (l2, result2) = if l % 2 == 1 {
      (l + 1, result + self.tree[row][l])
    } else {
      (l, result)
    }
    // Handle right boundary
    let (r2, result3) = if r % 2 == 1 {
      (r - 1, result2 + self.tree[row][r - 1])
    } else {
      (r, result2)
    }
    continue l2 / 2, r2 / 2, result3
  } else {
    result
  } where {
    invariant: l >= 0 && r >= 0,
    reasoning: (
      #|INVARIANT (2D col query):
      #|result sums processed column segments; [l, r) is the remaining range.
      #|MAINTENANCE:
      #|If l is a right child, add tree[row][l] and increment l; if r is a right
      #|boundary, decrement r and add tree[row][r-1], then move up.
      #|TERMINATION:
      #|When l >= r, result is the sum over columns [c1, c2) for this row.
    ),
  }
}

///|
test "2D segment tree" {
  let matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
  let st = SegmentTree2D::new(matrix)

  // Sum of entire matrix
  assert_eq(st.range_sum(0, 3, 0, 3), 45L)

  // Sum of first row
  assert_eq(st.range_sum(0, 1, 0, 3), 6L)

  // Sum of first column
  assert_eq(st.range_sum(0, 3, 0, 1), 12L)

  // Sum of 2x2 submatrix
  assert_eq(st.range_sum(0, 2, 0, 2), 12L) // 1+2+4+5

  // Update and query
  st.update(1, 1, 50L) // Change 5 to 50
  assert_eq(st.range_sum(0, 3, 0, 3), 90L) // 45 + 45
  assert_eq(st.range_sum(1, 2, 1, 2), 50L) // Just the updated cell
}
