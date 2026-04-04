// ============================================================================
// 2D FENWICK TREE (Binary Indexed Tree) - 2D Prefix Sums and Updates
// ============================================================================
//
// A 2D Fenwick Tree extends the 1D version to efficiently handle:
// - Point updates:  add value at position (r, c)                O(log n * log m)
// - Prefix queries: sum of rectangle [(1,1), (r,c)]             O(log n * log m)
// - Range queries:  sum of rectangle [(r1,c1), (r2,c2)]         O(log n * log m)
//
// KEY INSIGHT: We apply the 1D Fenwick tree concept in both dimensions.
// For each row position managed by the row lowbit chain, there is an
// independent 1D Fenwick tree managing the column axis.
//
// STRUCTURE:
// - tree is (rows+1) x (cols+1); index 0 in each axis is unused.
// - tree[i][j] stores a partial sum for the sub-rectangle:
//     rows (i - lowbit(i), i]   x   cols (j - lowbit(j), j]
//
// TRAVERSAL:
// - Update  (r, c): climb   i += lowbit(i),  j += lowbit(j)  until out of bounds
// - Query   (r, c): descend i -= lowbit(i),  j -= lowbit(j)  until i or j <= 0
//
// SPACE: O(n * m)

///|
/// A 2D Fenwick Tree (Binary Indexed Tree) for efficient point updates and
/// rectangle prefix-sum queries on a grid of `Int64` values.
///
/// All public methods use **1-indexed** coordinates: valid row indices are
/// `1..rows` and valid column indices are `1..cols`.
///
/// ## Invariant
///
/// `tree[i][j]` holds the sum of all `arr[x][y]` where
/// `x` is in `(i - lowbit(i), i]` and `y` is in `(j - lowbit(j), j]`.
/// Here `lowbit(k) = k & (-k)` isolates the lowest set bit of `k`.
pub struct Fenwick2D {
  tree : Array[Array[Int64]]
  rows : Int
  cols : Int
}

///|
/// Create a new `Fenwick2D` for a grid with the given number of `rows` and
/// `cols`. All cells are initialised to zero. Both dimensions must be
/// positive; the internal storage is `(rows+1) x (cols+1)` to support
/// 1-indexed access without an offset calculation at every call site.
///
/// ```moonbit
/// let fw = Fenwick2D::new(4, 6)
/// assert_eq!(fw.get_rows(), 4)
/// assert_eq!(fw.get_cols(), 6)
/// ```
pub fn Fenwick2D::new(rows : Int, cols : Int) -> Fenwick2D {
  // Use 1-indexed arrays (index 0 unused)
  let tree : Array[Array[Int64]] = []
  for _ in 0..<=rows {
    tree.push(Array::make(cols + 1, 0L))
  }
  { tree, rows, cols }
}

