// ============================================================================
// DINIC'S ALGORITHM - Max Flow and Min Cut
// ============================================================================
//
// Main algorithm combining BFS and DFS to find maximum flow.
// Also includes min cut computation.
//
// ALGORITHM:
// ```
//   While BFS finds path from source to sink:
//     Reset edge pointers
//     While DFS finds augmenting path:
//       Add path flow to total
//   Return total flow
// ```
//
// CORRECTNESS:
// ```
//   1. Each BFS phase increases distance from source to sink
//   2. At most V phases needed (distance can't exceed V)
//   3. Each phase finds a blocking flow in O(VE) time
//   4. Total: O(V²E)
// ```
//
// MAX-FLOW MIN-CUT THEOREM:
// ```
//   The maximum flow equals the minimum cut capacity.
//
//   After finding max flow:
//   - Source side: vertices reachable from source in residual graph
//   - Sink side: remaining vertices
//   - Cut edges: edges from source side to sink side with full capacity
// ```

///|
/// Compute maximum flow from source to sink.
///
/// ALGORITHM:
/// ```
///   1. BFS to build level graph
///   2. Reset edge pointers for DFS
///   3. Find blocking flow using repeated DFS
///   4. Repeat until sink unreachable
/// ```
///
/// INVARIANT:
/// ```
///   After each BFS phase:
///   - Distance from source to sink strictly increases
///   - All flow pushed respects capacity constraints
///   - Total flow equals sum of all augmenting path flows
/// ```
pub fn Dinic::max_flow(self : Dinic, source : Int, sink : Int) -> Int64 {
  let mut flow = 0L

  // Main loop: BFS phases
  while self.bfs(source, sink) {
    // Reset edge pointers for this phase
    for i = 0; i < self.n; i = i + 1 {
      self.iter[i] = 0
    } where {
      invariant: i >= 0 && i <= self.n && self.iter.length() == self.n,
      reasoning: (
        #|INVARIANT (iter reset):
        #|  iter[0..i) reset to 0 for fresh DFS exploration.
        #|
        #|WHY RESET:
        #|  The level graph changed, so edges that were dead ends
        #|  in the previous phase might now lead to augmenting paths.
        #|
        #|MAINTENANCE:
        #|  Set iter[i] = 0.
        #|
        #|TERMINATION:
        #|  At i = n, all pointers are reset.
      ),
    }

    // Find blocking flow using repeated DFS
    for f = self.dfs(source, sink, DINIC_INF); f > 0L; {
      flow = flow + f
      continue self.dfs(source, sink, DINIC_INF)
    } where {
      invariant: flow >= 0L,
      reasoning: (
        #|INVARIANT (blocking flow accumulation):
        #|  flow = total flow pushed so far.
        #|  Each positive DFS augments along a level-respecting path.
        #|
        #|BLOCKING FLOW PROPERTY:
        #|  When DFS returns 0, at least one edge is saturated on every
        #|  s-t path in the level graph. The graph is "blocked".
        #|
        #|TERMINATION:
        #|  DFS returns 0 when no augmenting path exists.
      ),
    }
  }
  flow
}

///|
/// Get flow on edge from u to v (first matching edge if multiple).
pub fn Dinic::get_flow(self : Dinic, u : Int, v : Int) -> Int64 {
  for i = 0; i < self.adj[u].length(); i = i + 1 {
    if self.adj[u][i].to == v {
      return self.adj[u][i].flow
    }
  } where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: (
      #|INVARIANT (get_flow scan):
      #|  Edges adj[u][0..i) have been checked for destination v.
      #|
      #|MAINTENANCE:
      #|  Check if edge i goes to v.
      #|
      #|TERMINATION:
      #|  At i = deg(u), no edge to v exists.
    ),
  }
  0L
}

///|
/// Reset all flows to 0 (for recomputing with different source/sink).
pub fn Dinic::reset(self : Dinic) -> Unit {
  for u = 0; u < self.n; u = u + 1 {
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      self.adj[u][i].flow = 0L
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT (reset flows inner):
        #|  Flows in adj[u][0..i) reset to 0.
        #|
        #|MAINTENANCE:
        #|  Set flow of edge i to 0.
        #|
        #|TERMINATION:
        #|  At i = deg(u), all flows from u are reset.
      ),
    }
  } where {
    invariant: u >= 0 && u <= self.n && self.adj.length() == self.n,
    reasoning: (
      #|INVARIANT (reset flows outer):
      #|  Vertices [0..u) have all flows reset.
      #|
      #|MAINTENANCE:
      #|  Reset all flows for vertex u.
      #|
      #|TERMINATION:
      #|  At u = n, all flows in network are reset.
    ),
  }
}

///|
/// Find vertices on source side of minimum cut.
///
/// ALGORITHM:
/// ```
///   After computing max flow, perform BFS from source
///   using only edges with residual capacity.
///   Reachable vertices are on source side of min cut.
/// ```
///
/// MIN CUT PROPERTY:
/// ```
///   Edges from source side to sink side are saturated
///   (cap == flow), so they have no residual capacity.
///   Total capacity of these edges = max flow.
/// ```
pub fn Dinic::min_cut_source_side(self : Dinic, source : Int) -> Array[Int] {
  let visited = Array::make(self.n, false)
  let result : Array[Int] = []
  let queue : Array[Int] = [source]
  visited[source] = true
  let mut front = 0
  while front < queue.length() {
    let u = queue[front]
    front = front + 1
    result.push(u)
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]
      if e.cap > e.flow && not(visited[e.to]) {
        visited[e.to] = true
        queue.push(e.to)
      }
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT (min-cut BFS):
        #|  Edges adj[u][0..i) processed.
        #|  Vertices reachable via residual edges are marked visited.
        #|
        #|CORRECTNESS:
        #|  A vertex is on source side iff reachable from source
        #|  via edges with residual capacity (cap > flow).
        #|
        #|MAINTENANCE:
        #|  Process edge i, enqueue unvisited reachable vertices.
        #|
        #|TERMINATION:
        #|  At i = deg(u), all residual edges from u examined.
      ),
    }
  }
  result
}

///|
/// Convenience function: compute max flow from edge list.
pub fn max_flow(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source : Int,
  sink : Int,
) -> Int64 {
  let flow = Dinic::new(n)
  edges.each(fn(edge) {
    let (u, v, cap) = edge
    flow.add_edge(u, v, cap)
  })
  flow.max_flow(source, sink)
}
