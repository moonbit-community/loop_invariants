// ============================================================================
// PERSISTENT SEGMENT TREE - Version Control for Range Queries
// ============================================================================
//
// A Persistent Segment Tree maintains all historical versions of a segment tree,
// allowing queries on any past version while supporting efficient updates.
//
// KEY INSIGHT: Instead of modifying nodes in-place, we create new nodes along
// the update path while sharing unchanged subtrees with previous versions.
// This is called "path copying" - only O(log n) new nodes per update.
//
// STRUCTURE:
// - Each node stores sum/value for its range
// - Internal nodes have left and right children (indices into node array)
// - Each version has its own root pointer
// - Unmodified subtrees are shared between versions
//
// EXAMPLE for array [1, 2, 3, 4]:
// Version 0 (initial):
//       [10]           <- root0 (sum 1+2+3+4)
//      /    \
//    [3]    [7]        <- internal nodes
//   /  \   /  \
//  1    2 3    4       <- leaves
//
// After update(index=1, value=5) -> Version 1:
//       [13]           <- root1 (new node)
//      /    \
//    [6]    [7]        <- left child new, right shared with v0
//   /  \
//  1    5              <- new leaf
//
// INVARIANTS:
// 1. Each version is immutable - nodes are never modified after creation
// 2. Shared subtrees: nodes not on update path are reused
// 3. Space: O(n) initial + O(log n) per update
// 4. Time: O(log n) for both update and query
//
// APPLICATIONS:
// - Range sum queries on any historical version
// - Count elements in range [l, r] with value in [lo, hi]
// - K-th smallest element in range queries
// - Undo/redo functionality

///|
/// A node in the persistent segment tree
/// Nodes are immutable once created
priv struct PNode {
  sum : Int64 // Sum of range
  left : Int // Index of left child (-1 for none)
  right : Int // Index of right child (-1 for none)
}

///|
/// Persistent Segment Tree with version control
priv struct PersistentSegTree {
  nodes : Array[PNode] // All nodes ever created
  roots : Array[Int] // Root index for each version
  n : Int // Size of array
}

///|
/// Create new node and return its index
fn push_node(nodes : Array[PNode], sum : Int64, left : Int, right : Int) -> Int {
  let idx = nodes.length()
  nodes.push({ sum, left, right })
  idx
}

///|
fn PersistentSegTree::new(arr : Array[Int64]) -> PersistentSegTree {
  let n = arr.length()
  if n == 0 {
    return { nodes: [], roots: [], n: 0 }
  }

  let nodes : Array[PNode] = []
  let roots : Array[Int] = []

  // Build initial tree recursively
  let root = build_tree(nodes, arr, 0, n - 1)
  roots.push(root)

  { nodes, roots, n }
}

///|
/// Build subtree for range [lo, hi]
/// Returns index of created node
/// REASONING: Recursively build left and right subtrees, then combine.
fn build_tree(
  nodes : Array[PNode],
  arr : Array[Int64],
  lo : Int,
  hi : Int
) -> Int {
  if lo == hi {
    // Leaf node
    return push_node(nodes, arr[lo], -1, -1)
  }

  // INVARIANT: lo < hi, so mid < hi and lo <= mid
  let mid = (lo + hi) / 2
  let left_idx = build_tree(nodes, arr, lo, mid)
  let right_idx = build_tree(nodes, arr, mid + 1, hi)

  let sum = nodes[left_idx].sum + nodes[right_idx].sum
  push_node(nodes, sum, left_idx, right_idx)
}

///|
/// Update value at position, creating a new version
/// Returns the new version number
/// REASONING: We create new nodes only along the path from root to the
/// updated leaf, sharing unchanged subtrees with the previous version.
fn PersistentSegTree::update(
  self : PersistentSegTree,
  version : Int,
  pos : Int,
  val : Int64
) -> Int {
  if version < 0 ||
    version >= self.roots.length() ||
    pos < 0 ||
    pos >= self.n {
    return version
  }

  let new_root = update_tree(
    self.nodes,
    self.roots[version],
    0,
    self.n - 1,
    pos,
    val,
  )
  self.roots.push(new_root)
  self.roots.length() - 1
}

