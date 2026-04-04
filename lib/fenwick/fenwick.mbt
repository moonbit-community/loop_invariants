// ============================================================================
// FENWICK TREE (Binary Indexed Tree) - Efficient Prefix Sums
// ============================================================================
//
// A Fenwick Tree (BIT) supports both point updates and prefix queries in O(log n).
// It's simpler and more cache-friendly than segment trees for many problems.
//
// KEY INSIGHT: Use binary representation to decompose ranges into O(log n) parts.
// Each index i is responsible for a range whose length is the lowest set bit of i.
//
// STRUCTURE:
// For 1-indexed array (we use 0-indexed internally by adding 1):
// - tree[i] stores sum of elements in range [i - lowbit(i) + 1, i]
// - lowbit(i) = i & (-i) = lowest set bit of i
//
// EXAMPLE (1-indexed):
// Index:    1    2    3    4    5    6    7    8
// Lowbit:   1    2    1    4    1    2    1    8
// Covers:  [1]  [1,2] [3] [1,4] [5] [5,6] [7] [1,8]
//
// PREFIX SUM query(7):
// - Start at 7, add tree[7], subtract lowbit(7)=1 → 6
// - Add tree[6], subtract lowbit(6)=2 → 4
// - Add tree[4], subtract lowbit(4)=4 → 0
// - Done: tree[7] + tree[6] + tree[4] = sum of [1..7]
//
// POINT UPDATE add(3, delta):
// - Start at 3, update tree[3], add lowbit(3)=1 → 4
// - Update tree[4], add lowbit(4)=4 → 8
// - Update tree[8], add lowbit(8)=8 → 16 (out of range)
// - Done: updated all nodes covering index 3
//
// INVARIANTS:
// 1. tree[i] = sum of arr[i - lowbit(i) + 1 .. i]
// 2. query(i) = sum of arr[1..i] = prefix sum
// 3. Each update touches exactly O(log n) nodes
//
// TIME COMPLEXITY: O(log n) for both update and query
// SPACE COMPLEXITY: O(n)

///|
/// A Fenwick Tree (Binary Indexed Tree) for efficient prefix sum queries and
/// point updates over a sequence of `Int64` values.
///
/// Each internal node `tree[i]` stores the sum of a range of elements whose
/// length equals `lowbit(i) = i & (-i)`. This structure allows both point
/// updates and prefix sum queries to run in O(log n) time.
///
/// The public API is 0-indexed (elements at positions 0..n-1), while the
/// internal storage is 1-indexed (indices 1..n) for easier bit manipulation.
pub struct FenwickTree {
  n : Int
  tree : Array[Int64]
}

///|
/// Creates a new Fenwick Tree of size `n` with all elements initialized to 0.
///
/// Parameters:
/// - `n`: the number of elements to track (valid indices are `0..n-1`).
///
/// Returns a `FenwickTree` ready for updates and queries.
///
/// Time complexity: O(n).
///
/// Example:
/// ```
/// let ft = FenwickTree::new(5)
/// ft.add(2, 7L)
/// assert_eq!(ft.prefix_sum(2), 7L)
/// ```
pub fn FenwickTree::new(n : Int) -> FenwickTree {
  // 1-indexed, so we need n+1 elements
  { n, tree: Array::make(n + 1, 0L) }
}

///|
/// Builds a Fenwick Tree from an existing array in O(n) time.
///
/// Uses the propagation method: after copying array values into the tree
/// buffer, each index `i` pushes its value to its parent at `i + lowbit(i)`.
/// Because the parent index is always strictly greater than `i`, each element
/// is propagated at most once, giving linear build time.
///
/// Parameters:
/// - `arr`: the source array of `Int64` values.
///
/// Returns a `FenwickTree` equivalent to inserting each element individually,
/// but built in O(n) rather than O(n log n).
///
/// Time complexity: O(n).
///
/// INVARIANT: After processing index i, tree[i] contains the correct partial
/// sum. Each index propagates its value to index i + lowbit(i).
/// REASONING: Parent index > current index ensures no revisits, O(n) total.
///
/// Example:
/// ```
/// let ft = FenwickTree::from_array([10L, 20L, 30L])
/// assert_eq!(ft.prefix_sum(2), 60L)
/// ```
pub fn FenwickTree::from_array(arr : Array[Int64]) -> FenwickTree {
  let n = arr.length()
  let tree = Array::make(n + 1, 0L)

  // Copy array values (convert to 1-indexed)
  for i in 0..<n {
    tree[i + 1] = arr[i]
  }

  // Build tree in O(n) by propagating each element to its parent
  for i in 1..<=n {
    let parent = i + (i & -i)
    if parent <= n {
      tree[parent] = tree[parent] + tree[i]
    }
  }
  { n, tree }
}

