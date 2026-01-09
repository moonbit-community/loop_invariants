// Network Flow Algorithms
// with rigorous loop invariants and mathematical reasoning

///|
/// Edge in a flow network
struct FlowEdge {
  to : Int
  capacity : Int
  mut flow : Int
  rev_idx : Int // Index of reverse edge in adj[to]
}

///|
/// Flow Network using adjacency list
struct FlowNetwork {
  adj : Array[Array[FlowEdge]]
  n : Int
}

///|
fn FlowNetwork::new(n : Int) -> FlowNetwork {
  let adj : Array[Array[FlowEdge]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  }
  { adj, n }
}

///|
fn FlowNetwork::add_edge(
  self : FlowNetwork,
  from : Int,
  to : Int,
  capacity : Int,
) -> Unit {
  let forward_idx = self.adj[from].length()
  let backward_idx = self.adj[to].length()

  // Forward edge
  self.adj[from].push({ to, capacity, flow: 0, rev_idx: backward_idx })

  // Backward edge (for residual graph)
  self.adj[to].push({ to: from, capacity: 0, flow: 0, rev_idx: forward_idx })
}

///|
/// BFS to find augmenting path
fn FlowNetwork::bfs_find_path(
  self : FlowNetwork,
  source : Int,
  sink : Int,
) -> (Bool, Array[(Int, Int)?]) {
  let parent : Array[(Int, Int)?] = Array::make(self.n, None)
  let visited : Array[Bool] = Array::make(self.n, false)
  let queue : Array[Int] = []
  queue.push(source)
  visited[source] = true
  for front = 0; front < queue.length() && not(visited[sink]); front = front + 1 {
    let u = queue[front]
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let edge = self.adj[u][i]
      let residual = edge.capacity - edge.flow
      if residual > 0 && not(visited[edge.to]) {
        visited[edge.to] = true
        parent[edge.to] = Some((u, i))
        queue.push(edge.to)
      }
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|BFS INVARIANT: All nodes in queue[0..front) have been processed.
      #|visited[v] = true iff v is reachable from source in residual graph.
    ),
  }
  (visited[sink], parent)
}

///|
/// Ford-Fulkerson using BFS (Edmonds-Karp Algorithm)
///
/// MATHEMATICAL FOUNDATION:
/// The max-flow min-cut theorem states that:
/// max_flow(s, t) = min_cut(s, t)
///
/// TIME: O(VE²) - each BFS finds shortest path, at most O(VE) iterations
fn FlowNetwork::edmonds_karp(
  self : FlowNetwork,
  source : Int,
  sink : Int,
) -> Int {
  let mut max_flow = 0
  let mut found_path = true
  while found_path {
    let (has_path, parent) = self.bfs_find_path(source, sink)
    found_path = has_path
    if has_path {
      // Find minimum residual capacity along path
      let mut path_flow = 2147483647
      let mut v = sink
      while v != source {
        match parent[v] {
          None => v = source // Exit loop
          Some((u, edge_idx)) => {
            let residual = self.adj[u][edge_idx].capacity -
              self.adj[u][edge_idx].flow
            if residual < path_flow {
              path_flow = residual
            }
            v = u
          }
        }
      }

      // Augment flow along path
      v = sink
      while v != source {
        match parent[v] {
          None => v = source
          Some((u, edge_idx)) => {
            self.adj[u][edge_idx].flow = self.adj[u][edge_idx].flow + path_flow
            let rev_idx = self.adj[u][edge_idx].rev_idx
            self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
            v = u
          }
        }
      }
      max_flow = max_flow + path_flow
    }
  }
  max_flow
}

///|
test "edmonds karp basic" {
  let network = FlowNetwork::new(6)

  // Classic max flow example
  network.add_edge(0, 1, 10)
  network.add_edge(0, 2, 10)
  network.add_edge(1, 3, 10)
  network.add_edge(1, 4, 2)
  network.add_edge(2, 4, 10)
  network.add_edge(3, 5, 10)
  network.add_edge(4, 5, 10)
  let max_flow = network.edmonds_karp(0, 5)
  assert_eq(max_flow, 20)
}

