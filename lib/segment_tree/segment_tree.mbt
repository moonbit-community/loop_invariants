// ============================================================================
// SEGMENT TREE - Range Queries and Point Updates
// ============================================================================
//
// A Segment Tree supports O(log n) range queries and point updates.
// It's a complete binary tree where each node stores aggregate information
// about a range of the underlying array.
//
// STRUCTURE:
// - Leaves store individual elements
// - Internal nodes store aggregate (sum, min, max, etc.) of their children's ranges
// - Node i has children 2i and 2i+1 (1-indexed)
//
// EXAMPLE for array [1, 2, 3, 4, 5]:
//               [1-5]=15
//              /        \
//         [1-3]=6     [4-5]=9
//         /    \       /    \
//      [1-2]=3 [3]=3 [4]=4 [5]=5
//      /    \
//    [1]=1 [2]=2
//
// OPERATIONS:
// - build(): O(n) - construct tree from array
// - update(i, val): O(log n) - update element at index i
// - query(l, r): O(log n) - query range [l, r]
//
// INVARIANTS:
// 1. tree[node] = aggregate of arr[start..end] for node's range
// 2. tree[node] = combine(tree[2*node], tree[2*node+1]) for internal nodes
// 3. Height is O(log n), so operations are O(log n)
//
// TIME COMPLEXITY: O(log n) per query/update, O(n) build
// SPACE COMPLEXITY: O(n)

///|
/// A segment tree supporting O(log n) range sum queries and O(log n) point
/// updates over an array of `Int64` values.
///
/// The tree is stored in a flat array of size `4 * n` using the standard
/// 1-indexed heap layout: node `k` has left child `2*k` and right child
/// `2*k+1`.  Each node holds the sum of its associated subrange.
///
/// # Fields
///
/// - `n`    : number of elements in the original array.
/// - `tree` : internal flat array; `tree[1]` is the root (sum of all elements).
///
/// # Invariants
///
/// 1. For every internal node `k` covering range `[s, e]`:
///    `tree[k] == tree[2*k] + tree[2*k+1]`
/// 2. For every leaf node `k` covering index `i`:
///    `tree[k] == arr[i]` (after any updates)
pub struct SegmentTree {
  n : Int
  tree : Array[Int64]
}

///|
/// Construct a `SegmentTree` from the given array in O(n) time.
///
/// - Returns an empty tree when `arr` is empty.
/// - The tree allocates `4 * arr.length()` internal nodes.
///
/// # Example
///
/// ```
/// let st = SegmentTree::new([1L, 2L, 3L, 4L, 5L])
/// // st.query(0, 4) == 15L
/// ```
pub fn SegmentTree::new(arr : Array[Int64]) -> SegmentTree {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [] }
  }
  let tree = Array::make(4 * n, 0L)
  build_tree(arr, tree, 1, 0, n - 1)
  { n, tree }
}

///|
/// Recursively fill `tree` for the subrange `[start, end]` rooted at `node`.
///
/// Leaves copy the corresponding array element; internal nodes store the sum
/// of their two children's values.
fn build_tree(
  arr : Array[Int64],
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
) -> Unit {
  if start == end {
    tree[node] = arr[start]
    return
  }
  let mid = (start + end) / 2
  build_tree(arr, tree, 2 * node, start, mid)
  build_tree(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Set the element at 0-indexed position `i` to `val` in O(log n) time.
///
/// The update descends to the leaf for `i`, sets it to `val`, then
/// recomputes the sum at every ancestor on the path back to the root.
///
/// Out-of-bounds indices (`i < 0` or `i >= n`) are silently ignored.
///
/// # Example
///
/// ```
/// let st = SegmentTree::new([1L, 2L, 3L])
/// st.update(1, 10L)
/// // st.query(0, 2) == 14L
/// ```
pub fn SegmentTree::update(self : SegmentTree, i : Int, val : Int64) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  update_helper(self.tree, 1, 0, self.n - 1, i, val)
}

///|
/// Recursively descend to leaf `i` inside `[start, end]`, set its value,
/// and propagate the updated sum upward to `node`.
fn update_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  i : Int,
  val : Int64,
) -> Unit {
  if start == end {
    tree[node] = val
    return
  }
  let mid = (start + end) / 2
  if i <= mid {
    update_helper(tree, 2 * node, start, mid, i, val)
  } else {
    update_helper(tree, 2 * node + 1, mid + 1, end, i, val)
  }
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Return the sum of elements in the closed range `[l, r]` in O(log n) time.
///
/// The query recurses down the tree, accumulating sums from nodes whose
/// range is completely inside `[l, r]`, and skipping nodes whose range is
/// completely outside.
///
/// Returns `0` for any invalid range: `l < 0`, `r >= n`, or `l > r`.
///
/// # Example
///
/// ```
/// let st = SegmentTree::new([1L, 2L, 3L, 4L, 5L])
/// // st.query(1, 3) == 9L   (2 + 3 + 4)
/// // st.query(0, 4) == 15L
/// ```
pub fn SegmentTree::query(self : SegmentTree, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return 0L
  }
  query_helper(self.tree, 1, 0, self.n - 1, l, r)
}

