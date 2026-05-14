// ============================================================================
// HELD-KARP TSP - Exact Traveling Salesman via bitmask DP
// ============================================================================
//
// PROBLEM
//
// Given `n` cities and a (possibly asymmetric) cost matrix
// `cost[i][j]` for travelling from city `i` directly to city `j`,
// find the cheapest Hamiltonian tour: a permutation of cities that
// starts at city 0, visits every other city exactly once, and
// returns to city 0.
//
// The brute-force enumeration of permutations costs `O(n!)`. Held &
// Karp (1962) gave the celebrated `O(2^n · n^2)` bitmask DP which is
// the best known *exact* algorithm for general TSP. It is fast
// enough for `n` up to about 20.
//
// THE STATE
//
//   dp[mask][i]  =  minimum cost of a path that
//                     - starts at city 0
//                     - visits exactly the cities in `mask`
//                     - ends at city i
//
// where `mask` is a bitmask with bit j set iff city j has been visited.
// Note: bit 0 is *always* set (the path starts at 0). For each mask the
// number of set bits equals the path length so far.
//
// BASE CASE
//
//   dp[{0}][0] = 0       (we're sitting at city 0; cost 0)
//   all other dp[*][*] = +inf
//
// RECURRENCE
//
//   for each mask with bit 0 set and |mask| >= 2:
//     for each i in mask, i != 0:
//       dp[mask][i] = min over j in mask, j != i of:
//         dp[mask \ {i}][j] + cost[j][i]
//
// FINAL ANSWER
//
//   min over i != 0 of (dp[{all}][i] + cost[i][0])
//
// where `{all}` is the bitmask `(1 << n) - 1`.
//
// THE LOOP INVARIANT
//
// At the end of the outer mask loop, dp[mask][*] is fully computed for
// every mask processed so far. The processing order matters: we must
// have dp[mask \ {i}] available, so we iterate masks in increasing
// `popcount` (or equivalently in numeric order since smaller masks
// have at most as many set bits as we need).
//
// TIME COMPLEXITY  : O(2^n * n^2)
// SPACE COMPLEXITY : O(2^n * n)

///|
/// Sentinel for "unreachable / infinite cost." Set to a value safely
/// summable with finite Int64 costs without overflow.
let hk_inf : Int64 = 1000000000000000000L

///|
/// Solve TSP exactly via Held-Karp dynamic programming.
///
/// ## Parameters
///
/// - `n`    : number of cities; must satisfy `0 <= n <= 20` for the
///            DP table (`2^n` entries times `n`) to fit in memory.
/// - `cost` : `n x n` cost matrix. `cost[i][j]` is the cost of going
///            directly from city `i` to city `j`. The matrix need
///            **not** be symmetric; this implementation handles both
///            symmetric (classical) and asymmetric TSP.
///
/// ## Returns
///
/// The cost of the cheapest Hamiltonian tour, or `None` when:
///   - `n` is zero, one, or out of range
///   - the cost matrix is malformed
///   - no Hamiltonian tour exists (some required edge is missing in
///     a sparse graph, encoded by passing `Int64::MAX_VALUE` for
///     unreachable edges)
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 3-city symmetric, costs 1-2-3 around the triangle.
///   let cost : Array[Array[Int64]] = [[0L, 1L, 3L], [1L, 0L, 2L], [3L, 2L, 0L]]
///   // Cheapest tour 0 -> 1 -> 2 -> 0 has cost 1 + 2 + 3 = 6.
///   assert_eq(@held_karp_tsp.shortest_tour(3, cost[:]), Some(6L))
/// }
/// ```
pub fn shortest_tour(n : Int, cost : ArrayView[Array[Int64]]) -> Int64? {
  if n <= 0 || n > 20 {
    return None
  }
  if cost.length() != n {
    return None
  }
  for row in cost {
    if row.length() != n {
      return None
    }
  }
  if n == 1 {
    // Degenerate tour: stay at city 0; cost is 0.
    return Some(0L)
  }
  let total_states = 1 << n
  // dp[mask * n + i] = the entry described in the file header.
  let dp = Array::make(total_states * n, hk_inf)
  // Base case: at city 0, only city 0 visited.
  dp[(1 << 0) * n + 0] = 0L
  // Iterate masks in numeric order; smaller masks (by popcount) come
  // first numerically up to interspersion, so we additionally require
  // the "current" mask to include bit 0 (the start city).
  for mask in 0..<total_states {
    if (mask & 1) == 0 {
      // Bit 0 must be set (tour starts at city 0).
      continue
    }
    for i in 0..<n {
      if (mask & (1 << i)) == 0 {
        continue
      }
      if dp[mask * n + i] >= hk_inf {
        continue
      }
      // Try extending the path by one new city j not yet visited.
      for j in 1..<n {
        if (mask & (1 << j)) != 0 {
          continue
        }
        let next_mask = mask | (1 << j)
        let candidate = dp[mask * n + i] + cost[i][j]
        if candidate < dp[next_mask * n + j] {
          dp[next_mask * n + j] = candidate
        }
      }
    }
  } where {
    proof_invariant: mask >= 0 && mask <= total_states,
    proof_reasoning: (
      #|INVARIANT (Held-Karp DP):
      #|After processing the inner loops for masks [0..mask),
      #|dp[m][i] holds the minimum cost of a path starting at city 0,
      #|visiting exactly the cities in m, and ending at i, for every
      #|(m, i) we have already seen.
      #|
      #|MAINTENANCE:
      #|We process each (m, i) by trying every extension i -> j
      #|where j is not yet in m, and tightening dp[m | {j}][j] if
      #|the new path is cheaper.
      #|
      #|TERMINATION:
      #|At mask = total_states, every reachable (mask, i) has been
      #|fully computed.
    ),
  }
  // Final answer: min over i != 0 of dp[all][i] + cost[i][0].
  let full = total_states - 1
  let mut best : Int64 = hk_inf
  for i in 1..<n {
    let leg = dp[full * n + i]
    if leg < hk_inf {
      let candidate = leg + cost[i][0]
      if candidate < best {
        best = candidate
      }
    }
  } where {
    proof_invariant: i >= 1 && i <= n,
    proof_invariant: best >= 0L,
    proof_reasoning: (
      #|INVARIANT (Closing leg):
      #|best is the minimum, over end-cities [1..i), of
      #|dp[full][end] + cost[end][0] -- i.e. the cheapest way to
      #|finish the Hamiltonian tour by returning to city 0.
    ),
  }
  if best >= hk_inf {
    None
  } else {
    Some(best)
  }
}