///|
/// Create updated subtree, reusing unchanged nodes
/// Returns index of new root for this subtree
/// INVARIANT: Only creates new nodes along path to pos
fn update_tree(
  nodes : Array[PNode],
  node_idx : Int,
  lo : Int,
  hi : Int,
  pos : Int,
  val : Int64
) -> Int {
  if lo == hi {
    // Create new leaf with updated value
    return push_node(nodes, val, -1, -1)
  }

  let mid = (lo + hi) / 2
  let old_node = nodes[node_idx]

  // INVARIANT: Only recurse into the subtree containing pos
  // The other subtree is shared with the previous version
  if pos <= mid {
    // Update left subtree, share right
    let new_left = update_tree(nodes, old_node.left, lo, mid, pos, val)
    let sum = nodes[new_left].sum + nodes[old_node.right].sum
    push_node(nodes, sum, new_left, old_node.right)
  } else {
    // Update right subtree, share left
    let new_right = update_tree(nodes, old_node.right, mid + 1, hi, pos, val)
    let sum = nodes[old_node.left].sum + nodes[new_right].sum
    push_node(nodes, sum, old_node.left, new_right)
  }
}

///|
/// Query sum in range [l, r] for a specific version
fn PersistentSegTree::query(
  self : PersistentSegTree,
  version : Int,
  l : Int,
  r : Int
) -> Int64 {
  if version < 0 ||
    version >= self.roots.length() ||
    l > r ||
    l >= self.n ||
    r < 0 {
    return 0L
  }

  let l_clamped = if l < 0 { 0 } else { l }
  let r_clamped = if r >= self.n { self.n - 1 } else { r }

  query_tree(self.nodes, self.roots[version], 0, self.n - 1, l_clamped, r_clamped)
}

///|
/// Query sum in range [l, r] from subtree
/// INVARIANT: result is sum of elements in intersection of [lo, hi] and [l, r]
fn query_tree(
  nodes : Array[PNode],
  node_idx : Int,
  lo : Int,
  hi : Int,
  l : Int,
  r : Int
) -> Int64 {
  if l > hi || r < lo {
    // No intersection
    return 0L
  }

  if l <= lo && hi <= r {
    // Fully contained
    return nodes[node_idx].sum
  }

  // Partial overlap - query both children
  let mid = (lo + hi) / 2
  let curr = nodes[node_idx]
  let left_sum = query_tree(nodes, curr.left, lo, mid, l, r)
  let right_sum = query_tree(nodes, curr.right, mid + 1, hi, l, r)
  left_sum + right_sum
}

///|
/// Get number of versions
fn PersistentSegTree::version_count(self : PersistentSegTree) -> Int {
  self.roots.length()
}

///|
/// Get total number of nodes (space usage)
fn PersistentSegTree::node_count(self : PersistentSegTree) -> Int {
  self.nodes.length()
}

///|
/// Get value at single position in a version
fn PersistentSegTree::get(
  self : PersistentSegTree,
  version : Int,
  pos : Int
) -> Int64 {
  self.query(version, pos, pos)
}

///|
/// Add delta to position, creating new version
fn PersistentSegTree::add(
  self : PersistentSegTree,
  version : Int,
  pos : Int,
  delta : Int64
) -> Int {
  let old_val = self.get(version, pos)
  self.update(version, pos, old_val + delta)
}

// ============================================================================
// K-TH SMALLEST IN RANGE using Persistent Segment Tree
// ============================================================================
//
// This variant uses coordinate compression to answer:
// "What is the k-th smallest value in range [l, r]?"
//
// IDEA: Build a persistent segment tree where each version represents
// the prefix [0, i] of the array. The segment tree stores frequencies
// of values (after coordinate compression).
//
// To find k-th smallest in [l, r]:
// We binary search on the segment trees of versions l-1 and r.
// count_in_range = tree[r].count - tree[l-1].count

///|
/// K-th smallest query structure
priv struct KthSmallest {
  nodes : Array[PNode]
  roots : Array[Int] // roots[i] = tree after inserting elements [0, i-1]
  sorted_vals : Array[Int64] // Sorted unique values
}

///|
fn KthSmallest::new(arr : Array[Int64]) -> KthSmallest {
  let n = arr.length()
  if n == 0 {
    return { nodes: [], roots: [], sorted_vals: [] }
  }

  // Coordinate compression
  let sorted_vals : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    sorted_vals.push(arr[i])
  }
  sorted_vals.sort_by(fn(a, b) {
    if a < b {
      -1
    } else if a > b {
      1
    } else {
      0
    }
  })

  // Remove duplicates and build value -> index map
  let unique_vals : Array[Int64] = []
  let val_to_idx : Map[Int64, Int] = {}
  for i = 0; i < sorted_vals.length(); i = i + 1 {
    if i == 0 || sorted_vals[i] != sorted_vals[i - 1] {
      val_to_idx[sorted_vals[i]] = unique_vals.length()
      unique_vals.push(sorted_vals[i])
    }
  }

  let m = unique_vals.length()
  let nodes : Array[PNode] = []
  let roots : Array[Int] = []

  // Build empty tree (version 0, represents prefix of length 0)
  let empty_root = build_empty_tree(nodes, 0, m - 1)
  roots.push(empty_root)

  // Insert elements one by one
  // INVARIANT: After processing arr[i], roots[i+1] contains frequencies for arr[0..i]
  for i = 0; i < n; i = i + 1 {
    let idx = match val_to_idx.get(arr[i]) {
      Some(v) => v
      None => 0
    }
    let prev_root = roots[roots.length() - 1]
    let new_root = kth_insert_tree(nodes, prev_root, 0, m - 1, idx)
    roots.push(new_root)
  }

  { nodes, roots, sorted_vals: unique_vals }
}

