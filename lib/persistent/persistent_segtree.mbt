// ============================================================================
// PERSISTENT SEGMENT TREE - Versioned Range Queries
// ============================================================================
//
// A Persistent Segment Tree maintains ALL historical versions of a segment tree,
// allowing queries on any past version while supporting updates that create
// new versions without destroying old ones.
//
// KEY CONCEPTS:
//
// 1. PATH COPYING: When updating a value, we only create new nodes on the
//    path from the updated leaf to the root. Other subtrees are shared.
//
// 2. STRUCTURAL SHARING: Unchanged subtrees are referenced by both old and
//    new versions, giving O(log n) space per update instead of O(n).
//
// 3. VERSION ROOTS: Each version is identified by its root node index.
//    Querying version v means starting from roots[v].
//
// COMPLEXITY:
// - Space: O(n) for initial tree + O(log n) per update
// - Time: O(log n) per query or update
// - Total: O(n + q log n) space for n elements and q updates
//
// APPLICATIONS:
// - Range sum/min/max queries on historical data
// - K-th smallest in range (with merge sort tree)
// - Offline dynamic connectivity
// - Undo/redo functionality

///|
/// Node in persistent segment tree
/// Nodes are never modified - updates create new nodes
priv struct PSTNode {
  left : Int // Left child index (-1 if leaf)
  right : Int // Right child index (-1 if leaf)
  sum : Int64 // Aggregate value (sum in this case)
}

///|
fn PSTNode::leaf(value : Int64) -> PSTNode {
  { left: -1, right: -1, sum: value }
}

///|
fn PSTNode::internal(left : Int, right : Int, sum : Int64) -> PSTNode {
  { left, right, sum }
}

///|
/// Persistent Segment Tree
priv struct PersistentSegTree {
  nodes : Array[PSTNode] // All nodes (never deleted, only added)
  roots : Array[Int] // Root index for each version
  n : Int // Array size
}

///|
/// Build initial persistent segment tree from array
fn PersistentSegTree::build(arr : Array[Int64]) -> PersistentSegTree {
  let n = arr.length()
  if n == 0 {
    return { nodes: [], roots: [], n: 0 }
  }
  let nodes : Array[PSTNode] = []

  // Build tree recursively, returns node index
  fn build_rec(
    arr : Array[Int64],
    nodes : Array[PSTNode],
    lo : Int,
    hi : Int,
  ) -> Int {
    if lo == hi {
      // Leaf node
      let idx = nodes.length()
      nodes.push(PSTNode::leaf(arr[lo]))
      idx
    } else {
      let mid = (lo + hi) / 2
      let left_idx = build_rec(arr, nodes, lo, mid)
      let right_idx = build_rec(arr, nodes, mid + 1, hi)
      let sum = nodes[left_idx].sum + nodes[right_idx].sum
      let idx = nodes.length()
      nodes.push(PSTNode::internal(left_idx, right_idx, sum))
      idx
    }
  }

  let root = build_rec(arr, nodes, 0, n - 1)
  { nodes, roots: [root], n }
}

///|
/// Create empty persistent segment tree of given size
fn PersistentSegTree::new(n : Int) -> PersistentSegTree {
  if n == 0 {
    return { nodes: [], roots: [], n: 0 }
  }
  let arr : Array[Int64] = Array::make(n, 0L)
  PersistentSegTree::build(arr)
}

// ============================================================================
// POINT UPDATE - Creates New Version
// ============================================================================

///|
/// Update position idx to new value in version ver, creating new version
/// Returns index of new version
fn PersistentSegTree::update(
  self : PersistentSegTree,
  ver : Int,
  idx : Int,
  value : Int64,
) -> Int {
  if ver < 0 || ver >= self.roots.length() || idx < 0 || idx >= self.n {
    return ver // Invalid, return same version
  }

  // Create new path from root to updated leaf
  let new_root = self.update_rec(self.roots[ver], 0, self.n - 1, idx, value)
  self.roots.push(new_root)
  self.roots.length() - 1
}

///|
/// Recursive update helper - creates new nodes on path to updated position
fn PersistentSegTree::update_rec(
  self : PersistentSegTree,
  node : Int,
  lo : Int,
  hi : Int,
  idx : Int,
  value : Int64,
) -> Int {
  if lo == hi {
    // Leaf - create new leaf with updated value
    let new_idx = self.nodes.length()
    self.nodes.push(PSTNode::leaf(value))
    return new_idx
  }
  let mid = (lo + hi) / 2
  let old = self.nodes[node]
  if idx <= mid {
    // Update in left subtree - create new node with new left child
    let new_left = self.update_rec(old.left, lo, mid, idx, value)
    let new_sum = self.nodes[new_left].sum + self.nodes[old.right].sum
    let new_idx = self.nodes.length()
    self.nodes.push(PSTNode::internal(new_left, old.right, new_sum))
    new_idx
  } else {
    // Update in right subtree - create new node with new right child
    let new_right = self.update_rec(old.right, mid + 1, hi, idx, value)
    let new_sum = self.nodes[old.left].sum + self.nodes[new_right].sum
    let new_idx = self.nodes.length()
    self.nodes.push(PSTNode::internal(old.left, new_right, new_sum))
    new_idx
  }
}

