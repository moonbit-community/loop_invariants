// ============================================================================
// DINIC'S ALGORITHM - Maximum Flow in O(V²E)
// ============================================================================
//
// Dinic's algorithm finds maximum flow using blocking flows in layered graphs.
// Faster than Ford-Fulkerson and Edmonds-Karp for many practical cases.
//
// KEY INSIGHT: Build layered graph using BFS, then find blocking flow using DFS.
// A blocking flow saturates at least one edge on every path from source to sink.
//
// ALGORITHM:
// 1. BFS to build level graph (distance from source)
// 2. DFS to find blocking flow in level graph
// 3. Repeat until no path from source to sink
//
// OPTIMIZATION:
// - Use pointer to skip saturated edges (avoid re-examining them)
// - Works in O(V²E) time, O(E√V) for unit capacity graphs
//
// INVARIANTS:
// 1. Level graph contains only edges going to higher levels
// 2. Blocking flow saturates ≥1 edge on every s-t path
// 3. After each phase, distance from s to t increases
//
// TIME COMPLEXITY: O(V²E), O(E√V) for unit capacity
// SPACE COMPLEXITY: O(V + E)

///|
const DINIC_INF : Int64 = 4611686018427387903L

///|
priv struct DinicEdge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int // Index of reverse edge
}

///|
priv struct Dinic {
  n : Int
  adj : Array[Array[DinicEdge]]
  level : Array[Int]
  iter : Array[Int] // Current edge pointer for each vertex
}

///|
fn Dinic::new(n : Int) -> Dinic {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  { n, adj, level: Array::make(n, 0), iter: Array::make(n, 0) }
}

///|
fn Dinic::add_edge(self : Dinic, from : Int, to : Int, cap : Int64) -> Unit {
  let rev_from = self.adj[to].length()
  let rev_to = self.adj[from].length()
  self.adj[from].push({ to, cap, flow: 0L, rev: rev_from })
  self.adj[to].push({ to: from, cap: 0L, flow: 0L, rev: rev_to })
}

///|
/// BFS to build level graph
fn Dinic::bfs(self : Dinic, source : Int, sink : Int) -> Bool {
  for i = 0; i < self.n; i = i + 1 {
    self.level[i] = -1
  }

  self.level[source] = 0
  let queue : Array[Int] = [source]
  let mut front = 0

  while front < queue.length() {
    let u = queue[front]
    front = front + 1

    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]
      if e.cap > e.flow && self.level[e.to] < 0 {
        self.level[e.to] = self.level[u] + 1
        queue.push(e.to)
      }
    }
  }

  self.level[sink] >= 0
}

///|
/// DFS to find blocking flow
fn Dinic::dfs(self : Dinic, u : Int, sink : Int, pushed : Int64) -> Int64 {
  if u == sink || pushed == 0L {
    return pushed
  }

  while self.iter[u] < self.adj[u].length() {
    let i = self.iter[u]
    let e = self.adj[u][i]

    if self.level[e.to] == self.level[u] + 1 && e.cap > e.flow {
      let can_push = if e.cap - e.flow < pushed { e.cap - e.flow } else { pushed }
      let d = self.dfs(e.to, sink, can_push)
      if d > 0L {
        self.adj[u][i].flow = self.adj[u][i].flow + d
        self.adj[e.to][e.rev].flow = self.adj[e.to][e.rev].flow - d
        return d
      }
    }
    self.iter[u] = self.iter[u] + 1
  }

  0L
}

///|
/// Compute maximum flow from source to sink
fn Dinic::max_flow(self : Dinic, source : Int, sink : Int) -> Int64 {
  let mut flow = 0L

  while self.bfs(source, sink) {
    // Reset edge pointers
    for i = 0; i < self.n; i = i + 1 {
      self.iter[i] = 0
    }

    // Find blocking flow
    let mut f = self.dfs(source, sink, DINIC_INF)
    while f > 0L {
      flow = flow + f
      f = self.dfs(source, sink, DINIC_INF)
    }
  }

  flow
}