///|
/// Returns the lowest set bit of `x`, i.e. `x & (-x)`.
///
/// This is the core primitive of the Fenwick Tree: the length of the range
/// that node `x` is responsible for equals `lowbit(x)`.
///
/// Examples:
/// - `lowbit(6)  = lowbit(0b110)  = 2`
/// - `lowbit(12) = lowbit(0b1100) = 4`
/// - `lowbit(8)  = lowbit(0b1000) = 8`
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
/// Adds `delta` to the element at 0-indexed position `i`.
///
/// Internally converts to 1-indexed, then walks up the tree by repeatedly
/// adding `lowbit(idx)` to `idx`, updating every node whose range covers
/// position `i`.
///
/// Parameters:
/// - `i`: 0-indexed position to update (silently ignored if out of bounds).
/// - `delta`: value to add (may be negative).
///
/// Time complexity: O(log n).
///
/// INVARIANT: `idx` covers all tree nodes responsible for index `i+1`.
/// REASONING: `idx` increases by at least 1 each step (lowbit >= 1),
/// so the loop terminates when `idx > n`.
///
/// Example:
/// ```
/// let ft = FenwickTree::new(4)
/// ft.add(0, 5L)
/// ft.add(0, -2L) // net value at index 0 is now 3
/// assert_eq!(ft.get(0), 3L)
/// ```
pub fn FenwickTree::add(self : FenwickTree, i : Int, delta : Int64) -> Unit {
  if i < 0 || i >= self.n {
    return
  }

  // Convert to 1-indexed
  for idx = i + 1 {
    if idx > self.n {
      break
    } else {
      self.tree[idx] = self.tree[idx] + delta
      continue idx + lowbit(idx)
    }
  }
}

///|
/// Returns the prefix sum of elements at 0-indexed positions `[0, i]`
/// (inclusive).
///
/// Internally converts to 1-indexed, then walks down the tree by repeatedly
/// subtracting `lowbit(idx)` from `idx`, accumulating partial sums.
///
/// Parameters:
/// - `i`: the last 0-indexed position to include in the sum.
///   - If `i < 0`, returns 0.
///   - If `i >= n`, the sum is clamped to cover all `n` elements.
///
/// Returns the sum `arr[0] + arr[1] + ... + arr[i]`.
///
/// Time complexity: O(log n).
///
/// INVARIANT: `sum` accumulates partial sums from tree nodes already visited.
/// REASONING: `idx` decreases by at least 1 each step (lowbit >= 1),
/// so the loop terminates when `idx <= 0`.
///
/// Example:
/// ```
/// let ft = FenwickTree::from_array([1L, 2L, 3L, 4L, 5L])
/// assert_eq!(ft.prefix_sum(3), 10L) // 1+2+3+4
/// ```
pub fn FenwickTree::prefix_sum(self : FenwickTree, i : Int) -> Int64 {
  if i < 0 {
    return 0L
  }

  // Convert to 1-indexed and clamp
  let idx_start = if i >= self.n { self.n } else { i + 1 }
  for idx = idx_start, sum = 0L {
    if idx <= 0 {
      break sum
    } else {
      continue idx - lowbit(idx), sum + self.tree[idx]
    }
  }
}

///|
/// Returns the sum of elements at 0-indexed positions `[l, r]` (inclusive).
///
/// Uses the identity: `range_sum(l, r) = prefix_sum(r) - prefix_sum(l - 1)`.
/// Returns 0 if the range is empty or entirely out of bounds.
///
/// Parameters:
/// - `l`: first 0-indexed position (inclusive).
/// - `r`: last 0-indexed position (inclusive).
///
/// Time complexity: O(log n) (two prefix sum calls).
///
/// Example:
/// ```
/// let ft = FenwickTree::from_array([1L, 2L, 3L, 4L, 5L])
/// assert_eq!(ft.range_sum(1, 3), 9L) // 2+3+4
/// ```
pub fn FenwickTree::range_sum(self : FenwickTree, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return 0L
  }
  if l == 0 {
    self.prefix_sum(r)
  } else {
    self.prefix_sum(r) - self.prefix_sum(l - 1)
  }
}

