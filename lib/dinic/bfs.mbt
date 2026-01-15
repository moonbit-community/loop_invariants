// ============================================================================
// DINIC'S ALGORITHM - BFS for Level Graph
// ============================================================================
//
// BFS builds the level graph by computing distances from source.
// Only edges with residual capacity are considered.
//
// LEVEL GRAPH PROPERTIES:
// ```
//   1. level[source] = 0
//   2. level[v] = shortest distance from source in residual graph
//   3. level[v] = -1 if v is unreachable
//
//   The level graph contains only edges (u, v) where:
//   - There is residual capacity (cap > flow)
//   - level[v] = level[u] + 1 (going to higher level)
// ```
//
// WHY LEVEL GRAPH:
// ```
//   By restricting DFS to level graph edges:
//   - Every path found is a shortest path
//   - We can find blocking flow efficiently
//   - Distance to sink increases after each phase
//
//   This guarantees O(V) phases, each taking O(VE) time.
// ```

///|
/// BFS to build level graph.
///
/// ALGORITHM:
/// ```
///   1. Reset all levels to -1
///   2. Set level[source] = 0, enqueue source
///   3. For each vertex u in queue:
///      - For each edge (u, v) with residual capacity:
///        - If level[v] = -1: set level[v] = level[u] + 1, enqueue v
///   4. Return whether sink is reachable
/// ```
///
/// RETURNS: true if sink is reachable from source in residual graph
pub fn Dinic::bfs(self : Dinic, source : Int, sink : Int) -> Bool {
  // Reset levels
  self.level.fill(-1)

  // Initialize BFS from source
  self.level[source] = 0
  let queue : Array[Int] = [source]

  // BFS loop
  let mut front = 0
  while queue.get(front) is Some(u) {
    // Explore all edges from u
    for e in self.adj[u] {
      // Only consider edges with residual capacity to unvisited vertices
      if e.cap > e.flow && self.level[e.to] < 0 {
        self.level[e.to] = self.level[u] + 1
        queue.push(e.to)
      }
    }
    front = front + 1
  }

  // Return true if sink is reachable
  self.level[sink] >= 0
}