///|
/// Dinic's Algorithm for Maximum Flow
///
/// Uses level graph (BFS levels) and blocking flows.
/// TIME: O(V²E) - at most V phases, each phase is O(VE)
struct DinicNetwork {
  adj : Array[Array[FlowEdge]]
  level : Array[Int]
  iter : Array[Int]
  n : Int
}

///|
fn DinicNetwork::new(n : Int) -> DinicNetwork {
  let adj : Array[Array[FlowEdge]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  }
  { adj, level: Array::make(n, -1), iter: Array::make(n, 0), n }
}

///|
fn DinicNetwork::add_edge_dinic(
  self : DinicNetwork,
  from : Int,
  to : Int,
  capacity : Int,
) -> Unit {
  let forward_idx = self.adj[from].length()
  let backward_idx = self.adj[to].length()
  self.adj[from].push({ to, capacity, flow: 0, rev_idx: backward_idx })
  self.adj[to].push({ to: from, capacity: 0, flow: 0, rev_idx: forward_idx })
}

///|
fn DinicNetwork::bfs_dinic(
  self : DinicNetwork,
  source : Int,
  sink : Int,
) -> Bool {
  for i = 0; i < self.n; i = i + 1 {
    self.level[i] = -1
  }
  self.level[source] = 0
  let queue : Array[Int] = []
  queue.push(source)
  for front = 0; front < queue.length(); front = front + 1 {
    let u = queue[front]
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let edge = self.adj[u][i]
      let residual = edge.capacity - edge.flow
      if residual > 0 && self.level[edge.to] < 0 {
        self.level[edge.to] = self.level[u] + 1
        queue.push(edge.to)
      }
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|BFS for level graph construction.
      #|level[v] = distance from source in residual graph.
    ),
  }
  self.level[sink] >= 0
}

///|
fn DinicNetwork::dfs_dinic(
  self : DinicNetwork,
  u : Int,
  sink : Int,
  flow_in : Int,
) -> Int {
  if u == sink {
    return flow_in
  }
  while self.iter[u] < self.adj[u].length() {
    let edge = self.adj[u][self.iter[u]]
    let residual = edge.capacity - edge.flow
    if residual > 0 && self.level[edge.to] == self.level[u] + 1 {
      let min_flow = if flow_in < residual { flow_in } else { residual }
      let pushed = self.dfs_dinic(edge.to, sink, min_flow)
      if pushed > 0 {
        self.adj[u][self.iter[u]].flow = self.adj[u][self.iter[u]].flow + pushed
        let rev_idx = edge.rev_idx
        self.adj[edge.to][rev_idx].flow = self.adj[edge.to][rev_idx].flow -
          pushed
        return pushed
      }
    }
    self.iter[u] = self.iter[u] + 1
  }
  0
}

///|
fn DinicNetwork::dinic_max_flow(
  self : DinicNetwork,
  source : Int,
  sink : Int,
) -> Int {
  let mut max_flow = 0
  while self.bfs_dinic(source, sink) {
    for i = 0; i < self.n; i = i + 1 {
      self.iter[i] = 0
    }
    let mut pushed = self.dfs_dinic(source, sink, 2147483647)
    while pushed > 0 {
      max_flow = max_flow + pushed
      pushed = self.dfs_dinic(source, sink, 2147483647)
    }
  }
  max_flow
}

///|
test "dinic basic" {
  let network = DinicNetwork::new(6)
  network.add_edge_dinic(0, 1, 10)
  network.add_edge_dinic(0, 2, 10)
  network.add_edge_dinic(1, 3, 10)
  network.add_edge_dinic(1, 4, 2)
  network.add_edge_dinic(2, 4, 10)
  network.add_edge_dinic(3, 5, 10)
  network.add_edge_dinic(4, 5, 10)
  let max_flow = network.dinic_max_flow(0, 5)
  assert_eq(max_flow, 20)
}

///|
/// Minimum Cost Maximum Flow
struct MCMFEdge {
  to : Int
  capacity : Int
  cost : Int
  mut flow : Int
  rev_idx : Int
}

