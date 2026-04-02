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
pub struct SparseTableMin {
  table : Array[Array[Int64]]
  log_table : Array[Int]
  n : Int
}

///|
/// Build a sparse table for range minimum queries.
pub fn SparseTableMin::new(arr : Array[Int64]) -> SparseTableMin {
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
  let table = Array::makei(n, i => {
    let row = Array::make(k, 0L)
    row[0] = arr[i]
    row
  })

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
/// Query minimum in range [l, r] inclusive
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
priv struct SparseTableMax {
  table : Array[Array[Int64]]
  log_table : Array[Int]
  n : Int
}

///|
fn SparseTableMax::new(arr : Array[Int64]) -> SparseTableMax {
  let n = arr.length()
  if n == 0 {
    return { table: [], log_table: [], n: 0 }
  }
  let log_table = Array::make(n + 1, 0)
  for i in 2..<=n {
    log_table[i] = log_table[i / 2] + 1
  }
  let k = log_table[n] + 1
  let table = Array::makei(n, i => {
    let row = Array::make(k, 0L)
    row[0] = arr[i]
    row
  })
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
fn gcd(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }
  while y != 0L {
    let t = y
    y = x % y
    x = t
  }
  x
}

///|
priv struct SparseTableGCD {
  table : Array[Array[Int64]]
  log_table : Array[Int]
  n : Int
}

///|
fn SparseTableGCD::new(arr : Array[Int64]) -> SparseTableGCD {
  let n = arr.length()
  if n == 0 {
    return { table: [], log_table: [], n: 0 }
  }
  let log_table = Array::make(n + 1, 0)
  for i in 2..<=n {
    log_table[i] = log_table[i / 2] + 1
  }
  let k = log_table[n] + 1
  let table = Array::makei(n, i => {
    let row = Array::make(k, 0L)
    row[0] = arr[i]
    row
  })
  for j in 1..<k {
    let len = 1 << j
    for i in 0..<(n - len + 1) {
      table[i][j] = gcd(table[i][j - 1], table[i + (1 << (j - 1))][j - 1])
    }
  }
  { table, log_table, n }
}

///|
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
  let st = SparseTableMin::new(arr)
  inspect(st.query(0, 7), content="1")
  inspect(st.query(0, 1), content="1")
  inspect(st.query(4, 7), content="2")
  inspect(st.query(2, 5), content="1")
}

///|
test "sparse table min single" {
  let arr : Array[Int64] = [42L]
  let st = SparseTableMin::new(arr)
  inspect(st.query(0, 0), content="42")
}

///|
test "sparse table max basic" {
  let arr : Array[Int64] = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let st = SparseTableMax::new(arr)
  inspect(st.query(0, 7), content="9")
  inspect(st.query(0, 2), content="4")
  inspect(st.query(6, 7), content="6")
}

///|
test "sparse table gcd" {
  let arr : Array[Int64] = [12L, 18L, 24L, 36L]
  let st = SparseTableGCD::new(arr)
  inspect(st.query(0, 3), content="6")
  inspect(st.query(0, 1), content="6")
  inspect(st.query(2, 3), content="12")
}

///|
test "sparse table empty" {
  let arr : Array[Int64] = []
  let st = SparseTableMin::new(arr)
  inspect(st.n, content="0")
}

///|
test "sparse table power of 2" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let st = SparseTableMin::new(arr)
  inspect(st.query(0, 7), content="1")
  inspect(st.query(4, 7), content="5")
}
