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
pub struct SparseTable {
  log : Array[Int]
  table : Array[Array[Int]]
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn build_sparse_table(arr : ArrayView[Int]) -> SparseTable {
  let n = arr.length()
  if n == 0 {
    return { log: [0], table: [] }
  }
  let log = Array::make(n + 1, 0)
  for i = 2; i <= n; i = i + 1 {
    log[i] = log[i / 2] + 1
  } where {
    invariant: i >= 2 && i <= n + 1,
    reasoning: (
      #|INVARIANT (log table):
      #|log[t] is computed for all t in [2, i). Each value is floor(log2(t)).
      #|MAINTENANCE:
      #|Use log[i/2] + 1 to extend to the next integer.
      #|TERMINATION:
      #|At i = n + 1, log is ready for all lengths up to n.
    ),
  }
  let kmax = log[n]
  let table = Array::makei(kmax + 1, fn(_) { Array::make(n, 0) })
  for i = 0; i < n; i = i + 1 {
    table[0][i] = arr[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (level 0):
      #|table[0][0..i) stores arr[0..i), i.e., minimums for length-1 ranges.
      #|MAINTENANCE:
      #|Copy arr[i] into table[0][i].
      #|TERMINATION:
      #|At i = n, the base level is fully populated.
    ),
  }
  for k = 1; k <= kmax; k = k + 1 {
    let span = 1 << k
    let half = span >> 1
    for i = 0; i + span <= n; i = i + 1 {
      table[k][i] = min(table[k - 1][i], table[k - 1][i + half])
    } where {
      invariant: i >= 0 && i + span <= n,
      reasoning: (
        #|INVARIANT (build level):
        #|table[k][0..i) holds minimums for all length-2^k ranges that start
        #|before i. Each entry combines two length-2^(k-1) halves.
        #|MAINTENANCE:
        #|Set table[k][i] = min(left half, right half).
        #|TERMINATION:
        #|At i + span > n, all valid ranges for this level are built.
      ),
    }
  } where {
    invariant: k >= 1 && k <= kmax + 1,
    reasoning: (
      #|INVARIANT (levels):
      #|Levels [0..k) are fully built, each storing min values for ranges of
      #|length 2^level.
      #|MAINTENANCE:
      #|Use level k-1 to compute level k by combining adjacent blocks.
      #|TERMINATION:
      #|At k = kmax + 1, all levels are available for O(1) queries.
    ),
  }
  { log, table }
}

///|
pub fn range_min(st : SparseTable, l : Int, r : Int) -> Int {
  let len = r - l
  let k = st.log[len]
  let span = 1 << k
  min(st.table[k][l], st.table[k][r - span])
}

///|
test "sparse_table_rmq" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = build_sparse_table(arr[:])
  assert_eq(range_min(st, 0, 8), 0)
  assert_eq(range_min(st, 1, 5), 1)
  assert_eq(range_min(st, 3, 6), 1)
}