///|
/// Recursively compute the range sum for `[l, r]` intersected with
/// the node's range `[start, end]`.
///
/// Three cases:
/// - No overlap   (`r < start` or `end < l`): return 0.
/// - Full overlap (`l <= start` and `end <= r`): return `tree[node]`.
/// - Partial overlap: recurse into both children and add their results.
fn query_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return 0L // No overlap
  }
  if l <= start && end <= r {
    return tree[node] // Complete overlap
  }
  let mid = (start + end) / 2
  let left = query_helper(tree, 2 * node, start, mid, l, r)
  let right = query_helper(tree, 2 * node + 1, mid + 1, end, l, r)
  left + right
}

///|
/// Return the number of elements in the tree (length of the original array).
fn SegmentTree::length(self : SegmentTree) -> Int {
  self.n
}

// ============================================================================
// SEGMENT TREE FOR RANGE MINIMUM QUERIES (RMQ)
// ============================================================================

///|
/// A segment tree that answers range-minimum queries (RMQ) and supports
/// point updates.  This type is private; it exists to verify the min-query
/// logic and is used only in tests.
///
/// Each node stores the minimum of its subrange.  `ST_INF` acts as the
/// identity element for the min operation.
priv struct SegmentTreeMin {
  n : Int
  tree : Array[Int64]
}

///|
/// Sentinel infinity value used as the identity element for the min
/// operation: `min(x, ST_INF) == x` for all finite `x`.
const ST_INF : Int64 = 9223372036854775807L

///|
/// Construct a `SegmentTreeMin` from `arr` in O(n) time.
///
/// Each internal node stores the minimum of its children; leaves store
/// the corresponding array element.  Empty arrays produce an empty tree.
fn SegmentTreeMin::new(arr : Array[Int64]) -> SegmentTreeMin {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [] }
  }
  let tree = Array::make(4 * n, ST_INF)
  build_min_tree(arr, tree, 1, 0, n - 1)
  { n, tree }
}

///|
/// Recursively fill `tree` with minimum values for the subrange `[start, end]`
/// rooted at `node`.
fn build_min_tree(
  arr : Array[Int64],
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
) -> Unit {
  if start == end {
    tree[node] = arr[start]
    return
  }
  let mid = (start + end) / 2
  build_min_tree(arr, tree, 2 * node, start, mid)
  build_min_tree(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = if tree[2 * node] < tree[2 * node + 1] {
    tree[2 * node]
  } else {
    tree[2 * node + 1]
  }
}

///|
/// Set element at 0-indexed position `i` to `val` and update all ancestor
/// minimums.  Out-of-bounds indices are silently ignored.
fn SegmentTreeMin::update(self : SegmentTreeMin, i : Int, val : Int64) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  update_min_helper(self.tree, 1, 0, self.n - 1, i, val)
}