///|
/// Returns the current value stored at 0-indexed position `i`.
///
/// Implemented as `range_sum(i, i)`.
///
/// Parameters:
/// - `i`: 0-indexed position to read.
///
/// Returns the element value, or 0 if `i` is out of bounds.
///
/// Time complexity: O(log n).
///
/// Example:
/// ```
/// let ft = FenwickTree::from_array([10L, 20L, 30L])
/// assert_eq!(ft.get(1), 20L)
/// ```
pub fn FenwickTree::get(self : FenwickTree, i : Int) -> Int64 {
  self.range_sum(i, i)
}

///|
/// Sets the element at 0-indexed position `i` to `value`, replacing its
/// current value.
///
/// Computes `delta = value - current` and delegates to `add`.
///
/// Parameters:
/// - `i`: 0-indexed position to modify.
/// - `value`: the new value to store at position `i`.
///
/// Time complexity: O(log n).
///
/// Example:
/// ```
/// let ft = FenwickTree::from_array([1L, 2L, 3L])
/// ft.set(1, 99L)
/// assert_eq!(ft.get(1), 99L)
/// assert_eq!(ft.prefix_sum(2), 103L) // 1 + 99 + 3
/// ```
pub fn FenwickTree::set(self : FenwickTree, i : Int, value : Int64) -> Unit {
  let current = self.get(i)
  self.add(i, value - current)
}

///|
/// Returns the number of elements tracked by this tree.
///
/// This is the `n` passed to `FenwickTree::new` or inferred from the array
/// passed to `FenwickTree::from_array`.
///
/// Time complexity: O(1).
///
/// Example:
/// ```
/// let ft = FenwickTree::new(10)
/// assert_eq!(ft.length(), 10)
/// ```
pub fn FenwickTree::length(self : FenwickTree) -> Int {
  self.n
}

// ============================================================================
// 2D FENWICK TREE
// ============================================================================

///|
/// A 2D Fenwick Tree (Binary Indexed Tree) for efficient rectangle sum queries
/// and point updates over a 2D grid of `Int64` values.
///
/// Extends the 1D idea: each cell `(i, j)` in the internal tree is responsible
/// for a sub-rectangle of size `lowbit(i) x lowbit(j)`. Updates and queries
/// walk the 2D lowbit chains, touching O(log rows * log cols) cells.
///
/// The public API is 0-indexed; internally rows and columns are 1-indexed.
priv struct FenwickTree2D {
  rows : Int
  cols : Int
  tree : Array[Array[Int64]]
}

///|
/// Creates a new 2D Fenwick Tree with `rows` rows and `cols` columns,
/// all initialized to 0.
///
/// Parameters:
/// - `rows`: number of rows (valid row indices: `0..rows-1`).
/// - `cols`: number of columns (valid column indices: `0..cols-1`).
///
/// Time complexity: O(rows * cols).
fn FenwickTree2D::new(rows : Int, cols : Int) -> FenwickTree2D {
  let tree : Array[Array[Int64]] = []
  for _ in 0..<=rows {
    tree.push(Array::make(cols + 1, 0L))
  }
  { rows, cols, tree }
}

///|
/// Adds `delta` to the cell at 0-indexed position `(r, c)`.
///
/// Walks the row chain (adding `lowbit(i)` to `i`) and for each row node
/// walks the column chain (adding `lowbit(j)` to `j`), updating all nodes
/// whose rectangles cover `(r, c)`.
///
/// Parameters:
/// - `r`: 0-indexed row (silently ignored if out of bounds).
/// - `c`: 0-indexed column (silently ignored if out of bounds).
/// - `delta`: value to add (may be negative).
///
/// Time complexity: O(log rows * log cols).
fn FenwickTree2D::add(
  self : FenwickTree2D,
  r : Int,
  c : Int,
  delta : Int64,
) -> Unit {
  if r < 0 || r >= self.rows || c < 0 || c >= self.cols {
    return
  }
  for i = r + 1 {
    if i > self.rows {
      break
    } else {
      for j = c + 1 {
        if j > self.cols {
          break
        } else {
          self.tree[i][j] = self.tree[i][j] + delta
          continue j + lowbit(j)
        }
      }
      continue i + lowbit(i)
    }
  }
}