///|
/// Build empty segment tree (all counts = 0)
fn build_empty_tree(nodes : Array[PNode], lo : Int, hi : Int) -> Int {
  if lo == hi {
    return push_node(nodes, 0L, -1, -1)
  }

  let mid = (lo + hi) / 2
  let left = build_empty_tree(nodes, lo, mid)
  let right = build_empty_tree(nodes, mid + 1, hi)
  push_node(nodes, 0L, left, right)
}

///|
/// Insert value at compressed index, incrementing count
fn kth_insert_tree(
  nodes : Array[PNode],
  node_idx : Int,
  lo : Int,
  hi : Int,
  pos : Int
) -> Int {
  let old = nodes[node_idx]

  if lo == hi {
    return push_node(nodes, old.sum + 1L, -1, -1)
  }

  let mid = (lo + hi) / 2
  if pos <= mid {
    let new_left = kth_insert_tree(nodes, old.left, lo, mid, pos)
    push_node(nodes, old.sum + 1L, new_left, old.right)
  } else {
    let new_right = kth_insert_tree(nodes, old.right, mid + 1, hi, pos)
    push_node(nodes, old.sum + 1L, old.left, new_right)
  }
}

///|
/// Find k-th smallest in range [l, r] (1-indexed k)
/// Returns None if k is out of range
fn KthSmallest::query(
  self : KthSmallest,
  l : Int,
  r : Int,
  k : Int
) -> Int64? {
  if l < 0 ||
    r >= self.roots.length() - 1 ||
    l > r ||
    k <= 0 ||
    self.sorted_vals.length() == 0 {
    return None
  }

  let range_size = r - l + 1
  if k > range_size {
    return None
  }

  let m = self.sorted_vals.length()
  let left_root = self.roots[l] // Tree for prefix [0, l-1]
  let right_root = self.roots[r + 1] // Tree for prefix [0, r]

  let idx = kth_query_tree(self.nodes, left_root, right_root, 0, m - 1, k)
  Some(self.sorted_vals[idx])
}

///|
/// Binary search for k-th smallest using two trees
/// INVARIANT: We search for k-th element in the difference (right - left)
/// REASONING: By comparing counts in left subtrees, we determine which
/// subtree contains the k-th element, recursively narrowing down.
fn kth_query_tree(
  nodes : Array[PNode],
  left_root : Int,
  right_root : Int,
  lo : Int,
  hi : Int,
  k : Int
) -> Int {
  if lo == hi {
    return lo
  }

  let mid = (lo + hi) / 2
  let left_node_l = nodes[nodes[left_root].left]
  let left_node_r = nodes[nodes[right_root].left]

  // Count in left subtree for range [l, r]
  let left_count = (left_node_r.sum - left_node_l.sum).to_int()

  // INVARIANT: k-th element is in left subtree if left_count >= k
  if left_count >= k {
    kth_query_tree(
      nodes,
      nodes[left_root].left,
      nodes[right_root].left,
      lo,
      mid,
      k,
    )
  } else {
    // k-th element is in right subtree; adjust k
    kth_query_tree(
      nodes,
      nodes[left_root].right,
      nodes[right_root].right,
      mid + 1,
      hi,
      k - left_count,
    )
  }
}

///|
fn KthSmallest::size(self : KthSmallest) -> Int {
  self.roots.length() - 1 // Subtract 1 for empty tree
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "persistent segtree basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let tree = PersistentSegTree::new(arr)

  // Version 0: original array
  inspect(tree.query(0, 0, 4), content="15") // 1+2+3+4+5
  inspect(tree.query(0, 1, 3), content="9") // 2+3+4
}

///|
test "persistent segtree update" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let tree = PersistentSegTree::new(arr)

  // Update position 2 to 10
  let v1 = tree.update(0, 2, 10L)
  inspect(v1, content="1")

  // Version 0 unchanged
  inspect(tree.query(0, 0, 4), content="15")

  // Version 1 has update
  inspect(tree.query(1, 0, 4), content="22") // 1+2+10+4+5
  inspect(tree.query(1, 2, 2), content="10")
}

