// ============================================================================
// MAXIMUM FLOW - Dinic's Algorithm
// ============================================================================
//
// Maximum flow finds the maximum amount that can be transported from source
// to sink through a network with edge capacities.
//
// DINIC'S ALGORITHM:
// 1. Build level graph using BFS from source
// 2. Find blocking flow using DFS (saturate at least one edge per path)
// 3. Repeat until no path exists
//
// KEY OPTIMIZATIONS:
// - Level graph: only consider edges going to next level (shorter paths first)
// - Blocking flow: process multiple augmenting paths per BFS
// - Dead-end pruning: remember which edges are exhausted
//
// WHY IT WORKS:
// - Each phase increases the shortest path length by at least 1
// - At most n phases (shortest path can be at most n-1)
// - Each phase does O(m*n) work with blocking flow optimization
// - Total: O(n²m)
//
// For unit capacity graphs: O(m * √n)
// For bipartite matching: O(m * √n)
//
// RESIDUAL GRAPH:
// - For each edge (u,v) with capacity c and flow f:
//   - Residual capacity u→v: c - f
//   - Residual capacity v→u: f (for flow cancellation)
//
// INVARIANTS:
// 1. Flow conservation: inflow = outflow for all non-source/sink nodes
// 2. Capacity constraints: 0 ≤ flow(e) ≤ capacity(e) for all edges
// 3. Level[u] < Level[v] for all edges (u,v) in level graph
// 4. After each phase, shortest s-t path length increases
//
// TIME COMPLEXITY: O(V²E) general, O(E√V) for unit capacity
// SPACE COMPLEXITY: O(V + E)

///|
/// A single directed edge in the flow network.
///
/// Each logical edge `u -> v` is stored as a pair: one forward `Edge` in
/// `adj[u]` and one reverse `Edge` in `adj[v]`.  The reverse edge starts with
/// `capacity = 0` so that it acts purely as a "cancel" arc in the residual
/// graph.
///
/// Fields:
/// - `to`       -- destination vertex index
/// - `capacity` -- maximum flow this edge can carry (immutable after creation)
/// - `flow`     -- current flow on this edge (mutable, 0 <= flow <= capacity)
/// - `rev_idx`  -- index of the paired reverse edge inside `adj[to]`, enabling
///                 O(1) residual updates
priv struct Edge {
  to : Int
  capacity : Int64
  mut flow : Int64
  rev_idx : Int // Index of reverse edge in adj[to]
}

///|
/// Flow network used by Dinic's algorithm.
///
/// Stores the adjacency lists for all vertices together with two auxiliary
/// arrays that are reused across BFS/DFS phases:
///
/// - `adj`   -- adjacency list; `adj[u]` holds all edges leaving vertex `u`
///              (both original forward edges and their reverse counterparts)
/// - `level` -- BFS distance from the source; reset to -1 before each BFS
/// - `iter`  -- current-arc pointer per vertex; used by DFS to skip edges
///              that have already been found to lead nowhere (dead-end
///              pruning), reducing the DFS work to O(VE) per phase
///
/// Create with `MaxFlow::new(n)` and populate with `add_edge` or
/// `add_undirected_edge` before calling `max_flow`.
priv struct MaxFlow {
  n : Int
  adj : Array[Array[Edge]]
  level : Array[Int]
  iter : Array[Int] // For dead-end pruning in DFS
}

///|
/// Create a new, empty flow network with `n` vertices (indexed 0..n-1).
///
/// All adjacency lists are initialised empty.  `level` and `iter` arrays are
/// pre-allocated but their initial values are overwritten before each use.
fn MaxFlow::new(n : Int) -> MaxFlow {
  let adj : Array[Array[Edge]] = Array::makei(n, _ => [])
  { n, adj, level: Array::make(n, -1), iter: Array::make(n, 0) }
}

