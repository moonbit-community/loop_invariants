// ============================================================================
// Challenge: Disjoint Sparse Table (Range Minimum Query)
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
fn highest_bit(x : Int) -> Int {
  for v = x, k = 0 {
    if v <= 1 {
      break k
    } else {
      continue v >> 1, k + 1
    }
  } where {
    proof_invariant: v >= 1,
    proof_reasoning: (
      #|INVARIANT (highest bit):
      #|v equals x >> k, so k is the number of shifts performed so far.
      #|MAINTENANCE:
      #|Shift v right by 1 and increment k.
      #|TERMINATION:
      #|When v <= 1, k is floor(log2(x)).
    ),
  }
}

///|
/// A disjoint sparse table for O(1) range minimum queries.
///
/// Stores, at each level `k`, left/right prefix minima around the midpoints of
/// blocks of size `2^(k+1)`. Any half-open query `[l, r)` crosses a unique
/// midpoint at level `k = highest_bit(l XOR (r-1))`, so the answer is the
/// minimum of two precomputed values. Unlike a classic sparse table, this
/// works for any associative operation (no idempotence required).
///
/// Build it with `build_disjoint_sparse_table` and query with `range_min`.
/// Build cost is `O(n log n)`, query cost is `O(1)`, space is `O(n log n)`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
///   let dst = build_disjoint_sparse_table(arr[:])
///   @debug.assert_eq(range_min(dst, 1, 5), 1)
///   @debug.assert_eq(range_min(dst, 5, 8), 0)
/// }
/// ```
pub struct DisjointSparseTable {
  n : Int
  table : Array[Array[Int]]
}

///|
/// Build a disjoint sparse table for range minimum queries.
pub fn build_disjoint_sparse_table(arr : ArrayView[Int]) -> DisjointSparseTable {
  let n = arr.length()
  if n == 0 {
    return { n: 0, table: [] }
  }
  let levels = highest_bit(n - 1) + 1
  let table = [ for _ in 0..<levels => Array::make(n, 0) ]
  for i, val in arr {
    table[0][i] = val
  }
  for k in 1..<levels {
    let span = 1 << (k + 1)
    let half = span >> 1
    for block = 0 {
      if block >= n {
        break
      } else {
        let mid = min(block + half, n)
        let end = min(block + span, n)
        if mid > block {
          table[k][mid - 1] = arr[mid - 1]
          let left_start = mid - 1
          for i in left_start>..block {
            table[k][i] = min(arr[i], table[k][i + 1])
          }
        }
        if mid < end {
          table[k][mid] = arr[mid]
          for i in (mid + 1)..<end {
            table[k][i] = min(table[k][i - 1], arr[i])
          } where {
            proof_invariant: i >= mid + 1 && i <= end,
            proof_reasoning: (
              #|INVARIANT (right prefix):
              #|table[k][mid..i) stores minima for ranges [mid, t].
              #|MAINTENANCE:
              #|Set table[k][i] as min(table[k][i-1], arr[i]).
              #|TERMINATION:
              #|At i = end, the right half is complete.
            ),
          }
        }
        continue block + span
      }
    } where {
      proof_invariant: block >= 0 && block <= n,
      proof_reasoning: (
        #|INVARIANT (block build):
        #|All blocks before block have their disjoint minima populated for
        #|level k. Each block covers span = 2^(k+1) elements.
        #|MAINTENANCE:
        #|Build left and right prefix minima within the current block.
        #|TERMINATION:
        #|At block >= n, all blocks for level k are built.
      ),
    }
  } where {
    proof_invariant: k >= 1 && k <= levels,
    proof_reasoning: (
      #|INVARIANT (levels):
      #|Levels [0..k) have disjoint prefix minima precomputed.
      #|MAINTENANCE:
      #|For level k, build disjoint blocks of size 2^(k+1).
      #|TERMINATION:
      #|At k = levels, the table is ready for O(1) queries.
    ),
  }
  { n, table }
}

///|
/// Query the minimum over [l, r).
pub fn range_min(dst : DisjointSparseTable, l : Int, r : Int) -> Int {
  if r - l <= 1 {
    return dst.table[0][l]
  }
  let k = highest_bit(l ^ (r - 1))
  min(dst.table[k][l], dst.table[k][r - 1])
}
