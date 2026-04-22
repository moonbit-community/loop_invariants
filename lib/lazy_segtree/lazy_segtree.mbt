// ============================================================================
// LAZY SEGMENT TREE - Range Updates and Queries in O(log n)
// ============================================================================
//
// Lazy Segment Tree extends regular segment tree to handle range updates
// efficiently by deferring work using "lazy propagation".
//
// KEY INSIGHT: Instead of updating all affected leaves immediately,
// store pending updates at internal nodes and propagate them only when needed.
//
// LAZY PROPAGATION:
// 1. When updating a range [l, r], if node's range is fully contained,
//    mark node as lazy and return (don't recurse to children)
// 2. Before accessing children, "push down" any pending lazy values
// 3. This defers work until absolutely necessary
//
// OPERATIONS:
// - range_update(l, r, val): Add val to all elements in [l, r]
// - range_query(l, r): Query sum/min/max of [l, r]
// - point_query(i): Query single element (special case of range query)
//
// EXAMPLE for range add with sum queries:
// arr = [1, 2, 3, 4, 5]
//
// Tree structure (showing sums):
//          [1,5]=15
//         /        \
//     [1,3]=6     [4,5]=9
//     /    \       /    \
//  [1,2]=3 [3]=3 [4]=4 [5]=5
//  /    \
// [1]=1 [2]=2
//
// range_update(2, 4, 10):
// - Mark nodes with lazy value instead of updating all leaves
// - Sum updated where needed, lazy propagated on demand
//
// INVARIANTS:
// 1. A node's value + effect of lazy on its range = true value
// 2. Before accessing children, parent's lazy must be pushed down
// 3. After any update, ancestors' sums are correctly updated
//
// TIME COMPLEXITY:
// - Build: O(n)
// - Range update: O(log n)
// - Range query: O(log n)
//
// SPACE COMPLEXITY: O(n)

// ============================================================================
// LAZY SEGMENT TREE FOR RANGE ADD + RANGE SUM
// ============================================================================

///|
/// A lazy segment tree that supports range addition and range sum queries in
/// O(log n) per operation.
///
/// ## Fields
///
/// - `n` -- number of elements in the original array.
/// - `tree` -- 1-indexed flat array of size 4n; `tree[k]` holds the sum of the
///   sub-range covered by node `k`, already incorporating any pending add that
///   was applied to node `k` itself.
/// - `pending` -- 1-indexed flat array of size 4n; `pending[k]` is the addend
///   that must still be propagated to the two children of node `k` before
///   those children are read.  For leaf nodes this field is never read.
///
/// ## Invariant
///
/// `tree[k]` is always the correct aggregate (sum) for node `k`'s range.
/// `pending[k]` represents work that is *owed to the children* but has not yet
/// been pushed down.  Together they satisfy:
///
/// ```
/// true_sum(left_child)  = tree[2k]   + pending[k] * left_size
/// true_sum(right_child) = tree[2k+1] + pending[k] * right_size
/// ```
///
/// This invariant is maintained by `push_down` before any descent and by
/// recomputing `tree[k]` from its children on the way back up.
pub struct LazySegTreeSum {
  n : Int
  tree : Array[Int64] // Sum of range
  pending : Array[Int64] // Pending add value
}

///|
/// Build a lazy segment tree for range-add / range-sum queries from `arr`.
///
/// Runs an O(n) bottom-up build that fills `tree` so that each node holds the
/// sum of its sub-range.  All `pending` slots are initialised to zero (no
/// deferred updates).
///
/// Returns an empty tree (with `n = 0`) when `arr` is empty; all subsequent
/// operations on an empty tree are no-ops or return `None`.
pub fn LazySegTreeSum::new(arr : Array[Int64]) -> LazySegTreeSum {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [], pending: [] }
  }
  let tree = Array::make(4 * n, 0L)
  let pending = Array::make(4 * n, 0L)
  build(arr, tree, 1, 0, n - 1)
  { n, tree, pending }
}

