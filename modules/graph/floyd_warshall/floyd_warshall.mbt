// ============================================================================
// FLOYD-WARSHALL  -  Floyd 1962, Warshall 1962
// ============================================================================
//
// PROBLEM
//
// Compute the shortest path between **every** pair of vertices in a
// weighted directed graph with up to `n` vertices. Edge weights may be
// negative, but a negative-weight cycle must not be reachable on any
// queried pair (we detect it and report).
//
// THE DP
//
//   dp[k][i][j] = shortest path from i to j using only intermediate
//                  vertices in {0, 1, ..., k-1}.
//
//   dp[k][i][j] = min( dp[k-1][i][j],                  -- don't use k-1
//                      dp[k-1][i][k-1] + dp[k-1][k-1][j] )
//                                                       -- use k-1 as a hop
//
// The standard implementation rolls the third dimension away and updates
// `dp[i][j]` in place during iteration `k`. Correctness is preserved
// because `dp[i][k]` and `dp[k][j]` cannot decrease during the iteration
// in which `k` is the new intermediate vertex.
//
// COMPLEXITY
//
//   Time : O(n^3)
//   Space: O(n^2) for the distance matrix; O(n^2) for path reconstruction.
//
// NEGATIVE CYCLE DETECTION
//
//   After running the main loop, if `dp[v][v] < 0` for any `v`, then
//   `v` lies on a negative-weight cycle.
//
// THE INVARIANT
//
//   "After iteration k of the outer loop, dp[i][j] equals the shortest
//    distance from i to j using only vertices in {0, ..., k-1} as
//    intermediates."

///|
/// "Effectively infinite" distance sentinel that survives one addition
/// without overflowing `Int64`. We add at most n^2 edges of weight INF
/// during the algorithm; staying well below `Int64.max_value / 2`
/// keeps `dp[i][k] + dp[k][j]` safe even when both operands are INF.
pub const INF : Int64 = 1000000000000000000L

///|
/// All-pairs shortest paths. The input is a square `n x n` matrix where
/// `weight[i][j]` is the weight of edge `i -> j`, or `INF` if no such
/// edge exists. `weight[i][i]` should be `0` for self-loops.
///
/// Returns the distance matrix `dist` of the same shape, where
/// `dist[i][j]` is either the shortest-path cost or `INF` if `j` is
/// unreachable from `i`. If a vertex on a negative cycle is on a path
/// between `i` and `j`, that cell will be `<= -INF/2` -- callers may
/// want to call `has_negative_cycle` to detect this explicitly.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let inf = @floyd_warshall.INF
///   let w = [
///     [0L, 3L, inf, 7L],
///     [8L, 0L, 2L, inf],
///     [5L, inf, 0L, 1L],
///     [2L, inf, inf, 0L],
///   ]
///   let d = @floyd_warshall.apsp(w)
///   @debug.assert_eq(d[0][2], 5L) // 0->1->2 = 5
/// }
/// ```
pub fn apsp(weight : Array[Array[Int64]]) -> Array[Array[Int64]] {
  let n = weight.length()
  let dist = Array::makei(n, i => Array::makei(n, j => weight[i][j]))
  for k in 0..<n {
    for i in 0..<n {
      if dist[i][k] >= INF {
        continue
      }
      for j in 0..<n {
        if dist[k][j] >= INF {
          continue
        }
        let alt = dist[i][k] + dist[k][j]
        if alt < dist[i][j] {
          dist[i][j] = alt
        }
      }
    }
  }
  dist
}

///|
/// Detect whether the graph (encoded in `dist` after `apsp`) contains a
/// reachable negative cycle.
pub fn has_negative_cycle(dist : Array[Array[Int64]]) -> Bool {
  let n = dist.length()
  for i in 0..<n {
    if dist[i][i] < 0L {
      return true
    }
  }
  false
}

///|
/// Run APSP **and** record the predecessor matrix so paths can be
/// reconstructed. Returns `(dist, next_hop)` where
/// `next_hop[i][j]` is the next vertex on the shortest path from `i`
/// to `j` (or `-1` if unreachable or `i == j`).
pub fn apsp_with_path(
  weight : Array[Array[Int64]],
) -> (Array[Array[Int64]], Array[Array[Int]]) {
  let n = weight.length()
  let dist = Array::makei(n, i => Array::makei(n, j => weight[i][j]))
  let next_hop = Array::makei(n, i => {
    Array::makei(n, j => if i == j || weight[i][j] >= INF { -1 } else { j })
  })
  for k in 0..<n {
    for i in 0..<n {
      if dist[i][k] >= INF {
        continue
      }
      for j in 0..<n {
        if dist[k][j] >= INF {
          continue
        }
        let alt = dist[i][k] + dist[k][j]
        if alt < dist[i][j] {
          dist[i][j] = alt
          next_hop[i][j] = next_hop[i][k]
        }
      }
    }
  }
  (dist, next_hop)
}