///|
/// Get flow on edge from u to v (first edge if multiple)
fn Dinic::get_flow(self : Dinic, u : Int, v : Int) -> Int64 {
  for i = 0; i < self.adj[u].length(); i = i + 1 {
    if self.adj[u][i].to == v {
      return self.adj[u][i].flow
    }
  }
  0L
}

///|
/// Reset all flows to 0
fn Dinic::reset(self : Dinic) -> Unit {
  for u = 0; u < self.n; u = u + 1 {
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      self.adj[u][i].flow = 0L
    }
  }
}

// ============================================================================
// MIN CUT
// ============================================================================

///|
/// Find vertices on source side of min cut
fn Dinic::min_cut_source_side(self : Dinic, source : Int) -> Array[Int] {
  // After max flow, BFS to find reachable vertices
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
    }
  }

  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "dinic basic" {
  let dinic = Dinic::new(4)
  // 0 -> 1 -> 3
  //  \-> 2 -/
  dinic.add_edge(0, 1, 3L)
  dinic.add_edge(0, 2, 2L)
  dinic.add_edge(1, 3, 2L)
  dinic.add_edge(2, 3, 3L)

  inspect(dinic.max_flow(0, 3), content="4")
}

///|
test "dinic simple" {
  let dinic = Dinic::new(2)
  dinic.add_edge(0, 1, 5L)

  inspect(dinic.max_flow(0, 1), content="5")
}

///|
test "dinic parallel" {
  let dinic = Dinic::new(2)
  dinic.add_edge(0, 1, 3L)
  dinic.add_edge(0, 1, 2L)

  inspect(dinic.max_flow(0, 1), content="5")
}

///|
test "dinic diamond" {
  let dinic = Dinic::new(4)
  dinic.add_edge(0, 1, 10L)
  dinic.add_edge(0, 2, 10L)
  dinic.add_edge(1, 3, 10L)
  dinic.add_edge(2, 3, 10L)

  inspect(dinic.max_flow(0, 3), content="20")
}

///|
test "dinic bottleneck" {
  let dinic = Dinic::new(3)
  dinic.add_edge(0, 1, 100L)
  dinic.add_edge(1, 2, 1L) // Bottleneck

  inspect(dinic.max_flow(0, 2), content="1")
}

///|
test "dinic no path" {
  let dinic = Dinic::new(3)
  dinic.add_edge(0, 1, 5L)
  // No edge to vertex 2

  inspect(dinic.max_flow(0, 2), content="0")
}

///|
test "dinic min cut" {
  let dinic = Dinic::new(4)
  dinic.add_edge(0, 1, 3L)
  dinic.add_edge(0, 2, 2L)
  dinic.add_edge(1, 3, 2L)
  dinic.add_edge(2, 3, 3L)

  let _ = dinic.max_flow(0, 3)
  let source_side = dinic.min_cut_source_side(0)
  // Source side should include source
  let has_source = source_side.contains(0)
  inspect(has_source, content="true")
}

///|
test "dinic larger" {
  let dinic = Dinic::new(6)
  // More complex network
  dinic.add_edge(0, 1, 16L)
  dinic.add_edge(0, 2, 13L)
  dinic.add_edge(1, 2, 10L)
  dinic.add_edge(1, 3, 12L)
  dinic.add_edge(2, 1, 4L)
  dinic.add_edge(2, 4, 14L)
  dinic.add_edge(3, 2, 9L)
  dinic.add_edge(3, 5, 20L)
  dinic.add_edge(4, 3, 7L)
  dinic.add_edge(4, 5, 4L)

  inspect(dinic.max_flow(0, 5), content="23")
}

///|
test "dinic reset" {
  let dinic = Dinic::new(2)
  dinic.add_edge(0, 1, 5L)

  inspect(dinic.max_flow(0, 1), content="5")
  dinic.reset()
  inspect(dinic.max_flow(0, 1), content="5")
}