///|
/// Returns the sum of all cells in the rectangle `[0, 0]` to `[r, c]`
/// (inclusive, 0-indexed).
///
/// Walks the row chain downward and for each node walks the column chain
/// downward, accumulating partial sums.
///
/// Parameters:
/// - `r`: last 0-indexed row (clamped to `rows-1` if larger).
/// - `c`: last 0-indexed column (clamped to `cols-1` if larger).
///
/// Returns 0 if `r < 0` or `c < 0`.
///
/// Time complexity: O(log rows * log cols).
fn FenwickTree2D::prefix_sum(self : FenwickTree2D, r : Int, c : Int) -> Int64 {
  if r < 0 || c < 0 {
    return 0L
  }
  let ri = if r >= self.rows { self.rows } else { r + 1 }
  let ci = if c >= self.cols { self.cols } else { c + 1 }
  for i = ri, sum = 0L {
    if i <= 0 {
      break sum
    } else {
      let row_sum = for j = ci, acc = 0L {
        if j <= 0 {
          break acc
        } else {
          continue j - lowbit(j), acc + self.tree[i][j]
        }
      }
      continue i - lowbit(i), sum + row_sum
    }
  }
}

///|
/// Returns the sum of all cells in the rectangle `[r1, c1]` to `[r2, c2]`
/// (inclusive, 0-indexed).
///
/// Uses the 2D inclusion-exclusion identity:
/// ```
/// range_sum(r1,c1,r2,c2)
///   = prefix(r2,c2) - prefix(r1-1,c2) - prefix(r2,c1-1) + prefix(r1-1,c1-1)
/// ```
///
/// Returns 0 if the rectangle is empty (`r1 > r2` or `c1 > c2`).
///
/// Time complexity: O(log rows * log cols).
fn FenwickTree2D::range_sum(
  self : FenwickTree2D,
  r1 : Int,
  c1 : Int,
  r2 : Int,
  c2 : Int,
) -> Int64 {
  if r1 > r2 || c1 > c2 {
    return 0L
  }
  // Inclusion-exclusion principle
  self.prefix_sum(r2, c2) -
  self.prefix_sum(r1 - 1, c2) -
  self.prefix_sum(r2, c1 - 1) +
  self.prefix_sum(r1 - 1, c1 - 1)
}

// ============================================================================
// FENWICK TREE FOR RANGE UPDATE + POINT QUERY
// ============================================================================

///|
/// A Fenwick Tree variant that supports range updates and point queries using
/// the difference array technique.
///
/// Instead of storing element values directly, this tree stores differences:
/// adding `delta` to range `[l, r]` is encoded as two point updates,
/// `diff[l] += delta` and `diff[r+1] -= delta`.  A point query for position
/// `i` then becomes a prefix sum of the difference tree up to `i`.
///
/// This is the dual of the standard Fenwick Tree:
/// - Standard: O(1) range queries, O(log n) point updates.
/// - This:    O(log n) range updates, O(log n) point queries.
priv struct FenwickTreeRangeUpdate {
  n : Int
  tree : Array[Int64] // Stores differences
}

///|
/// Creates a new `FenwickTreeRangeUpdate` of size `n`, all values zero.
///
/// Parameters:
/// - `n`: number of elements (valid indices: `0..n-1`).
///
/// Time complexity: O(n).
fn FenwickTreeRangeUpdate::new(n : Int) -> FenwickTreeRangeUpdate {
  { n, tree: Array::make(n + 1, 0L) }
}

///|
/// Internal helper: adds `delta` to a single position in the difference tree.
///
/// This is identical to a standard Fenwick Tree point update. It is called
/// twice by `range_add` to encode a range update as two point updates on the
/// difference array.
///
/// Parameters:
/// - `i`: 0-indexed position.
/// - `delta`: value to add.
///
/// Time complexity: O(log n).
fn FenwickTreeRangeUpdate::point_add(
  self : FenwickTreeRangeUpdate,
  i : Int,
  delta : Int64,
) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  for idx = i + 1 {
    if idx > self.n {
      break
    } else {
      self.tree[idx] = self.tree[idx] + delta
      continue idx + lowbit(idx)
    }
  }
}

