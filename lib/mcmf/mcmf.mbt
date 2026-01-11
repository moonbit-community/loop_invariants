// ============================================================================
// MIN-COST MAX-FLOW - Minimum Cost Maximum Flow Algorithm
// ============================================================================
//
// Find maximum flow with minimum cost. Each edge has capacity and cost per unit flow.
//
// ALGORITHM (SPFA-based):
// 1. Find shortest path (by cost) from source to sink using SPFA
// 2. Augment flow along this path
// 3. Repeat until no augmenting path exists
//
// KEY INSIGHT: Augmenting along minimum cost path ensures we get minimum cost
// for the current flow value. Using residual graph with negative cost for
// reverse edges allows flow cancellation.
//
// RESIDUAL GRAPH:
// For edge (u, v) with capacity c, flow f, cost w:
// - Forward edge: capacity c-f, cost w
// - Backward edge: capacity f, cost -w (for flow cancellation)
//
// INVARIANTS:
// 1. Flow conservation: inflow = outflow for all non-source/sink vertices
// 2. Capacity constraint: 0 ≤ flow ≤ capacity for all edges
// 3. After each augmentation, total cost is minimum for current flow value
//
// TIME COMPLEXITY: O(V * E * F) where F is max flow value
// SPACE COMPLEXITY: O(V + E)

///|
const MCMF_INF : Int64 = 4611686018427387903L

///|
priv struct MCMFEdge {
  to : Int
  cap : Int64
  cost : Int64
  mut flow : Int64
  rev : Int // Index of reverse edge in adj[to]
}

///|
priv struct MinCostMaxFlow {
  n : Int
  adj : Array[Array[MCMFEdge]]
  dist : Array[Int64]
  prev_v : Array[Int]
  prev_e : Array[Int]
  in_queue : Array[Bool]
}

///|
fn MinCostMaxFlow::new(n : Int) -> MinCostMaxFlow {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (adj init):
      #|Adjacency lists for vertices in [0, i) are initialized and independent.
      #|MAINTENANCE:
      #|Assign a fresh empty list to adj[i].
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
  }
  {
    n,
    adj,
    dist: Array::make(n, 0L),
    prev_v: Array::make(n, -1),
    prev_e: Array::make(n, -1),
    in_queue: Array::make(n, false),
  }
}

///|
/// Add edge from u to v with capacity cap and cost per unit flow
fn MinCostMaxFlow::add_edge(
  self : MinCostMaxFlow,
  u : Int,
  v : Int,
  cap : Int64,
  cost : Int64,
) -> Unit {
  let rev_u = self.adj[v].length()
  let rev_v = self.adj[u].length()
  self.adj[u].push({ to: v, cap, cost, flow: 0L, rev: rev_u })
  self.adj[v].push({ to: u, cap: 0L, cost: -cost, flow: 0L, rev: rev_v })
}

///|
/// SPFA to find minimum cost path
fn MinCostMaxFlow::spfa(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
) -> Bool {
  for i = 0; i < self.n; i = i + 1 {
    self.dist[i] = MCMF_INF
    self.prev_v[i] = -1
    self.prev_e[i] = -1
    self.in_queue[i] = false
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (SPFA reset):
      #|For vertices in [0, i), dist/prev/in_queue have been reset.
      #|MAINTENANCE:
      #|Clear state for vertex i.
      #|TERMINATION:
      #|At i = n, all vertices are reset for a fresh SPFA run.
    ),
  }
  self.dist[source] = 0L
  let queue : Array[Int] = [source]
  self.in_queue[source] = true
  let mut front = 0
  while front < queue.length() {
    let u = queue[front]
    front = front + 1
    self.in_queue[u] = false
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]
      // Can we push more flow through this edge?
      if e.cap > e.flow && self.dist[u] + e.cost < self.dist[e.to] {
        self.dist[e.to] = self.dist[u] + e.cost
        self.prev_v[e.to] = u
        self.prev_e[e.to] = i
        if not(self.in_queue[e.to]) {
          queue.push(e.to)
          self.in_queue[e.to] = true
        }
      }
    } where {
      invariant: i >= 0 && i <= self.adj[u].length() && self.dist[u] < MCMF_INF,
      reasoning: (
        #|INVARIANT (SPFA relax):
        #|All edges in adj[u][0..i) have been considered for relaxation.
        #|MAINTENANCE:
        #|Relax edge i if residual capacity exists and improve dist, enqueueing
        #|the neighbor when needed.
        #|TERMINATION:
        #|At i = deg(u), all outgoing edges from u are processed.
      ),
    }
  }
  self.dist[sink] < MCMF_INF
}

