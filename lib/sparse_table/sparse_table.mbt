// ============================================================================
// SPARSE TABLE - O(1) Range Minimum/Maximum Queries
// ============================================================================
//
// Sparse Table is a data structure for answering Range Minimum Queries (RMQ)
// in O(1) time after O(n log n) preprocessing, using O(n log n) space.
//
// KEY INSIGHT: Precompute answers for all ranges of power-of-2 lengths.
// Any range [l, r] can be covered by two overlapping power-of-2 ranges.
// Since min/max are idempotent (min(a, a) = a), overlapping is fine.
//
// STRUCTURE:
// - table[k][i] = answer for range [i, i + 2^k - 1]
// - k ranges from 0 to floor(log2(n))
// - For query [l, r]: find largest k where 2^k <= r - l + 1
//   answer = combine(table[k][l], table[k][r - 2^k + 1])
//
// EXAMPLE for arr = [3, 1, 4, 1, 5, 9, 2, 6] with min operation:
// table[0] = [3, 1, 4, 1, 5, 9, 2, 6]  (ranges of length 1)
// table[1] = [1, 1, 1, 1, 5, 2, 2, _]  (ranges of length 2)
// table[2] = [1, 1, 1, 1, 2, 2, _, _]  (ranges of length 4)
// table[3] = [1, 1, _, _, _, _, _, _]  (ranges of length 8)
//
// Query [2, 5]: length = 4, k = 2
// answer = min(table[2][2], table[2][5-4+1]) = min(table[2][2], table[2][2])
//        = min(1, 1) = 1
//
// INVARIANTS:
// 1. table[k][i] contains answer for [i, i + 2^k - 1]
// 2. table[k][i] = combine(table[k-1][i], table[k-1][i + 2^(k-1)])
// 3. Query uses two ranges that together cover [l, r] with possible overlap
//
// TIME COMPLEXITY:
// - Build: O(n log n)
// - Query: O(1)
//
// SPACE COMPLEXITY: O(n log n)

///|
/// Sparse Table for Range Minimum Queries
priv struct SparseTableMin {
  table : Array[Array[Int64]] // table[k][i] = min in [i, i + 2^k - 1]
  log_table : Array[Int] // log_table[i] = floor(log2(i))
  n : Int
}

///|
fn SparseTableMin::new(arr : Array[Int64]) -> SparseTableMin {
  let n = arr.length()
  if n == 0 {
    return { table: [], log_table: [], n: 0 }
  }

  // Precompute logarithms
  // INVARIANT: log_table[i] = floor(log2(i)) for i >= 1
  let log_table = Array::make(n + 1, 0)
  for i = 2; i <= n; i = i + 1 {
    log_table[i] = log_table[i / 2] + 1
  }

  let max_k = log_table[n] + 1
  let table : Array[Array[Int64]] = []

  // Initialize table[0] with original array
  let row0 : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    row0.push(arr[i])
  }
  table.push(row0)

  // Build table for k = 1 to max_k - 1
  // INVARIANT: After iteration k, table[k][i] contains min of [i, i + 2^k - 1]
  for k = 1; k < max_k; k = k + 1 {
    let prev_len = 1 << (k - 1) // 2^(k-1)
    let row : Array[Int64] = []

    // INVARIANT: i + 2^k - 1 < n for valid entries
    for i = 0; i + (1 << k) <= n; i = i + 1 {
      // Combine two ranges of length 2^(k-1)
      let left = table[k - 1][i]
      let right = table[k - 1][i + prev_len]
      row.push(if left < right { left } else { right })
    }
    table.push(row)
  }

  { table, log_table, n }
}

///|
/// Query minimum in range [l, r] (inclusive)
/// REASONING: Find largest k where 2^k <= length, then use two overlapping ranges
fn SparseTableMin::query(self : SparseTableMin, l : Int, r : Int) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }

  let length = r - l + 1
  let k = self.log_table[length]

  // Two ranges: [l, l + 2^k - 1] and [r - 2^k + 1, r]
  // Together they cover [l, r] with possible overlap
  let left = self.table[k][l]
  let right = self.table[k][r - (1 << k) + 1]

  Some(if left < right { left } else { right })
}

