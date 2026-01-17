// ============================================================================
// 2D FENWICK TREE (Binary Indexed Tree) - 2D Prefix Sums and Updates
// ============================================================================
//
// A 2D Fenwick Tree extends the 1D version to efficiently handle:
// - Point updates: add value at position (x, y)
// - Prefix queries: sum of rectangle [(0,0), (x,y)]
// - Range queries: sum of rectangle [(x1,y1), (x2,y2)] using inclusion-exclusion
//
// KEY INSIGHT: We apply the 1D Fenwick tree concept in both dimensions.
// For each row position managed by 1D Fenwick logic, we have another
// 1D Fenwick tree managing columns.
//
// STRUCTURE:
// - tree[i][j] stores partial sum contribution for position (i,j)
// - i manages row aggregation using lowbit(i) = i & (-i)
// - j manages column aggregation using lowbit(j) = j & (-j)
//
// INVARIANT (2D extension of 1D):
// tree[i][j] = sum of arr[x][y] where:
//   x in (i - lowbit(i), i]
//   y in (j - lowbit(j), j]
//
// OPERATIONS:
// - Point update: O(log n * log m)
// - Prefix query: O(log n * log m)
// - Range query: O(log n * log m) using 4 prefix queries
//
// SPACE: O(n * m)

///|
/// 2D Fenwick Tree for prefix sums
pub struct Fenwick2D {
  tree : Array[Array[Int64]]
  rows : Int
  cols : Int
}

///|
/// Create a 2D Fenwick tree for rows x cols grid (1-indexed operations).
pub fn Fenwick2D::new(rows : Int, cols : Int) -> Fenwick2D {
  // Use 1-indexed arrays (index 0 unused)
  let tree : Array[Array[Int64]] = []
  for _ in 0..<=rows {
    tree.push(Array::make(cols + 1, 0L))
  }
  { tree, rows, cols }
}

///|
/// Get lowest set bit
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
/// Add delta to position (x, y) (1-indexed)
/// REASONING: We update all positions that "cover" (x, y) in both dimensions.
/// In row dimension: positions x, x + lowbit(x), x + lowbit(x + lowbit(x)), ...
/// In col dimension: same pattern for y
pub fn Fenwick2D::update(
  self : Fenwick2D,
  x : Int,
  y : Int,
  delta : Int64,
) -> Unit {
  if x <= 0 || x > self.rows || y <= 0 || y > self.cols {
    return
  }
  loop x {
    i => {
      if i > self.rows {
        break ()
      }
      loop y {
        j => {
          if j > self.cols {
            break ()
          }
          self.tree[i][j] = self.tree[i][j] + delta
          continue j + lowbit(j)
        }
      }
      continue i + lowbit(i)
    }
  }
}

///|
/// Query prefix sum: sum of [(1,1), (x,y)]
/// REASONING: We collect contributions from all positions that
/// contribute to the prefix sum in both dimensions.
pub fn Fenwick2D::prefix_sum(self : Fenwick2D, x : Int, y : Int) -> Int64 {
  if x <= 0 || y <= 0 {
    return 0L
  }
  let x_clamped = if x > self.rows { self.rows } else { x }
  let y_clamped = if y > self.cols { self.cols } else { y }
  loop (x_clamped, 0L) {
    (i, sum) => {
      if i <= 0 {
        break sum
      }
      let row_sum = loop (y_clamped, 0L) {
        (j, acc) => {
          if j <= 0 {
            break acc
          }
          continue (j - lowbit(j), acc + self.tree[i][j])
        }
      }
      continue (i - lowbit(i), sum + row_sum)
    }
  }
}

///|
/// Query range sum: sum of [(x1,y1), (x2,y2)] (inclusive)
/// Using inclusion-exclusion principle:
/// sum(x1,y1,x2,y2) = prefix(x2,y2) - prefix(x1-1,y2) - prefix(x2,y1-1) + prefix(x1-1,y1-1)
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
/// Set value at position (x, y) (1-indexed)
/// Requires knowing the current value
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
/// Get value at single position (x, y)
/// This is less efficient than point query in regular array
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
  loop x {
    i => {
      if i > self.rows {
        break ()
      }
      loop y {
        j => {
          if j > self.cols {
            break ()
          }
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
  loop (x_clamped, 0L) {
    (i, sum) => {
      if i <= 0 {
        break sum
      }
      let row_sum = loop (y_clamped, 0L) {
        (j, acc) => {
          if j <= 0 {
            break acc
          }
          continue (j - lowbit(j), acc + self.tree[i][j])
        }
      }
      continue (i - lowbit(i), sum + row_sum)
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
  for i in 1 ..<= 5 {
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