///|
/// Recursively descend to leaf `i`, set its value to `val`, and propagate
/// the updated minimum back to the root.
fn update_min_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  i : Int,
  val : Int64,
) -> Unit {
  if start == end {
    tree[node] = val
    return
  }
  let mid = (start + end) / 2
  if i <= mid {
    update_min_helper(tree, 2 * node, start, mid, i, val)
  } else {
    update_min_helper(tree, 2 * node + 1, mid + 1, end, i, val)
  }
  tree[node] = if tree[2 * node] < tree[2 * node + 1] {
    tree[2 * node]
  } else {
    tree[2 * node + 1]
  }
}

///|
/// Return the minimum element in the closed range `[l, r]`.
///
/// Returns `ST_INF` for invalid ranges (`l < 0`, `r >= n`, or `l > r`).
fn SegmentTreeMin::query(self : SegmentTreeMin, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return ST_INF
  }
  query_min_helper(self.tree, 1, 0, self.n - 1, l, r)
}

///|
/// Recursively compute the range minimum for `[l, r]` intersected with
/// `[start, end]`.
///
/// Returns `ST_INF` when there is no overlap (identity for min), and
/// `tree[node]` when the node's range is fully contained in `[l, r]`.
fn query_min_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return ST_INF
  }
  if l <= start && end <= r {
    return tree[node]
  }
  let mid = (start + end) / 2
  let left = query_min_helper(tree, 2 * node, start, mid, l, r)
  let right = query_min_helper(tree, 2 * node + 1, mid + 1, end, l, r)
  if left < right {
    left
  } else {
    right
  }
}

// ============================================================================
// ITERATIVE SEGMENT TREE (more efficient, uses 2n space)
// ============================================================================

///|
/// An iterative segment tree that uses only `2n` space and is more
/// cache-friendly than the recursive variant.
///
/// Layout: leaves occupy indices `[n, 2n)` of a flat array; internal nodes
/// occupy `[1, n)`.  The root is at index `1`.  Node `k` has left child
/// `2*k` and right child `2*k+1`; the parent of node `k` is `k/2`.
///
/// This type is private and is used only in tests to cross-check
/// `SegmentTree`.
priv struct IterativeSegTree {
  n : Int
  tree : Array[Int64] // 0-indexed, leaves at indices [n, 2n)
}

///|
/// Construct an `IterativeSegTree` from `arr` in O(n) time.
///
/// Copies leaves into `tree[n..2n)`, then fills internal nodes bottom-up
/// so that `tree[i] = tree[2i] + tree[2i+1]`.
fn IterativeSegTree::new(arr : Array[Int64]) -> IterativeSegTree {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [] }
  }
  let tree = Array::make(2 * n, 0L)

  // Copy leaves
  for i in 0..<n {
    tree[n + i] = arr[i]
  }

  // Build internal nodes from bottom up
  for i in n>..1 {
    tree[i] = tree[2 * i] + tree[2 * i + 1]
  }
  { n, tree }
}

///|
/// Set element at 0-indexed position `i` to `val` in O(log n) time.
///
/// Writes directly to the leaf at `tree[n + i]`, then walks up to the
/// root recomputing `tree[parent] = tree[2*parent] + tree[2*parent+1]`
/// at each step.  Out-of-bounds indices are silently ignored.
fn IterativeSegTree::update(
  self : IterativeSegTree,
  i : Int,
  val : Int64,
) -> Unit {
  if i < 0 || i >= self.n {
    return
  }

  // Update leaf
  let idx = i + self.n
  self.tree[idx] = val

  // Propagate up to root
  let _ = for idx = idx; idx > 1; {
    let parent = idx / 2
    self.tree[parent] = self.tree[2 * parent] + self.tree[2 * parent + 1]
    continue parent
  }
}