///|
/// Adds `delta` to all elements in the range `[l, r]` (inclusive, 0-indexed).
///
/// Encodes the range update as two point updates on the internal difference
/// array: `diff[l] += delta` and `diff[r+1] -= delta` (when `r+1 < n`).
///
/// Parameters:
/// - `l`: first 0-indexed position (inclusive).
/// - `r`: last 0-indexed position (inclusive, clamped to `n-1`).
/// - `delta`: value to add to every element in the range.
///
/// Time complexity: O(log n).
fn FenwickTreeRangeUpdate::range_add(
  self : FenwickTreeRangeUpdate,
  l : Int,
  r : Int,
  delta : Int64,
) -> Unit {
  if l > r || l < 0 {
    return
  }
  let r_clamped = if r >= self.n { self.n - 1 } else { r }
  self.point_add(l, delta)
  if r_clamped + 1 < self.n {
    self.point_add(r_clamped + 1, -delta)
  }
}

///|
/// Returns the current value at 0-indexed position `i`.
///
/// Computed as the prefix sum of the difference tree up to `i`, which
/// recovers the accumulated delta applied to position `i` by all previous
/// range updates.
///
/// Parameters:
/// - `i`: 0-indexed position to query.
///
/// Returns 0 if `i` is out of bounds.
///
/// Time complexity: O(log n).
fn FenwickTreeRangeUpdate::query(
  self : FenwickTreeRangeUpdate,
  i : Int,
) -> Int64 {
  if i < 0 || i >= self.n {
    return 0L
  }
  for idx = i + 1, sum = 0L {
    if idx <= 0 {
      break sum
    } else {
      continue idx - lowbit(idx), sum + self.tree[idx]
    }
  }
}

// ============================================================================
// FENWICK TREE FOR RANGE UPDATE + RANGE QUERY
// ============================================================================

///|
/// A Fenwick Tree that supports both range updates and range sum queries by
/// maintaining two internal BITs (`bit1` and `bit2`).
///
/// The mathematical trick: if we let `b(i)` be the difference array such that
/// `arr[i] = sum_{k=1}^{i} b(k)`, then:
/// ```
/// prefix_sum(i) = sum_{j=1}^{i} arr[j]
///              = sum_{j=1}^{i} sum_{k=1}^{j} b(k)
///              = sum_{k=1}^{i} b(k) * (i - k + 1)
///              = (i+1) * sum_{k=1}^{i} b(k) - sum_{k=1}^{i} b(k)*(k-1)
/// ```
/// `bit1` stores `b(k)` and `bit2` stores `b(k) * (k-1)`, so each prefix
/// query is two BIT queries combined.
priv struct FenwickTreeRangeRange {
  n : Int
  bit1 : Array[Int64] // Coefficient for (i+1) term
  bit2 : Array[Int64] // Constant term
}

///|
/// Creates a new `FenwickTreeRangeRange` of size `n`, all values zero.
///
/// Parameters:
/// - `n`: number of elements (valid indices: `0..n-1`).
///
/// Time complexity: O(n).
fn FenwickTreeRangeRange::new(n : Int) -> FenwickTreeRangeRange {
  { n, bit1: Array::make(n + 1, 0L), bit2: Array::make(n + 1, 0L) }
}

///|
/// Internal helper: standard Fenwick Tree point-add on an arbitrary array.
///
/// Parameters:
/// - `arr`: the internal BIT array (1-indexed, length >= n+1).
/// - `n`: the logical size bound for the BIT.
/// - `i`: 1-indexed position to start the update at.
/// - `delta`: value to add.
///
/// Time complexity: O(log n).
fn add_internal(arr : Array[Int64], n : Int, i : Int, delta : Int64) -> Unit {
  for idx = i {
    if idx > n {
      break
    } else {
      arr[idx] = arr[idx] + delta
      continue idx + lowbit(idx)
    }
  }
}

