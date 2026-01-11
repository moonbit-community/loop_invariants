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
/// Fenwick Tree for sum queries
priv struct FenwickTree {
  n : Int
  tree : Array[Int64]
}

///|
/// Create a new Fenwick Tree with n elements (all initialized to 0)
fn FenwickTree::new(n : Int) -> FenwickTree {
  // 1-indexed, so we need n+1 elements
  { n, tree: Array::make(n + 1, 0L) }
}

///|
/// Build Fenwick Tree from an existing array
/// TIME: O(n) using the propagation method
///
/// INVARIANT: After processing index i, tree[i] contains correct partial sum.
/// Each index propagates its value to index i + lowbit(i).
/// REASONING: Parent index > current index ensures no revisits, O(n) total.
fn FenwickTree::from_array(arr : Array[Int64]) -> FenwickTree {
  let n = arr.length()
  let tree = Array::make(n + 1, 0L)

  // Copy array values (convert to 1-indexed)
  for i = 0; i < n; i = i + 1 {
    tree[i + 1] = arr[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|tree[1..i] equals arr[0..i) in 1-indexed form.
    ),
  }

  // Build tree in O(n) by propagating each element to its parent
  for i = 1; i <= n; i = i + 1 {
    let parent = i + (i & -i)
    if parent <= n {
      tree[parent] = tree[parent] + tree[i]
    }
  } where {
    invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|INVARIANT (build BIT):
      #|tree[1..i) already holds the correct partial sums for their ranges.
      #|MAINTENANCE:
      #|Compute parent = i + lowbit(i) and add tree[i] to tree[parent], which
      #|extends the parent's covered range. Since parent > i, tree[i] is final.
      #|TERMINATION:
      #|At i = n + 1, every tree[j] stores the sum of its lowbit range.
    ),
  }
  { n, tree }
}

///|
/// Get lowest set bit (isolate rightmost 1)
/// lowbit(6) = lowbit(110₂) = 2 = 10₂
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
/// Add delta to element at index i (0-indexed)
/// TIME: O(log n)
///
/// INVARIANT: idx covers all tree nodes responsible for index i+1.
/// REASONING: idx increases by at least 1 each step (lowbit >= 1), terminates when > n.
fn FenwickTree::add(self : FenwickTree, i : Int, delta : Int64) -> Unit {
  if i < 0 || i >= self.n {
    return
  }

  // Convert to 1-indexed
  let mut idx = i + 1
  while idx <= self.n {
    self.tree[idx] = self.tree[idx] + delta
    idx = idx + lowbit(idx)
  }
}

///|
/// Query prefix sum [0, i] (inclusive, 0-indexed)
/// Returns sum of elements arr[0] + arr[1] + ... + arr[i]
/// TIME: O(log n)
///
/// INVARIANT: sum accumulates prefix sums from tree nodes.
/// REASONING: idx decreases by at least 1 each step (lowbit >= 1), terminates at 0.
fn FenwickTree::prefix_sum(self : FenwickTree, i : Int) -> Int64 {
  if i < 0 {
    return 0L
  }

  // Convert to 1-indexed and clamp
  let idx_start = if i >= self.n { self.n } else { i + 1 }
  for idx = idx_start, sum = 0L; idx > 0; {
    continue idx - lowbit(idx), sum + self.tree[idx]
  } else {
    sum
  } where {
    invariant: idx >= 0 && idx <= idx_start,
    reasoning: (
      #|sum accumulates tree nodes already visited along the BIT path from
      #|idx_start down to idx; the remaining idx positions still cover the
      #|unaccounted prefix ranges.
    ),
  }
}