///|
/// Add a directed edge `from -> to` with the given `capacity`.
///
/// Internally this also inserts a **reverse edge** `to -> from` with capacity
/// 0.  The reverse edge is essential for the residual graph: pushing `d` units
/// of flow on `from -> to` reduces its residual by `d` and increases the
/// reverse residual by `d`, allowing the algorithm to "undo" flow decisions
/// made in earlier phases.
///
/// Panics (index-out-of-bounds) if `from` or `to` is outside `[0, n)`.
fn MaxFlow::add_edge(
  self : MaxFlow,
  from : Int,
  to : Int,
  capacity : Int64,
) -> Unit {
  let from_idx = self.adj[from].length()
  let to_idx = self.adj[to].length()

  // Forward edge
  self.adj[from].push({ to, capacity, flow: 0L, rev_idx: to_idx })
  // Reverse edge (for flow cancellation)
  self.adj[to].push({ to: from, capacity: 0L, flow: 0L, rev_idx: from_idx })
}

///|
/// Add an **undirected** edge between `u` and `v` with capacity `capacity` in
/// each direction.
///
/// Unlike `add_edge`, both halves of the edge are stored as forward edges with
/// the specified capacity.  Each half still gets the other as its reverse for
/// residual-graph updates, so flow pushed in one direction can be cancelled by
/// flow in the other direction.
///
/// Use this when the underlying connection is symmetric (e.g., undirected
/// graphs, two-way pipes).
///
/// Panics (index-out-of-bounds) if `u` or `v` is outside `[0, n)`.
fn MaxFlow::add_undirected_edge(
  self : MaxFlow,
  u : Int,
  v : Int,
  capacity : Int64,
) -> Unit {
  let u_idx = self.adj[u].length()
  let v_idx = self.adj[v].length()
  self.adj[u].push({ to: v, capacity, flow: 0L, rev_idx: v_idx })
  self.adj[v].push({ to: u, capacity, flow: 0L, rev_idx: u_idx })
}

///|
/// Build the level graph by running BFS from `source` in the residual network.
///
/// Assigns `level[v]` = shortest-hop distance from `source` to `v` through
/// edges with positive residual capacity.  Sets `level[v] = -1` for vertices
/// that cannot be reached.
///
/// Returns `true` if `sink` is reachable (i.e., another Dinic phase is
/// possible), `false` otherwise (algorithm should terminate).
///
/// This function is called once per Dinic phase and resets all level values
/// before each run so stale data from the previous phase does not interfere.
fn MaxFlow::bfs(self : MaxFlow, source : Int, sink : Int) -> Bool {
  for i in 0..<self.n {
    self.level[i] = -1
  } where {
    proof_invariant: i >= 0 && i <= self.n,
    proof_reasoning: (
      #|INVARIANT (reset levels):
      #|level[0..i) are reset to -1 from the previous BFS phase.
      #|MAINTENANCE:
      #|Set level[i] = -1 to clear the next node.
      #|TERMINATION:
      #|At i = n, all levels are reset.
    ),
  }
  self.level[source] = 0
  let queue : Array[Int] = [source]

  // INVARIANT: head >= 0 && head <= queue.length()
  // I: level[source]=0, queue=[source]. M: BFS explores vertices level by level.
  // For each vertex u at level d, we set level[v] = d+1 for unvisited neighbors v
  // with residual capacity. This constructs the level graph where only edges to
  // next level are used. T: When queue exhausted, level[v] = shortest path
  // distance from source, or -1 if unreachable.
  for head = 0; head < queue.length(); {
    let u = queue[head]
    for i in 0..<self.adj[u].length() {
      let e = self.adj[u][i]
      if self.level[e.to] < 0 && e.capacity > e.flow {
        self.level[e.to] = self.level[u] + 1
        queue.push(e.to)
      }
    } where {
      proof_invariant: i >= 0 && i <= self.adj[u].length(),
      proof_reasoning: (
        #|INVARIANT (bfs edges):
        #|Edges adj[u][0..i) have been scanned; reachable neighbors are leveled.
        #|MAINTENANCE:
        #|If residual > 0 and unseen, set level and enqueue.
        #|TERMINATION:
        #|At i = deg(u), all outgoing edges are processed.
      ),
    }
    continue head + 1
  }
  self.level[sink] >= 0
}

