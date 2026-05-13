// ============================================================================
// MINIMUM S-T CUT - Max-Flow / Residual Reachability
// ============================================================================
//
// For a directed graph with non-negative capacities, the max-flow min-cut
// theorem states:
//   max_flow(s, t) = min_cut_capacity(s, t)
//
// This package computes the minimum s-t cut by:
// 1. Running Dinic's max flow algorithm.
// 2. Doing a BFS in the residual graph to find the source side.
// 3. The cut capacity is the max flow value.
//
// TIME COMPLEXITY: O(V^2 E) (Dinic)
// SPACE COMPLEXITY: O(V + E)

///|
const INF64 : Int64 = 4611686018427387903L

///|
/// The result returned by `min_cut_st`.
///
/// Fields:
/// - `value`: the minimum cut capacity, equal to the maximum flow from
///   `source` to `sink`.
/// - `source_side`: the set of vertices reachable from `source` in the
///   residual graph after max flow.  These vertices define the S-side of
///   the minimum cut.  Every edge from a vertex in `source_side` to a
///   vertex NOT in `source_side` is a cut edge.
pub(all) struct MinCutSTResult {
  value : Int64
  source_side : Array[Int]
}

///|
/// A directed edge in the internal flow network.
///
/// Each original edge `u -> v` with capacity `cap` is paired with a
/// reverse edge `v -> u` with capacity 0.  The `rev` field stores the
/// index of the paired edge in the adjacency list of the opposite endpoint,
/// enabling O(1) residual updates.
priv struct Edge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int
}

///|
/// The internal Dinic flow graph.
///
/// Fields:
/// - `n`: vertex count.
/// - `adj`: adjacency lists; `adj[u]` contains all edges leaving `u`.
/// - `level`: BFS level assigned to each vertex during the level-graph build.
///   `-1` means the vertex was not reached in the current BFS.
/// - `iter`: current-arc pointer per vertex used by the DFS blocking-flow
///   phase to skip already-exhausted edges.
priv struct FlowGraph {
  n : Int
  adj : Array[Array[Edge]]
  level : Array[Int]
  iter : Array[Int]
}

///|
/// Create a new flow graph with `n` vertices and no edges.
fn FlowGraph::FlowGraph(n : Int) -> FlowGraph {
  let adj = [ for _ in 0..<n => [] ]
  { n, adj, level: Array::make(n, -1), iter: Array::make(n, 0) }
}

///|
/// Add a directed edge `from -> to` with the given capacity to the flow
/// graph.
///
/// A corresponding reverse edge with capacity 0 is also added so that the
/// DFS can cancel flow along the forward edge.
fn FlowGraph::add_edge(
  self : FlowGraph,
  from : Int,
  to : Int,
  cap : Int64,
) -> Unit {
  let rev_from = self.adj[to].length()
  let rev_to = self.adj[from].length()
  self.adj[from].push({ to, cap, flow: 0L, rev: rev_from })
  self.adj[to].push({ to: from, cap: 0L, flow: 0L, rev: rev_to })
}

///|
/// Run BFS from `source` on the residual graph to assign BFS levels.
///
/// Returns `true` if `sink` is reachable, meaning another blocking-flow
/// phase is possible.  Populates `self.level` with shortest-path distances
/// in the residual graph.
fn FlowGraph::bfs(self : FlowGraph, source : Int, sink : Int) -> Bool {
  for i in 0..<self.n {
    self.level[i] = -1
  } where {
    proof_invariant: i >= 0 && i <= self.n && self.level.length() == self.n,
    proof_reasoning: (
      #|INVARIANT (level reset):
      #|level[0..i) have been cleared to -1 for the next BFS layer build.
      #|MAINTENANCE:
      #|Set level[i] to -1 to forget the previous BFS distances.
      #|TERMINATION:
      #|At i = n, all vertices are unvisited.
    ),
  }
  self.level[source] = 0
  let queue : Array[Int] = [source]
  for front = 0; front < queue.length(); {
    let u = queue[front]
    for i in 0..<self.adj[u].length() {
      let e = self.adj[u][i]
      if e.cap > e.flow && self.level[e.to] < 0 {
        self.level[e.to] = self.level[u] + 1
        queue.push(e.to)
      }
    } where {
      proof_invariant: i >= 0 && i <= self.adj[u].length() && self.level[u] >= 0,
      proof_reasoning: (
        #|INVARIANT (BFS edge scan):
        #|Edges adj[u][0..i) have been scanned. Any vertex reachable from u via
        #|a residual edge has been assigned its correct BFS level and enqueued.
        #|MAINTENANCE:
        #|Inspect edge i and enqueue e.to when residual capacity exists.
        #|TERMINATION:
        #|At i = deg(u), all outgoing edges from u are processed.
      ),
    }
    continue front + 1
  }
  self.level[sink] >= 0
}

