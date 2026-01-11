// ============================================================================
// Challenge: Bellman-Ford Shortest Paths
// Handles negative weights and detects negative cycles
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Compute shortest paths from src using Bellman-Ford.
/// Returns (distances, has_negative_cycle_reachable).
#warnings("+missing_invariant+missing_reasoning")
pub fn bellman_ford(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
  src : Int,
) -> (Array[Int], Bool) {
  let dist = Array::make(n, INF)
  if src >= 0 && src < n {
    dist[src] = 0
  }
  let m = edges.length()
  for iter = 0; iter < n - 1; iter = iter + 1 {
    let mut changed = false
    for i = 0; i < m; i = i + 1 {
      let (u, v, w) = edges[i]
      if dist[u] != INF && dist[u] + w < dist[v] {
        dist[v] = dist[u] + w
        changed = true
      }
    } where {
      invariant: i >= 0 && i <= m,
      reasoning: (
        #|INVARIANT (Relaxation pass):
        #|After processing edges[0..i), all possible relaxations in that prefix
        #|have been applied to dist.
        #|MAINTENANCE:
        #|Relax the next edge if it improves the shortest known path.
        #|TERMINATION:
        #|At i = m, the full pass over edges is complete.
      ),
    }
    if !changed {
      break
    }
  } where {
    invariant: iter >= 0 && iter <= n - 1,
    reasoning: (
      #|INVARIANT (k-edge shortest paths):
      #|After iter iterations, dist holds shortest paths using at most iter
      #|edges from src.
      #|MAINTENANCE:
      #|One relaxation pass extends correctness to paths with one more edge.
      #|TERMINATION:
      #|After n-1 passes, all shortest paths are finalized unless a negative
      #|cycle is reachable.
    ),
  }
  let mut has_neg = false
  for i = 0; i < m; i = i + 1 {
    let (u, v, w) = edges[i]
    if dist[u] != INF && dist[u] + w < dist[v] {
      has_neg = true
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (Negative-cycle check):
      #|If any edge can still relax, a reachable negative cycle exists.
      #|MAINTENANCE:
      #|Scan edges and flag if a relaxation is possible.
      #|TERMINATION:
      #|At i = m, has_neg reflects the presence of a negative cycle.
    ),
  }
  (dist, has_neg)
}

///|
test "bellman_ford_basic" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (0, 2, 5),
    (2, 3, 1),
  ]
  let (dist, neg) = bellman_ford(4, edges[:], 0)
  assert_eq(dist, [0, 1, 3, 4])
  assert_eq(neg, false)
}

///|
test "bellman_ford_negative_cycle" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, -2), (2, 1, -2)]
  let (_dist, neg) = bellman_ford(3, edges[:], 0)
  assert_eq(neg, true)
}
