// ============================================================================
// SPARSE TABLE - O(1) Range Minimum Queries
// ============================================================================
//
// Sparse Table answers range minimum/maximum queries in O(1) after
// O(n log n) preprocessing. Uses the idempotent property of min/max.
//
// KEY INSIGHT: For idempotent operations (min, max, gcd), overlapping
// ranges give correct answers. Query [l, r] = op(table[l][k], table[r-2^k+1][k])
// where 2^k is the largest power of 2 ≤ r-l+1.
//
// STRUCTURE:
// table[i][j] = op of elements from i to i + 2^j - 1
//
// BUILDING:
// table[i][0] = arr[i]
// table[i][j] = op(table[i][j-1], table[i + 2^(j-1)][j-1])
//
// QUERYING:
// query(l, r): k = log2(r - l + 1)
//              return op(table[l][k], table[r - 2^k + 1][k])
//
// INVARIANTS:
// 1. table[i][j] correctly stores op of range [i, i + 2^j - 1]
// 2. Two ranges of length 2^k cover any range [l, r] where 2^k ≤ r-l+1 < 2^(k+1)
// 3. Idempotency ensures overlapping doesn't affect result
//
// TIME COMPLEXITY: O(n log n) build, O(1) query
// SPACE COMPLEXITY: O(n log n)

///|
/// A sparse table for O(1) range minimum queries over a static array of Int64.
///
/// The table precomputes minimums over all power-of-2-length intervals during
/// construction (O(n log n) time and space). After construction the array must
/// not change; no updates are supported.
///
/// Fields:
/// - `table`: 2-D array where `table[i][j]` holds the minimum of the subarray
///   `[i, i + 2^j - 1]`.
/// - `log_table`: precomputed floor-log2 values; `log_table[x] = floor(log2(x))`.
/// - `n`: number of elements in the original array.
pub struct SparseTableMin {
  table : Array[Array[Int64]]
  log_table : Array[Int]
  n : Int
}

///|
/// Build a sparse table over `arr` for range minimum queries.
///
/// Parameters:
/// - `arr`: the static input array of `Int64` values.
///
/// Returns a `SparseTableMin` that can answer any range-minimum query in O(1).
///
/// Time complexity: O(n log n) where n = `arr.length()`.
/// Space complexity: O(n log n).
pub fn SparseTableMin::SparseTableMin(arr : Array[Int64]) -> SparseTableMin {
  let n = arr.length()
  if n == 0 {
    return { table: [], log_table: [], n: 0 }
  }

  // Precompute log values
  let log_table = Array::make(n + 1, 0)
  for i in 2..<=n {
    log_table[i] = log_table[i / 2] + 1
  }
  let k = log_table[n] + 1
  let table = [
    for i in 0..<n => {
      let row = Array::make(k, 0L)
      row[0] = arr[i]
      row
    }
  ]

  // Build sparse table
  for j in 1..<k {
    let len = 1 << j // 2^j
    for i in 0..<(n - len + 1) {
      let left = table[i][j - 1]
      let right = table[i + (1 << (j - 1))][j - 1]
      table[i][j] = if left < right { left } else { right }
    }
  }
  { table, log_table, n }
}

///|
/// Return the minimum value in the inclusive range `[l, r]`.
///
/// The query is answered in O(1) by combining two precomputed intervals of
/// length `2^k` (the largest power of two that fits in `r - l + 1`). Because
/// `min` is idempotent, overlapping intervals produce the correct result.
///
/// Parameters:
/// - `self`: the sparse table built by `SparseTableMin::new`.
/// - `l`: left index of the query range (inclusive, 0-based).
/// - `r`: right index of the query range (inclusive, 0-based).
///
/// Returns the minimum element in `arr[l..=r]`, or `Int64::max_value`
/// (`9223372036854775807`) if the range is empty or out of bounds.
///
/// Time complexity: O(1).
pub fn SparseTableMin::query(self : SparseTableMin, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return 9223372036854775807L // INT64_MAX
  }
  let len = r - l + 1
  let k = self.log_table[len]
  let left = self.table[l][k]
  let right = self.table[r - (1 << k) + 1][k]
  if left < right {
    left
  } else {
    right
  }
}

// ============================================================================
// SPARSE TABLE FOR MAXIMUM
// ============================================================================

///|
/// A sparse table for O(1) range maximum queries over a static array of Int64.
///
/// Mirrors `SparseTableMin` but uses the `max` operator. The same idempotency
/// property guarantees correctness when two intervals overlap during a query.
///
/// Fields:
/// - `table`: 2-D array where `table[i][j]` holds the maximum of the subarray
///   `[i, i + 2^j - 1]`.
/// - `log_table`: precomputed floor-log2 values.
/// - `n`: number of elements in the original array.
priv struct SparseTableMax {
  table : Array[Array[Int64]]
  log_table : Array[Int]
  n : Int
}

///|
/// Build a sparse table over `arr` for range maximum queries.
///
/// Parameters:
/// - `arr`: the static input array of `Int64` values.
///
/// Returns a `SparseTableMax` that can answer any range-maximum query in O(1).
///
/// Time complexity: O(n log n) where n = `arr.length()`.
/// Space complexity: O(n log n).
fn SparseTableMax::SparseTableMax(arr : Array[Int64]) -> SparseTableMax {
  let n = arr.length()
  if n == 0 {
    return { table: [], log_table: [], n: 0 }
  }
  let log_table = Array::make(n + 1, 0)
  for i in 2..<=n {
    log_table[i] = log_table[i / 2] + 1
  }
  let k = log_table[n] + 1
  let table = [
    for i in 0..<n => {
      let row = Array::make(k, 0L)
      row[0] = arr[i]
      row
    }
  ]
  for j in 1..<k {
    let len = 1 << j
    for i in 0..<(n - len + 1) {
      let left = table[i][j - 1]
      let right = table[i + (1 << (j - 1))][j - 1]
      table[i][j] = if left > right { left } else { right }
    }
  }
  { table, log_table, n }
}