///|
/// DFS blocking-flow phase for Dinic's algorithm.
///
/// Attempts to push `pushed` units of flow from `u` to `sink` along the
/// current level graph.  Returns the amount successfully pushed (0 if no
/// augmenting path exists from `u`).
///
/// Uses the current-arc optimization: `self.iter[u]` remembers the first
/// edge from `u` not yet proven useless, avoiding repeated scanning.
fn FlowGraph::dfs(
  self : FlowGraph,
  u : Int,
  sink : Int,
  pushed : Int64,
) -> Int64 {
  if u == sink || pushed == 0L {
    return pushed
  }
  for next_edge = self.iter[u] < self.adj[u].length(); next_edge; {
    let i = self.iter[u]
    let e = self.adj[u][i]
    if self.level[e.to] == self.level[u] + 1 && e.cap > e.flow {
      let can_push = if e.cap - e.flow < pushed {
        e.cap - e.flow
      } else {
        pushed
      }
      let d = self.dfs(e.to, sink, can_push)
      if d > 0L {
        self.adj[u][i].flow = self.adj[u][i].flow + d
        self.adj[e.to][e.rev].flow = self.adj[e.to][e.rev].flow - d
        return d
      }
    }
    self.iter[u] = self.iter[u] + 1
    continue self.iter[u] < self.adj[u].length()
  }
  0L
}

///|
/// Compute the maximum flow from `source` to `sink` using Dinic's algorithm.
///
/// Alternates between BFS (build level graph) and DFS (find blocking flow)
/// until the sink is unreachable in the residual graph.  Returns the total
/// flow value.
fn FlowGraph::max_flow(self : FlowGraph, source : Int, sink : Int) -> Int64 {
  for flow = 0L; self.bfs(source, sink); {
    for i in 0..<self.n {
      self.iter[i] = 0
    } where {
      proof_invariant: i >= 0 && i <= self.n && self.iter.length() == self.n,
      proof_reasoning: (
        #|INVARIANT (iter reset):
        #|iter[0..i) are reset so DFS starts at edge 0 for those vertices.
        #|MAINTENANCE:
        #|Set iter[i] = 0 for vertex i.
        #|TERMINATION:
        #|At i = n, all iter pointers are reset.
      ),
    }
    let flow = for pushed = self.dfs(source, sink, INF64), flow = flow; pushed >
                  0L; {
      continue self.dfs(source, sink, INF64), flow + pushed
    } nobreak {
      flow
    } where {
      proof_invariant: flow >= 0L,
      proof_reasoning: (
        #|INVARIANT (blocking flow augmentation):
        #|flow equals the total amount sent so far. Each DFS call augments along
        #|the current level graph, preserving feasibility and increasing flow.
        #|MAINTENANCE:
        #|Add the returned pushed value; if it is positive, we found another
        #|augmenting path in the level graph.
        #|TERMINATION:
        #|When DFS returns 0, the current level graph is blocked.
      ),
    }
    continue flow
  } nobreak {
    flow
  }
}

///|
/// BFS the residual graph from `source` and return all reachable vertices.
///
/// Called after `max_flow` completes.  A vertex `v` is in the returned set
/// if there is a directed path from `source` to `v` in the residual graph
/// (i.e., every edge on the path has strictly positive residual capacity).
///
/// The returned array is the S-side of the minimum s-t cut.  Every original
/// edge from a vertex in this set to a vertex NOT in this set is a saturated
/// cut edge.
fn FlowGraph::min_cut_source_side(self : FlowGraph, source : Int) -> Array[Int] {
  let visited = Array::make(self.n, false)
  let queue : Array[Int] = [source]
  visited[source] = true
  let result : Array[Int] = []
  for front = 0; front < queue.length(); {
    let u = queue[front]
    result.push(u)
    for i in 0..<self.adj[u].length() {
      let e = self.adj[u][i]
      if e.cap > e.flow && !visited[e.to] {
        visited[e.to] = true
        queue.push(e.to)
      }
    } where {
      proof_invariant: i >= 0 &&
      i <= self.adj[u].length() &&
      visited.length() == self.n,
      proof_reasoning: (
        #|INVARIANT (residual BFS edges):
        #|Edges adj[u][0..i) are scanned; any vertex reachable by a residual edge
        #|from u is marked visited and enqueued.
        #|MAINTENANCE:
        #|When residual capacity exists, mark and enqueue e.to.
        #|TERMINATION:
        #|At i = deg(u), all outgoing residual edges are processed.
      ),
    }
    continue front + 1
  }
  result
}