///|
struct MCMFNetwork {
  adj : Array[Array[MCMFEdge]]
  n : Int
}

///|
fn MCMFNetwork::new(n : Int) -> MCMFNetwork {
  let adj : Array[Array[MCMFEdge]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  }
  { adj, n }
}

///|
fn MCMFNetwork::add_edge_mcmf(
  self : MCMFNetwork,
  from : Int,
  to : Int,
  capacity : Int,
  cost : Int,
) -> Unit {
  let forward_idx = self.adj[from].length()
  let backward_idx = self.adj[to].length()
  self.adj[from].push({ to, capacity, cost, flow: 0, rev_idx: backward_idx })
  self.adj[to].push({
    to: from,
    capacity: 0,
    cost: -cost,
    flow: 0,
    rev_idx: forward_idx,
  })
}

///|
fn MCMFNetwork::spfa_mcmf(
  self : MCMFNetwork,
  source : Int,
  sink : Int,
  dist : Array[Int],
  parent : Array[(Int, Int)?],
) -> Bool {
  let inf = 2147483647
  for i = 0; i < self.n; i = i + 1 {
    dist[i] = inf
    parent[i] = None
  }
  dist[source] = 0
  let in_queue : Array[Bool] = Array::make(self.n, false)
  let queue : Array[Int] = []
  queue.push(source)
  in_queue[source] = true
  for front = 0; front < queue.length(); front = front + 1 {
    let u = queue[front]
    in_queue[u] = false
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let edge = self.adj[u][i]
      let residual = edge.capacity - edge.flow
      if residual > 0 && dist[u] + edge.cost < dist[edge.to] {
        dist[edge.to] = dist[u] + edge.cost
        parent[edge.to] = Some((u, i))
        if not(in_queue[edge.to]) {
          queue.push(edge.to)
          in_queue[edge.to] = true
        }
      }
    }
  } where {
    invariant: front >= 0,
    reasoning: (
      #|SPFA for minimum cost path.
      #|Handles negative edges from reverse flows.
    ),
  }
  dist[sink] < inf
}

///|
fn MCMFNetwork::min_cost_max_flow(
  self : MCMFNetwork,
  source : Int,
  sink : Int,
) -> (Int, Int) {
  let mut max_flow = 0
  let mut min_cost = 0
  let dist : Array[Int] = Array::make(self.n, 0)
  let parent : Array[(Int, Int)?] = Array::make(self.n, None)
  while self.spfa_mcmf(source, sink, dist, parent) {
    // Find minimum residual capacity
    let mut path_flow = 2147483647
    let mut v = sink
    while v != source {
      match parent[v] {
        None => v = source
        Some((u, edge_idx)) => {
          let residual = self.adj[u][edge_idx].capacity -
            self.adj[u][edge_idx].flow
          if residual < path_flow {
            path_flow = residual
          }
          v = u
        }
      }
    }

    // Augment flow
    v = sink
    while v != source {
      match parent[v] {
        None => v = source
        Some((u, edge_idx)) => {
          self.adj[u][edge_idx].flow = self.adj[u][edge_idx].flow + path_flow
          let rev_idx = self.adj[u][edge_idx].rev_idx
          self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
          min_cost = min_cost + path_flow * self.adj[u][edge_idx].cost
          v = u
        }
      }
    }
    max_flow = max_flow + path_flow
  }
  (max_flow, min_cost)
}

///|
test "min cost max flow" {
  let network = MCMFNetwork::new(4)
  network.add_edge_mcmf(0, 1, 10, 1)
  network.add_edge_mcmf(0, 2, 10, 2)
  network.add_edge_mcmf(1, 3, 10, 1)
  network.add_edge_mcmf(2, 3, 10, 2)
  let (flow, cost) = network.min_cost_max_flow(0, 3)
  assert_eq(flow, 20)
  assert_eq(cost, 60)
}

