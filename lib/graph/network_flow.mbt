// Network Flow Algorithms
// with rigorous loop invariants and mathematical reasoning

///|
/// Edge in a flow network
priv struct FlowEdge {
  to : Int
  capacity : Int
  mut flow : Int
  rev_idx : Int // Index of reverse edge in adj[to]
}

///|
/// Flow Network using adjacency list
priv struct FlowNetwork {
  adj : Array[Array[FlowEdge]]
  n : Int
}

///|
fn FlowNetwork::new(n : Int) -> FlowNetwork {
  let adj : Array[Array[FlowEdge]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init network):
      #|adj[0..i) are allocated as empty adjacency lists.
      #|MAINTENANCE:
      #|Push a fresh empty list for vertex i.
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
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
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT 1 (Edge scan):
        #|After processing edges adj[u][0..i), every neighbor reachable via a
        #|positive-residual edge from u has been marked visited and enqueued
        #|(if it was previously undiscovered), with parent set to (u, edge_idx).
        #|
        #|This preserves the BFS tree: parent[v] records the first edge that
        #|discovers v, giving a shortest (fewest-edge) path from source.
      ),
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|INVARIANT 1 (Queue processing):
      #|All nodes in queue[0..front) have had their outgoing residual edges
      #|scanned; queue[front..] are discovered but not yet expanded.
      #|
      #|INVARIANT 2 (Reachability):
      #|visited[v] = true iff v is reachable from source in the residual graph
      #|via the edges scanned so far; parent[v] stores a valid predecessor edge
      #|for all visited v != source.
      #|
      #|TERMINATION:
      #|We stop once sink is visited (shortest augmenting path found), or once
      #|the queue is exhausted (no augmenting path exists).
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
priv struct DinicNetwork {
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
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init dinic):
      #|adj[0..i) are allocated as empty adjacency lists.
      #|MAINTENANCE:
      #|Push a fresh empty list for vertex i.
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
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
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (reset levels):
      #|level[0..i) are cleared to -1 from the previous BFS.
      #|MAINTENANCE:
      #|Set level[i] = -1 to reset the next node.
      #|TERMINATION:
      #|At i = n, all levels are reset.
    ),
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
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT (Edge scan):
        #|After processing edges adj[u][0..i), all neighbors reachable from u
        #|by a positive-residual edge have been assigned a level and enqueued.
        #|Each such neighbor gets level = level[u] + 1, preserving BFS layers.
      ),
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|INVARIANT (Level graph):
      #|All nodes in queue[0..front) have been expanded; for any visited node v,
      #|level[v] equals the shortest edge-distance from source in the residual
      #|graph. Unvisited nodes keep level = -1.
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
    } where {
      invariant: i >= 0 && i <= self.n,
      reasoning: (
        #|INVARIANT (reset iter):
        #|iter[0..i) are reset to 0 for the next blocking-flow phase.
        #|MAINTENANCE:
        #|Set iter[i] = 0 to restart edge scans from the beginning.
        #|TERMINATION:
        #|At i = n, all iterators are reset.
      ),
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
priv struct MCMFEdge {
  to : Int
  capacity : Int
  cost : Int
  mut flow : Int
  rev_idx : Int
}

///|
priv struct MCMFNetwork {
  adj : Array[Array[MCMFEdge]]
  n : Int
}

///|
fn MCMFNetwork::new(n : Int) -> MCMFNetwork {
  let adj : Array[Array[MCMFEdge]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init mcmf):
      #|adj[0..i) are allocated as empty adjacency lists.
      #|MAINTENANCE:
      #|Push a fresh empty list for vertex i.
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
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
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (init SPFA):
      #|dist/parent for indices [0..i) are reset to inf/None.
      #|MAINTENANCE:
      #|Set dist[i] = inf and parent[i] = None for the next vertex.
      #|TERMINATION:
      #|At i = n, all vertices are reset for the new shortest-path search.
    ),
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
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT (Relaxation):
        #|After processing edges adj[u][0..i), any neighbor reachable from u
        #|via a positive-residual edge has been relaxed. If a shorter path
        #|is found, dist and parent are updated and the neighbor is queued.
      ),
    }
  } where {
    invariant: front >= 0,
    reasoning: (
      #|INVARIANT (SPFA queue):
      #|Vertices in queue are candidates whose outgoing edges may further
      #|improve dist. dist[v] always represents the best known cost of a
      #|residual path from source to v; parent encodes that path.
      #|
      #|SPFA handles negative-cost reverse edges introduced by flow updates,
      #|while ensuring dist decreases only when a strictly cheaper path is found.
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
  } where {
    invariant: i >= 0 && i <= left_size,
    reasoning: (
      #|INVARIANT (source edges):
      #|Edges from source to left vertices [0..i) are added.
      #|MAINTENANCE:
      #|Add edge from source to left vertex i with capacity 1.
      #|TERMINATION:
      #|At i = left_size, all left vertices are connected to the source.
    ),
  }
  for i = 0; i < right_size; i = i + 1 {
    network.add_edge(left_size + 1 + i, sink, 1)
  } where {
    invariant: i >= 0 && i <= right_size,
    reasoning: (
      #|INVARIANT (sink edges):
      #|Edges from right vertices [0..i) to sink are added.
      #|MAINTENANCE:
      #|Add edge from right vertex i to sink with capacity 1.
      #|TERMINATION:
      #|At i = right_size, all right vertices are connected to the sink.
    ),
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (left, right) = edges[i]
    network.add_edge(left + 1, left_size + 1 + right, 1)
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (matching edges):
      #|Edges[0..i) have been added between corresponding left/right vertices.
      #|MAINTENANCE:
      #|Add edge for edges[i] to encode a potential match.
      #|TERMINATION:
      #|At i = edges.length(), the flow network encodes the full bipartite graph.
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
      } where {
        invariant: j >= 1 && j <= m + 1,
        reasoning: (
          #|INVARIANT (Reduced costs):
          #|For each un-used column k in [1..j), minv[k] stores the minimum
          #|reduced cost of an alternating path from the current tree to k,
          #|and way[k] records the predecessor column on that path.
          #|
          #|delta/j1 track the smallest minv among un-used columns scanned so
          #|far, selecting the next column to enter the tree.
        ),
      }

      // Update potentials
      for j = 0; j <= m; j = j + 1 {
        if used[j] {
          u[p[j]] = u[p[j]] + delta
          v[j] = v[j] - delta
        } else {
          minv[j] = minv[j] - delta
        }
      } where {
        invariant: j >= 0 && j <= m + 1,
        reasoning: (
          #|INVARIANT (Feasible potentials):
          #|Updating u/v by delta preserves feasibility:
          #|u[i] + v[j] <= cost[i][j] for all assigned rows/columns, while
          #|minv for un-used columns decreases uniformly so the best candidate
          #|reaches zero reduced cost.
        ),
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
      #|HUNGARIAN ALGORITHM INVARIANT:
      #|After iteration i-1, p encodes a minimum-cost matching for rows
      #|1..i-1. Potentials u, v are feasible (u[i] + v[j] <= cost[i][j]) and
      #|tight on matched pairs (equality holds on assigned edges).
      #|
      #|The inner phase builds an alternating tree and augments along a
      #|zero reduced-cost path, extending the matching by one row.
    ),
  }

  // Compute total cost
  let mut total_cost = 0
  for j = 1; j <= m; j = j + 1 {
    if p[j] > 0 && p[j] <= n {
      total_cost = total_cost + cost[p[j] - 1][j - 1]
    }
  } where {
    invariant: j >= 1 && j <= m + 1,
    reasoning: (
      #|INVARIANT (cost sum):
      #|total_cost equals the sum of costs for assigned columns in [1..j).
      #|MAINTENANCE:
      #|If column j is assigned, add its cost; otherwise skip.
      #|TERMINATION:
      #|At j = m + 1, total_cost is the full assignment cost.
    ),
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