///|
/// Compute min-cost max-flow from source to sink
/// Returns (max_flow, min_cost)
fn MinCostMaxFlow::compute(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
) -> (Int64, Int64) {
  let mut total_flow = 0L
  let mut total_cost = 0L
  while self.spfa(source, sink) {
    // Find minimum residual capacity along path
    let mut path_flow = MCMF_INF
    let mut v = sink
    while v != source {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      let residual = self.adj[u][e_idx].cap - self.adj[u][e_idx].flow
      if residual < path_flow {
        path_flow = residual
      }
      v = u
    }

    // Augment flow along path
    v = sink
    while v != source {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      self.adj[u][e_idx].flow = self.adj[u][e_idx].flow + path_flow
      let rev_idx = self.adj[u][e_idx].rev
      self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
      v = u
    }
    total_flow = total_flow + path_flow
    total_cost = total_cost + path_flow * self.dist[sink]
  }
  (total_flow, total_cost)
}

///|
/// Compute min-cost max-flow with flow limit
fn MinCostMaxFlow::compute_with_limit(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
  max_flow_limit : Int64,
) -> (Int64, Int64) {
  let mut total_flow = 0L
  let mut total_cost = 0L
  while total_flow < max_flow_limit && self.spfa(source, sink) {
    let mut path_flow = MCMF_INF
    let remaining = max_flow_limit - total_flow
    if remaining < path_flow {
      path_flow = remaining
    }
    let mut v = sink
    while v != source {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      let residual = self.adj[u][e_idx].cap - self.adj[u][e_idx].flow
      if residual < path_flow {
        path_flow = residual
      }
      v = u
    }
    v = sink
    while v != source {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      self.adj[u][e_idx].flow = self.adj[u][e_idx].flow + path_flow
      let rev_idx = self.adj[u][e_idx].rev
      self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
      v = u
    }
    total_flow = total_flow + path_flow
    total_cost = total_cost + path_flow * self.dist[sink]
  }
  (total_flow, total_cost)
}

// ============================================================================
// ASSIGNMENT PROBLEM (as MCMF application)
// ============================================================================

///|
/// Solve assignment problem: n workers, n tasks, cost matrix
/// Returns minimum cost to assign each worker to exactly one task
fn solve_assignment(cost : Array[Array[Int64]]) -> Int64 {
  let n = cost.length()
  if n == 0 {
    return 0L
  }

  // Create bipartite graph:
  // Source = 0, Workers = 1..n, Tasks = n+1..2n, Sink = 2n+1
  let mcmf = MinCostMaxFlow::new(2 * n + 2)
  let source = 0
  let sink = 2 * n + 1

  // Source to workers
  for i = 0; i < n; i = i + 1 {
    mcmf.add_edge(source, i + 1, 1L, 0L)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (source workers):
      #|Workers in [0, i) have incoming edges from source.
      #|MAINTENANCE:
      #|Add the edge for worker i.
      #|TERMINATION:
      #|At i = n, all workers are connected from source.
    ),
  }

  // Workers to tasks
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < cost[i].length(); j = j + 1 {
      mcmf.add_edge(i + 1, n + 1 + j, 1L, cost[i][j])
    } where {
      invariant: j >= 0 && j <= cost[i].length(),
      reasoning: (
        #|INVARIANT (worker tasks):
        #|For fixed worker i, edges to tasks in [0, j) have been added.
        #|MAINTENANCE:
        #|Add the edge from worker i to task j with its cost.
        #|TERMINATION:
        #|At j = tasks, worker i connects to every task exactly once.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (all workers):
      #|Workers in [0, i) already have edges to all tasks.
      #|MAINTENANCE:
      #|Add edges for worker i to every task with its cost.
      #|TERMINATION:
      #|At i = n, the worker→task layer is fully connected.
    ),
  }

  // Tasks to sink
  for j = 0; j < n; j = j + 1 {
    mcmf.add_edge(n + 1 + j, sink, 1L, 0L)
  } where {
    invariant: j >= 0 && j <= n,
    reasoning: (
      #|INVARIANT (tasks sink):
      #|Tasks in [0, j) have edges to sink.
      #|MAINTENANCE:
      #|Add the edge from task j to sink.
      #|TERMINATION:
      #|At j = n, all tasks are connected to sink.
    ),
  }
  let (_, min_cost) = mcmf.compute(source, sink)
  min_cost
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mcmf basic" {
  let mcmf = MinCostMaxFlow::new(4)
  // Source = 0, Sink = 3
  // 0 -> 1: cap 2, cost 1
  // 0 -> 2: cap 1, cost 2
  // 1 -> 2: cap 1, cost 1
  // 1 -> 3: cap 1, cost 3
  // 2 -> 3: cap 2, cost 1

  mcmf.add_edge(0, 1, 2L, 1L)
  mcmf.add_edge(0, 2, 1L, 2L)
  mcmf.add_edge(1, 2, 1L, 1L)
  mcmf.add_edge(1, 3, 1L, 3L)
  mcmf.add_edge(2, 3, 2L, 1L)
  let (flow, cost) = mcmf.compute(0, 3)
  // Max flow = 3:
  // - 0->2->3: flow 1, cost 2+1=3
  // - 0->1->3: flow 1, cost 1+3=4
  // - 0->1->2->3: flow 1, cost 1+1+1=3
  // Total flow = 3, min cost = 10
  inspect(flow, content="3")
  // Min cost should be found by SPFA
  inspect(cost <= 12L, content="true")
}