///|
/// Internal helper: standard Fenwick Tree prefix-sum query on an arbitrary
/// array.
///
/// Parameters:
/// - `arr`: the internal BIT array (1-indexed).
/// - `i`: 1-indexed upper bound for the prefix sum.
///
/// Returns the prefix sum from index 1 to `i`.
///
/// Time complexity: O(log n).
fn query_internal(arr : Array[Int64], i : Int) -> Int64 {
  for idx = i, sum = 0L {
    if idx <= 0 {
      break sum
    } else {
      continue idx - lowbit(idx), sum + arr[idx]
    }
  }
}

///|
/// Adds `delta` to all elements in the range `[l, r]` (inclusive, 0-indexed).
///
/// Updates both internal BITs to maintain the invariant required for O(log n)
/// range prefix queries:
/// - `bit1`: records the difference-array coefficients.
/// - `bit2`: records the weighted difference-array coefficients.
///
/// Parameters:
/// - `l`: first 0-indexed position (inclusive).
/// - `r`: last 0-indexed position (inclusive).
/// - `delta`: value to add to every element in `[l, r]`.
///
/// Time complexity: O(log n).
fn FenwickTreeRangeRange::range_add(
  self : FenwickTreeRangeRange,
  l : Int,
  r : Int,
  delta : Int64,
) -> Unit {
  if l > r || l < 0 {
    return
  }
  let l1 = l + 1
  let r1 = if r >= self.n { self.n } else { r + 1 }

  // Update BIT1 and BIT2 for range [l, r]
  add_internal(self.bit1, self.n, l1, delta)
  add_internal(self.bit1, self.n, r1 + 1, -delta)
  add_internal(self.bit2, self.n, l1, delta * (l1 - 1).to_int64())
  add_internal(self.bit2, self.n, r1 + 1, -delta * r1.to_int64())
}

///|
/// Returns the prefix sum of elements at 0-indexed positions `[0, i]`
/// (inclusive).
///
/// Uses the two-BIT formula:
/// `prefix_sum(i) = bit1.query(i) * (i+1) - bit2.query(i)`
///
/// Parameters:
/// - `i`: last 0-indexed position to include (returns 0 if `i < 0`).
///
/// Time complexity: O(log n).
fn FenwickTreeRangeRange::prefix_sum(
  self : FenwickTreeRangeRange,
  i : Int,
) -> Int64 {
  if i < 0 {
    return 0L
  }
  let idx = if i >= self.n { self.n } else { i + 1 }
  query_internal(self.bit1, idx) * idx.to_int64() -
  query_internal(self.bit2, idx)
}

///|
/// Returns the sum of elements at 0-indexed positions `[l, r]` (inclusive).
///
/// Uses the identity: `range_sum(l, r) = prefix_sum(r) - prefix_sum(l - 1)`.
/// Returns 0 if the range is empty or `l < 0`.
///
/// Parameters:
/// - `l`: first 0-indexed position (inclusive).
/// - `r`: last 0-indexed position (inclusive).
///
/// Time complexity: O(log n).
fn FenwickTreeRangeRange::range_sum(
  self : FenwickTreeRangeRange,
  l : Int,
  r : Int,
) -> Int64 {
  if l > r || l < 0 {
    return 0L
  }
  if l == 0 {
    self.prefix_sum(r)
  } else {
    self.prefix_sum(r) - self.prefix_sum(l - 1)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "fenwick tree basic" {
  let ft = FenwickTree::new(5)
  ft.add(0, 1L)
  ft.add(1, 2L)
  ft.add(2, 3L)
  ft.add(3, 4L)
  ft.add(4, 5L)
  inspect(ft.prefix_sum(0), content="1")
  inspect(ft.prefix_sum(1), content="3")
  inspect(ft.prefix_sum(2), content="6")
  inspect(ft.prefix_sum(4), content="15")
}

///|
test "fenwick tree from array" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let ft = FenwickTree::from_array(arr)
  inspect(ft.prefix_sum(0), content="1")
  inspect(ft.prefix_sum(2), content="6")
  inspect(ft.prefix_sum(4), content="15")
}

///|
test "fenwick tree range sum" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let ft = FenwickTree::from_array(arr)
  inspect(ft.range_sum(0, 4), content="15")
  inspect(ft.range_sum(1, 3), content="9")
  inspect(ft.range_sum(2, 2), content="3")
}

///|
test "fenwick tree get and set" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let ft = FenwickTree::from_array(arr)
  inspect(ft.get(2), content="3")
  ft.set(2, 10L)
  inspect(ft.get(2), content="10")
  inspect(ft.prefix_sum(4), content="22")
}

