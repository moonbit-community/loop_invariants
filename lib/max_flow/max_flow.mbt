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
priv struct Edge {
  to : Int
  capacity : Int64
  mut flow : Int64
  rev_idx : Int // Index of reverse edge in adj[to]
}

///|
priv struct MaxFlow {
  n : Int
  adj : Array[Array[Edge]]
  level : Array[Int]
  iter : Array[Int] // For dead-end pruning in DFS
}

///|
fn MaxFlow::new(n : Int) -> MaxFlow {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: "I: adj filled with default empty array. M: Create fresh empty array at each position to avoid aliasing. T: All n vertices have independent adjacency lists.",
  }
  { n, adj, level: Array::make(n, -1), iter: Array::make(n, 0) }
}

///|
/// Add edge from u to v with given capacity
fn MaxFlow::add_edge(self : MaxFlow, from : Int, to : Int, capacity : Int64) -> Unit {
  let from_idx = self.adj[from].length()
  let to_idx = self.adj[to].length()

  // Forward edge
  self.adj[from].push({ to, capacity, flow: 0L, rev_idx: to_idx })
  // Reverse edge (for flow cancellation)
  self.adj[to].push({ to: from, capacity: 0L, flow: 0L, rev_idx: from_idx })
}

///|
/// Add undirected edge (two directed edges with same capacity)
fn MaxFlow::add_undirected_edge(self : MaxFlow, u : Int, v : Int, capacity : Int64) -> Unit {
  let u_idx = self.adj[u].length()
  let v_idx = self.adj[v].length()

  self.adj[u].push({ to: v, capacity, flow: 0L, rev_idx: v_idx })
  self.adj[v].push({ to: u, capacity, flow: 0L, rev_idx: u_idx })
}

///|
/// BFS to build level graph
fn MaxFlow::bfs(self : MaxFlow, source : Int, sink : Int) -> Bool {
  for i = 0; i < self.n; i = i + 1 {
    self.level[i] = -1
  }

  self.level[source] = 0
  let queue : Array[Int] = [source]
  let mut head = 0

  // INVARIANT: head >= 0 && head <= queue.length()
  // I: level[source]=0, queue=[source]. M: BFS explores vertices level by level.
  // For each vertex u at level d, we set level[v] = d+1 for unvisited neighbors v
  // with residual capacity. This constructs the level graph where only edges to
  // next level are used. T: When queue exhausted, level[v] = shortest path
  // distance from source, or -1 if unreachable.
  while head < queue.length() {
    let u = queue[head]
    head = head + 1

    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]
      if self.level[e.to] < 0 && e.capacity > e.flow {
        self.level[e.to] = self.level[u] + 1
        queue.push(e.to)
      }
    }
  }

  self.level[sink] >= 0
}

///|
/// DFS to find blocking flow
fn MaxFlow::dfs(self : MaxFlow, u : Int, sink : Int, pushed : Int64) -> Int64 {
  if u == sink {
    return pushed
  }

  while self.iter[u] < self.adj[u].length() {
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
  }

  0L
}

///|
const FLOW_INF : Int64 = 9223372036854775807L

///|
/// Compute maximum flow from source to sink
fn MaxFlow::max_flow(self : MaxFlow, source : Int, sink : Int) -> Int64 {
  let mut flow = 0L

  // INVARIANT: flow >= 0
  // I: flow=0, no flow pushed. M: Each iteration builds level graph via BFS.
  // If sink unreachable, we're done (max-flow min-cut theorem). Otherwise, find
  // blocking flow via DFS: repeatedly find augmenting paths until no more exist.
  // Blocking flow saturates at least one edge on every s-t path in level graph.
  // After each phase, shortest path length increases by at least 1.
  // T: After at most n phases, sink becomes unreachable and flow equals maximum.
  while self.bfs(source, sink) {
    // Reset iteration pointers for dead-end pruning
    for i = 0; i < self.n; i = i + 1 {
      self.iter[i] = 0
    }

    // Find blocking flow
    for {
      let pushed = self.dfs(source, sink, FLOW_INF)
      if pushed == 0L {
        break
      }
      flow = flow + pushed
    }
  }

  flow
}

///|
/// Get the minimum cut (edges from source side to sink side)
fn MaxFlow::min_cut(self : MaxFlow, source : Int) -> Array[(Int, Int, Int64)] {
  // After max flow, do one more BFS to find reachable vertices
  let visited = Array::make(self.n, false)
  let queue : Array[Int] = [source]
  visited[source] = true
  let mut head = 0

  while head < queue.length() {
    let u = queue[head]
    head = head + 1
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]
      if not(visited[e.to]) && e.capacity > e.flow {
        visited[e.to] = true
        queue.push(e.to)
      }
    }
  }

  // Collect cut edges: from visited to non-visited with original capacity
  let cut : Array[(Int, Int, Int64)] = []
  for u = 0; u < self.n; u = u + 1 {
    if visited[u] {
      for i = 0; i < self.adj[u].length(); i = i + 1 {
        let e = self.adj[u][i]
        if not(visited[e.to]) && e.capacity > 0L {
          cut.push((u, e.to, e.capacity))
        }
      }
    }
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
  let mut cut_capacity = 0L
  for i = 0; i < cut.length(); i = i + 1 {
    let (_, _, cap) = cut[i]
    cut_capacity = cut_capacity + cap
  }
  inspect(cut_capacity, content="4")
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