///|
/// Recursively fills `tree[node]` with the sum of `arr[start..end]` (inclusive).
/// Called once during construction; not exposed publicly.
fn build(
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
  build(arr, tree, 2 * node, start, mid)
  build(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Propagate the pending addend at `node` down to its two children, then clear
/// `pending[node]`.
///
/// Must be called before descending into the children of any non-leaf node
/// during a range update or query that does not fully cover the node's range.
///
/// ## What it does
///
/// Given node `k` covering `[start..end]` with `mid = (start+end)/2`:
///
/// ```
/// tree[2k]     += pending[k] * (mid - start + 1)
/// tree[2k+1]   += pending[k] * (end - mid)
/// pending[2k]  += pending[k]
/// pending[2k+1]+= pending[k]
/// pending[k]    = 0
/// ```
///
/// After this call the children's `tree` values are correct for their own
/// ranges, and `pending[node]` is zero (no pending work at this node).
///
/// ## Invariant preserved
///
/// Before: `tree[k]` is correct for `[start..end]`; children may be stale.
/// After:  `tree[k]` is still correct; children are now also correct for their
///         own ranges (modulo *their* pending values, which are untouched).
fn push_down(
  tree : Array[Int64],
  pending : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
) -> Unit {
  if pending[node] != 0L {
    let mid = (start + end) / 2
    let left_len = (mid - start + 1).to_int64()
    let right_len = (end - mid).to_int64()

    // Update children's values
    tree[2 * node] = tree[2 * node] + pending[node] * left_len
    tree[2 * node + 1] = tree[2 * node + 1] + pending[node] * right_len

    // Propagate lazy to children
    pending[2 * node] = pending[2 * node] + pending[node]
    pending[2 * node + 1] = pending[2 * node + 1] + pending[node]

    // Clear current lazy
    pending[node] = 0L
  }
}

///|
/// Add `val` to every element in the closed range `[l, r]`.
///
/// Uses lazy propagation: nodes whose range is fully contained in `[l, r]`
/// receive the update immediately (both their `tree` value and their `pending`
/// slot), while nodes with only partial overlap push their own pending value
/// down before recursing.  Ancestor sums are recomputed on the way back up.
///
/// - Time: O(log n)
/// - `l` and `r` are 0-indexed and inclusive.
/// - Out-of-bounds or inverted ranges (`l < 0`, `r >= n`, `l > r`) are silently
///   ignored.
pub fn LazySegTreeSum::range_add(
  self : LazySegTreeSum,
  l : Int,
  r : Int,
  val : Int64,
) -> Unit {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return
  }
  range_add_helper(self.tree, self.pending, 1, 0, self.n - 1, l, r, val)
}

///|
/// Recursive worker for `range_add`.  Handles the three cases:
/// - No overlap with `[l..r]`: return immediately.
/// - Full containment in `[l..r]`: apply update and store in `pending`.
/// - Partial overlap: push-down, recurse into both halves, recompute parent.
fn range_add_helper(
  tree : Array[Int64],
  pending : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
  val : Int64,
) -> Unit {
  if r < start || end < l {
    // No overlap
    return
  }
  if l <= start && end <= r {
    // Complete overlap - apply lazy
    let len = (end - start + 1).to_int64()
    tree[node] = tree[node] + val * len
    pending[node] = pending[node] + val
    return
  }

  // Partial overlap - push down and recurse
  push_down(tree, pending, node, start, end)
  let mid = (start + end) / 2
  range_add_helper(tree, pending, 2 * node, start, mid, l, r, val)
  range_add_helper(tree, pending, 2 * node + 1, mid + 1, end, l, r, val)

  // Update current node from children
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Return the sum of elements in the closed range `[l, r]`, or `None` if the
/// range is empty or out of bounds.
///
/// Traverses the tree top-down, calling `push_down` before entering any node
/// with partial overlap so that the children reflect all accumulated updates.
/// Nodes fully covered by `[l, r]` contribute their `tree` value directly
/// without further descent.
///
/// - Time: O(log n)
/// - Returns `None` when `l < 0`, `r >= n`, `l > r`, or the tree is empty.
pub fn LazySegTreeSum::range_sum(
  self : LazySegTreeSum,
  l : Int,
  r : Int,
) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  Some(range_sum_helper(self.tree, self.pending, 1, 0, self.n - 1, l, r))
}

///|
/// Recursive worker for `range_sum`.  Returns 0 for no-overlap nodes and
/// `tree[node]` for fully-covered nodes.  For partial overlaps it calls
/// `push_down` then recurses into both children.
fn range_sum_helper(
  tree : Array[Int64],
  pending : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return 0L
  }
  if l <= start && end <= r {
    return tree[node]
  }
  push_down(tree, pending, node, start, end)
  let mid = (start + end) / 2
  let left_sum = range_sum_helper(tree, pending, 2 * node, start, mid, l, r)
  let right_sum = range_sum_helper(
    tree,
    pending,
    2 * node + 1,
    mid + 1,
    end,
    l,
    r,
  )
  left_sum + right_sum
}