///|
/// Bipartite Matching using Maximum Flow
fn bipartite_matching(
  left_size : Int,
  right_size : Int,
  edges : Array[(Int, Int)],
) -> Int {
  let n = left_size + right_size + 2
  let source = 0
  let sink = n - 1
  let network = FlowNetwork::new(n)
  for i = 0; i < left_size; i = i + 1 {
    network.add_edge(source, i + 1, 1)
  }
  for i = 0; i < right_size; i = i + 1 {
    network.add_edge(left_size + 1 + i, sink, 1)
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (left, right) = edges[i]
    network.add_edge(left + 1, left_size + 1 + right, 1)
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|Building flow network for bipartite matching.
      #|Max flow = maximum matching size.
    ),
  }
  network.edmonds_karp(source, sink)
}

///|
test "bipartite matching" {
  let edges = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
  let matching = bipartite_matching(3, 3, edges)
  assert_eq(matching, 3)
}

///|
/// Hungarian Algorithm for Assignment Problem
///
/// Find minimum cost assignment in bipartite graph.
/// TIME: O(n³)
fn hungarian_algorithm(cost : Array[Array[Int]]) -> Int {
  let n = cost.length()
  if n == 0 {
    return 0
  }
  let m = cost[0].length()
  let inf = 2147483647

  // Potentials for rows and columns
  let u : Array[Int] = Array::make(n + 1, 0)
  let v : Array[Int] = Array::make(m + 1, 0)
  let p : Array[Int] = Array::make(m + 1, 0) // p[j] = row assigned to column j
  let way : Array[Int] = Array::make(m + 1, 0)
  for i = 1; i <= n; i = i + 1 {
    p[0] = i
    let mut j0 = 0
    let minv : Array[Int] = Array::make(m + 1, inf)
    let used : Array[Bool] = Array::make(m + 1, false)

    // Find augmenting path
    let mut done = false
    while not(done) {
      used[j0] = true
      let i0 = p[j0]
      let mut delta = inf
      let mut j1 = 0
      for j = 1; j <= m; j = j + 1 {
        if not(used[j]) {
          let cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
          if cur < minv[j] {
            minv[j] = cur
            way[j] = j0
          }
          if minv[j] < delta {
            delta = minv[j]
            j1 = j
          }
        }
      }

      // Update potentials
      for j = 0; j <= m; j = j + 1 {
        if used[j] {
          u[p[j]] = u[p[j]] + delta
          v[j] = v[j] - delta
        } else {
          minv[j] = minv[j] - delta
        }
      }
      j0 = j1
      done = p[j0] == 0
    }

    // Augment along path
    while j0 != 0 {
      let j1 = way[j0]
      p[j0] = p[j1]
      j0 = j1
    }
  } where {
    invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|HUNGARIAN ALGORITHM:
      #|Maintains optimal potentials u, v such that:
      #|u[i] + v[j] <= cost[i][j] for all i, j
      #|u[i] + v[j] = cost[i][j] for assigned pairs
      #|
      #|Each iteration adds one row to assignment.
    ),
  }

  // Compute total cost
  let mut total_cost = 0
  for j = 1; j <= m; j = j + 1 {
    if p[j] > 0 && p[j] <= n {
      total_cost = total_cost + cost[p[j] - 1][j - 1]
    }
  }
  total_cost
}

///|
test "hungarian algorithm" {
  // Assignment cost matrix
  let cost : Array[Array[Int]] = [
    [4, 1, 3], // Worker 0 costs for jobs 0, 1, 2
    [2, 0, 5], // Worker 1
    [3, 2, 2],
  ] // Worker 2
  let min_cost = hungarian_algorithm(cost)
  // Optimal: Worker 0 -> Job 2 (3), Worker 1 -> Job 0 (2), Worker 2 -> Job 1 (2)
  // or: Worker 0 -> Job 1 (1), Worker 1 -> Job 0 (2), Worker 2 -> Job 2 (2)
  // Total = 5
  assert_eq(min_cost, 5)
}

///|
test "hungarian simple" {
  let cost : Array[Array[Int]] = [[1, 2], [3, 4]]
  let min_cost = hungarian_algorithm(cost)
  // Optimal: 0->0 (1), 1->1 (4) = 5
  // or: 0->1 (2), 1->0 (3) = 5
  assert_eq(min_cost, 5)
}
