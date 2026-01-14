// ============================================================================
// DINIC'S ALGORITHM - Type Definitions
// ============================================================================
//
// Dinic's algorithm finds maximum flow using blocking flows in layered graphs.
// It's faster than Ford-Fulkerson and Edmonds-Karp for many practical cases.
//
// ALGORITHM OVERVIEW:
// ```
//   1. Build level graph using BFS from source
//      (only edges to higher levels are included)
//
//   2. Find blocking flow using DFS
//      (saturate at least one edge on every s-t path)
//
//   3. Repeat until no path from source to sink
// ```
//
// KEY INSIGHT - BLOCKING FLOW:
// ```
//   A blocking flow saturates at least one edge on every s-t path
//   in the level graph. After finding a blocking flow:
//
//   - The level graph is "blocked" (no augmenting path remains)
//   - We must rebuild the level graph
//   - The distance from s to t strictly increases
//   - Thus, at most O(V) phases are needed
// ```
//
// VISUAL EXAMPLE:
// ```
//   Original network:        Level graph (after BFS):
//
//     s --5--> a --3--> t       Level 0    Level 1    Level 2
//      \       |                  s -----> a -------> t
//       2      4                   \-----> b --------/
//        \     v
//         --> b --2--> t        (Only forward edges, no back edges)
//
//   Blocking flow finds paths and saturates edges:
//   - s->a->t: push 3 (saturates a->t)
//   - s->b->t: push 2 (saturates s->b and b->t)
// ```
//
// TIME COMPLEXITY:
// ```
//   O(V²E) for general graphs
//   O(E√V) for unit capacity graphs
//   O(E√V) for bipartite matching
// ```
//
// SPACE COMPLEXITY: O(V + E)
//
// APPLICATIONS:
//   - Maximum bipartite matching
//   - Minimum cut problems
//   - Project selection
//   - Image segmentation

///|
/// Infinity constant for Dinic's algorithm.
pub const DINIC_INF : Int64 = 4611686018427387903L

///|
/// Edge in the flow network.
///
/// STRUCTURE:
/// ```
///   to:   Destination vertex
///   cap:  Edge capacity
///   flow: Current flow (can be negative for reverse edges)
///   rev:  Index of reverse edge in adj[to]
///
///   Residual capacity = cap - flow
///   For reverse edges, cap = 0 and flow can become negative.
/// ```
pub(all) struct DinicEdge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int // Index of reverse edge
}

///|
/// Dinic's algorithm data structure.
///
/// COMPONENTS:
/// ```
///   n:     Number of vertices
///   adj:   Adjacency list of edges
///   level: BFS distance from source (-1 if unreachable)
///   iter:  Current edge pointer for DFS (optimization)
/// ```
///
/// EDGE STORAGE:
/// ```
///   For each edge (u, v, cap), we store:
///   - Forward edge in adj[u]: (to=v, cap=cap, flow=0, rev=idx_in_adj[v])
///   - Reverse edge in adj[v]: (to=u, cap=0, flow=0, rev=idx_in_adj[u])
///
///   When we push flow f on (u,v):
///   - adj[u][i].flow += f
///   - adj[v][rev].flow -= f  (negative flow = reverse capacity)
/// ```
pub(all) struct Dinic {
  n : Int
  adj : Array[Array[DinicEdge]]
  level : Array[Int]
  iter : Array[Int] // Current edge pointer for each vertex
}

///|
/// Create a new Dinic instance with n vertices.
pub fn Dinic::new(n : Int) -> Dinic {
  let adj = Array::makei(n, fn(_i) { [] })
  { n, adj, level: Array::make(n, 0), iter: Array::make(n, 0) }
}

///|
/// Add a directed edge from `from` to `to` with capacity `cap`.
///
/// IMPLEMENTATION:
/// ```
///   1. Record indices for reverse edge linking
///   2. Add forward edge: (to, cap, 0, rev_index)
///   3. Add reverse edge: (from, 0, 0, forward_index)
///
///   The reverse edge has capacity 0 but can have negative flow,
///   which represents "undoing" flow pushed on the forward edge.
/// ```
pub fn Dinic::add_edge(self : Dinic, from : Int, to : Int, cap : Int64) -> Unit {
  let rev_from = self.adj[to].length()
  let rev_to = self.adj[from].length()
  self.adj[from].push({ to, cap, flow: 0L, rev: rev_from })
  self.adj[to].push({ to: from, cap: 0L, flow: 0L, rev: rev_to })
}