///|
/// Recursively find and push flow along a single augmenting path in the level
/// graph (DFS phase of Dinic's algorithm).
///
/// Parameters:
/// - `u`      -- current vertex
/// - `sink`   -- destination vertex
/// - `pushed` -- maximum flow budget available on the path so far (starts at
///               `FLOW_INF` from the top-level caller)
///
/// Returns the amount of flow actually pushed (0 if no augmenting path was
/// found from `u` to `sink`).
///
/// The current-arc optimisation (`iter[u]`) means that once an edge is found
/// to lead nowhere (DFS returned 0), `iter[u]` is advanced past it and it will
/// never be re-examined in this phase.  This keeps the total DFS work across
/// all calls in a single phase to O(V * E).
fn MaxFlow::dfs(self : MaxFlow, u : Int, sink : Int, pushed : Int64) -> Int64 {
  if u == sink {
    return pushed
  }
  for next_edge = self.iter[u] < self.adj[u].length(); next_edge; {
    let idx = self.iter[u]
    let e = self.adj[u][idx]
    if self.level[u] + 1 == self.level[e.to] && e.capacity > e.flow {
      let residual = e.capacity - e.flow
      let can_push = if pushed < residual { pushed } else { residual }
      let d = self.dfs(e.to, sink, can_push)
      if d > 0L {
        self.adj[u][idx].flow = e.flow + d
        self.adj[e.to][e.rev_idx].flow = self.adj[e.to][e.rev_idx].flow - d
        return d
      }
    }
    self.iter[u] = self.iter[u] + 1
    continue self.iter[u] < self.adj[u].length()
  }
  0L
}

///|
/// Sentinel value used as the initial flow budget passed into `dfs`.
///
/// Equal to `Int64` maximum value (2^63 - 1).  Because every real edge
/// capacity is finite and much smaller than this, the actual bottleneck on any
/// path will always be the tightest edge, not this sentinel.
const FLOW_INF : Int64 = 9223372036854775807L

///|
/// Compute the maximum flow from `source` to `sink` using Dinic's algorithm.
///
/// The algorithm alternates between two phases until `sink` becomes unreachable
/// in the residual graph:
///
/// 1. **BFS phase** -- builds the level graph (`level[]` array).
/// 2. **DFS phase** -- finds a blocking flow (saturates every shortest path),
///    using the current-arc array (`iter[]`) to prune dead ends.
///
/// Returns the total flow value as `Int64`.
///
/// Complexity: O(V^2 * E) in general, O(E * sqrt(V)) for unit-capacity graphs
/// (e.g., bipartite matching).
///
/// The flow values accumulated in the `Edge.flow` fields can be inspected
/// after this call to determine the actual flow on each individual edge.
/// Call `min_cut` afterwards to identify a minimum cut achieving this flow.
fn MaxFlow::max_flow(self : MaxFlow, source : Int, sink : Int) -> Int64 {
  // INVARIANT: flow >= 0
  // I: flow=0, no flow pushed. M: Each iteration builds level graph via BFS.
  // If sink unreachable, we're done (max-flow min-cut theorem). Otherwise, find
  // blocking flow via DFS: repeatedly find augmenting paths until no more exist.
  // Blocking flow saturates at least one edge on every s-t path in level graph.
  // After each phase, shortest path length increases by at least 1.
  // T: After at most n phases, sink becomes unreachable and flow equals maximum.
  for flow = 0L; self.bfs(source, sink); {
    // Reset iteration pointers for dead-end pruning
    for i in 0..<self.n {
      self.iter[i] = 0
    } where {
      proof_invariant: i >= 0 && i <= self.n,
      proof_reasoning: (
        #|INVARIANT (reset iter):
        #|iter[0..i) are reset for the new level graph.
        #|MAINTENANCE:
        #|Set iter[i] = 0 to restart DFS scans at each node.
        #|TERMINATION:
        #|At i = n, all iterators are reset.
      ),
    }

    // Find blocking flow
    let flow = for pushed = self.dfs(source, sink, FLOW_INF), flow = flow; pushed >
                  0L; {
      continue self.dfs(source, sink, FLOW_INF), flow + pushed
    } nobreak {
      flow
    } where {
      proof_invariant: flow >= 0L,
      proof_reasoning: (
        #|INVARIANT (blocking flow):
        #|flow is the total pushed in this phase plus prior phases.
        #|MAINTENANCE:
        #|Add each augmenting path's flow until dfs returns 0.
        #|TERMINATION:
        #|When pushed == 0, a blocking flow is reached.
      ),
    }
    continue flow
  } nobreak {
    flow
  }
}