// ============================================================================
// RANGE QUERY - Query Any Version
// ============================================================================

///|
/// Query sum in range [l, r] for version ver
fn PersistentSegTree::query(
  self : PersistentSegTree,
  ver : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if ver < 0 || ver >= self.roots.length() || l > r || l < 0 || r >= self.n {
    return 0L
  }
  self.query_rec(self.roots[ver], 0, self.n - 1, l, r)
}

///|
/// Recursive query helper
fn PersistentSegTree::query_rec(
  self : PersistentSegTree,
  node : Int,
  lo : Int,
  hi : Int,
  l : Int,
  r : Int,
) -> Int64 {
  // Loop invariant maintained through recursion:
  // - [lo, hi] is the range covered by node
  // - [l, r] is the query range
  // - Query range [l, r] overlaps with [lo, hi]

  if l <= lo && hi <= r {
    // Node range completely inside query range
    return self.nodes[node].sum
  }
  let mid = (lo + hi) / 2
  let curr = self.nodes[node]
  let mut result : Int64 = 0L
  if l <= mid {
    // Query overlaps left child
    result = result + self.query_rec(curr.left, lo, mid, l, r)
  }
  if r > mid {
    // Query overlaps right child
    result = result + self.query_rec(curr.right, mid + 1, hi, l, r)
  }
  result
}

// ============================================================================
// VERSION MANAGEMENT
// ============================================================================

///|
/// Get number of versions
fn PersistentSegTree::version_count(self : PersistentSegTree) -> Int {
  self.roots.length()
}

///|
/// Get value at position idx in version ver
fn PersistentSegTree::get(
  self : PersistentSegTree,
  ver : Int,
  idx : Int,
) -> Int64 {
  self.query(ver, idx, idx)
}

///|
/// Create a copy of version ver (useful for branching history)
fn PersistentSegTree::fork(self : PersistentSegTree, ver : Int) -> Int {
  if ver < 0 || ver >= self.roots.length() {
    return -1
  }
  self.roots.push(self.roots[ver])
  self.roots.length() - 1
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "persistent segment tree basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let pst = PersistentSegTree::build(arr)

  // Initial version (0) sum queries
  inspect(pst.query(0, 0, 4), content="15") // 1+2+3+4+5 = 15
  inspect(pst.query(0, 1, 3), content="9") // 2+3+4 = 9
  inspect(pst.query(0, 2, 2), content="3") // just 3
}

///|
test "persistent segment tree update creates version" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let pst = PersistentSegTree::build(arr)

  // Update position 2: 3 -> 10, creates version 1
  let v1 = pst.update(0, 2, 10L)
  inspect(v1, content="1")

  // Version 0 unchanged
  inspect(pst.query(0, 0, 4), content="15")
  inspect(pst.query(0, 2, 2), content="3")

  // Version 1 has the update
  inspect(pst.query(1, 0, 4), content="22") // 1+2+10+4+5 = 22
  inspect(pst.query(1, 2, 2), content="10")
}

///|
test "persistent segment tree multiple versions" {
  let pst = PersistentSegTree::new(5)

  // v0: [0, 0, 0, 0, 0], sum = 0
  inspect(pst.query(0, 0, 4), content="0")

  // v1: [10, 0, 0, 0, 0]
  let v1 = pst.update(0, 0, 10L)
  inspect(pst.query(v1, 0, 4), content="10")

  // v2: [10, 20, 0, 0, 0] (branch from v1)
  let v2 = pst.update(v1, 1, 20L)
  inspect(pst.query(v2, 0, 4), content="30")

  // v3: [0, 0, 30, 0, 0] (branch from v0, independent of v1/v2)
  let v3 = pst.update(0, 2, 30L)
  inspect(pst.query(v3, 0, 4), content="30")

  // All versions still accessible
  inspect(pst.query(0, 0, 4), content="0")
  inspect(pst.query(v1, 0, 4), content="10")
  inspect(pst.query(v2, 0, 4), content="30")
  inspect(pst.query(v3, 0, 4), content="30")

  // Check individual positions
  inspect(pst.get(v2, 0), content="10")
  inspect(pst.get(v2, 1), content="20")
  inspect(pst.get(v3, 2), content="30")
}

