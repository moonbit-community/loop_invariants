// ============================================================================
// DINIC'S ALGORITHM - DFS for Blocking Flow
// ============================================================================
//
// DFS finds augmenting paths in the level graph and pushes flow along them.
// The current-arc optimisation (iter[]) avoids re-examining dead edges.
//
// BLOCKING FLOW CONCEPT:
// ```
//   A blocking flow saturates at least one edge on every s-t path in the
//   level graph.  After a blocking flow:
//   - No augmenting path remains in the current level graph.
//   - We must call BFS again; the new distance to the sink is strictly larger.
// ```
//
// CURRENT-ARC OPTIMISATION:
// ```
//   iter[u] = index of the first edge from u that has not yet been declared
//             "dead" in this phase.
//
//   An edge is declared dead when it is either:
//     - Saturated (residual capacity == 0), or
//     - Part of a path that leads to a dead end.
//
//   Advancing iter[u] past a dead edge means we never examine it again
//   in this phase, reducing the work per phase from O(E^2) to O(VE).
// ```
//
// DFS STRATEGY:
// ```
//   At vertex u trying to push `pushed` units:
//   1. Scan edges from iter[u] onward.
//   2. For each edge e to the next level with residual capacity:
//      a. Compute can_push = min(residual(e), pushed).
//      b. Recurse: d = dfs(e.to, sink, can_push).
//      c. If d > 0: update flows and return d (success).
//   3. If no edge worked, advance iter[u] and try the next edge.
//   4. If all edges exhausted, return 0 (dead end).
// ```

///|
/// DFS that pushes a blocking flow through the level graph from vertex `u`.
///
/// Only edges satisfying `level[e.to] == level[u] + 1` and
/// `e.cap > e.flow` (positive residual capacity) are considered.
/// The current-arc pointer `iter[u]` is advanced past any edge that
/// proves fruitless, so each edge is visited at most once per BFS phase.
///
/// Parameters:
/// - `u`      : current vertex in the DFS
/// - `sink`   : target vertex; reaching it terminates the path
/// - `pushed` : maximum flow that can be pushed along the path to `u`
///              (equals the minimum residual capacity seen so far)
///
/// Returns the amount of flow successfully pushed from `u` to `sink`,
/// or `0` if no augmenting path was found.
///
/// Side effects: updates `flow` fields on forward and reverse edges.
///
/// Algorithm:
/// ```
///   Base case: u == sink or pushed == 0  →  return pushed.
///
///   For each edge e starting at iter[u]:
///     If e leads to level[u]+1 and has residual capacity:
///       d = dfs(e.to, sink, min(residual(e), pushed))
///       If d > 0:
///         adj[u][i].flow        += d   (forward edge: more flow)
///         adj[e.to][e.rev].flow -= d   (reverse edge: cancellation)
///         return d
///     Advance iter[u].
///
///   return 0   (dead end)
/// ```
pub fn Dinic::dfs(self : Dinic, u : Int, sink : Int, pushed : Int64) -> Int64 {
  // Base cases
  if u == sink || pushed == 0L {
    return pushed
  }

  // Try edges starting from iter[u]
  for next_edge = self.iter[u] < self.adj[u].length(); next_edge; {
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
    continue self.iter[u] < self.adj[u].length()
  }

  // No augmenting path found from u
  0L
}