///|
/// Get the minimum in the entire array
fn SparseTableMin::min_all(self : SparseTableMin) -> Int64? {
  if self.n == 0 {
    return None
  }
  self.query(0, self.n - 1)
}

///|
fn SparseTableMin::length(self : SparseTableMin) -> Int {
  self.n
}

// ============================================================================
// SPARSE TABLE FOR MAXIMUM QUERIES
// ============================================================================

///|
/// Sparse Table for Range Maximum Queries
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
  for i = 2; i <= n; i = i + 1 {
    log_table[i] = log_table[i / 2] + 1
  }

  let max_k = log_table[n] + 1
  let table : Array[Array[Int64]] = []

  let row0 : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    row0.push(arr[i])
  }
  table.push(row0)

  // Build for maximum
  for k = 1; k < max_k; k = k + 1 {
    let prev_len = 1 << (k - 1)
    let row : Array[Int64] = []

    for i = 0; i + (1 << k) <= n; i = i + 1 {
      let left = table[k - 1][i]
      let right = table[k - 1][i + prev_len]
      row.push(if left > right { left } else { right })
    }
    table.push(row)
  }

  { table, log_table, n }
}

///|
/// Query maximum in range [l, r] (inclusive)
fn SparseTableMax::query(self : SparseTableMax, l : Int, r : Int) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }

  let length = r - l + 1
  let k = self.log_table[length]

  let left = self.table[k][l]
  let right = self.table[k][r - (1 << k) + 1]

  Some(if left > right { left } else { right })
}

///|
fn SparseTableMax::max_all(self : SparseTableMax) -> Int64? {
  if self.n == 0 {
    return None
  }
  self.query(0, self.n - 1)
}

///|
fn SparseTableMax::length(self : SparseTableMax) -> Int {
  self.n
}

// ============================================================================
// SPARSE TABLE FOR GCD QUERIES
// ============================================================================
//
// GCD is also idempotent: gcd(a, a) = a, so we can use sparse table

///|
fn gcd(a : Int64, b : Int64) -> Int64 {
  let a_abs = if a < 0L { -a } else { a }
  let b_abs = if b < 0L { -b } else { b }

  // Euclidean algorithm
  // INVARIANT: gcd(a, b) = gcd(b, a mod b)
  for curr_a = a_abs, curr_b = b_abs; curr_b != 0L; {
    continue curr_b, curr_a % curr_b
  } else {
    curr_a
  }
}

///|
/// Sparse Table for Range GCD Queries
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
  for i = 2; i <= n; i = i + 1 {
    log_table[i] = log_table[i / 2] + 1
  }

  let max_k = log_table[n] + 1
  let table : Array[Array[Int64]] = []

  let row0 : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    row0.push(arr[i])
  }
  table.push(row0)

  // Build for GCD
  for k = 1; k < max_k; k = k + 1 {
    let prev_len = 1 << (k - 1)
    let row : Array[Int64] = []

    for i = 0; i + (1 << k) <= n; i = i + 1 {
      let left = table[k - 1][i]
      let right = table[k - 1][i + prev_len]
      row.push(gcd(left, right))
    }
    table.push(row)
  }

  { table, log_table, n }
}

///|
/// Query GCD in range [l, r] (inclusive)
fn SparseTableGCD::query(self : SparseTableGCD, l : Int, r : Int) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }

  let length = r - l + 1
  let k = self.log_table[length]

  let left = self.table[k][l]
  let right = self.table[k][r - (1 << k) + 1]

  Some(gcd(left, right))
}

