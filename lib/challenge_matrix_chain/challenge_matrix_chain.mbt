// ============================================================================
// Challenge: Matrix Chain Multiplication (DP)
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Minimum scalar multiplications for matrix chain.
/// dims has length n+1, where matrix i is dims[i] x dims[i+1].
#warnings("+missing_invariant+missing_reasoning")
pub fn matrix_chain_min_cost(dims : ArrayView[Int]) -> Int {
  let n = dims.length() - 1
  if n <= 0 {
    return 0
  }
  let dp : Array[Array[Int]] = Array::makei(n, _ => Array::make(n, 0))
  for len in 2..=n {
    for i in 0..=(n - len) {
      let j = i + len - 1
      dp[i][j] = INF
      for k in i..<j {
        let cost = dp[i][k] + dp[k + 1][j] + dims[i] * dims[k + 1] * dims[j + 1]
        if cost < dp[i][j] {
          dp[i][j] = cost
        }
      }
    }
  }
  dp[0][n - 1]
}
