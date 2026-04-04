// ============================================================================
// DINIC'S ALGORITHM - BFS for Level Graph
// ============================================================================
//
// BFS builds the level graph by computing shortest distances from the source
// in the residual graph.  Only edges with positive residual capacity are used.
//
// LEVEL GRAPH PROPERTIES:
// ```
//   1. level[source] = 0
//   2. level[v] = shortest distance from source in residual graph
//   3. level[v] = -1 if v is unreachable from source
//
//   The level graph retains only edges (u, v) satisfying:
//     - residual capacity > 0  (cap > flow)
//     - level[v] == level[u] + 1  (strictly advancing)
// ```
//
// WHY THE LEVEL GRAPH MATTERS:
// ```
//   By restricting DFS to level-graph edges:
//   - Every augmenting path found is a shortest path.
//   - Blocking flows can be found in O(VE) per phase.
//   - After each blocking flow the distance to the sink strictly increases,
//     guaranteeing at most O(V) BFS phases in total.
// ```

///|
/// Run BFS from `source` to assign BFS levels to every reachable vertex.
///
/// Builds the level graph implicitly: after this call, `self.level[v]`
/// holds the shortest-path distance from `source` to `v` in the current
/// residual graph, or `-1` if `v` is not reachable.
///
/// The DFS (`dfs`) then only follows edges where
/// `level[e.to] == level[u] + 1` and `e.cap > e.flow`.
///
/// Algorithm:
/// ```
///   1. Set all levels to -1.
///   2. Set level[source] = 0 and enqueue source.
///   3. For each vertex u dequeued:
///        For each edge (u, v) with residual capacity > 0:
///          If level[v] == -1: set level[v] = level[u] + 1, enqueue v.
///   4. Return true iff level[sink] >= 0.
/// ```
///
/// Returns `true` if `sink` is reachable from `source` in the residual graph,
/// meaning another blocking-flow phase is possible.
pub fn Dinic::bfs(self : Dinic, source : Int, sink : Int) -> Bool {
  // Reset levels
  self.level.fill(-1)

  // Initialize BFS from source
  self.level[source] = 0
  let queue : Array[Int] = [source]

  // BFS loop
  for front = 0; queue.get(front) is Some(u); {
    // Explore all edges from u
    for e in self.adj[u] {
      // Only consider edges with residual capacity to unvisited vertices
      if e.cap > e.flow && self.level[e.to] < 0 {
        self.level[e.to] = self.level[u] + 1
        queue.push(e.to)
      }
    }
    continue front + 1
  }

  // Return true if sink is reachable
  self.level[sink] >= 0
}
