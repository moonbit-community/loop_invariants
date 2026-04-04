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
pub(all) struct MinCutSTResult {
  value : Int64
  source_side : Array[Int]
}

///|
priv struct Edge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int
}

///|
priv struct FlowGraph {
  n : Int
  adj : Array[Array[Edge]]
  level : Array[Int]
  iter : Array[Int]
}

///|
fn FlowGraph::new(n : Int) -> FlowGraph {
  let adj = Array::makei(n, _ => [])
  { n, adj, level: Array::make(n, -1), iter: Array::make(n, 0) }
}

///|
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
fn FlowGraph::bfs(self : FlowGraph, source : Int, sink : Int) -> Bool {
  for i in 0..<self.n {
    self.level[i] = -1
  } where {
    proof_invariant: i >= 0 && i <= self.n && self.level.length() == self.n,
    reasoning: (
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
      reasoning: (
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
fn FlowGraph::max_flow(self : FlowGraph, source : Int, sink : Int) -> Int64 {
  for flow = 0L; self.bfs(source, sink); {
    for i in 0..<self.n {
      self.iter[i] = 0
    } where {
      proof_invariant: i >= 0 && i <= self.n && self.iter.length() == self.n,
      reasoning: (
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
      reasoning: (
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
      reasoning: (
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
/// Compute minimum s-t cut by max-flow/min-cut.
/// Returns None for invalid inputs (n <= 0, source/sink out of range, or equal).
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
  let flow = FlowGraph::new(n)
  for i in 0..<edges.length() {
    let (u, v, cap) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n && u != v && cap > 0L {
      flow.add_edge(u, v, cap)
    }
  } where {
    proof_invariant: i >= 0 && i <= edges.length(),
    reasoning: (
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
  let result = min_cut_st(4, edges[:], 0, 3).unwrap()
  inspect(result.value, content="4")
  inspect(cut_capacity(4, edges[:], result.source_side), content="4")
}

///|
test "min cut st no path" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = min_cut_st(3, edges[:], 0, 2).unwrap()
  inspect(result.value, content="0")
}

///|
test "min cut st invalid" {
  let edges : Array[(Int, Int, Int64)] = []
  guard min_cut_st(0, edges[:], 0, 0) is None else { fail("expected None") }
}
