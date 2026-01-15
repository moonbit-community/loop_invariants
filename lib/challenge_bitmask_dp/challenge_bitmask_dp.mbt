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
  let dp : Array[Array[Int]] = Array::makei(total, fn(_) { Array::make(n, inf) })
  dp[1][0] = 0
  for mask = 1; mask < total; mask = mask + 1 {
    for u = 0; u < n; u = u + 1 {
      if dp[mask][u] < inf {
        for v = 0; v < n; v = v + 1 {
          if (mask & (1 << v)) == 0 {
            let new_mask = mask | (1 << v)
            let cand = dp[mask][u] + dist[u][v]
            if cand < dp[new_mask][v] {
              dp[new_mask][v] = cand
            }
          }
        } where {
          invariant: v >= 0 && v <= n,
          reasoning: (
            #|INVARIANT (Transition over v):
            #|All destinations < v have been relaxed from (mask, u).
            #|MAINTENANCE:
            #|Try extending the path to v and update dp[new_mask][v].
            #|TERMINATION:
            #|At v = n, all outgoing transitions are processed.
          ),
        }
      }
    } where {
      invariant: u >= 0 && u <= n,
      reasoning: (
        #|INVARIANT (States for mask):
        #|All dp[mask][u] for u < current u have been expanded.
        #|MAINTENANCE:
        #|Expand transitions from dp[mask][u] to unvisited v.
        #|TERMINATION:
        #|At u = n, all states for this mask are processed.
      ),
    }
  } where {
    invariant: mask >= 1 && mask <= total,
    reasoning: (
      #|INVARIANT (Masks processed):
      #|All dp states for masks < current mask are finalized.
      #|MAINTENANCE:
      #|Process transitions from the current mask.
      #|TERMINATION:
      #|At mask = total, all subsets are processed.
    ),
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
