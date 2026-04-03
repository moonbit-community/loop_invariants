// ============================================================================
// Challenge: Longest Common Subsequence Length
// ============================================================================

///|
fn max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Compute LCS length using two-row DP.
#warnings("+missing_invariant+missing_reasoning")
pub fn lcs_length(a : ArrayView[Char], b : ArrayView[Char]) -> Int {
  let m = a.length()
  let n = b.length()
  if m == 0 || n == 0 {
    return 0
  }
  let prev : Array[Int] = for
    i in 1..<=m
    prev = Array::make(n + 1, 0), curr = Array::make(n + 1, 0) {
    curr[0] = 0
    for j in 1..<=n {
      if a[i - 1] == b[j - 1] {
        curr[j] = prev[j - 1] + 1
      } else {
        curr[j] = max(prev[j], curr[j - 1])
      }
    }
    continue curr, prev
  } nobreak {
    prev
  }
  prev[n]
}

///|
test "lcs_length" {
  let a : Array[Char] = ['A', 'B', 'C', 'B', 'D', 'A', 'B']
  let b : Array[Char] = ['B', 'D', 'C', 'A', 'B', 'A']
  assert_eq(lcs_length(a[:], b[:]), 4)
  assert_eq(lcs_length(['A', 'B', 'C'][:], ['A', 'B', 'C'][:]), 3)
}