///|
test "fenwick tree 2d" {
  let ft = FenwickTree2D::new(3, 3)

  // Set up a 3x3 grid:
  // 1 2 3
  // 4 5 6
  // 7 8 9
  ft.add(0, 0, 1L)
  ft.add(0, 1, 2L)
  ft.add(0, 2, 3L)
  ft.add(1, 0, 4L)
  ft.add(1, 1, 5L)
  ft.add(1, 2, 6L)
  ft.add(2, 0, 7L)
  ft.add(2, 1, 8L)
  ft.add(2, 2, 9L)
  inspect(ft.prefix_sum(0, 0), content="1")
  inspect(ft.prefix_sum(1, 1), content="12") // 1+2+4+5
  inspect(ft.prefix_sum(2, 2), content="45") // sum of all
}

///|
test "fenwick tree 2d range" {
  let ft = FenwickTree2D::new(3, 3)

  // 1 2 3
  // 4 5 6
  // 7 8 9
  ft.add(0, 0, 1L)
  ft.add(0, 1, 2L)
  ft.add(0, 2, 3L)
  ft.add(1, 0, 4L)
  ft.add(1, 1, 5L)
  ft.add(1, 2, 6L)
  ft.add(2, 0, 7L)
  ft.add(2, 1, 8L)
  ft.add(2, 2, 9L)

  // Center 2x2: 5+6+8+9 = 28
  inspect(ft.range_sum(1, 1, 2, 2), content="28")

  // Middle row: 4+5+6 = 15
  inspect(ft.range_sum(1, 0, 1, 2), content="15")
}

///|
test "fenwick tree range update point query" {
  let ft = FenwickTreeRangeUpdate::new(5)

  // Add 10 to range [1, 3]
  ft.range_add(1, 3, 10L)
  inspect(ft.query(0), content="0")
  inspect(ft.query(1), content="10")
  inspect(ft.query(2), content="10")
  inspect(ft.query(3), content="10")
  inspect(ft.query(4), content="0")
}

///|
test "fenwick tree range range" {
  let ft = FenwickTreeRangeRange::new(5)

  // Add 1 to each element [0, 4]
  ft.range_add(0, 4, 1L)
  inspect(ft.range_sum(0, 4), content="5")

  // Add 2 to [1, 3]
  ft.range_add(1, 3, 2L)
  // Now: [1, 3, 3, 3, 1]
  inspect(ft.range_sum(0, 4), content="11")
  inspect(ft.range_sum(1, 3), content="9")
}

///|
test "fenwick tree empty" {
  let ft = FenwickTree::new(0)
  inspect(ft.length(), content="0")
  inspect(ft.prefix_sum(0), content="0")
}

///|
test "fenwick tree single element" {
  let ft = FenwickTree::new(1)
  ft.add(0, 42L)
  inspect(ft.prefix_sum(0), content="42")
  inspect(ft.get(0), content="42")
}

///|
test "fenwick tree negative values" {
  let ft = FenwickTree::new(3)
  ft.add(0, -5L)
  ft.add(1, 10L)
  ft.add(2, -3L)
  inspect(ft.prefix_sum(0), content="-5")
  inspect(ft.prefix_sum(1), content="5")
  inspect(ft.prefix_sum(2), content="2")
}

///|
test "lowbit function" {
  inspect(lowbit(1), content="1")
  inspect(lowbit(2), content="2")
  inspect(lowbit(3), content="1")
  inspect(lowbit(4), content="4")
  inspect(lowbit(6), content="2")
  inspect(lowbit(8), content="8")
}

///|
test "fenwick tree large updates" {
  let ft = FenwickTree::new(10)

  // Add large values
  for i in 0..<10 {
    ft.add(i, 1000000000L)
  }
  inspect(ft.prefix_sum(9), content="10000000000")
}

///|
test "fenwick tree boundary" {
  let ft = FenwickTree::new(5)
  ft.add(0, 1L)
  ft.add(4, 5L)
  inspect(ft.prefix_sum(-1), content="0")
  inspect(ft.prefix_sum(0), content="1")
  inspect(ft.prefix_sum(4), content="6")
  inspect(ft.prefix_sum(10), content="6") // Beyond bounds returns total
}
