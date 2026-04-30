// ============================================================================
// DINIC'S ALGORITHM - Max Flow and Min Cut
// ============================================================================
//
// Main algorithm combining BFS level-graph construction and DFS blocking-flow
// search to find the maximum flow from a source to a sink.
//
// ALGORITHM LOOP:
// ```
//   While BFS finds a path from source to sink in the residual graph:
//     Reset current-arc pointers (iter[]) for the new phase.
//     Repeatedly call DFS until it returns 0 (level graph is blocked).
//     Accumulate the flow from each DFS call.
//   Return total accumulated flow.
// ```
//
// CORRECTNESS:
// ```
//   1. Each BFS phase strictly increases the shortest s-t distance.
//   2. At most V-1 phases are needed (distance is bounded by V).
//   3. Each phase finds a blocking flow in O(VE) time via DFS + current-arc.
//   4. Total: O(V^2 * E).
// ```
//
// MAX-FLOW MIN-CUT THEOREM:
// ```
//   The value of the maximum flow equals the capacity of the minimum cut.
//
//   After Dinic terminates:
//   - Source side: vertices reachable from source in the residual graph.
//   - Sink side: all remaining vertices.
//   - Min-cut edges: edges from the source side to the sink side whose
//     residual capacity is 0 (i.e., they are fully saturated).
// ```

///|
/// Compute the maximum flow from `source` to `sink` in `self`.
///
/// Runs Dinic's algorithm: alternating BFS phases (level-graph construction)
/// and DFS phases (blocking-flow search) until the sink is unreachable in
/// the residual graph.
///
/// The flow values stored in `self.adj` are updated in place.
/// Call `reset` before re-running on the same graph with a different
/// source/sink pair.
///
/// Algorithm:
/// ```
///   1. BFS to build level graph.
///   2. Reset iter[] (current-arc pointers) for this phase.
///   3. Loop: call dfs(source, sink, DINIC_INF) until it returns 0.
///   4. Go to step 1.
///   Return total flow when BFS can no longer reach the sink.
/// ```
///
/// Loop invariant: at the start of each outer iteration, `flow` equals
/// the total flow pushed across all completed BFS phases, and every
/// intermediate flow assignment respects capacity constraints.
pub fn Dinic::max_flow(self : Dinic, source : Int, sink : Int) -> Int64 {
  // Main loop: BFS phases
  for flow = 0L; self.bfs(source, sink); {
    // Reset edge pointers for this phase
    self.iter.fill(0)

    // Find blocking flow using repeated DFS
    let flow = for f = self.dfs(source, sink, DINIC_INF), flow = flow; f > 0L; {
      continue self.dfs(source, sink, DINIC_INF), flow + f
    } nobreak {
      flow
    } where {
      proof_invariant: flow >= 0L,
      proof_reasoning: (
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
    continue flow
  } nobreak {
    flow
  }
}

///|
/// Return the flow currently assigned to the first edge from `u` to `v`.
///
/// If multiple parallel edges exist between `u` and `v`, only the flow on
/// the first matching forward edge is returned.  Returns `0` if no edge
/// from `u` to `v` exists.
///
/// Useful for inspecting individual edge flows after `max_flow` has run.
pub fn Dinic::get_flow(self : Dinic, u : Int, v : Int) -> Int64 {
  for e in self.adj[u] {
    if e.to == v {
      return e.flow
    }
  }
  0L
}

///|
/// Reset all edge flows to 0, allowing `max_flow` to be called again.
///
/// The graph topology (vertices and edges added via `add_edge`) is
/// preserved; only the `flow` field of every edge is zeroed.
///
/// Use this when you want to recompute the maximum flow with a different
/// source or sink without rebuilding the entire `Dinic` instance.
pub fn Dinic::reset(self : Dinic) -> Unit {
  for u in 0..<self.n {
    for e in self.adj[u] {
      e.flow = 0L
    }
  }
}

///|
/// Return the set of vertices on the **source side** of the minimum cut.
///
/// Must be called **after** `max_flow` has been computed on `self`.
/// Performs a BFS from `source` in the residual graph (only edges with
/// positive residual capacity `cap > flow` are traversed).
///
/// The returned array contains every vertex reachable from `source` in
/// the residual graph, which forms the source side of a minimum cut whose
/// capacity equals the maximum flow (Max-flow Min-cut theorem).
///
/// Min-cut edges are those that go from a vertex in the returned set to a
/// vertex not in the set, and have zero residual capacity (fully saturated).
///
/// Algorithm:
/// ```
///   BFS from source using only edges with cap > flow.
///   Collect all visited vertices and return them.
/// ```
pub fn Dinic::min_cut_source_side(self : Dinic, source : Int) -> Array[Int] {
  let visited = Array::make(self.n, false)
  let result : Array[Int] = []
  let queue : Array[Int] = [source]
  visited[source] = true
  for front = 0; queue.get(front) is Some(u); {
    result.push(u)
    for e in self.adj[u] {
      if e.cap > e.flow && !visited[e.to] {
        visited[e.to] = true
        queue.push(e.to)
      }
    }
    continue front + 1
  }
  result
}

///|
/// Convenience function: build a `Dinic` instance from an edge list and
/// return the maximum flow from `source` to `sink`.
///
/// Parameters:
/// - `n`      : total number of vertices (labelled `0` to `n-1`)
/// - `edges`  : slice of `(from, to, capacity)` tuples
/// - `source` : source vertex index
/// - `sink`   : sink vertex index
///
/// This is equivalent to:
/// ```
///   let d = Dinic(n)
///   for (u, v, cap) in edges { d.add_edge(u, v, cap) }
///   d.max_flow(source, sink)
/// ```
///
/// Use `Dinic::new` directly if you need access to per-edge flows,
/// min-cut information, or the ability to `reset` and rerun.
pub fn max_flow(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source : Int,
  sink : Int,
) -> Int64 {
  let flow = Dinic(n)
  for edge in edges {
    let (u, v, cap) = edge
    flow.add_edge(u, v, cap)
  }
  flow.max_flow(source, sink)
}