///|
/// Return the edges of a minimum s-t cut after `max_flow` has been called.
///
/// A minimum cut partitions the vertices into two sets:
/// - `S` -- vertices reachable from `source` in the **residual** graph
/// - `T` -- all other vertices (including the sink)
///
/// Every edge from `S` to `T` in the **original** graph (capacity > 0) is a
/// cut edge; together their capacities sum to the maximum flow value
/// (by the max-flow min-cut theorem).
///
/// Returns an array of `(u, v, capacity)` triples for each cut edge.
///
/// Note: this function must be called **after** `max_flow`; calling it on a
/// fresh network (no flow computed) will return the trivial cut containing all
/// edges out of `source`.
fn MaxFlow::min_cut(self : MaxFlow, source : Int) -> Array[(Int, Int, Int64)] {
  // After max flow, do one more BFS to find reachable vertices
  let visited = Array::make(self.n, false)
  let queue : Array[Int] = [source]
  visited[source] = true
  for head = 0; head < queue.length(); {
    let u = queue[head]
    for i in 0..<self.adj[u].length() {
      let e = self.adj[u][i]
      if !visited[e.to] && e.capacity > e.flow {
        visited[e.to] = true
        queue.push(e.to)
      }
    } where {
      proof_invariant: i >= 0 && i <= self.adj[u].length(),
      proof_reasoning: (
        #|INVARIANT (min-cut BFS edges):
        #|Edges adj[u][0..i) have been scanned for residual reachability.
        #|MAINTENANCE:
        #|If residual > 0 and unseen, mark visited and enqueue.
        #|TERMINATION:
        #|At i = deg(u), all outgoing edges are processed.
      ),
    }
    continue head + 1
  }

  // Collect cut edges: from visited to non-visited with original capacity
  let cut : Array[(Int, Int, Int64)] = []
  for u in 0..<self.n {
    if visited[u] {
      for i in 0..<self.adj[u].length() {
        let e = self.adj[u][i]
        if !visited[e.to] && e.capacity > 0L {
          cut.push((u, e.to, e.capacity))
        }
      } where {
        proof_invariant: i >= 0 && i <= self.adj[u].length(),
        proof_reasoning: (
          #|INVARIANT (cut edges):
          #|Edges adj[u][0..i) have been checked for cut crossings.
          #|MAINTENANCE:
          #|If edge goes to an unvisited node and has capacity, add to cut.
          #|TERMINATION:
          #|At i = deg(u), all outgoing edges from u are processed.
        ),
      }
    }
  } where {
    proof_invariant: u >= 0 && u <= self.n,
    proof_reasoning: (
      #|INVARIANT (cut scan):
      #|Vertices [0..u) have been scanned for cut edges.
      #|MAINTENANCE:
      #|Process vertex u if visited, collecting its crossing edges.
      #|TERMINATION:
      #|At u = n, all reachable vertices are processed.
    ),
  }
  cut
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "max flow basic" {
  // Simple graph:
  //   1 -- 2
  //  /|    |\
  // s |    | t
  //  \|    |/
  //   3 -- 4
  // All edges have capacity 1
  let mf = MaxFlow::new(6)
  let s = 0
  let t = 5
  mf.add_edge(s, 1, 10L)
  mf.add_edge(s, 3, 10L)
  mf.add_edge(1, 2, 4L)
  mf.add_edge(1, 3, 2L)
  mf.add_edge(3, 4, 9L)
  mf.add_edge(2, t, 10L)
  mf.add_edge(4, 2, 6L)
  mf.add_edge(4, t, 10L)

  // Max flow = 13 (min cut at edges 1->2: 4, 3->4: 9)
  inspect(mf.max_flow(s, t), content="13")
}

///|
test "max flow simple path" {
  // s -> a -> b -> t, all capacity 5
  let mf = MaxFlow::new(4)
  mf.add_edge(0, 1, 5L)
  mf.add_edge(1, 2, 5L)
  mf.add_edge(2, 3, 5L)
  inspect(mf.max_flow(0, 3), content="5")
}

///|
test "max flow parallel edges" {
  // s -> t with multiple edges
  let mf = MaxFlow::new(2)
  mf.add_edge(0, 1, 5L)
  mf.add_edge(0, 1, 3L)
  mf.add_edge(0, 1, 2L)
  inspect(mf.max_flow(0, 1), content="10")
}

///|
test "max flow bottleneck" {
  // s -> a (100) -> b (1) -> t (100)
  let mf = MaxFlow::new(4)
  mf.add_edge(0, 1, 100L)
  mf.add_edge(1, 2, 1L)
  mf.add_edge(2, 3, 100L)
  inspect(mf.max_flow(0, 3), content="1")
}

///|
test "max flow no path" {
  // Disconnected graph
  let mf = MaxFlow::new(4)
  mf.add_edge(0, 1, 10L)
  mf.add_edge(2, 3, 10L)
  inspect(mf.max_flow(0, 3), content="0")
}

///|
test "max flow bipartite matching" {
  // Bipartite graph: left {1,2,3}, right {4,5,6}
  // Source 0, sink 7
  let mf = MaxFlow::new(8)

  // Source to left
  mf.add_edge(0, 1, 1L)
  mf.add_edge(0, 2, 1L)
  mf.add_edge(0, 3, 1L)

  // Left to right
  mf.add_edge(1, 4, 1L)
  mf.add_edge(1, 5, 1L)
  mf.add_edge(2, 5, 1L)
  mf.add_edge(2, 6, 1L)
  mf.add_edge(3, 4, 1L)

  // Right to sink
  mf.add_edge(4, 7, 1L)
  mf.add_edge(5, 7, 1L)
  mf.add_edge(6, 7, 1L)

  // Maximum matching = 3
  inspect(mf.max_flow(0, 7), content="3")
}

///|
test "max flow min cut" {
  let mf = MaxFlow::new(4)
  mf.add_edge(0, 1, 3L)
  mf.add_edge(0, 2, 2L)
  mf.add_edge(1, 3, 2L)
  mf.add_edge(2, 3, 3L)
  let flow = mf.max_flow(0, 3)
  // Max flow: 0->1->3 (2) + 0->2->3 (2) = 4
  inspect(flow, content="4")
  let cut = mf.min_cut(0)
  // Cut should have total capacity = max flow
  let cut_capacity = for i = 0, cut_capacity = 0L; i < cut.length(); {
    let (_, _, cap) = cut[i]
    continue i + 1, cut_capacity + cap
  } nobreak {
    cut_capacity
  } where {
    proof_invariant: i >= 0 && i <= cut.length(),
    proof_reasoning: (
      #|INVARIANT (cut sum):
      #|cut_capacity equals the sum of cut[0..i) capacities.
      #|MAINTENANCE:
      #|Add cut[i].capacity to the running total.
      #|TERMINATION:
      #|At i = cut.length(), cut_capacity is the full cut sum.
    ),
  }
  inspect(cut_capacity, content="4")
}

///|
test "max flow undirected edge" {
  let mf = MaxFlow::new(2)
  mf.add_undirected_edge(0, 1, 7L)
  inspect(mf.max_flow(0, 1), content="7")
}

///|
test "max flow empty" {
  let mf = MaxFlow::new(2)
  inspect(mf.max_flow(0, 1), content="0")
}

///|
test "max flow self loop ignored" {
  let mf = MaxFlow::new(3)
  mf.add_edge(0, 1, 10L)
  mf.add_edge(1, 2, 10L)
  // Self loop doesn't affect flow
  mf.add_edge(1, 1, 100L)
  inspect(mf.max_flow(0, 2), content="10")
}