///|
/// Return the value of the single element at index `i`, or `None` if `i` is
/// out of bounds.
///
/// Implemented as `range_sum(i, i)`.  All accumulated pending additions along
/// the path from the root to the leaf are correctly applied before the value
/// is returned.
///
/// - Time: O(log n)
pub fn LazySegTreeSum::point_query(self : LazySegTreeSum, i : Int) -> Int64? {
  self.range_sum(i, i)
}

///|
/// Set the element at index `i` to `val`.
///
/// Reads the current value via `point_query`, then applies
/// `range_add(i, i, val - current)` so that all existing pending additions
/// are accounted for before the difference is computed.
///
/// - Time: O(log n) (two tree traversals: one read, one write)
/// - Out-of-bounds indices are silently ignored.
pub fn LazySegTreeSum::point_set(
  self : LazySegTreeSum,
  i : Int,
  val : Int64,
) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  // Get current value and add the difference
  match self.point_query(i) {
    Some(curr) => self.range_add(i, i, val - curr)
    None => ()
  }
}

///|
/// Return the number of elements in the original array that was used to build
/// this tree.  Valid index range for all operations is `[0, length() - 1]`.
pub fn LazySegTreeSum::length(self : LazySegTreeSum) -> Int {
  self.n
}

// ============================================================================
// LAZY SEGMENT TREE FOR RANGE SET + RANGE SUM
// ============================================================================

///|
/// A private lazy segment tree that supports range assignment and range sum
/// queries.
///
/// Unlike `LazySegTreeSum` (range add), this variant uses an *assignment* lazy
/// tag: setting `[l, r]` to a value `v` overwrites whatever was there before.
/// Because assignment does not compose with itself (any subsequent assignment
/// simply replaces the previous one), the push-down logic unconditionally
/// overwrites the children's pending values.
///
/// ## Fields
///
/// - `tree` -- `tree[k]` is the sum of the range covered by node `k`.
/// - `pending` -- `pending[k]` is the pending assignment value for node `k`'s
///   range when `has_pending[k]` is `true`.
/// - `has_pending` -- distinguishes "no pending assignment" from "assign 0".
///   A fresh tree has all `has_pending` slots set to `false`.
priv struct LazySegTreeSetSum {
  n : Int
  tree : Array[Int64]
  pending : Array[Int64]
  has_pending : Array[Bool] // Whether node has pending assignment
}

///|
/// Build a `LazySegTreeSetSum` from `arr`.  All `has_pending` slots start as
/// `false` (no pending assignments).
fn LazySegTreeSetSum::new(arr : Array[Int64]) -> LazySegTreeSetSum {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [], pending: [], has_pending: [] }
  }
  let tree = Array::make(4 * n, 0L)
  let pending = Array::make(4 * n, 0L)
  let has_pending = Array::make(4 * n, false)
  build_set(arr, tree, 1, 0, n - 1)
  { n, tree, pending, has_pending }
}

