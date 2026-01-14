// ============================================================================
// DINIC'S ALGORITHM - DFS for Blocking Flow
// ============================================================================
//
// DFS finds augmenting paths in the level graph and pushes flow along them.
// Uses edge pointer optimization to avoid re-examining saturated edges.
//
// BLOCKING FLOW CONCEPT:
// ```
//   A blocking flow saturates at least one edge on every s-t path.
//   After finding a blocking flow in the level graph:
//   - No more augmenting paths exist in the current level graph
//   - We must rebuild levels (distance to sink increases)
// ```
//
// EDGE POINTER OPTIMIZATION:
// ```
//   iter[u] = index of first unsaturated edge from u
//
//   Once an edge is saturated or leads to a dead end,
//   we never examine it again in this phase.
//   This gives O(VE) time per phase instead of O(E²).
// ```
//
// DFS STRATEGY:
// ```
//   At vertex u with flow to push:
//   1. Try edges starting from iter[u]
//   2. For each edge to next level with residual capacity:
//      - Recursively push flow
//      - If successful, update edge flows and return
//   3. If no flow pushed, advance iter[u] and continue
//   4. If all edges tried, return 0
// ```

///|
/// DFS to find blocking flow in level graph.
///
/// PARAMETERS:
///   u:      Current vertex
///   sink:   Target vertex
///   pushed: Amount of flow we're trying to push
///
/// RETURNS: Amount of flow actually pushed (0 if no path found)
///
/// ALGORITHM:
/// ```
///   Base case: if u == sink or pushed == 0, return pushed
///
///   For each edge from iter[u] to end:
///     If edge goes to next level and has residual capacity:
///       Try to push min(residual, pushed) recursively
///       If successful:
///         Update forward and reverse edge flows
///         Return pushed amount
///     Else:
///       Advance iter[u] (edge is dead for this phase)
///
///   Return 0 (no augmenting path found)
/// ```
pub fn Dinic::dfs(self : Dinic, u : Int, sink : Int, pushed : Int64) -> Int64 {
  // Base cases
  if u == sink || pushed == 0L {
    return pushed
  }

  // Try edges starting from iter[u]
  while self.iter[u] < self.adj[u].length() {
    let i = self.iter[u]
    let e = self.adj[u][i]

    // Only use edges to next level with residual capacity
    if self.level[e.to] == self.level[u] + 1 && e.cap > e.flow {
      // Calculate how much we can push through this edge
      let can_push = if e.cap - e.flow < pushed {
        e.cap - e.flow
      } else {
        pushed
      }

      // Recursively try to push flow
      let d = self.dfs(e.to, sink, can_push)
      if d > 0L {
        // Flow was pushed successfully
        // Update forward edge: flow increases
        self.adj[u][i].flow = self.adj[u][i].flow + d
        // Update reverse edge: flow decreases (cancellation)
        self.adj[e.to][e.rev].flow = self.adj[e.to][e.rev].flow - d
        return d
      }
    }

    // This edge didn't work, try next one
    self.iter[u] = self.iter[u] + 1
  }

  // No augmenting path found from u
  0L
}
