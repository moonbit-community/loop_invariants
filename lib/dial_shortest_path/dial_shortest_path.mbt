// ============================================================================
// DIAL'S ALGORITHM - Shortest Paths with Small Integer Weights
// ============================================================================
//
// Dial's algorithm is a bucketed version of Dijkstra for graphs with
// non-negative integer weights bounded by C. Distances are processed in
// increasing order by scanning buckets of vertices with the same tentative
// distance.
//
// KEY IDEA:
// If max weight is C, then the shortest path length is at most C*(n-1).
// We can keep an array of buckets indexed by distance, and relax edges
// in O(V + E + C*V) time.
//
// TIME COMPLEXITY: O(E + C*V)
// SPACE COMPLEXITY: O(E + C*V)

///|
/// Sentinel distance used for unreachable vertices.
///
/// Any vertex whose final `dist` entry equals this value was not reachable from
/// the source. The value 1,000,000,000 is large enough for practical graphs
/// while remaining safely below `Int` overflow when incremented by a single
/// edge weight.
const DIAL_INF : Int = 1000000000

///|
/// A directed edge with a non-negative integer weight.
///
/// `to` is the 0-based index of the destination vertex.
/// `weight` must satisfy `0 <= weight <= max_weight` as declared in the
/// enclosing `Graph`; larger values silently produce incorrect results.
pub struct Edge {
  to : Int
  weight : Int
} derive(Debug)

///|
/// A directed graph stored as an adjacency list, suitable for Dial's algorithm.
///
/// Vertices are numbered `0` to `n - 1`. The field `max_weight` declares the
/// upper bound `C` on any single edge weight; the algorithm allocates
/// `C * (n - 1) + 1` distance buckets, so keep `C` small.
///
/// # Fields
///
/// - `n`: number of vertices
/// - `max_weight`: maximum allowed edge weight `C`
/// - `adj`: `adj[u]` is the list of edges leaving vertex `u`
pub struct Graph {
  n : Int
  max_weight : Int
  adj : Array[Array[Edge]]
}

///|
/// Create an empty directed graph with `n` vertices and maximum edge weight
/// `max_weight`.
///
/// All vertex indices passed to `add_edge`, `add_undirected_edge`, and
/// `dial_shortest_paths` must lie in `[0, n)`. All edge weights must lie in
/// `[0, max_weight]`.
///
/// The algorithm pre-allocates `max_weight * (n - 1) + 1` distance buckets, so
/// choose `max_weight` to be the tightest correct upper bound.
///
/// # Parameters
///
/// - `n`: number of vertices (must be > 0 for meaningful results)
/// - `max_weight`: upper bound on edge weights; must be >= 0
///
/// # Example
///
/// ```
/// let g = @dial_shortest_path.Graph::new(5, 3)  // 5 vertices, weights in [0, 3]
/// ```
pub fn Graph::new(n : Int, max_weight : Int) -> Graph {
  let adj : Array[Array[Edge]] = Array::makei(n, _ => [])
  { n, max_weight, adj }
}

///|
/// Add a directed edge `u -> v` with the given weight.
///
/// The edge is one-directional. For a bidirectional edge use
/// `add_undirected_edge`. The weight must be in `[0, max_weight]`.
///
/// # Parameters
///
/// - `u`: source vertex index (0-based)
/// - `v`: destination vertex index (0-based)
/// - `weight`: edge cost in `[0, max_weight]`
///
/// # Example
///
/// ```
/// let g = @dial_shortest_path.Graph::new(3, 2)
/// g.add_edge(0, 1, 1)
/// g.add_edge(1, 2, 2)
/// ```
pub fn Graph::add_edge(self : Graph, u : Int, v : Int, weight : Int) -> Unit {
  self.adj[u].push({ to: v, weight })
}

///|
/// Add an undirected edge between `u` and `v` with the given weight.
///
/// This is a convenience wrapper that calls `add_edge` in both directions so
/// the edge can be traversed from `u` to `v` and from `v` to `u`.
///
/// # Parameters
///
/// - `u`, `v`: endpoint vertex indices (0-based, order does not matter)
/// - `weight`: edge cost in `[0, max_weight]`
///
/// # Example
///
/// ```
/// let g = @dial_shortest_path.Graph::new(4, 2)
/// g.add_undirected_edge(0, 1, 1)
/// g.add_undirected_edge(1, 2, 2)
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
/// Dial's algorithm.
///
/// Returns an array `dist` of length `graph.n` where `dist[v]` is the
/// shortest-path distance from `source` to `v`. Vertices unreachable from
/// `source` keep the sentinel value `DIAL_INF` (1,000,000,000).
///
/// # Algorithm
///
/// Dial's algorithm replaces Dijkstra's priority queue with a flat array of
/// `max_weight * (n - 1) + 1` buckets. Each bucket `d` holds vertices whose
/// current best-known distance equals `d`. The algorithm scans buckets in
/// increasing order:
///
/// 1. For each distance `d` from 0 to `max_dist`:
///    a. Drain bucket `d` one vertex `u` at a time.
///    b. Skip `u` if `dist[u] != d` (a stale duplicate entry).
///    c. For each outgoing edge `(u, v, w)`:
///       - Compute candidate `nd = d + w`.
///       - If `nd < dist[v]`, update `dist[v] = nd` and push `v` to `bucket[nd]`.
///
/// Because edge weights are non-negative integers and `d` is scanned in
/// strictly increasing order, the first time a vertex is processed with
/// `dist[u] == d` its distance is final.
///
/// # Complexity
///
/// - Time:  O(E + C * V), where C = `max_weight`
/// - Space: O(E + C * V)
///
/// # Parameters
///
/// - `graph`: directed graph built with `Graph::new` and `add_edge`
/// - `source`: starting vertex (0-based)
///
/// # Example
///
/// ```
/// let g = @dial_shortest_path.Graph::new(3, 2)
/// g.add_edge(0, 1, 1)
/// g.add_edge(1, 2, 2)
/// let dist = @dial_shortest_path.dial_shortest_paths(g, 0)
/// // dist == [0, 1, 3]
/// ```
pub fn dial_shortest_paths(graph : Graph, source : Int) -> Array[Int] {
  let n = graph.n
  let dist = Array::make(n, DIAL_INF)
  if n == 0 {
    return dist
  }
  let max_dist = if graph.max_weight == 0 {
    0
  } else {
    graph.max_weight * (n - 1)
  }
  let buckets : Array[Array[Int]] = Array::makei(max_dist + 1, _ => [])
  dist[source] = 0
  buckets[0].push(source)
  for d in 0..<(max_dist + 1) {
    let _ = for idx = 0; idx < buckets[d].length(); {
      let u = buckets[d][idx]
      if dist[u] != d {
        continue idx + 1
      }
      for e in graph.adj[u] {
        let nd = d + e.weight
        if nd < dist[e.to] {
          dist[e.to] = nd
          buckets[nd].push(e.to)
        }
      }
      continue idx + 1
    }
  }
  dist
}