///|
/// Bottom-up build helper for `LazySegTreeSetSum`.
fn build_set(
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
  build_set(arr, tree, 2 * node, start, mid)
  build_set(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Push-down for the assignment variant.  When `has_pending[node]` is true,
/// both children receive the same assignment value: their `tree` values are
/// overwritten with `pending[node] * child_size`, their `pending` slots are set
/// to `pending[node]`, and their `has_pending` flags are set to `true`.
/// After the push, `has_pending[node]` is cleared to `false`.
fn push_down_set(
  tree : Array[Int64],
  pending : Array[Int64],
  has_pending : Array[Bool],
  node : Int,
  start : Int,
  end : Int,
) -> Unit {
  if has_pending[node] {
    let mid = (start + end) / 2
    let left_len = (mid - start + 1).to_int64()
    let right_len = (end - mid).to_int64()

    // Set children's values
    tree[2 * node] = pending[node] * left_len
    tree[2 * node + 1] = pending[node] * right_len

    // Propagate lazy to children
    pending[2 * node] = pending[node]
    pending[2 * node + 1] = pending[node]
    has_pending[2 * node] = true
    has_pending[2 * node + 1] = true

    // Clear current lazy
    has_pending[node] = false
  }
}

///|
/// Set every element in the closed range `[l, r]` to `val`.
///
/// Nodes whose range is fully contained in `[l, r]` are updated in O(1):
/// `tree[k] = val * size` and `pending[k] = val`, `has_pending[k] = true`.
/// Ancestor sums are recomputed on the way back up.
///
/// - Time: O(log n)
fn LazySegTreeSetSum::range_set(
  self : LazySegTreeSetSum,
  l : Int,
  r : Int,
  val : Int64,
) -> Unit {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return
  }
  range_set_helper(
    self.tree,
    self.pending,
    self.has_pending,
    1,
    0,
    self.n - 1,
    l,
    r,
    val,
  )
}

///|
/// Recursive worker for `range_set`.
fn range_set_helper(
  tree : Array[Int64],
  pending : Array[Int64],
  has_pending : Array[Bool],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
  val : Int64,
) -> Unit {
  if r < start || end < l {
    return
  }
  if l <= start && end <= r {
    let len = (end - start + 1).to_int64()
    tree[node] = val * len
    pending[node] = val
    has_pending[node] = true
    return
  }
  push_down_set(tree, pending, has_pending, node, start, end)
  let mid = (start + end) / 2
  range_set_helper(tree, pending, has_pending, 2 * node, start, mid, l, r, val)
  range_set_helper(
    tree,
    pending,
    has_pending,
    2 * node + 1,
    mid + 1,
    end,
    l,
    r,
    val,
  )
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Return the sum of elements in the closed range `[l, r]`, or `None` if the
/// range is empty or out of bounds.  All pending assignments are applied via
/// push-down before the value is read.
///
/// - Time: O(log n)
fn LazySegTreeSetSum::range_sum(
  self : LazySegTreeSetSum,
  l : Int,
  r : Int,
) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  Some(
    range_sum_set_helper(
      self.tree,
      self.pending,
      self.has_pending,
      1,
      0,
      self.n - 1,
      l,
      r,
    ),
  )
}

///|
/// Recursive worker for `LazySegTreeSetSum::range_sum`.
fn range_sum_set_helper(
  tree : Array[Int64],
  pending : Array[Int64],
  has_pending : Array[Bool],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return 0L
  }
  if l <= start && end <= r {
    return tree[node]
  }
  push_down_set(tree, pending, has_pending, node, start, end)
  let mid = (start + end) / 2
  let left = range_sum_set_helper(
    tree,
    pending,
    has_pending,
    2 * node,
    start,
    mid,
    l,
    r,
  )
  let right = range_sum_set_helper(
    tree,
    pending,
    has_pending,
    2 * node + 1,
    mid + 1,
    end,
    l,
    r,
  )
  left + right
}

///|
/// Return the number of elements tracked by this tree.
fn LazySegTreeSetSum::length(self : LazySegTreeSetSum) -> Int {
  self.n
}

// ============================================================================
// LAZY SEGMENT TREE FOR RANGE ADD + RANGE MIN
// ============================================================================

///|
/// A private lazy segment tree that supports range addition and range minimum
/// queries.
///
/// The aggregation function is `min` instead of `+`, so `tree[k]` holds the
/// minimum value in node `k`'s range.  The lazy tag is the same addend
/// mechanism as in `LazySegTreeSum`: `pending[k]` is an addend owed to all
/// elements in the range.  Because adding a constant to all elements in a range
/// shifts the minimum by the same constant, push-down simply adds `pending[k]`
/// to both children's `tree` values (no multiplication by size is needed).
///
/// ## Fields
///
/// - `tree` -- `tree[k]` is the minimum of the sub-range covered by node `k`,
///   already accounting for `pending[k]` itself.
/// - `pending` -- addend owed to the children of node `k`.
priv struct LazySegTreeMin {
  n : Int
  tree : Array[Int64] // Min of range
  pending : Array[Int64] // Pending add value
}

///|
/// Sentinel value used as the identity element for `min` queries.  Returned
/// for no-overlap nodes during range-min queries so that `min(INT64_MAX, x) = x`
/// for any real element `x`.
const INT64_MAX : Int64 = 9223372036854775807L

///|
/// Build a `LazySegTreeMin` from `arr`.  Each node is initialised to the
/// minimum of its sub-range; all `pending` slots start at zero.
fn LazySegTreeMin::new(arr : Array[Int64]) -> LazySegTreeMin {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [], pending: [] }
  }
  let tree = Array::make(4 * n, INT64_MAX)
  let pending = Array::make(4 * n, 0L)
  build_min(arr, tree, 1, 0, n - 1)
  { n, tree, pending }
}

