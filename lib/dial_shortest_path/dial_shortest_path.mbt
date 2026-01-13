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
  let adj = Array::make(n, [])
  for i in 0..<n {
    adj[i] = []
  }
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
  let buckets = Array::make(max_dist + 1, [])
  for i in 0..<buckets.length() {
    buckets[i] = []
  }
  dist[source] = 0
  buckets[0].push(source)
  for d = 0; d <= max_dist; d = d + 1 {
    for idx = 0; idx < buckets[d].length(); idx = idx + 1 {
      let u = buckets[d][idx]
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
    } where {
      invariant: idx >= 0 && idx <= buckets[d].length(),
      reasoning: (
        #|INVARIANT (bucket scan):
        #|All vertices in buckets[d][0..idx) have been processed and their
        #|outgoing edges relaxed. Any new vertex added to buckets[d] is appended,
        #|so increasing idx eventually processes it as well.
        #|MAINTENANCE:
        #|Process buckets[d][idx], relax its edges, and increment idx. Newly
        #|inserted entries are appended to the end, preserving completeness.
        #|TERMINATION:
        #|At idx == buckets[d].length(), every vertex with tentative distance d
        #|has been processed.
      ),
    }
  } where {
    invariant: d >= 0 && d <= max_dist + 1,
    reasoning: (
      #|INVARIANT (distance layers):
      #|Before processing distance d, all vertices with final shortest distance
      #|< d have been settled, and any vertex in buckets[d] has current
      #|distance exactly d. Outdated entries are skipped via dist[u] != d.
      #|MAINTENANCE:
      #|Processing bucket d relaxes edges to distances >= d, placing vertices
      #|into the appropriate later buckets while preserving minimality.
      #|TERMINATION:
      #|After d > max_dist, all reachable vertices have been processed and dist
      #|stores their shortest path lengths.
    ),
  }
  dist
}
