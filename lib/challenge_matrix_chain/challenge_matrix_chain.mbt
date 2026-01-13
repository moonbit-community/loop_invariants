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
  for len = 2; len <= n; len = len + 1 {
    for i = 0; i + len <= n; i = i + 1 {
      let j = i + len - 1
      dp[i][j] = INF
      for k = i; k < j; k = k + 1 {
        let cost = dp[i][k] + dp[k + 1][j] + dims[i] * dims[k + 1] * dims[j + 1]
        if cost < dp[i][j] {
          dp[i][j] = cost
        }
      } where {
        invariant: k >= i && k <= j,
        reasoning: (
          #|INVARIANT (Split scan):
          #|dp[i][j] is the minimum cost among splits in [i..k).
          #|MAINTENANCE:
          #|Evaluate split at k and update dp[i][j] if cheaper.
          #|TERMINATION:
          #|At k = j, dp[i][j] is minimal over all splits.
        ),
      }
    } where {
      invariant: i >= 0 && i + len <= n,
      reasoning: (
        #|INVARIANT (Window fill):
        #|All dp entries for chains starting < i and of length len are computed.
        #|MAINTENANCE:
        #|Compute dp[i][j] using shorter subchains.
        #|TERMINATION:
        #|At i + len = n+1, all windows of this length are filled.
      ),
    }
  } where {
    invariant: len >= 2 && len <= n + 1,
    reasoning: (
      #|INVARIANT (DP by length):
      #|All chains of length < len have their optimal costs computed.
      #|MAINTENANCE:
      #|Use shorter chains to compute length len.
      #|TERMINATION:
      #|At len = n+1, dp[0][n-1] is the optimal cost.
    ),
  }
  dp[0][n - 1]
}
