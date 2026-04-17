// ============================================================================
// Challenge: TSP (Bitmask DP)
// Minimum Hamiltonian cycle starting at node 0
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Return minimal tour cost visiting all nodes and returning to 0.
pub fn tsp_min_cycle(dist : Array[Array[Int]]) -> Int {
  let n = dist.length()
  if n <= 1 {
    return 0
  }
  let total = 1 << n
  let dp : Array[Array[Int]] = [ for _ in 0..<total => Array::make(n, INF) ]
  dp[1][0] = 0
  for mask in 1..<total {
    for u in 0..<n {
      if (mask & (1 << u)) != 0 && dp[mask][u] != INF {
        for v in 0..<n {
          if (mask & (1 << v)) == 0 {
            let new_mask = mask | (1 << v)
            let cand = dp[mask][u] + dist[u][v]
            if cand < dp[new_mask][v] {
              dp[new_mask][v] = cand
            }
          }
        }
      }
    }
  }
  let full = total - 1
  for u in 1..<n; best = INF {
    let cand = dp[full][u] + dist[u][0]
    continue if cand < best { cand } else { best }
  } nobreak {
    best
  }
}

///|
test "tsp_min_cycle" {
  let dist = [
    [0, 10, 15, 20],
    [10, 0, 35, 25],
    [15, 35, 0, 30],
    [20, 25, 30, 0],
  ]
  assert_eq(tsp_min_cycle(dist), 80)
  assert_eq(tsp_min_cycle([[0]]), 0)
}