///|
/// Return the maximum value in the inclusive range `[l, r]`.
///
/// Parameters:
/// - `self`: the sparse table built by `SparseTableMax::new`.
/// - `l`: left index of the query range (inclusive, 0-based).
/// - `r`: right index of the query range (inclusive, 0-based).
///
/// Returns the maximum element in `arr[l..=r]`, or `Int64::min_value`
/// (`-9223372036854775808`) if the range is empty or out of bounds.
///
/// Time complexity: O(1).
fn SparseTableMax::query(self : SparseTableMax, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return -9223372036854775808L // INT64_MIN
  }
  let len = r - l + 1
  let k = self.log_table[len]
  let left = self.table[l][k]
  let right = self.table[r - (1 << k) + 1][k]
  if left > right {
    left
  } else {
    right
  }
}

// ============================================================================
// SPARSE TABLE FOR GCD (also idempotent)
// ============================================================================

///|
/// Compute the greatest common divisor of two `Int64` values using the
/// Euclidean algorithm.
///
/// Parameters:
/// - `a`: first operand (sign is ignored; the result is always non-negative).
/// - `b`: second operand.
///
/// Returns `gcd(|a|, |b|)`. Returns `0` when both inputs are `0`.
///
/// Time complexity: O(log(min(|a|, |b|))).
fn gcd(a : Int64, b : Int64) -> Int64 {
  for x = (if a < 0L { -a } else { a }), y = (if b < 0L { -b } else { b }) {
    if y != 0L {
      continue y, x % y
    } else {
      break x
    }
  }
}

///|
/// A sparse table for O(1) range GCD queries over a static array of Int64.
///
/// GCD is idempotent (`gcd(x, x) = x`), so two overlapping intervals of the
/// same length always yield the correct GCD for any sub-range.
///
/// Fields:
/// - `table`: 2-D array where `table[i][j]` holds the GCD of the subarray
///   `[i, i + 2^j - 1]`.
/// - `log_table`: precomputed floor-log2 values.
/// - `n`: number of elements in the original array.
priv struct SparseTableGCD {
  table : Array[Array[Int64]]
  log_table : Array[Int]
  n : Int
}

///|
/// Build a sparse table over `arr` for range GCD queries.
///
/// Parameters:
/// - `arr`: the static input array of `Int64` values.
///
/// Returns a `SparseTableGCD` that can answer any range-GCD query in O(1).
///
/// Time complexity: O(n log n) where n = `arr.length()`.
/// Space complexity: O(n log n).
fn SparseTableGCD::SparseTableGCD(arr : Array[Int64]) -> SparseTableGCD {
  let n = arr.length()
  if n == 0 {
    return { table: [], log_table: [], n: 0 }
  }
  let log_table = Array::make(n + 1, 0)
  for i in 2..<=n {
    log_table[i] = log_table[i / 2] + 1
  }
  let k = log_table[n] + 1
  let table = [
    for i in 0..<n => {
      let row = Array::make(k, 0L)
      row[0] = arr[i]
      row
    }
  ]
  for j in 1..<k {
    let len = 1 << j
    for i in 0..<(n - len + 1) {
      table[i][j] = gcd(table[i][j - 1], table[i + (1 << (j - 1))][j - 1])
    }
  }
  { table, log_table, n }
}

///|
/// Return the GCD of all elements in the inclusive range `[l, r]`.
///
/// Parameters:
/// - `self`: the sparse table built by `SparseTableGCD::new`.
/// - `l`: left index of the query range (inclusive, 0-based).
/// - `r`: right index of the query range (inclusive, 0-based).
///
/// Returns `gcd(arr[l], arr[l+1], ..., arr[r])`, or `0` if the range is
/// empty or out of bounds.
///
/// Time complexity: O(1).
fn SparseTableGCD::query(self : SparseTableGCD, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return 0L
  }
  let len = r - l + 1
  let k = self.log_table[len]
  gcd(self.table[l][k], self.table[r - (1 << k) + 1][k])
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "sparse table min basic" {
  let arr : Array[Int64] = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let st = SparseTableMin(arr)
  debug_inspect(st.query(0, 7), content="1")
  debug_inspect(st.query(0, 1), content="1")
  debug_inspect(st.query(4, 7), content="2")
  debug_inspect(st.query(2, 5), content="1")
}

///|
test "sparse table min single" {
  let arr : Array[Int64] = [42L]
  let st = SparseTableMin(arr)
  debug_inspect(st.query(0, 0), content="42")
}

///|
test "sparse table max basic" {
  let arr : Array[Int64] = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let st = SparseTableMax(arr)
  debug_inspect(st.query(0, 7), content="9")
  debug_inspect(st.query(0, 2), content="4")
  debug_inspect(st.query(6, 7), content="6")
}

///|
test "sparse table gcd" {
  let arr : Array[Int64] = [12L, 18L, 24L, 36L]
  let st = SparseTableGCD(arr)
  debug_inspect(st.query(0, 3), content="6")
  debug_inspect(st.query(0, 1), content="6")
  debug_inspect(st.query(2, 3), content="12")
}

///|
test "sparse table empty" {
  let arr : Array[Int64] = []
  let st = SparseTableMin(arr)
  debug_inspect(st.n, content="0")
}

///|
test "sparse table power of 2" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let st = SparseTableMin(arr)
  debug_inspect(st.query(0, 7), content="1")
  debug_inspect(st.query(4, 7), content="5")
}
