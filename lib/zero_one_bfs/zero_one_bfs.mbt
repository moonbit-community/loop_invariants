// ============================================================================
// 0-1 BFS - Shortest Paths with Edge Weights 0 or 1
// ============================================================================
//
// 0-1 BFS computes single-source shortest paths on graphs whose edge weights
// are only 0 or 1. It replaces Dijkstra's priority queue with a deque:
// - weight 0 edges push the neighbor to the front  (same distance)
// - weight 1 edges push the neighbor to the back   (distance + 1)
//
// This maintains a nondecreasing distance order in the deque, giving an
// O(V + E) time bound.
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V + E)

///|
/// Sentinel distance used for unreachable vertices.
///
/// Any vertex whose final distance equals this value was not reachable from
/// the source. The value is 1,000,000,000, which is safely below `Int` overflow
/// when added to 0 or 1.
const ZERO_ONE_INF : Int = 1000000000

///|
/// A directed edge with a weight that must be 0 or 1.
///
/// `to` is the destination vertex index (0-based).
/// `weight` must be 0 or 1; any other value produces undefined results.
pub struct Edge {
  to : Int
  weight : Int
} derive(Debug)

///|
/// A directed graph stored as an adjacency list, suitable for 0-1 BFS.
///
/// Vertices are numbered 0 to `n - 1`. Each entry in `adj[u]` is an `Edge`
/// leaving vertex `u`.
pub struct Graph {
  n : Int
  adj : Array[Array[Edge]]
}

///|
/// Create an empty directed graph with `n` vertices and no edges.
///
/// All vertex indices used with `add_edge`, `add_undirected_edge`, and
/// `zero_one_bfs` must be in the range `[0, n)`.
///
/// # Example
///
/// ```
/// let g = Graph(5)   // vertices 0..4
/// ```
pub fn Graph::Graph(n : Int) -> Graph {
  let adj : Array[Array[Edge]] = [ for _ in 0..<n => [] ]
  { n, adj }
}

///|
/// Add a directed edge `u -> v` with the given weight (0 or 1).
///
/// The edge is one-directional: traversal is only allowed from `u` to `v`.
/// For an undirected edge use `add_undirected_edge`.
///
/// # Parameters
///
/// - `u`: source vertex (0-based)
/// - `v`: destination vertex (0-based)
/// - `weight`: must be 0 or 1
///
/// # Example
///
/// ```
/// let g = Graph(3)
/// g.add_edge(0, 1, 0)   // free edge
/// g.add_edge(1, 2, 1)   // unit-cost edge
/// ```
pub fn Graph::add_edge(self : Graph, u : Int, v : Int, weight : Int) -> Unit {
  self.adj[u].push({ to: v, weight })
}

///|
/// Add an undirected edge between `u` and `v` with the given weight (0 or 1).
///
/// This is a convenience wrapper that calls `add_edge` in both directions, so
/// the edge can be traversed from `u` to `v` and from `v` to `u`.
///
/// # Parameters
///
/// - `u`, `v`: endpoints (0-based, order does not matter)
/// - `weight`: must be 0 or 1
///
/// # Example
///
/// ```
/// let g = Graph(4)
/// g.add_undirected_edge(0, 1, 0)   // bidirectional free edge
/// g.add_undirected_edge(1, 2, 1)   // bidirectional unit-cost edge
/// ```
pub fn Graph::add_undirected_edge(
  self : Graph,
  u : Int,
  v : Int,
  weight : Int,
) -> Unit {
  self.add_edge(u, v, weight)
  self.add_edge(v, u, weight)
}

///|
/// Compute the shortest distance from `source` to every other vertex using
/// 0-1 BFS.
///
/// Returns an array `dist` of length `graph.n` where `dist[v]` is the
/// shortest-path distance from `source` to `v`. Vertices unreachable from
/// `source` keep the sentinel value `ZERO_ONE_INF` (1,000,000,000).
///
/// # Algorithm
///
/// The algorithm maintains a deque and the invariant that every element in the
/// deque has a distance no less than the front element. When a vertex `u` is
/// popped from the front:
///
/// - For each edge `u -> v` with weight `w`:
///   - Compute candidate distance `nd = dist[u] + w`.
///   - If `nd < dist[v]`, update `dist[v] = nd`.
///   - Push `v` to the **front** if `w == 0` (same distance level) or to the
///     **back** if `w == 1` (next distance level).
///
/// This guarantees that the deque is always sorted in non-decreasing order of
/// distance, so the front always yields the globally minimum tentative distance.
///
/// # Complexity
///
/// - Time: O(V + E) — each vertex and edge is processed at most twice
/// - Space: O(V + E) — for the distance array and the deque
///
/// # Parameters
///
/// - `graph`: the directed graph built with `Graph::new` and `add_edge`
/// - `source`: the starting vertex (0-based)
///
/// # Example
///
/// ```
/// let g = Graph(3)
/// g.add_edge(0, 1, 0)
/// g.add_edge(1, 2, 1)
/// let dist = zero_one_bfs(g, 0)
/// // dist == [0, 0, 1]
/// ```
pub fn zero_one_bfs(graph : Graph, source : Int) -> Array[Int] {
  let n = graph.n
  let dist = Array::make(n, ZERO_ONE_INF)
  if n == 0 {
    return dist
  }
  dist[source] = 0
  let deque : @deque.Deque[Int] = @deque.Deque::new()
  deque.push_front(source)
  let _ = for popped = deque.pop_front() {
    match popped {
      None => break ()
      Some(u) => {
        let du = dist[u]
        for e in graph.adj[u] {
          let nd = du + e.weight
          if nd < dist[e.to] {
            dist[e.to] = nd
            if e.weight == 0 {
              deque.push_front(e.to)
            } else {
              deque.push_back(e.to)
            }
          }
        }
        continue deque.pop_front()
      }
    }
  }
  dist
}
