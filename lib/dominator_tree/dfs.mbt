// ============================================================================
// DOMINATOR TREE - DFS Traversal
// ============================================================================
//
// The first phase of Lengauer-Tarjan: number vertices by DFS discovery order.
// This establishes the foundation for semi-dominator computation.
//
// KEY INSIGHT:
//   DFS numbering has special properties:
//   1. Parent's index < child's index (tree property)
//   2. Ancestor indices form an interval in [1..n]
//   3. Back edges go from higher to lower indices
//
// These properties enable efficient semi-dominator queries via union-find.

///|
/// Perform DFS from vertex u, assigning DFS indices.
///
/// ALGORITHM:
///   Assign sequential timestamps as we discover vertices.
///   Record parent-child relationships in the DFS tree.
///   Initialize union-find structures for each discovered vertex.
///
/// DFS INDEX ASSIGNMENT:
/// ```
///   time := time + 1
///   arr[u] := time          // vertex → index mapping
///   rev[time] := u          // index → vertex mapping
///   sdom[time] := time      // initially, sdom is self
///   label[time] := time     // union-find label
///   dsu[time] := time       // union-find parent (self = root)
/// ```
///
/// WHY INITIALIZE sdom TO SELF:
///   The semi-dominator starts at the vertex itself.
///   It gets reduced as we find paths with lower-numbered endpoints.
///
/// PARAMETERS:
///   - self: working data structures
///   - u: starting vertex (by vertex ID, not DFS index)
///
/// POST-CONDITION:
///   All vertices reachable from u have DFS indices assigned.
///   The DFS tree structure is recorded in parent[].
fn DominatorWork::dfs(self : DominatorWork, u : Int) -> Unit {
  // Assign DFS number to u
  self.time.val = self.time.val + 1
  let t = self.time.val
  self.arr[u] = t
  self.rev[t] = u
  self.sdom[t] = t
  self.label[t] = t
  self.dsu[t] = t

  // Visit all neighbors
  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]
    if self.arr[v] == 0 {
      // v is unvisited - recurse
      self.dfs(v)
      // Record parent relationship (child's index → parent's index)
      self.parent[self.arr[v]] = t
    }
    // If arr[v] != 0, it's already visited (back/cross edge)
    // These are handled later via predecessor lists
  } where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: (
      #|INVARIANT (neighbor exploration):
      #|  adj[u][0..i) have been processed.
      #|  Unvisited neighbors have been recursively explored.
      #|  Their parent[] entries point back to t.
      #|
      #|MAINTENANCE:
      #|  Process adj[u][i], recursing if unvisited.
      #|
      #|TERMINATION:
      #|  At i = deg(u), all neighbors are explored.
    ),
  }
}

///|
/// Build predecessor lists from edges using DFS indices.
///
/// PURPOSE:
///   Convert edges from vertex-space to DFS-index-space.
///   Only include edges between reachable vertices.
///   pred[v] = list of DFS indices that have edges to v.
///
/// WHY PREDECESSORS:
///   Semi-dominator computation needs to know:
///   "What vertices can reach v via one edge?"
///   We answer this by iterating pred[v].
///
/// PARAMETERS:
///   - self: working data structures (arr must be filled by DFS)
///   - edges: the original edge list
fn DominatorWork::build_predecessors(
  self : DominatorWork,
  edges : ArrayView[(Int, Int)],
) -> Unit {
  for edge in edges {
    let (u, v) = edge
    // Skip out-of-range vertices
    guard u >= 0 && u < self.n && v >= 0 && v < self.n else { continue }
    let du = self.arr[u]
    let dv = self.arr[v]
    // Skip unreachable vertices (arr = 0)
    guard du != 0 && dv != 0 else { continue }
    // Add predecessor relationship in DFS-index space
    self.pred[dv].push(du)
  }
}
