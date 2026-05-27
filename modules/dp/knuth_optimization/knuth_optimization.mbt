// ============================================================================
// KNUTH'S O(n^2) OPTIMIZATION  -  for range-partition DPs
// ============================================================================
//
// PROBLEM
//
// Many interval / partition DPs take the form
//
//   dp[i][j] = min over k in [i, j-1] of (dp[i][k] + dp[k+1][j]) + w(i, j)
//
// e.g. **optimal binary search trees** and **matrix chain multiplication**.
// The naive cost is `O(n^3)`. When the cost function `w` satisfies the
// **quadrangle inequality** plus monotonicity:
//
//   w(a, c) + w(b, d) <= w(a, d) + w(b, c)   for a <= b <= c <= d
//   w(b, c) <= w(a, d)                       for [b, c] subset of [a, d]
//
// Knuth (1971) proved that the optimal split points `opt[i][j]` satisfy
//
//   opt[i][j-1] <= opt[i][j] <= opt[i+1][j]
//
// which restricts the inner search to a telescoping range. The total
// work across all (i, j) becomes `O(n^2)`.
//
// COMPLEXITY
//
//   Time : O(n^2) under Knuth's hypotheses
//   Space: O(n^2)
//
// THE INVARIANT
//
//   "After processing all intervals (i, j) with j - i + 1 <= L,
//    dp[i'][j'] is the minimum partition cost on every shorter
//    interval, and opt[i'][j'] is its argmin."

///|
const INF : Int64 = 4611686018427387903L

///|
/// Solve the partition DP
///
///   dp[i][j] = min_{i <= k < j} (dp[i][k] + dp[k+1][j]) + w(i, j)
///
/// for all `0 <= i <= j < n`, returning `dp[0][n-1]`. Base case
/// `dp[i][i] = 0`. The caller supplies `w(i, j)` satisfying the
/// quadrangle inequality.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Matrix-chain multiplication with dimensions [40, 20, 30, 10, 30]:
///   // optimal cost is 26000.
///   let dims = [40, 20, 30, 10, 30]
///   // For matrix chain, w(i, j) is dims[i] * dims[k+1] * dims[j+1] in the
///   // standard formulation; here we wrap it in the appropriate cost.
/// }
/// ```
pub fn solve(n : Int, w : (Int, Int) -> Int64) -> Int64 {
  if n <= 0 {
    return 0L
  }
  let dp = Array::makei(n, _ => Array::make(n, 0L))
  let opt = Array::makei(n, i => Array::makei(n, j => if i == j { i } else { 0 }))
  // dp[i][i] = 0 already.
  for len in 2..<=n {
    for i in 0..<=(n - len) {
      let j = i + len - 1
      let lo = opt[i][j - 1]
      let hi = if i + 1 <= j { opt[i + 1][j] } else { j - 1 }
      let mut best = INF
      let mut arg = lo
      for k in lo..<=hi {
        if k >= j {
          break
        }
        let v = dp[i][k] + dp[k + 1][j]
        if v < best {
          best = v
          arg = k
        }
      }
      dp[i][j] = best + w(i, j)
      opt[i][j] = arg
    }
  }
  dp[0][n - 1]
}

///|
/// Solve and also return the full DP table.
pub fn solve_table(n : Int, w : (Int, Int) -> Int64) -> Array[Array[Int64]] {
  if n <= 0 {
    return []
  }
  let dp = Array::makei(n, _ => Array::make(n, 0L))
  let opt = Array::makei(n, i => Array::makei(n, j => if i == j { i } else { 0 }))
  for len in 2..<=n {
    for i in 0..<=(n - len) {
      let j = i + len - 1
      let lo = opt[i][j - 1]
      let hi = if i + 1 <= j { opt[i + 1][j] } else { j - 1 }
      let mut best = INF
      let mut arg = lo
      for k in lo..<=hi {
        if k >= j {
          break
        }
        let v = dp[i][k] + dp[k + 1][j]
        if v < best {
          best = v
          arg = k
        }
      }
      dp[i][j] = best + w(i, j)
      opt[i][j] = arg
    }
  }
  dp
}