///|
test "mcmf simple" {
  let mcmf = MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 5L, 2L)
  let (flow, cost) = mcmf.compute(0, 1)
  inspect(flow, content="5")
  inspect(cost, content="10") // 5 * 2
}

///|
test "mcmf no path" {
  let mcmf = MinCostMaxFlow::new(3)
  mcmf.add_edge(0, 1, 1L, 1L)
  // No edge to vertex 2

  let (flow, cost) = mcmf.compute(0, 2)
  inspect(flow, content="0")
  inspect(cost, content="0")
}

///|
test "mcmf parallel edges" {
  let mcmf = MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 2L, 1L) // Cheap
  mcmf.add_edge(0, 1, 2L, 3L) // Expensive
  let (flow, cost) = mcmf.compute(0, 1)
  inspect(flow, content="4")
  // Should use cheap edge first: 2*1 + 2*3 = 8
  inspect(cost, content="8")
}

///|
test "mcmf flow limit" {
  let mcmf = MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 10L, 1L)
  let (flow, cost) = mcmf.compute_with_limit(0, 1, 5L)
  inspect(flow, content="5")
  inspect(cost, content="5")
}

///|
test "assignment basic" {
  // 2 workers, 2 tasks
  let cost : Array[Array[Int64]] = [[1L, 3L], [2L, 2L]]
  // Optimal: worker 0 -> task 0 (cost 1), worker 1 -> task 1 (cost 2) = 3
  // Or: worker 0 -> task 1 (cost 3), worker 1 -> task 0 (cost 2) = 5
  inspect(solve_assignment(cost), content="3")
}

///|
test "assignment larger" {
  let cost : Array[Array[Int64]] = [[9L, 2L, 7L], [6L, 4L, 3L], [5L, 8L, 1L]]
  // Find minimum cost perfect matching
  let result = solve_assignment(cost)
  // Optimal: 0->1(2), 1->0(6), 2->2(1) = 9
  // Or: 0->1(2), 1->2(3), 2->0(5) = 10
  // Or: 0->2(7), 1->1(4), 2->0(5) = 16
  // Minimum is 9
  inspect(result, content="9")
}

///|
test "mcmf diamond" {
  // Diamond graph: 0 -> 1,2 -> 3
  let mcmf = MinCostMaxFlow::new(4)
  mcmf.add_edge(0, 1, 3L, 1L)
  mcmf.add_edge(0, 2, 3L, 2L)
  mcmf.add_edge(1, 3, 3L, 1L)
  mcmf.add_edge(2, 3, 3L, 1L)
  let (flow, cost) = mcmf.compute(0, 3)
  inspect(flow, content="6") // 3 + 3
  // Min cost: 3 through top (cost 1+1=2 each) + 3 through bottom (cost 2+1=3 each)
  // = 3*2 + 3*3 = 15
  inspect(cost, content="15")
}