///|
/// Compute the minimum s-t cut of a directed graph.
///
/// Uses the max-flow min-cut theorem: the value of the minimum s-t cut equals
/// the maximum flow from `source` to `sink`.  The algorithm runs Dinic's max
/// flow, then BFS-walks the residual graph to identify the source-side
/// partition S.
///
/// Parameters:
/// - `n`: number of vertices, labeled `0` to `n-1`.
/// - `edges`: directed edges as `(from, to, capacity)` triples.
///   Edges with non-positive capacity, self-loops, or out-of-range endpoints
///   are silently ignored.
/// - `source`: the source vertex `s`; must satisfy `0 <= source < n`.
/// - `sink`: the sink vertex `t`; must satisfy `0 <= sink < n` and
///   `sink != source`.
///
/// Returns:
/// - `None` if any of the following hold:
///   - `n <= 0`
///   - `source` or `sink` is out of range
///   - `source == sink`
/// - `Some(result)` otherwise, where:
///   - `result.value` is the minimum cut capacity (equals max flow).
///   - `result.source_side` is the array of vertices on the S-side of the
///     cut (reachable from `source` in the residual graph after max flow).
///     The S-side always contains `source` and never contains `sink`.
///
/// The cut edges are all original edges `(u, v, cap)` such that `u` is in
/// `result.source_side` and `v` is not.  Their capacities sum to
/// `result.value`.
///
/// Example:
/// ```
///   Edges: 0->1(3), 0->2(2), 1->3(2), 2->3(3)
///   source = 0, sink = 3
///
///   Max flow = 4  =>  min cut = 4
///   source_side = {0, 1}
///   Cut edges: 0->2 (cap 2) and 1->3 (cap 2)
/// ```
pub fn min_cut_st(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source : Int,
  sink : Int,
) -> MinCutSTResult? {
  if n <= 0 ||
    source < 0 ||
    source >= n ||
    sink < 0 ||
    sink >= n ||
    source == sink {
    return None
  }
  let flow = FlowGraph(n)
  for i in 0..<edges.length() {
    let (u, v, cap) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n && u != v && cap > 0L {
      flow.add_edge(u, v, cap)
    }
  } where {
    proof_invariant: i >= 0 && i <= edges.length(),
    proof_reasoning: (
      #|INVARIANT (edge load):
      #|All edges in edges[0..i) that are valid (in range, non-self-loop, cap>0)
      #|have been inserted into the flow network.
      #|MAINTENANCE:
      #|Add edge i when it is valid, preserving the processed-prefix property.
      #|TERMINATION:
      #|At i = edges.length(), the flow network encodes all valid edges.
    ),
  }
  let value = flow.max_flow(source, sink)
  let source_side = flow.min_cut_source_side(source)
  Some({ value, source_side })
}

// ============================================================================
// TESTS
// ============================================================================

///|
fn cut_capacity(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source_side : Array[Int],
) -> Int64 {
  let in_source = Array::make(n, false)
  for v in source_side {
    if v >= 0 && v < n {
      in_source[v] = true
    }
  }
  for edge in edges; total = 0L {
    let (u, v, cap) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      if in_source[u] && !in_source[v] {
        continue total + cap
      }
    }
    continue total
  } nobreak {
    total
  }
}

///|
test "min cut st basic" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 3L),
    (0, 2, 2L),
    (1, 3, 2L),
    (2, 3, 3L),
  ]
  let result = min_cut_st(4, edges, 0, 3).unwrap()
  debug_inspect(result.value, content="4")
  debug_inspect(cut_capacity(4, edges, result.source_side), content="4")
}

///|
test "min cut st no path" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = min_cut_st(3, edges, 0, 2).unwrap()
  debug_inspect(result.value, content="0")
}

///|
test "min cut st invalid" {
  let edges : Array[(Int, Int, Int64)] = []
  guard min_cut_st(0, edges, 0, 0) is None else { fail("expected None") }
}
