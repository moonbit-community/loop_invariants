// ============================================================================
// Challenge: Bitmask DP (Traveling Salesman - Small n)
// ============================================================================

///|
/// Minimum Hamiltonian cycle cost starting at node 0.
#warnings("+missing_invariant+missing_reasoning")
pub fn tsp_min_cycle(dist : Array[Array[Int]], inf : Int) -> Int {
  let n = dist.length()
  if n == 0 {
    return 0
  }
  let total = 1 << n
  let dp : Array[Array[Int]] = Array::makei(total, _ => Array::make(n, inf))
  dp[1][0] = 0
  for mask in 1..<total {
    for u in 0..<n {
      if dp[mask][u] < inf {
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
  let best = for u = 0, ans = inf {
    if u >= n {
      break ans
    } else {
      let cand = dp[full][u] + dist[u][0]
      let new_ans = if cand < ans { cand } else { ans }
      continue u + 1, new_ans
    }
  } where {
    invariant: u >= 0 && u <= n,
    reasoning: (
      #|INVARIANT (Close the tour):
      #|ans is the minimum cycle cost among processed endpoints < u.
      #|MAINTENANCE:
      #|Consider endpoint u and update ans if smaller.
      #|TERMINATION:
      #|At u = n, ans is the minimum Hamiltonian cycle cost.
    ),
  }
  if best >= inf {
    -1
  } else {
    best
  }
}

///|
test "tsp_min_cycle" {
  let inf = 1_000_000
  let dist : Array[Array[Int]] = [
    [0, 1, 3, 4],
    [1, 0, 2, 5],
    [3, 2, 0, 6],
    [4, 5, 6, 0],
  ]
  assert_eq(tsp_min_cycle(dist, inf), 13)
}