///|
test "persistent segment tree version count" {
  let pst = PersistentSegTree::new(3)
  inspect(pst.version_count(), content="1") // v0
  let _ = pst.update(0, 0, 1L)
  inspect(pst.version_count(), content="2") // v0, v1
  let _ = pst.update(1, 1, 2L)
  inspect(pst.version_count(), content="3") // v0, v1, v2
}

///|
test "persistent segment tree fork" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let pst = PersistentSegTree::build(arr)

  // Fork v0 -> v1 (same state as v0)
  let v1 = pst.fork(0)
  inspect(pst.query(v1, 0, 2), content="6")

  // Update v1
  let v2 = pst.update(v1, 0, 10L)
  inspect(pst.query(v2, 0, 2), content="15") // 10+2+3

  // v0 and v1 still unchanged
  inspect(pst.query(0, 0, 2), content="6")
  inspect(pst.query(v1, 0, 2), content="6")
}

// ============================================================================
// PERSISTENT SEGMENT TREE WITH K-TH SMALLEST
// ============================================================================

///|
/// Persistent segment tree for k-th smallest queries
/// Uses coordinate compression and difference between versions
priv struct KthSmallestTree {
  pst : PersistentSegTree
  sorted_values : Array[Int] // Coordinate compressed values
  n : Int
}

///|
/// Build k-th smallest tree from array
/// Each position i creates version i with values [0..i] inserted
fn KthSmallestTree::build(arr : Array[Int]) -> KthSmallestTree {
  if arr.length() == 0 {
    return { pst: PersistentSegTree::new(0), sorted_values: [], n: 0 }
  }

  // Coordinate compression
  let sorted : Array[Int] = arr.copy()
  sorted.sort()

  // Remove duplicates
  let unique : Array[Int] = []
  for i = 0; i < sorted.length(); i = i + 1 {
    if i == 0 || sorted[i] != sorted[i - 1] {
      unique.push(sorted[i])
    }
  } where {
    invariant: i >= 0 && i <= sorted.length(),
    reasoning: (
      #|INVARIANT (deduplicate):
      #|unique contains distinct values from sorted[0..i) in order.
      #|MAINTENANCE:
      #|Append sorted[i] when it differs from the previous value.
      #|TERMINATION:
      #|At i = sorted.length(), unique is the sorted list of unique values.
    ),
  }
  let m = unique.length()

  // Create initial empty tree (version -1, stored as version 0)
  let pst = PersistentSegTree::new(m)

  // Build versions - version i has count of values in arr[0..i-1]
  // We need version 0 to be empty, then version i = prefix [0..i-1]
  for i = 0; i < arr.length(); i = i + 1 {
    // Find rank of arr[i] in unique
    let rank = binary_search(unique, arr[i])

    // Get previous version (i for 0-indexed prefix)
    let prev_ver = i

    // Add 1 to position rank
    let old_val = pst.get(prev_ver, rank)
    let _ = pst.update(prev_ver, rank, old_val + 1L)

  } where {
    invariant: i >= 0 && i <= arr.length(),
    reasoning: (
      #|INVARIANT (build versions):
      #|Versions 0..i represent prefix counts for arr[0..i-1].
      #|MAINTENANCE:
      #|Update version i at the rank of arr[i], creating version i+1.
      #|TERMINATION:
      #|At i = n, there are n+1 versions representing all prefixes.
    ),
  }
  { pst, sorted_values: unique, n: arr.length() }
}

///|
/// Binary search for value in sorted array
fn binary_search(arr : Array[Int], value : Int) -> Int {
  for lo = 0, hi = arr.length() - 1; lo <= hi; {
    let mid = (lo + hi) / 2
    if arr[mid] == value {
      break mid
    } else if arr[mid] < value {
      continue mid + 1, hi
    } else {
      continue lo, mid - 1
    }
  } else {
    -1
  } where {
    invariant: lo >= 0 && hi < arr.length(),
    reasoning: (
      #|BINARY SEARCH INVARIANT:
      #|
      #|1. If value exists, it's in arr[lo..hi]
      #|2. Each iteration halves the search space
      #|3. Loop terminates when lo > hi (not found) or we find value
    ),
  }
}