///|
test "held-karp triangle" {
  let cost : Array[Array[Int64]] = [[0L, 1L, 3L], [1L, 0L, 2L], [3L, 2L, 0L]]
  // Cheapest Hamiltonian tour: 0 -> 1 -> 2 -> 0  =  1 + 2 + 3 = 6.
  @debug.assert_eq(shortest_tour(3, cost[:]), Some(6L))
}

///|
test "held-karp asymmetric four cities" {
  // Asymmetric: cost[i][j] differs from cost[j][i].
  let cost : Array[Array[Int64]] = [
    [0L, 10L, 15L, 20L],
    [5L, 0L, 9L, 10L],
    [6L, 13L, 0L, 12L],
    [8L, 8L, 9L, 0L],
  ]
  let result = shortest_tour(4, cost[:])
  // Reference value for this well-known example: cheapest tour
  // 0 -> 1 -> 3 -> 2 -> 0 has cost 10 + 10 + 9 + 6 = 35.
  @debug.assert_eq(result, Some(35L))
}

///|
test "held-karp single city is zero" {
  let cost : Array[Array[Int64]] = [[0L]]
  @debug.assert_eq(shortest_tour(1, cost[:]), Some(0L))
}

///|
test "held-karp empty input is none" {
  let cost : Array[Array[Int64]] = []
  @debug.assert_eq(shortest_tour(0, cost[:]), None)
}

///|
test "held-karp two cities is roundtrip" {
  let cost : Array[Array[Int64]] = [[0L, 7L], [4L, 0L]]
  // The "tour" 0 -> 1 -> 0 has cost 7 + 4 = 11 (asymmetric).
  @debug.assert_eq(shortest_tour(2, cost[:]), Some(11L))
}

///|
test "held-karp disconnected gives none" {
  // City 2 cannot be reached from anywhere (cost 1e18 sentinel).
  let inf = hk_inf
  let cost : Array[Array[Int64]] = [
    [0L, 1L, inf],
    [1L, 0L, inf],
    [inf, inf, 0L],
  ]
  @debug.assert_eq(shortest_tour(3, cost[:]), None)
}

///|
test "held-karp malformed matrix is none" {
  // Row count mismatch.
  let cost : Array[Array[Int64]] = [[0L, 1L], [1L, 0L]]
  @debug.assert_eq(shortest_tour(3, cost[:]), None)
}

///|
test "held-karp five cities matches brute force" {
  // Specifically constructed so we can verify by enumeration.
  let cost : Array[Array[Int64]] = [
    [0L, 2L, 9L, 10L, 4L],
    [2L, 0L, 6L, 4L, 8L],
    [9L, 6L, 0L, 3L, 7L],
    [10L, 4L, 3L, 0L, 5L],
    [4L, 8L, 7L, 5L, 0L],
  ]
  // Brute-force minimum over the 24 tours starting at 0:
  // best is 0 -> 1 -> 3 -> 2 -> 4 -> 0 = 2 + 4 + 3 + 7 + 4 = 20.
  @debug.assert_eq(shortest_tour(5, cost[:]), Some(20L))
}
