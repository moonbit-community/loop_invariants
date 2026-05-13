// ============================================================================
// Challenge: Sparse Table (Range Minimum Query)
// ============================================================================

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// A classic sparse table for O(1) range minimum queries on a static array.
///
/// At each level `k`, `table[k][i]` stores the minimum over the window
/// `arr[i ..< i + 2^k]`. A query on `[l, r)` of length `len` picks
/// `k = log[len]` and returns `min(table[k][l], table[k][r - 2^k])`, exploiting
/// the idempotence of `min` to overlap the two windows. `log[len]` provides
/// `floor(log2(len))` in O(1).
///
/// Build it with `build_sparse_table` and query with `range_min`. Build cost
/// is `O(n log n)`, query cost is `O(1)`, space is `O(n log n)`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
///   let st = build_sparse_table(arr[:])
///   assert_eq(range_min(st, 1, 5), 1)
///   assert_eq(range_min(st, 0, 8), 0)
/// }
/// ```
pub struct SparseTable {
  log : Array[Int]
  table : Array[Array[Int]]
}

///|
/// Build a sparse table for range minimum queries.
pub fn build_sparse_table(arr : ArrayView[Int]) -> SparseTable {
  let n = arr.length()
  if n == 0 {
    return { log: [0], table: [] }
  }
  let log = Array::make(n + 1, 0)
  for i in 2..<(n + 1) {
    log[i] = log[i / 2] + 1
  }
  let kmax = log[n]
  let table = [ for _ in 0..<(kmax + 1) => Array::make(n, 0) ]
  for i in 0..<n {
    table[0][i] = arr[i]
  }
  for k in 1..<(kmax + 1) {
    let span = 1 << k
    let half = span >> 1
    for i in 0..<(n - span + 1) {
      table[k][i] = min(table[k - 1][i], table[k - 1][i + half])
    }
  }
  { log, table }
}

///|
/// Query the minimum over [l, r).
pub fn range_min(st : SparseTable, l : Int, r : Int) -> Int {
  let len = r - l
  let k = st.log[len]
  let span = 1 << k
  min(st.table[k][l], st.table[k][r - span])
}