///|
test "persistent segtree multiple versions" {
  let arr : Array[Int64] = [1L, 1L, 1L, 1L]
  let tree = PersistentSegTree::new(arr)

  // Create chain of updates
  let v1 = tree.update(0, 0, 2L)
  let v2 = tree.update(v1, 1, 3L)
  let v3 = tree.update(v2, 2, 4L)
  let _ = tree.update(v3, 3, 5L)

  // All versions accessible
  inspect(tree.query(0, 0, 3), content="4") // [1,1,1,1]
  inspect(tree.query(1, 0, 3), content="5") // [2,1,1,1]
  inspect(tree.query(2, 0, 3), content="7") // [2,3,1,1]
  inspect(tree.query(3, 0, 3), content="10") // [2,3,4,1]
  inspect(tree.query(4, 0, 3), content="14") // [2,3,4,5]
}

///|
test "persistent segtree branching versions" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let tree = PersistentSegTree::new(arr)

  // Branch from version 0
  let _ = tree.update(0, 0, 10L) // [10, 2, 3]
  let _ = tree.update(0, 1, 20L) // [1, 20, 3] - branch from v0

  inspect(tree.query(1, 0, 2), content="15") // 10+2+3
  inspect(tree.query(2, 0, 2), content="24") // 1+20+3
}

///|
test "persistent segtree space efficiency" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let tree = PersistentSegTree::new(arr)

  let initial_nodes = tree.node_count()

  // Each update should create O(log n) new nodes
  let _ = tree.update(0, 0, 100L)
  let after_one = tree.node_count()

  // For n=8, log n = 3, so ~4 new nodes (including leaf)
  let new_nodes = after_one - initial_nodes
  inspect(new_nodes <= 10, content="true") // Should be small
}

///|
test "persistent segtree get and add" {
  let arr : Array[Int64] = [5L, 10L, 15L]
  let tree = PersistentSegTree::new(arr)

  inspect(tree.get(0, 1), content="10")

  let v1 = tree.add(0, 1, 5L) // Add 5 to position 1
  inspect(tree.get(v1, 1), content="15")
  inspect(tree.get(0, 1), content="10") // Original unchanged
}

///|
test "persistent segtree empty" {
  let arr : Array[Int64] = []
  let tree = PersistentSegTree::new(arr)

  inspect(tree.version_count(), content="0")
  inspect(tree.query(0, 0, 0), content="0")
}

///|
test "persistent segtree single element" {
  let arr : Array[Int64] = [42L]
  let tree = PersistentSegTree::new(arr)

  inspect(tree.query(0, 0, 0), content="42")

  let v1 = tree.update(0, 0, 100L)
  inspect(tree.query(v1, 0, 0), content="100")
  inspect(tree.query(0, 0, 0), content="42")
}

///|
test "kth smallest basic" {
  let arr : Array[Int64] = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let kth = KthSmallest::new(arr)

  // Query [0, 7] (whole array): sorted = [1,1,2,3,4,5,6,9]
  inspect(kth.query(0, 7, 1), content="Some(1)")
  inspect(kth.query(0, 7, 2), content="Some(1)")
  inspect(kth.query(0, 7, 3), content="Some(2)")
  inspect(kth.query(0, 7, 8), content="Some(9)")
}

///|
test "kth smallest range" {
  let arr : Array[Int64] = [5L, 1L, 3L, 2L, 4L]
  let kth = KthSmallest::new(arr)

  // Range [1, 3]: values [1, 3, 2] -> sorted [1, 2, 3]
  inspect(kth.query(1, 3, 1), content="Some(1)")
  inspect(kth.query(1, 3, 2), content="Some(2)")
  inspect(kth.query(1, 3, 3), content="Some(3)")

  // Range [0, 2]: values [5, 1, 3] -> sorted [1, 3, 5]
  inspect(kth.query(0, 2, 1), content="Some(1)")
  inspect(kth.query(0, 2, 2), content="Some(3)")
  inspect(kth.query(0, 2, 3), content="Some(5)")
}

///|
test "kth smallest out of range" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let kth = KthSmallest::new(arr)

  inspect(kth.query(0, 2, 4), content="None") // k > range size
  inspect(kth.query(0, 2, 0), content="None") // k <= 0
}

///|
test "kth smallest single element" {
  let arr : Array[Int64] = [42L]
  let kth = KthSmallest::new(arr)

  inspect(kth.query(0, 0, 1), content="Some(42)")
  inspect(kth.query(0, 0, 2), content="None")
}

///|
test "kth smallest duplicates" {
  let arr : Array[Int64] = [5L, 5L, 5L, 5L]
  let kth = KthSmallest::new(arr)

  // All elements are 5
  inspect(kth.query(0, 3, 1), content="Some(5)")
  inspect(kth.query(0, 3, 4), content="Some(5)")
}

///|
test "kth smallest size" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let kth = KthSmallest::new(arr)

  inspect(kth.size(), content="5")
}
