// ============================================================================
// Challenge: Dijkstra Shortest Paths (O(n^2))
// Non-negative edge weights with array-based selection
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Compute shortest path distances from src in a non-negative graph.
/// adj[u] entries are (v, weight).
#warnings("+missing_invariant+missing_reasoning")
pub fn dijkstra(adj : Array[Array[(Int, Int)]], src : Int) -> Array[Int] {
  let n = adj.length()
  let dist = Array::make(n, INF)
  let used = Array::make(n, false)
  if src < 0 || src >= n {
    return dist
  }
  dist[src] = 0
  for iter = 0; iter < n; iter = iter + 1 {
    let mut u = -1
    let mut best = INF
    for i = 0; i < n; i = i + 1 {
      if !used[i] && dist[i] < best {
        u = i
        best = dist[i]
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Min scan):
        #|best is the smallest dist among unvisited nodes in [0..i).
        #|MAINTENANCE:
        #|Update best when a smaller unvisited distance is found.
        #|TERMINATION:
        #|At i = n, u is the unvisited node with minimum dist (if any).
      ),
    }
    if u < 0 {
      break
    }
    used[u] = true
    let neighbors = adj[u]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let (v, w) = neighbors[j]
      let cand = dist[u] + w
      if !used[v] && cand < dist[v] {
        dist[v] = cand
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (Relaxation scan):
        #|All edges neighbors[0..j) have been relaxed from u.
        #|MAINTENANCE:
        #|Relax edge (u -> v) and update dist[v] if a shorter path is found.
        #|TERMINATION:
        #|After the loop, all outgoing edges from u are processed.
      ),
    }
  } where {
    invariant: iter >= 0 && iter <= n,
    invariant: dist.length() == n && used.length() == n,
    reasoning: (
      #|INVARIANT (Dijkstra frontier):
      #|All used nodes have final shortest distances from src.
      #|For unused nodes, dist is the shortest path using only used nodes
      #|as intermediate vertices.
      #|MAINTENANCE:
      #|Select the unused node with minimum tentative distance and relax edges.
      #|TERMINATION:
      #|After n iterations or when no reachable nodes remain, dist is correct.
    ),
  }
  dist
}

///|
test "dijkstra_basic" {
  let adj : Array[Array[(Int, Int)]] = [
    [(1, 2), (2, 5)],
    [(2, 1), (3, 2)],
    [(3, 3)],
    [(4, 1)],
    [],
  ]
  let dist = dijkstra(adj, 0)
  assert_eq(dist, [0, 2, 3, 4, 5])
  let dist2 = dijkstra(adj, 4)
  assert_eq(dist2[0], INF)
}