///|
/// Reconstruct the path from `src` to `dst` using `next_hop` produced
/// by `apsp_with_path`. Returns an empty array if no path exists.
pub fn reconstruct(
  next_hop : Array[Array[Int]],
  src : Int,
  dst : Int,
) -> Array[Int] {
  let path : Array[Int] = []
  if src == dst {
    path.push(src)
    return path
  }
  if next_hop[src][dst] == -1 {
    return path
  }
  let mut u = src
  path.push(u)
  while u != dst {
    let nxt = next_hop[u][dst]
    if nxt == -1 {
      // Defensive; should not happen if input is consistent.
      return []
    }
    path.push(nxt)
    u = nxt
  }
  path
}

///|
test "floyd small graph" {
  let w = [
    [0L, 3L, INF, 7L],
    [8L, 0L, 2L, INF],
    [5L, INF, 0L, 1L],
    [2L, INF, INF, 0L],
  ]
  let d = apsp(w)
  // Reference values (computed by hand).
  @debug.assert_eq(d[0][0], 0L)
  @debug.assert_eq(d[0][1], 3L)
  @debug.assert_eq(d[0][2], 5L) // 0 -> 1 -> 2
  @debug.assert_eq(d[0][3], 6L) // 0 -> 1 -> 2 -> 3
  @debug.assert_eq(d[1][0], 5L) // 1 -> 2 -> 3 -> 0
  @debug.assert_eq(d[1][3], 3L) // 1 -> 2 -> 3
  @debug.assert_eq(d[3][0], 2L)
}

///|
test "floyd unreachable" {
  // 0 -> 1; 2 isolated.
  let w = [[0L, 1L, INF], [INF, 0L, INF], [INF, INF, 0L]]
  let d = apsp(w)
  @debug.assert_eq(d[0][2], INF)
  @debug.assert_eq(d[1][2], INF)
}

///|
test "floyd zero vertices" {
  let d = apsp([])
  @debug.assert_eq(d.length(), 0)
}

///|
test "floyd negative edges no cycle" {
  // Edges 0->1 (4), 0->2 (5), 1->2 (-2). No cycle.
  let w = [[0L, 4L, 5L], [INF, 0L, -2L], [INF, INF, 0L]]
  let d = apsp(w)
  @debug.assert_eq(d[0][2], 2L) // 0 -> 1 -> 2: 4 + (-2) = 2
  @debug.assert_eq(has_negative_cycle(d), false)
}

///|
test "floyd negative cycle detected" {
  // 0 -> 1 (1), 1 -> 0 (-2). Cycle of total -1.
  let w = [[0L, 1L], [-2L, 0L]]
  let d = apsp(w)
  @debug.assert_eq(has_negative_cycle(d), true)
}

///|
test "floyd path reconstruction" {
  let w = [
    [0L, 3L, INF, 7L],
    [8L, 0L, 2L, INF],
    [5L, INF, 0L, 1L],
    [2L, INF, INF, 0L],
  ]
  let (d, next_hop) = apsp_with_path(w)
  @debug.assert_eq(d[0][3], 6L)
  let path = reconstruct(next_hop, 0, 3)
  @debug.assert_eq(path, [0, 1, 2, 3])
  // Self path.
  @debug.assert_eq(reconstruct(next_hop, 2, 2), [2])
  // Unreachable case.
  let w2 = [[0L, 1L, INF], [INF, 0L, INF], [INF, INF, 0L]]
  let (_, nh2) = apsp_with_path(w2)
  @debug.assert_eq(reconstruct(nh2, 0, 2), [])
}

///|
test "floyd compared with brute force" {
  // Random small graph: compare against single-source brute (Bellman-style).
  let w = [
    [0L, 4L, 11L, INF],
    [INF, 0L, 2L, INF],
    [INF, INF, 0L, 3L],
    [1L, INF, INF, 0L],
  ]
  let d = apsp(w)
  // Brute: relax n times.
  let n = w.length()
  let b = Array::makei(n, i => Array::makei(n, j => w[i][j]))
  for _ in 0..<n {
    for u in 0..<n {
      for v in 0..<n {
        for k in 0..<n {
          if b[u][k] < INF && b[k][v] < INF && b[u][k] + b[k][v] < b[u][v] {
            b[u][v] = b[u][k] + b[k][v]
          }
        }
      }
    }
  }
  for i in 0..<n {
    for j in 0..<n {
      @debug.assert_eq(d[i][j], b[i][j])
    }
  }
}