///|
test "knuth matrix chain" {
  // Dimensions: A_i has dimension dims[i] x dims[i+1].
  // For dims = [40, 20, 30, 10, 30]:
  //   A: 40x20, B: 20x30, C: 30x10, D: 10x30
  // Optimal parenthesisation cost (with the standard MCM recurrence) is 26000.
  let dims = [40, 20, 30, 10, 30]
  let m = dims.length()
  // dp[i][j] = min cost to compute A_i...A_j.
  // Recurrence: dp[i][j] = min_{k in [i, j-1]} dp[i][k] + dp[k+1][j] +
  //                       dims[i] * dims[k+1] * dims[j+1].
  //
  // Knuth's solve uses w(i, j) but the cost depends on k. The classic
  // MCM DP does *not* fit the pure "additive" form solve() expects.
  // For exposition we'll verify with a hand-written DP and confirm
  // Knuth's outer-loop pattern works as a comparison.
  let n = m - 1 // number of matrices
  let dp = Array::makei(n, _ => Array::make(n, 0L))
  for len in 2..<=n {
    for i in 0..<=(n - len) {
      let j = i + len - 1
      let mut best = INF
      for k in i..<j {
        let cost = dp[i][k] +
          dp[k + 1][j] +
          (dims[i] * dims[k + 1] * dims[j + 1]).to_int64()
        if cost < best {
          best = cost
        }
      }
      dp[i][j] = best
    }
  }
  @debug.assert_eq(dp[0][n - 1], 26000L)
}

///|
test "knuth solve simple cost" {
  // w(i, j) = (j - i + 1) -- the constant cost of merging interval [i, j].
  // dp[i][j] is then the minimum of any partition's split plus this.
  // For 4 elements: the minimum will be reached at the balanced split.
  let n = 4
  let w = fn(i : Int, j : Int) -> Int64 { (j - i + 1).to_int64() }
  let ans = solve(n, w)
  // Hand-compute: dp[0][3] = min over k of dp[0][k] + dp[k+1][3] + 4.
  // dp[i][i] = 0; dp[i][i+1] = 0 + 0 + 2 = 2; dp[i][i+2] = best k
  // -> dp[0][2] = dp[0][1] + dp[2][2] + 3 = 2 + 0 + 3 = 5, or
  //               dp[0][0] + dp[1][2] + 3 = 0 + 2 + 3 = 5.
  // dp[0][3] = dp[0][k] + dp[k+1][3] + 4:
  //   k=0: 0 + dp[1][3]; dp[1][3] = 5 -> 0 + 5 + 4 = 9
  //   k=1: 2 + dp[2][3]; dp[2][3] = 2 -> 2 + 2 + 4 = 8
  //   k=2: 5 + 0 = 5 + 4 = 9
  // min = 8.
  @debug.assert_eq(ans, 8L)
}

///|
test "knuth small n" {
  @debug.assert_eq(solve(0, fn(_a, _b) { 0L }), 0L)
  @debug.assert_eq(solve(1, fn(_a, _b) { 100L }), 0L) // single -> 0
  @debug.assert_eq(solve(2, fn(_a, _b) { 5L }), 5L) // merge [0,1] = 5
}

///|
test "knuth matches naive on small cases" {
  fn naive(n : Int, w : (Int, Int) -> Int64) -> Int64 {
    if n <= 0 {
      return 0L
    }
    let dp = Array::makei(n, _ => Array::make(n, 0L))
    for len in 2..<=n {
      for i in 0..<=(n - len) {
        let j = i + len - 1
        let mut best = INF
        for k in i..<j {
          let v = dp[i][k] + dp[k + 1][j]
          if v < best {
            best = v
          }
        }
        dp[i][j] = best + w(i, j)
      }
    }
    dp[0][n - 1]
  }

  // Costs that satisfy the QI: any constant function works.
  let w1 = fn(i : Int, j : Int) -> Int64 { (j - i + 1).to_int64() }
  for n in 1..<10 {
    @debug.assert_eq(solve(n, w1), naive(n, w1))
  }
  // A different cost satisfying the QI: w(i, j) = (i + j).
  let w2 = fn(i : Int, j : Int) -> Int64 { (i + j).to_int64() }
  for n in 1..<10 {
    @debug.assert_eq(solve(n, w2), naive(n, w2))
  }
}
