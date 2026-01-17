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
const DIAL_INF : Int = 1000000000

///|
/// Directed edge with integer weight.
pub struct Edge {
  to : Int
  weight : Int
} derive(Show)

///|
/// Graph with bounded edge weights.
pub struct Graph {
  n : Int
  max_weight : Int
  adj : Array[Array[Edge]]
}

///|
/// Create a graph with n vertices and maximum edge weight max_weight.
pub fn Graph::new(n : Int, max_weight : Int) -> Graph {
  let adj : Array[Array[Edge]] = Array::makei(n, _ => [])
  { n, max_weight, adj }
}

///|
/// Add a directed edge u -> v with weight in [0, max_weight].
pub fn Graph::add_edge(self : Graph, u : Int, v : Int, weight : Int) -> Unit {
  self.adj[u].push({ to: v, weight })
}

///|
/// Add an undirected edge (u, v) with weight in [0, max_weight].
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
/// Compute shortest distances from source using Dial's algorithm.
/// Unreachable vertices keep distance DIAL_INF.
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
    let mut idx = 0
    while idx < buckets[d].length() {
      let u = buckets[d][idx]
      idx = idx + 1
      if dist[u] != d {
        continue
      }
      for e in graph.adj[u] {
        let nd = d + e.weight
        if nd < dist[e.to] {
          dist[e.to] = nd
          buckets[nd].push(e.to)
        }
      }
    }
  }
  dist
}
