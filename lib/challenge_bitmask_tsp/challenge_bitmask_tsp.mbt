// ============================================================================
// Challenge: TSP (Bitmask DP)
// Minimum Hamiltonian cycle starting at node 0
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Return minimal tour cost visiting all nodes and returning to 0.
#warnings("+missing_invariant+missing_reasoning")
pub fn tsp_min_cycle(dist : Array[Array[Int]]) -> Int {
  let n = dist.length()
  if n <= 1 {
    return 0
  }
  let total = 1 << n
  let dp : Array[Array[Int]] = Array::makei(total, _ => Array::make(n, INF))
  dp[1][0] = 0
  for mask = 1; mask < total; mask = mask + 1 {
    for u = 0; u < n; u = u + 1 {
      if (mask & (1 << u)) != 0 && dp[mask][u] != INF {
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
            #|INVARIANT (Extend tour):
            #|All candidates to extend from u using nodes < v are considered.
            #|MAINTENANCE:
            #|Try visiting v if not yet in mask.
            #|TERMINATION:
            #|At v = n, all next steps from u are processed.
          ),
        }
      }
    } where {
      invariant: u >= 0 && u <= n,
      reasoning: (
        #|INVARIANT (End node scan):
        #|All dp[mask][u'] for u' < u have been relaxed for this mask.
        #|MAINTENANCE:
        #|Use dp[mask][u] to extend to unvisited nodes.
        #|TERMINATION:
        #|At u = n, this mask is fully processed.
      ),
    }
  } where {
    invariant: mask >= 1 && mask <= total,
    reasoning: (
      #|INVARIANT (Subset DP):
      #|dp holds the best costs for all masks < current.
      #|MAINTENANCE:
      #|Extend tours by one node while preserving minimality.
      #|TERMINATION:
      #|At mask = total, all subsets are processed.
    ),
  }
  let full = total - 1
  for u = 1, best = INF; u < n; {
    let cand = dp[full][u] + dist[u][0]
    continue u + 1, if cand < best { cand } else { best }
  } else {
    best
  } where {
    invariant: u >= 1 && u <= n,
    reasoning: (
      #|INVARIANT (Close tour):
      #|best is the minimum tour cost using end nodes in [1..u).
      #|MAINTENANCE:
      #|Close the tour at u and update best if smaller.
      #|TERMINATION:
      #|At u = n, best is the optimal tour cost.
    ),
  }
}