///|
/// Return the sum of elements in the closed range `[l, r]` in O(log n) time.
///
/// Uses the standard iterative two-pointer technique: start with
/// `left = n + l` and `right = n + r + 1` (exclusive upper bound).  At each
/// level, if `left` is an odd index (right child), include `tree[left]` and
/// advance `left`; if `right` is odd (right child), include `tree[right-1]`
/// and retreat `right`.  Both pointers then move to their parents.
///
/// Returns `0` for invalid ranges (`l < 0`, `r >= n`, or `l > r`).
fn IterativeSegTree::query(self : IterativeSegTree, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return 0L
  }

  // Traverse from leaves to root, accumulating sum
  for left = l + self.n, right = r + self.n + 1, sum = 0L; left < right; {
    let (new_left, sum1) = if (left & 1) == 1 {
      (left + 1, sum + self.tree[left])
    } else {
      (left, sum)
    }
    let (new_right, sum2) = if (right & 1) == 1 {
      (right - 1, sum1 + self.tree[right - 1])
    } else {
      (right, sum1)
    }
    continue new_left / 2, new_right / 2, sum2
  } nobreak {
    sum
  } where {
    proof_invariant: left >= 0 && right >= 0 && left <= right,
    proof_reasoning: (
      #|INVARIANT (iterative segtree query):
      #|sum accumulates the range sum for nodes processed so far.
      #|left and right converge toward each other as we move up the tree.
      #|MAINTENANCE:
      #|Include boundary nodes if they are right children, then move to parents.
      #|TERMINATION:
      #|left and right halve each iteration, eventually meeting.
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "segment tree basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = SegmentTree::new(arr)
  inspect(st.query(0, 4), content="15")
  inspect(st.query(0, 2), content="6")
  inspect(st.query(2, 4), content="12")
  inspect(st.query(1, 3), content="9")
}

///|
test "segment tree update" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = SegmentTree::new(arr)
  st.update(2, 10L)
  inspect(st.query(0, 4), content="22") // 1+2+10+4+5
  inspect(st.query(2, 2), content="10")
}

///|
test "segment tree single element" {
  let arr : Array[Int64] = [42L]
  let st = SegmentTree::new(arr)
  inspect(st.query(0, 0), content="42")
  st.update(0, 100L)
  inspect(st.query(0, 0), content="100")
}

///|
test "segment tree min basic" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let st = SegmentTreeMin::new(arr)
  inspect(st.query(0, 4), content="1")
  inspect(st.query(0, 2), content="2")
  inspect(st.query(2, 4), content="1")
}

///|
test "segment tree min update" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let st = SegmentTreeMin::new(arr)
  st.update(3, 100L) // Change 1 to 100
  inspect(st.query(0, 4), content="2")
  inspect(st.query(2, 4), content="8")
}

///|
test "iterative segment tree basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = IterativeSegTree::new(arr)
  inspect(st.query(0, 4), content="15")
  inspect(st.query(0, 2), content="6")
  inspect(st.query(2, 4), content="12")
}

///|
test "iterative segment tree update" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = IterativeSegTree::new(arr)
  st.update(2, 10L)
  inspect(st.query(0, 4), content="22")
}

///|
test "iterative segment tree update power of two" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let st = IterativeSegTree::new(arr)
  st.update(3, 100L)
  inspect(st.query(0, 7), content="132")
  inspect(st.query(0, 3), content="106")
  inspect(st.query(4, 7), content="26")
}

///|
test "segment tree empty" {
  let arr : Array[Int64] = []
  let st = SegmentTree::new(arr)
  inspect(st.length(), content="0")
}

///|
test "segment tree boundary" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let st = SegmentTree::new(arr)
  inspect(st.query(-1, 0), content="0") // Invalid
  inspect(st.query(0, 10), content="0") // Invalid
  inspect(st.query(2, 1), content="0") // Invalid
}

///|
test "segment tree large" {
  let n = 100
  let arr : Array[Int64] = [ for i in 0..<n => i.to_int64() ]
  let st = SegmentTree::new(arr)
  // Sum of 0..99 = 99*100/2 = 4950
  inspect(st.query(0, 99), content="4950")
}

///|
test "iterative vs recursive" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let st1 = SegmentTree::new(arr)
  let st2 = IterativeSegTree::new(arr)

  // Both should give same results
  inspect(st1.query(0, 7) == st2.query(0, 7), content="true")
  inspect(st1.query(2, 5) == st2.query(2, 5), content="true")
  inspect(st1.query(0, 0) == st2.query(0, 0), content="true")
}