///|
/// Return the value of the lowest set bit of `x` (i.e. `x & -x`).
///
/// This is the fundamental primitive of the Fenwick Tree: it determines how
/// many elements a tree node is responsible for, and drives both the climb
/// (update) and descent (query) traversals.
///
/// Examples: `lowbit(1)=1`, `lowbit(2)=2`, `lowbit(3)=1`, `lowbit(4)=4`,
/// `lowbit(6)=2`, `lowbit(8)=8`.
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
/// Add `delta` to cell `(x, y)` (1-indexed).
///
/// Propagates the change to every `tree[i][j]` whose sub-rectangle contains
/// `(x, y)`. The row index `i` climbs via `i += lowbit(i)`, and for each
/// such `i` the column index `j` climbs via `j += lowbit(j)`. At most
/// `ceil(log2(rows)) x ceil(log2(cols))` cells are touched.
///
/// Coordinates outside `[1..rows] x [1..cols]` are silently ignored.
///
/// ```moonbit
/// let fw = Fenwick2D::new(3, 3)
/// fw.update(2, 2, 10L)
/// assert_eq!(fw.get(2, 2), 10L)
/// ```
pub fn Fenwick2D::update(
  self : Fenwick2D,
  x : Int,
  y : Int,
  delta : Int64,
) -> Unit {
  if x <= 0 || x > self.rows || y <= 0 || y > self.cols {
    return
  }
  for i = x {
    if i > self.rows {
      break
    } else {
      for j = y {
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
/// Return the prefix sum over all cells in `[1..x][1..y]` (1-indexed).
///
/// The row index `i` descends via `i -= lowbit(i)`, and for each `i` the
/// column index `j` descends via `j -= lowbit(j)`. The collected sub-rectangles
/// are disjoint and together tile `[1..x][1..y]` exactly.
///
/// - Returns `0` when `x <= 0` or `y <= 0`.
/// - Values of `x > rows` or `y > cols` are clamped to the grid boundary.
///
/// ```moonbit
/// let fw = Fenwick2D::new(3, 3)
/// fw.update(1, 1, 3L)
/// fw.update(2, 2, 7L)
/// assert_eq!(fw.prefix_sum(2, 2), 10L)
/// assert_eq!(fw.prefix_sum(0, 2), 0L)
/// ```
pub fn Fenwick2D::prefix_sum(self : Fenwick2D, x : Int, y : Int) -> Int64 {
  if x <= 0 || y <= 0 {
    return 0L
  }
  let x_clamped = if x > self.rows { self.rows } else { x }
  let y_clamped = if y > self.cols { self.cols } else { y }
  for i = x_clamped, sum = 0L {
    if i <= 0 {
      break sum
    } else {
      let row_sum = for j = y_clamped, acc = 0L {
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
/// Return the sum of all cells in the rectangle `[x1..x2][y1..y2]`
/// (both endpoints inclusive, 1-indexed).
///
/// Uses the inclusion-exclusion identity over four prefix sums:
///
/// ```
/// range_sum(x1,y1,x2,y2)
///   = prefix(x2,  y2 )
///   - prefix(x1-1,y2 )
///   - prefix(x2,  y1-1)
///   + prefix(x1-1,y1-1)
/// ```
///
/// Returns `0` when `x1 > x2` or `y1 > y2` (empty rectangle).
///
/// ```moonbit
/// let fw = Fenwick2D::new(3, 3)
/// fw.update(2, 2, 5L)
/// fw.update(3, 3, 3L)
/// assert_eq!(fw.range_sum(2, 2, 3, 3), 8L)
/// assert_eq!(fw.range_sum(1, 1, 1, 1), 0L)
/// ```
pub fn Fenwick2D::range_sum(
  self : Fenwick2D,
  x1 : Int,
  y1 : Int,
  x2 : Int,
  y2 : Int,
) -> Int64 {
  if x1 > x2 || y1 > y2 {
    return 0L
  }
  self.prefix_sum(x2, y2) -
  self.prefix_sum(x1 - 1, y2) -
  self.prefix_sum(x2, y1 - 1) +
  self.prefix_sum(x1 - 1, y1 - 1)
}

///|
/// Replace the value at cell `(x, y)` (1-indexed) with `new_val`.
///
/// The caller must supply the cell's current value as `old_val`. Internally
/// this calls `update(x, y, new_val - old_val)`, so its complexity is the
/// same as `update`: O(log rows x log cols).
///
/// If the old value is unknown, use `get(x, y)` first (at the same cost).
///
/// ```moonbit
/// let fw = Fenwick2D::new(3, 3)
/// fw.update(1, 1, 7L)
/// fw.set(1, 1, 7L, 10L)
/// assert_eq!(fw.get(1, 1), 10L)
/// ```
pub fn Fenwick2D::set(
  self : Fenwick2D,
  x : Int,
  y : Int,
  old_val : Int64,
  new_val : Int64,
) -> Unit {
  self.update(x, y, new_val - old_val)
}

///|
/// Return the value stored at cell `(x, y)` (1-indexed).
///
/// Implemented as `range_sum(x, y, x, y)` (four prefix-sum queries), so
/// it runs in O(log rows x log cols) -- slower than direct array access but
/// consistent with the tree's internal representation where no single cell
/// holds its own value directly.
///
/// Returns `0` for coordinates outside `[1..rows] x [1..cols]`.
///
/// ```moonbit
/// let fw = Fenwick2D::new(3, 3)
/// fw.update(2, 3, 42L)
/// assert_eq!(fw.get(2, 3), 42L)
/// assert_eq!(fw.get(1, 1), 0L)
/// ```
pub fn Fenwick2D::get(self : Fenwick2D, x : Int, y : Int) -> Int64 {
  self.range_sum(x, y, x, y)
}

///|
/// Return number of rows in the grid.
pub fn Fenwick2D::get_rows(self : Fenwick2D) -> Int {
  self.rows
}

///|
/// Return number of columns in the grid.
pub fn Fenwick2D::get_cols(self : Fenwick2D) -> Int {
  self.cols
}

// ============================================================================
// 2D FENWICK TREE WITH RANGE UPDATE
// ============================================================================
//
// To support range updates efficiently, we use a different approach:
// Instead of storing values directly, we store differences.
//
// For range add on [(x1,y1), (x2,y2)] by delta:
// We update 4 corners using inclusion-exclusion in the difference array.

///|
/// 2D Fenwick Tree supporting range updates and point queries
priv struct Fenwick2DRange {
  tree : Array[Array[Int64]]
  rows : Int
  cols : Int
}

///|
fn Fenwick2DRange::new(rows : Int, cols : Int) -> Fenwick2DRange {
  let tree : Array[Array[Int64]] = []
  for _ in 0..<=rows {
    tree.push(Array::make(cols + 1, 0L))
  }
  { tree, rows, cols }
}

///|
/// Internal update (same as Fenwick2D::update)
fn Fenwick2DRange::internal_update(
  self : Fenwick2DRange,
  x : Int,
  y : Int,
  delta : Int64,
) -> Unit {
  if x <= 0 || x > self.rows || y <= 0 || y > self.cols {
    return
  }
  for i = x {
    if i > self.rows {
      break
    } else {
      for j = y {
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
/// Internal prefix sum (same as Fenwick2D::prefix_sum)
fn Fenwick2DRange::internal_prefix(
  self : Fenwick2DRange,
  x : Int,
  y : Int,
) -> Int64 {
  if x <= 0 || y <= 0 {
    return 0L
  }
  let x_clamped = if x > self.rows { self.rows } else { x }
  let y_clamped = if y > self.cols { self.cols } else { y }
  for i = x_clamped, sum = 0L {
    if i <= 0 {
      break sum
    } else {
      let row_sum = for j = y_clamped, acc = 0L {
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
/// Add delta to all elements in range [(x1,y1), (x2,y2)]
/// Uses 2D difference array technique:
/// update(x1, y1, +delta), update(x1, y2+1, -delta),
/// update(x2+1, y1, -delta), update(x2+1, y2+1, +delta)
fn Fenwick2DRange::range_add(
  self : Fenwick2DRange,
  x1 : Int,
  y1 : Int,
  x2 : Int,
  y2 : Int,
  delta : Int64,
) -> Unit {
  if x1 > x2 || y1 > y2 {
    return
  }
  self.internal_update(x1, y1, delta)
  self.internal_update(x1, y2 + 1, -delta)
  self.internal_update(x2 + 1, y1, -delta)
  self.internal_update(x2 + 1, y2 + 1, delta)
}

///|
/// Query value at position (x, y)
/// The prefix sum of the difference array gives the actual value
fn Fenwick2DRange::query(self : Fenwick2DRange, x : Int, y : Int) -> Int64 {
  self.internal_prefix(x, y)
}

///|
fn Fenwick2DRange::get_rows(self : Fenwick2DRange) -> Int {
  self.rows
}

///|
fn Fenwick2DRange::get_cols(self : Fenwick2DRange) -> Int {
  self.cols
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "fenwick2d basic" {
  let ft = Fenwick2D::new(4, 4)

  // Set some values
  ft.update(1, 1, 1L)
  ft.update(1, 2, 2L)
  ft.update(2, 1, 3L)
  ft.update(2, 2, 4L)

  // Prefix sums
  inspect(ft.prefix_sum(1, 1), content="1")
  inspect(ft.prefix_sum(1, 2), content="3") // 1 + 2
  inspect(ft.prefix_sum(2, 1), content="4") // 1 + 3
  inspect(ft.prefix_sum(2, 2), content="10") // 1 + 2 + 3 + 4
}

///|
test "fenwick2d range sum" {
  let ft = Fenwick2D::new(4, 4)

  // Create 2x2 grid:
  // 1 2
  // 3 4
  ft.update(1, 1, 1L)
  ft.update(1, 2, 2L)
  ft.update(2, 1, 3L)
  ft.update(2, 2, 4L)

  // Range queries
  inspect(ft.range_sum(1, 1, 1, 1), content="1")
  inspect(ft.range_sum(1, 1, 1, 2), content="3") // row 1
  inspect(ft.range_sum(1, 1, 2, 1), content="4") // col 1
  inspect(ft.range_sum(2, 2, 2, 2), content="4") // single element
  inspect(ft.range_sum(1, 2, 2, 2), content="6") // right column: 2 + 4
}

///|
test "fenwick2d get" {
  let ft = Fenwick2D::new(3, 3)
  ft.update(1, 1, 5L)
  ft.update(2, 2, 10L)
  ft.update(3, 3, 15L)
  inspect(ft.get(1, 1), content="5")
  inspect(ft.get(2, 2), content="10")
  inspect(ft.get(3, 3), content="15")
  inspect(ft.get(1, 2), content="0") // empty cell
}

///|
test "fenwick2d update multiple times" {
  let ft = Fenwick2D::new(3, 3)
  ft.update(1, 1, 5L)
  inspect(ft.get(1, 1), content="5")
  ft.update(1, 1, 3L)
  inspect(ft.get(1, 1), content="8") // 5 + 3
  ft.update(1, 1, -2L)
  inspect(ft.get(1, 1), content="6") // 8 - 2

  // Test set function
  ft.set(1, 1, 6L, 10L) // old value 6, new value 10
  inspect(ft.get(1, 1), content="10")
}

///|
test "fenwick2d larger grid" {
  let ft = Fenwick2D::new(5, 5)

  // Fill diagonal
  for i in 1..<=5 {
    ft.update(i, i, i.to_int64())
  }

  // Sum of diagonal: 1 + 2 + 3 + 4 + 5 = 15
  inspect(ft.prefix_sum(5, 5), content="15")

  // Sum excluding first row and column
  inspect(ft.range_sum(2, 2, 5, 5), content="14") // 2 + 3 + 4 + 5
}

///|
test "fenwick2d range update basic" {
  let ft = Fenwick2DRange::new(4, 4)

  // Add 5 to rectangle [(1,1), (2,2)]
  ft.range_add(1, 1, 2, 2, 5L)
  inspect(ft.query(1, 1), content="5")
  inspect(ft.query(1, 2), content="5")
  inspect(ft.query(2, 1), content="5")
  inspect(ft.query(2, 2), content="5")
  inspect(ft.query(3, 3), content="0") // outside range
}

///|
test "fenwick2d range update overlapping" {
  let ft = Fenwick2DRange::new(4, 4)

  // Add 5 to [(1,1), (2,2)]
  ft.range_add(1, 1, 2, 2, 5L)

  // Add 3 to [(2,2), (3,3)]
  ft.range_add(2, 2, 3, 3, 3L)
  inspect(ft.query(1, 1), content="5")
  inspect(ft.query(2, 2), content="8") // 5 + 3 (overlap)
  inspect(ft.query(3, 3), content="3")
  inspect(ft.query(1, 3), content="0")
}

///|
test "fenwick2d empty" {
  let ft = Fenwick2D::new(3, 3)
  inspect(ft.prefix_sum(3, 3), content="0")
  inspect(ft.range_sum(1, 1, 3, 3), content="0")
  inspect(ft.get(2, 2), content="0")
}

///|
test "fenwick2d boundary" {
  let ft = Fenwick2D::new(3, 3)
  ft.update(3, 3, 100L)
  inspect(ft.prefix_sum(3, 3), content="100")
  inspect(ft.prefix_sum(2, 3), content="0")
  inspect(ft.prefix_sum(3, 2), content="0")

  // Out of bounds queries should handle gracefully
  inspect(ft.prefix_sum(0, 0), content="0")
  inspect(ft.prefix_sum(5, 5), content="100") // clamped to bounds
}

///|
test "fenwick2d dimensions" {
  let ft = Fenwick2D::new(10, 20)
  inspect(ft.get_rows(), content="10")
  inspect(ft.get_cols(), content="20")
}

///|
test "fenwick2d range dimensions" {
  let ft = Fenwick2DRange::new(15, 25)
  inspect(ft.get_rows(), content="15")
  inspect(ft.get_cols(), content="25")
}
