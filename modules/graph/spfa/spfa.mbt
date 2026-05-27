// ============================================================================
// SPFA (Shortest Path Faster Algorithm)
// ============================================================================
//
// PROBLEM
//
// Single-source shortest paths in a graph that may contain **negative**
// edges (but no negative-cycle on the path from the source).
//
// SPFA is a queue-based variant of Bellman-Ford. Instead of relaxing
// every edge on every iteration, it relaxes only the edges out of
// vertices whose distance changed in the previous round.
//
// COMPLEXITY
//
//   Worst case  : O(V * E) -- same as Bellman-Ford
//   Random      : Often near O(E) on competitive-programming inputs
//   Pathological: A known family (e.g. zigzag grids with adversarial
//                 edge ordering) realises the worst case.
//
// NEGATIVE-CYCLE DETECTION
//
// If a vertex enters the queue more than `n - 1` times, a negative
// cycle is reachable from the source. We return early with a flag.
//
// THE INVARIANT
//
//   "At the start of each outer iteration, dist[v] equals the length
//    of some path from source to v (possibly suboptimal), and any
//    vertex u with a tighter path obtainable via a relaxable edge is
//    in the queue."
//
// When the queue empties (and no negative cycle is detected), the
// distance array is optimal.

///|
/// A weighted directed edge.
pub(all) struct Edge {
  to : Int
  w : Int64
}

///|
/// Distance sentinel; representative of "infinity". Safe under one
/// addition (`dist[u] + w` cannot overflow when `dist[u] < INF`).
pub const INF : Int64 = 4611686018427387903L

///|
/// Result of running SPFA.
///
/// - `dist`           : shortest distance from `source`; `INF` if unreachable
/// - `parent`         : predecessor vertex on the shortest path; `-1` if source or unreachable
/// - `negative_cycle` : `true` iff a negative cycle is reachable from `source`.
///                       When this is `true`, `dist` is unreliable.
pub(all) struct SpfaResult {
  dist : Array[Int64]
  parent : Array[Int]
  negative_cycle : Bool
}

///|
/// SSSP via SPFA. `n` is the vertex count (vertices are `0..n`).
/// `adj[u]` is the list of outgoing edges from `u`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let adj : Array[Array[@spfa.Edge]] = [
///     [{ to: 1, w: 4L }, { to: 2, w: 5L }],
///     [{ to: 2, w: -3L }],
///     [],
///   ]
///   let r = @spfa.shortest_path(3, adj, 0)
///   @debug.assert_eq(r.dist[2], 1L) // 0 -> 1 -> 2: 4 + (-3) = 1
/// }
/// ```
pub fn shortest_path(
  n : Int,
  adj : Array[Array[Edge]],
  source : Int,
) -> SpfaResult {
  let dist = Array::make(n, INF)
  let parent = Array::make(n, -1)
  if source < 0 || source >= n {
    return { dist, parent, negative_cycle: false }
  }
  dist[source] = 0L
  // SLF-like queue using a circular buffer; we use a plain queue plus
  // an `in_queue` flag.
  let queue : Array[Int] = []
  let in_queue = Array::make(n, false)
  let count = Array::make(n, 0)
  queue.push(source)
  in_queue[source] = true
  count[source] = 1
  let mut head = 0
  let mut neg_cycle = false
  while head < queue.length() {
    let u = queue[head]
    head = head + 1
    in_queue[u] = false
    if dist[u] >= INF {
      continue
    }
    for e in adj[u] {
      if e.to < 0 || e.to >= n {
        continue
      }
      let alt = dist[u] + e.w
      if alt < dist[e.to] {
        dist[e.to] = alt
        parent[e.to] = u
        if !in_queue[e.to] {
          queue.push(e.to)
          in_queue[e.to] = true
          count[e.to] = count[e.to] + 1
          if count[e.to] >= n {
            neg_cycle = true
            break
          }
        }
      }
    }
    if neg_cycle {
      break
    }
  }
  { dist, parent, negative_cycle: neg_cycle }
}

///|
/// Reconstruct the path from `source` to `target` using `parent`.
/// Returns `[]` when no path exists.
pub fn reconstruct(
  parent : Array[Int],
  source : Int,
  target : Int,
) -> Array[Int] {
  let path : Array[Int] = []
  let mut v = target
  while v != -1 && v != source {
    path.push(v)
    v = parent[v]
  }
  if v != source {
    return []
  }
  path.push(source)
  // Reverse.
  let mut i = 0
  let mut j = path.length() - 1
  while i < j {
    let t = path[i]
    path[i] = path[j]
    path[j] = t
    i = i + 1
    j = j - 1
  }
  path
}

///|
test "spfa basic positive weights" {
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 7L }, { to: 2, w: 9L }, { to: 5, w: 14L }],
    [{ to: 0, w: 7L }, { to: 2, w: 10L }, { to: 3, w: 15L }],
    [{ to: 0, w: 9L }, { to: 1, w: 10L }, { to: 3, w: 11L }, { to: 5, w: 2L }],
    [{ to: 1, w: 15L }, { to: 2, w: 11L }, { to: 4, w: 6L }],
    [{ to: 3, w: 6L }, { to: 5, w: 9L }],
    [{ to: 0, w: 14L }, { to: 2, w: 2L }, { to: 4, w: 9L }],
  ]
  let r = shortest_path(6, adj, 0)
  let expected = [0L, 7L, 9L, 20L, 20L, 11L]
  for v in 0..<6 {
    @debug.assert_eq(r.dist[v], expected[v])
  }
  @debug.assert_eq(r.negative_cycle, false)
}

///|
test "spfa with negative edge no cycle" {
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 4L }, { to: 2, w: 5L }],
    [{ to: 2, w: -3L }],
    [],
  ]
  let r = shortest_path(3, adj, 0)
  @debug.assert_eq(r.dist[2], 1L)
  @debug.assert_eq(r.negative_cycle, false)
}

///|
test "spfa negative cycle detected" {
  // 0 -> 1 (1), 1 -> 2 (1), 2 -> 1 (-3): cycle 1 - 2 - 1 of total -2.
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 1L }],
    [{ to: 2, w: 1L }],
    [{ to: 1, w: -3L }],
  ]
  let r = shortest_path(3, adj, 0)
  @debug.assert_eq(r.negative_cycle, true)
}

///|
test "spfa unreachable" {
  let adj : Array[Array[Edge]] = [[{ to: 1, w: 1L }], [], []]
  let r = shortest_path(3, adj, 0)
  @debug.assert_eq(r.dist[2], INF)
}

///|
test "spfa empty graph" {
  let r = shortest_path(0, [], 0)
  @debug.assert_eq(r.dist.length(), 0)
}

///|
test "spfa source out of range" {
  let adj : Array[Array[Edge]] = [[]]
  let r = shortest_path(1, adj, -1)
  @debug.assert_eq(r.dist[0], INF)
}

///|
test "spfa path reconstruction" {
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 1L }, { to: 2, w: 10L }],
    [{ to: 3, w: 2L }],
    [{ to: 3, w: 1L }],
    [],
  ]
  let r = shortest_path(4, adj, 0)
  @debug.assert_eq(r.dist[3], 3L) // 0 -> 1 -> 3
  let path = reconstruct(r.parent, 0, 3)
  @debug.assert_eq(path, [0, 1, 3])
}