///|
/// Bottom-up build helper for `LazySegTreeMin`.  Internal nodes store the
/// minimum of their two children.
fn build_min(
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
  build_min(arr, tree, 2 * node, start, mid)
  build_min(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = if tree[2 * node] < tree[2 * node + 1] {
    tree[2 * node]
  } else {
    tree[2 * node + 1]
  }
}

///|
/// Push-down for the min variant.  Because min shifts uniformly when a constant
/// is added to all elements, the children's `tree` values are incremented by
/// `pending[node]` without any multiplication by range size.
///
/// ```
/// tree[2k]     += pending[k]
/// tree[2k+1]   += pending[k]
/// pending[2k]  += pending[k]
/// pending[2k+1]+= pending[k]
/// pending[k]    = 0
/// ```
fn push_down_min(
  tree : Array[Int64],
  pending : Array[Int64],
  node : Int,
) -> Unit {
  if pending[node] != 0L {
    tree[2 * node] = tree[2 * node] + pending[node]
    tree[2 * node + 1] = tree[2 * node + 1] + pending[node]
    pending[2 * node] = pending[2 * node] + pending[node]
    pending[2 * node + 1] = pending[2 * node + 1] + pending[node]
    pending[node] = 0L
  }
}

///|
/// Add `val` to every element in the closed range `[l, r]`.
///
/// For the min variant, adding a constant to all elements in a range shifts the
/// range minimum by the same constant, so `tree[k] += val` for fully-covered
/// nodes and `pending[k] += val` records the deferred work for children.
///
/// - Time: O(log n)
fn LazySegTreeMin::range_add(
  self : LazySegTreeMin,
  l : Int,
  r : Int,
  val : Int64,
) -> Unit {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return
  }
  range_add_min_helper(self.tree, self.pending, 1, 0, self.n - 1, l, r, val)
}

///|
/// Recursive worker for `LazySegTreeMin::range_add`.
fn range_add_min_helper(
  tree : Array[Int64],
  pending : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
  val : Int64,
) -> Unit {
  if r < start || end < l {
    return
  }
  if l <= start && end <= r {
    tree[node] = tree[node] + val
    pending[node] = pending[node] + val
    return
  }
  push_down_min(tree, pending, node)
  let mid = (start + end) / 2
  range_add_min_helper(tree, pending, 2 * node, start, mid, l, r, val)
  range_add_min_helper(tree, pending, 2 * node + 1, mid + 1, end, l, r, val)
  tree[node] = if tree[2 * node] < tree[2 * node + 1] {
    tree[2 * node]
  } else {
    tree[2 * node + 1]
  }
}

///|
/// Return the minimum element in the closed range `[l, r]`, or `None` if the
/// range is empty or out of bounds.
///
/// No-overlap nodes contribute `INT64_MAX` (the identity for `min`), so the
/// accumulation `min(left, right)` is correct at every level.
///
/// - Time: O(log n)
fn LazySegTreeMin::range_min(self : LazySegTreeMin, l : Int, r : Int) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  Some(range_min_helper(self.tree, self.pending, 1, 0, self.n - 1, l, r))
}

///|
/// Recursive worker for `LazySegTreeMin::range_min`.
fn range_min_helper(
  tree : Array[Int64],
  pending : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return INT64_MAX
  }
  if l <= start && end <= r {
    return tree[node]
  }
  push_down_min(tree, pending, node)
  let mid = (start + end) / 2
  let left = range_min_helper(tree, pending, 2 * node, start, mid, l, r)
  let right = range_min_helper(tree, pending, 2 * node + 1, mid + 1, end, l, r)
  if left < right {
    left
  } else {
    right
  }
}

///|
/// Return the number of elements tracked by this tree.
fn LazySegTreeMin::length(self : LazySegTreeMin) -> Int {
  self.n
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "lazy segtree sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = LazySegTreeSum::new(arr)

  // Initial sums
  inspect(st.range_sum(0, 4), content="Some(15)")
  inspect(st.range_sum(0, 2), content="Some(6)")
  inspect(st.range_sum(2, 4), content="Some(12)")
}

///|
test "lazy segtree sum range add" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = LazySegTreeSum::new(arr)

  // Add 10 to [1, 3]
  st.range_add(1, 3, 10L)

  // arr is now [1, 12, 13, 14, 5]
  inspect(st.range_sum(0, 4), content="Some(45)") // 1+12+13+14+5
  inspect(st.range_sum(1, 3), content="Some(39)") // 12+13+14
  inspect(st.point_query(0), content="Some(1)")
  inspect(st.point_query(2), content="Some(13)")
}