///|
/// Find k-th smallest in range [l, r] (1-indexed k)
fn KthSmallestTree::kth_smallest(
  self : KthSmallestTree,
  l : Int,
  r : Int,
  k : Int,
) -> Int? {
  if l < 0 || r >= self.n || l > r || k <= 0 {
    return None
  }

  // Use versions l and r+1
  // Count in [l, r] = count in [0, r] - count in [0, l-1]
  let left_ver = l // version l represents prefix [0, l-1]
  let right_ver = r + 1 // version r+1 represents prefix [0, r]
  self.kth_rec(
    self.pst.roots[left_ver],
    self.pst.roots[right_ver],
    0,
    self.sorted_values.length() - 1,
    k,
  )
}

///|
/// Recursive k-th smallest using two-version difference
fn KthSmallestTree::kth_rec(
  self : KthSmallestTree,
  left_node : Int,
  right_node : Int,
  lo : Int,
  hi : Int,
  k : Int,
) -> Int? {
  if lo == hi {
    return Some(self.sorted_values[lo])
  }
  let mid = (lo + hi) / 2
  let left_data = self.pst.nodes[left_node]
  let right_data = self.pst.nodes[right_node]

  // Count in left subtree for range [l, r]
  let left_count = self.pst.nodes[right_data.left].sum -
    self.pst.nodes[left_data.left].sum
  if k <= left_count.to_int() {
    // k-th element is in left subtree
    self.kth_rec(left_data.left, right_data.left, lo, mid, k)
  } else {
    // k-th element is in right subtree
    self.kth_rec(
      left_data.right,
      right_data.right,
      mid + 1,
      hi,
      k - left_count.to_int(),
    )
  }
}

///|
test "kth smallest basic" {
  let arr = [5, 1, 3, 2, 4]
  let kst = KthSmallestTree::build(arr)

  // Full range [0, 4]: sorted is [1, 2, 3, 4, 5]
  inspect(kst.kth_smallest(0, 4, 1), content="Some(1)") // 1st smallest
  inspect(kst.kth_smallest(0, 4, 3), content="Some(3)") // 3rd smallest
  inspect(kst.kth_smallest(0, 4, 5), content="Some(5)") // 5th smallest
}

///|
test "kth smallest range queries" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]
  let kst = KthSmallestTree::build(arr)

  // Range [0, 2]: values are [3, 1, 4], sorted: [1, 3, 4]
  inspect(kst.kth_smallest(0, 2, 1), content="Some(1)")
  inspect(kst.kth_smallest(0, 2, 2), content="Some(3)")
  inspect(kst.kth_smallest(0, 2, 3), content="Some(4)")

  // Range [2, 5]: values are [4, 1, 5, 9], sorted: [1, 4, 5, 9]
  inspect(kst.kth_smallest(2, 5, 1), content="Some(1)")
  inspect(kst.kth_smallest(2, 5, 2), content="Some(4)")
}

// ============================================================================
// PERSISTENT ARRAY (Using Persistent Segment Tree)
// ============================================================================

///|
/// Fully persistent array supporting:
/// - get(version, index)
/// - set(version, index, value) -> new_version
priv struct PersistentArray {
  pst : PersistentSegTree
}

///|
fn PersistentArray::new(n : Int, default_value : Int64) -> PersistentArray {
  let arr : Array[Int64] = Array::make(n, default_value)
  { pst: PersistentSegTree::build(arr) }
}

///|
fn PersistentArray::from_array(arr : Array[Int64]) -> PersistentArray {
  { pst: PersistentSegTree::build(arr) }
}

///|
fn PersistentArray::get(
  self : PersistentArray,
  version : Int,
  index : Int,
) -> Int64 {
  self.pst.get(version, index)
}

///|
fn PersistentArray::set(
  self : PersistentArray,
  version : Int,
  index : Int,
  value : Int64,
) -> Int {
  self.pst.update(version, index, value)
}

///|
fn PersistentArray::version_count(self : PersistentArray) -> Int {
  self.pst.version_count()
}

///|
test "persistent array" {
  let empty = PersistentArray::new(2, 7L)
  inspect(empty.get(0, 1), content="7")
  let parr = PersistentArray::from_array([10L, 20L, 30L])

  // v0: [10, 20, 30]
  inspect(parr.get(0, 0), content="10")
  inspect(parr.get(0, 1), content="20")
  inspect(parr.get(0, 2), content="30")

  // v1: [100, 20, 30]
  let v1 = parr.set(0, 0, 100L)
  inspect(parr.get(v1, 0), content="100")

  // v2: [100, 200, 30] (from v1)
  let v2 = parr.set(v1, 1, 200L)
  inspect(parr.get(v2, 1), content="200")

  // v3: [10, 20, 300] (from v0, independent branch)
  let v3 = parr.set(0, 2, 300L)
  inspect(parr.get(v3, 2), content="300")
  inspect(parr.get(v3, 0), content="10") // unchanged from v0

  // All versions accessible
  inspect(parr.version_count(), content="4")
}