///|
/// Query range sum [l, r] (inclusive, 0-indexed)
fn FenwickTree::range_sum(self : FenwickTree, l : Int, r : Int) -> Int64 {
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
/// Get single element value at index i
fn FenwickTree::get(self : FenwickTree, i : Int) -> Int64 {
  self.range_sum(i, i)
}

///|
/// Set element at index i to value
fn FenwickTree::set(self : FenwickTree, i : Int, value : Int64) -> Unit {
  let current = self.get(i)
  self.add(i, value - current)
}

///|
fn FenwickTree::length(self : FenwickTree) -> Int {
  self.n
}

// ============================================================================
// 2D FENWICK TREE
// ============================================================================

///|
/// 2D Fenwick Tree for rectangle sum queries
priv struct FenwickTree2D {
  rows : Int
  cols : Int
  tree : Array[Array[Int64]]
}

///|
fn FenwickTree2D::new(rows : Int, cols : Int) -> FenwickTree2D {
  let tree : Array[Array[Int64]] = []
  for i = 0; i <= rows; i = i + 1 {
    tree.push(Array::make(cols + 1, 0L))
  } where {
    invariant: i >= 0 && i <= rows + 1,
    reasoning: (
      #|tree has been allocated for rows 0..i) with cols+1 entries each.
    ),
  }
  { rows, cols, tree }
}

///|
/// Add delta to cell (r, c) (0-indexed)
fn FenwickTree2D::add(
  self : FenwickTree2D,
  r : Int,
  c : Int,
  delta : Int64,
) -> Unit {
  if r < 0 || r >= self.rows || c < 0 || c >= self.cols {
    return
  }
  let mut i = r + 1
  while i <= self.rows {
    let mut j = c + 1
    while j <= self.cols {
      self.tree[i][j] = self.tree[i][j] + delta
      j = j + lowbit(j)
    }
    i = i + lowbit(i)
  }
}

///|
/// Query sum of rectangle [0, 0] to [r, c] (inclusive, 0-indexed)
fn FenwickTree2D::prefix_sum(self : FenwickTree2D, r : Int, c : Int) -> Int64 {
  if r < 0 || c < 0 {
    return 0L
  }
  let ri = if r >= self.rows { self.rows } else { r + 1 }
  let ci = if c >= self.cols { self.cols } else { c + 1 }
  let mut sum = 0L
  let mut i = ri
  while i > 0 {
    let mut j = ci
    while j > 0 {
      sum = sum + self.tree[i][j]
      j = j - lowbit(j)
    }
    i = i - lowbit(i)
  }
  sum
}

///|
/// Query sum of rectangle [r1, c1] to [r2, c2] (inclusive, 0-indexed)
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
/// Fenwick Tree variant that supports range updates and point queries
/// Uses difference array technique
priv struct FenwickTreeRangeUpdate {
  n : Int
  tree : Array[Int64] // Stores differences
}

///|
fn FenwickTreeRangeUpdate::new(n : Int) -> FenwickTreeRangeUpdate {
  { n, tree: Array::make(n + 1, 0L) }
}

///|
/// Internal: add delta at index
fn FenwickTreeRangeUpdate::point_add(
  self : FenwickTreeRangeUpdate,
  i : Int,
  delta : Int64,
) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  let mut idx = i + 1
  while idx <= self.n {
    self.tree[idx] = self.tree[idx] + delta
    idx = idx + lowbit(idx)
  }
}

///|
/// Add delta to range [l, r] (inclusive, 0-indexed)
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
/// Query value at index i (0-indexed)
fn FenwickTreeRangeUpdate::query(
  self : FenwickTreeRangeUpdate,
  i : Int,
) -> Int64 {
  if i < 0 || i >= self.n {
    return 0L
  }
  let mut idx = i + 1
  let mut sum = 0L
  while idx > 0 {
    sum = sum + self.tree[idx]
    idx = idx - lowbit(idx)
  }
  sum
}

// ============================================================================
// FENWICK TREE FOR RANGE UPDATE + RANGE QUERY
// ============================================================================

///|
/// Fenwick Tree that supports both range updates and range queries
/// Uses two BITs to track coefficients
priv struct FenwickTreeRangeRange {
  n : Int
  bit1 : Array[Int64] // Coefficient for (i+1) term
  bit2 : Array[Int64] // Constant term
}

///|
fn FenwickTreeRangeRange::new(n : Int) -> FenwickTreeRangeRange {
  { n, bit1: Array::make(n + 1, 0L), bit2: Array::make(n + 1, 0L) }
}

///|
fn add_internal(arr : Array[Int64], n : Int, i : Int, delta : Int64) -> Unit {
  let mut idx = i
  while idx <= n {
    arr[idx] = arr[idx] + delta
    idx = idx + lowbit(idx)
  }
}

///|
fn query_internal(arr : Array[Int64], i : Int) -> Int64 {
  let mut idx = i
  let mut sum = 0L
  while idx > 0 {
    sum = sum + arr[idx]
    idx = idx - lowbit(idx)
  }
  sum
}

///|
/// Add delta to range [l, r] (inclusive, 0-indexed)
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
/// Query prefix sum [0, i] (inclusive, 0-indexed)
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
/// Query range sum [l, r] (inclusive, 0-indexed)
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