///|
test "lazy segtree sum multiple updates" {
  let arr : Array[Int64] = [0L, 0L, 0L, 0L, 0L]
  let st = LazySegTreeSum::new(arr)
  st.range_add(0, 4, 1L) // [1,1,1,1,1]
  st.range_add(1, 3, 2L) // [1,3,3,3,1]
  st.range_add(2, 2, 5L) // [1,3,8,3,1]
  inspect(st.range_sum(0, 4), content="Some(16)")
  inspect(st.point_query(2), content="Some(8)")
}

///|
test "lazy segtree sum point set" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = LazySegTreeSum::new(arr)
  st.point_set(2, 10L)
  inspect(st.range_sum(0, 4), content="Some(22)") // 1+2+10+4+5
  inspect(st.point_query(2), content="Some(10)")
}

///|
test "lazy segtree set sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = LazySegTreeSetSum::new(arr)
  inspect(st.range_sum(0, 4), content="Some(15)")

  // Set [1, 3] to 10
  st.range_set(1, 3, 10L)

  // arr is now [1, 10, 10, 10, 5]
  inspect(st.range_sum(0, 4), content="Some(36)") // 1+10+10+10+5
  inspect(st.range_sum(1, 3), content="Some(30)") // 10+10+10
}

///|
test "lazy segtree set sum overwrite" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = LazySegTreeSetSum::new(arr)
  st.range_set(0, 4, 1L) // All 1s
  inspect(st.range_sum(0, 4), content="Some(5)")
  st.range_set(2, 3, 100L) // [1, 1, 100, 100, 1]
  inspect(st.range_sum(0, 4), content="Some(203)")
}

///|
test "lazy segtree min basic" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let st = LazySegTreeMin::new(arr)
  inspect(st.range_min(0, 4), content="Some(1)")
  inspect(st.range_min(0, 2), content="Some(2)")
  inspect(st.range_min(2, 4), content="Some(1)")
}

///|
test "lazy segtree min range add" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let st = LazySegTreeMin::new(arr)

  // Add 10 to [0, 2]
  st.range_add(0, 2, 10L)

  // arr is now [15, 12, 18, 1, 9]
  inspect(st.range_min(0, 4), content="Some(1)")
  inspect(st.range_min(0, 2), content="Some(12)")
}

///|
test "lazy segtree sum empty" {
  let arr : Array[Int64] = []
  let st = LazySegTreeSum::new(arr)
  inspect(st.length(), content="0")
  inspect(st.range_sum(0, 0), content="None")
}

///|
test "lazy segtree sum single" {
  let arr : Array[Int64] = [42L]
  let st = LazySegTreeSum::new(arr)
  inspect(st.range_sum(0, 0), content="Some(42)")
  st.range_add(0, 0, 8L)
  inspect(st.range_sum(0, 0), content="Some(50)")
}

///|
test "lazy segtree invalid range" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let st = LazySegTreeSum::new(arr)
  inspect(st.range_sum(-1, 0), content="None")
  inspect(st.range_sum(0, 10), content="None")
  inspect(st.range_sum(2, 1), content="None")
}

///|
test "lazy segtree min negative values" {
  let arr : Array[Int64] = [-5L, -2L, -8L, -1L, -9L]
  let st = LazySegTreeMin::new(arr)
  inspect(st.range_min(0, 4), content="Some(-9)")
  inspect(st.range_min(0, 2), content="Some(-8)")
  st.range_add(4, 4, 20L) // -9 + 20 = 11
  inspect(st.range_min(0, 4), content="Some(-8)")
}

///|
test "lazy segtree length" {
  let st1 = LazySegTreeSum::new([1L, 2L, 3L])
  let st2 = LazySegTreeSetSum::new([1L, 2L])
  let st3 = LazySegTreeMin::new([1L])
  inspect(st1.length(), content="3")
  inspect(st2.length(), content="2")
  inspect(st3.length(), content="1")
}

///|
test "lazy segtree large updates" {
  let arr : Array[Int64] = [0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L]
  let st = LazySegTreeSum::new(arr)

  // Multiple overlapping updates
  st.range_add(0, 7, 1L)
  st.range_add(0, 3, 1L)
  st.range_add(4, 7, 1L)
  st.range_add(2, 5, 1L)

  // [2, 2, 3, 3, 3, 3, 2, 2]
  inspect(st.range_sum(0, 7), content="Some(20)")
}