///|
fn SparseTableGCD::length(self : SparseTableGCD) -> Int {
  self.n
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "sparse table min basic" {
  let arr : Array[Int64] = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let st = SparseTableMin::new(arr)

  // Single elements
  inspect(st.query(0, 0), content="Some(3)")
  inspect(st.query(1, 1), content="Some(1)")

  // Ranges
  inspect(st.query(0, 1), content="Some(1)")
  inspect(st.query(0, 3), content="Some(1)")
  inspect(st.query(4, 7), content="Some(2)")
  inspect(st.query(0, 7), content="Some(1)")
}

///|
test "sparse table min edge cases" {
  let arr : Array[Int64] = [5L]
  let st = SparseTableMin::new(arr)

  inspect(st.query(0, 0), content="Some(5)")
  inspect(st.min_all(), content="Some(5)")
  inspect(st.length(), content="1")
}

///|
test "sparse table min empty" {
  let arr : Array[Int64] = []
  let st = SparseTableMin::new(arr)

  inspect(st.query(0, 0), content="None")
  inspect(st.min_all(), content="None")
  inspect(st.length(), content="0")
}

///|
test "sparse table min invalid range" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let st = SparseTableMin::new(arr)

  inspect(st.query(-1, 0), content="None")
  inspect(st.query(0, 10), content="None")
  inspect(st.query(2, 1), content="None")
}

///|
test "sparse table max basic" {
  let arr : Array[Int64] = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let st = SparseTableMax::new(arr)

  inspect(st.query(0, 0), content="Some(3)")
  inspect(st.query(0, 7), content="Some(9)")
  inspect(st.query(0, 3), content="Some(4)")
  inspect(st.query(4, 7), content="Some(9)")
}

///|
test "sparse table max all same" {
  let arr : Array[Int64] = [5L, 5L, 5L, 5L]
  let st = SparseTableMax::new(arr)

  inspect(st.query(0, 3), content="Some(5)")
  inspect(st.max_all(), content="Some(5)")
}

///|
test "sparse table max ascending" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = SparseTableMax::new(arr)

  inspect(st.query(0, 0), content="Some(1)")
  inspect(st.query(0, 2), content="Some(3)")
  inspect(st.query(0, 4), content="Some(5)")
  inspect(st.query(2, 4), content="Some(5)")
}

///|
test "sparse table max length" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let st = SparseTableMax::new(arr)

  inspect(st.length(), content="3")
}

///|
test "sparse table gcd basic" {
  let arr : Array[Int64] = [12L, 18L, 24L, 36L]
  let st = SparseTableGCD::new(arr)

  // Single elements
  inspect(st.query(0, 0), content="Some(12)")

  // GCD of pairs
  inspect(st.query(0, 1), content="Some(6)") // gcd(12, 18) = 6

  // GCD of all
  inspect(st.query(0, 3), content="Some(6)") // gcd(12, 18, 24, 36) = 6
}

///|
test "sparse table gcd coprime" {
  let arr : Array[Int64] = [7L, 11L, 13L, 17L]
  let st = SparseTableGCD::new(arr)

  // All coprime primes
  inspect(st.query(0, 3), content="Some(1)")
}

///|
test "sparse table gcd powers of 2" {
  let arr : Array[Int64] = [8L, 16L, 32L, 64L]
  let st = SparseTableGCD::new(arr)

  // GCD of powers of 2 is smallest
  inspect(st.query(0, 3), content="Some(8)")
  inspect(st.query(1, 3), content="Some(16)")
}

///|
test "sparse table gcd length" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = SparseTableGCD::new(arr)

  inspect(st.length(), content="5")
}

///|
test "sparse table min power of 2 size" {
  // Test with exact power of 2 size
  let arr : Array[Int64] = [4L, 2L, 3L, 1L, 8L, 6L, 7L, 5L]
  let st = SparseTableMin::new(arr)

  inspect(st.query(0, 7), content="Some(1)")
  inspect(st.query(0, 3), content="Some(1)")
  inspect(st.query(4, 7), content="Some(5)")
}

///|
test "sparse table min non power of 2 size" {
  // Test with non-power of 2 size
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L, 3L]
  let st = SparseTableMin::new(arr)

  inspect(st.query(0, 5), content="Some(1)")
  inspect(st.query(0, 2), content="Some(2)")
  inspect(st.query(3, 5), content="Some(1)")
}
