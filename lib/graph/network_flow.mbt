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
  // Use makei to create adjacency list with independent empty arrays
  let adj : Array[Array[FlowEdge]] = Array::makei(n, _ => [])
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
  let _ = for front = 0 {
    match queue.get(front) {
      None => break ()
      Some(u) => {
        if visited[sink] {
          break ()
        }
        for i, edge in self.adj[u] {
          let residual = edge.capacity - edge.flow
          if residual > 0 && !visited[edge.to] {
            visited[edge.to] = true
            parent[edge.to] = Some((u, i))
            queue.push(edge.to)
          }
        }
        continue front + 1
      }
    }
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
  for max_flow = 0 {
    let (has_path, parent) = self.bfs_find_path(source, sink)
    if !has_path {
      break max_flow
    }
    // Find minimum residual capacity along path
    let path_flow = for v = sink, path_flow = 2147483647; v != source; {
      match parent[v] {
        None => break path_flow
        Some((u, edge_idx)) => {
          let residual = self.adj[u][edge_idx].capacity -
            self.adj[u][edge_idx].flow
          continue u, if residual < path_flow { residual } else { path_flow }
        }
      }
    } nobreak {
      path_flow
    } where {
      proof_invariant: v >= 0 && v < self.n,
      reasoning: (
        #|INVARIANT (Bottleneck scan):
        #|Traversing the parent chain from sink toward source, path_flow equals
        #|the minimum residual capacity over the edges on the already scanned
        #|suffix of the path.
        #|MAINTENANCE:
        #|Each step considers one parent edge (u, v) and updates path_flow with
        #|min(path_flow, residual), preserving the minimum over the suffix.
        #|TERMINATION:
        #|When v == source (or parent is None), the bottleneck of the path
        #|from source to sink is determined.
      ),
    }

    // Augment flow along path
    for v = sink; v != source; {
      match parent[v] {
        None => break
        Some((u, edge_idx)) => {
          self.adj[u][edge_idx].flow = self.adj[u][edge_idx].flow + path_flow
          let rev_idx = self.adj[u][edge_idx].rev_idx
          self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
          continue u
        }
      }
    } where {
      proof_invariant: v >= 0 && v < self.n,
      reasoning: (
        #|INVARIANT (Augmentation):
        #|For edges on the already processed suffix of the parent path, the
        #|forward flow has been increased and the reverse flow decreased by
        #|path_flow, preserving flow conservation and residual capacities.
        #|MAINTENANCE:
        #|Updating one edge and its reverse keeps antisymmetric residual
        #|flows; continuing moves one step closer to source.
        #|TERMINATION:
        #|When v == source, the entire augmenting path has been updated.
      ),
    }
    continue max_flow + path_flow
  } where {
    proof_invariant: max_flow >= 0,
    reasoning: (
      #|INVARIANT (Edmonds-Karp progress):
      #|max_flow equals the value of the current feasible flow, and each
      #|iteration augments along a shortest residual path (fewest edges).
      #|MAINTENANCE:
      #|BFS yields a shortest augmenting path; augmenting by path_flow
      #|preserves feasibility and strictly increases max_flow.
      #|TERMINATION:
      #|When BFS finds no augmenting path, the residual graph has no s→t path,
      #|so by max-flow/min-cut, the current flow is maximum.
    ),
  }
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
  // Use makei to create adjacency list with independent empty arrays
  let adj : Array[Array[FlowEdge]] = Array::makei(n, _ => [])
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
  self.level.fill(-1)
  self.level[source] = 0
  let queue : Array[Int] = []
  queue.push(source)
  let _ = for front = 0 {
    match queue.get(front) {
      None => break ()
      Some(u) => {
        for edge in self.adj[u] {
          let residual = edge.capacity - edge.flow
          if residual > 0 && self.level[edge.to] < 0 {
            self.level[edge.to] = self.level[u] + 1
            queue.push(edge.to)
          }
        }
        continue front + 1
      }
    }
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
  for idx = self.iter[u]; idx < self.adj[u].length(); {
    let edge = self.adj[u][idx]
    let residual = edge.capacity - edge.flow
    if residual > 0 && self.level[edge.to] == self.level[u] + 1 {
      let min_flow = if flow_in < residual { flow_in } else { residual }
      let pushed = self.dfs_dinic(edge.to, sink, min_flow)
      if pushed > 0 {
        self.adj[u][idx].flow = self.adj[u][idx].flow + pushed
        let rev_idx = edge.rev_idx
        self.adj[edge.to][rev_idx].flow = self.adj[edge.to][rev_idx].flow -
          pushed
        self.iter[u] = idx
        break pushed
      }
    }
    self.iter[u] = idx + 1
    continue idx + 1
  } nobreak {
    0
  } where {
    proof_invariant: idx >= 0 && idx <= self.adj[u].length(),
    proof_invariant: self.iter[u] == idx,
    reasoning: (
      #|INVARIANT (DFS edge scan):
      #|Edges adj[u][0..idx) have been fully explored for blocking flow, and
      #|self.iter[u] tracks the first untried edge index.
      #|MAINTENANCE:
      #|If an edge cannot push flow, we advance idx and iter[u] together. If
      #|we push flow, we stop and keep iter[u] at idx to allow further pushes.
      #|TERMINATION:
      #|idx increases toward adj[u].length(); the loop ends when all edges are
      #|exhausted (return 0) or a positive flow is pushed.
    ),
  }
}

///|
fn DinicNetwork::dinic_max_flow(
  self : DinicNetwork,
  source : Int,
  sink : Int,
) -> Int {
  for max_flow = 0 {
    if !self.bfs_dinic(source, sink) {
      break max_flow
    }
    for i in 0..<self.n {
      self.iter[i] = 0
    }
    let phase_flow = for pushed = self.dfs_dinic(source, sink, 2147483647), phase_flow = 0; pushed >
                        0; {
      continue self.dfs_dinic(source, sink, 2147483647), phase_flow + pushed
    } nobreak {
      phase_flow
    } where {
      proof_invariant: pushed >= 0,
      reasoning: (
        #|INVARIANT (Blocking flow augmentation):
        #|Each successful dfs_dinic call augments along the current level
        #|graph, so phase_flow accumulates the flow sent in this phase.
        #|MAINTENANCE:
        #|Adding pushed preserves flow feasibility and increases phase_flow.
        #|TERMINATION:
        #|When pushed == 0, the current level graph is blocked.
      ),
    }
    continue max_flow + phase_flow
  } where {
    proof_invariant: max_flow >= 0,
    reasoning: (
      #|INVARIANT (Dinic phases):
      #|Each iteration builds a level graph and sends a blocking flow, so
      #|max_flow is the value of a feasible flow in the network.
      #|MAINTENANCE:
      #|Blocking flow augmentation preserves feasibility and strictly increases
      #|max_flow whenever the sink is reachable.
      #|TERMINATION:
      #|When BFS cannot reach sink, no augmenting path exists; the flow is max.
    ),
  }
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
  // Use makei to create adjacency list with independent empty arrays
  let adj : Array[Array[MCMFEdge]] = Array::makei(n, _ => [])
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
  dist.fill(inf)
  parent.fill(None)
  dist[source] = 0
  let in_queue : Array[Bool] = Array::make(self.n, false)
  let queue : Array[Int] = []
  queue.push(source)
  in_queue[source] = true
  let _ = for front = 0 {
    match queue.get(front) {
      None => break ()
      Some(u) => {
        in_queue[u] = false
        for i, edge in self.adj[u] {
          let residual = edge.capacity - edge.flow
          if residual > 0 && dist[u] + edge.cost < dist[edge.to] {
            dist[edge.to] = dist[u] + edge.cost
            parent[edge.to] = Some((u, i))
            if !in_queue[edge.to] {
              queue.push(edge.to)
              in_queue[edge.to] = true
            }
          }
        }
        continue front + 1
      }
    }
  }
  dist[sink] < inf
}

///|
fn MCMFNetwork::min_cost_max_flow(
  self : MCMFNetwork,
  source : Int,
  sink : Int,
) -> (Int, Int) {
  let dist : Array[Int] = Array::make(self.n, 0)
  let parent : Array[(Int, Int)?] = Array::make(self.n, None)
  for max_flow = 0, min_cost = 0 {
    if !self.spfa_mcmf(source, sink, dist, parent) {
      break (max_flow, min_cost)
    }
    // Find minimum residual capacity
    let path_flow = for v = sink, path_flow = 2147483647; v != source; {
      match parent[v] {
        None => break path_flow
        Some((u, edge_idx)) => {
          let residual = self.adj[u][edge_idx].capacity -
            self.adj[u][edge_idx].flow
          continue u, if residual < path_flow { residual } else { path_flow }
        }
      }
    } nobreak {
      path_flow
    } where {
      proof_invariant: v >= 0 && v < self.n,
      reasoning: (
        #|INVARIANT (Bottleneck scan):
        #|path_flow is the minimum residual capacity over the scanned suffix
        #|of the parent path from sink toward source.
        #|MAINTENANCE:
        #|Each parent edge updates path_flow with a min against its residual.
        #|TERMINATION:
        #|When v == source, the full-path bottleneck is known.
      ),
    }

    // Augment flow
    for v = sink; v != source; {
      match parent[v] {
        None => break
        Some((u, edge_idx)) => {
          self.adj[u][edge_idx].flow = self.adj[u][edge_idx].flow + path_flow
          let rev_idx = self.adj[u][edge_idx].rev_idx
          self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
          continue u
        }
      }
    } where {
      proof_invariant: v >= 0 && v < self.n,
      reasoning: (
        #|INVARIANT (Augmentation):
        #|For the processed suffix of the path, flow has been augmented by
        #|path_flow while preserving residual consistency.
        #|MAINTENANCE:
        #|Updating one edge and its reverse preserves feasibility.
        #|TERMINATION:
        #|When v == source, the entire augmenting path is updated.
      ),
    }
    continue max_flow + path_flow, min_cost + path_flow * dist[sink]
  } where {
    proof_invariant: max_flow >= 0,
    reasoning: (
      #|INVARIANT (MCMF progress):
      #|max_flow/min_cost describe a feasible flow and its total cost.
      #|Each SPFA iteration finds the cheapest residual path and augments it.
      #|MAINTENANCE:
      #|Augmenting by path_flow preserves feasibility and increases max_flow
      #|while updating min_cost by the path cost.
      #|TERMINATION:
      #|When no residual path exists, the current flow is max with min cost.
    ),
  }
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
  for i in 0..<left_size {
    network.add_edge(source, i + 1, 1)
  }
  for i in 0..<right_size {
    network.add_edge(left_size + 1 + i, sink, 1)
  }
  for edge in edges {
    let (left, right) = edge
    network.add_edge(left + 1, left_size + 1 + right, 1)
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
  for i in 1..<=n {
    p[0] = i
    let minv : Array[Int] = Array::make(m + 1, inf)
    let used : Array[Bool] = Array::make(m + 1, false)

    // Find augmenting path
    let j0 = for j0 = 0 {
      used[j0] = true
      let i0 = p[j0]
      let (delta, j1) = for j in 1..<=m; delta = inf, j1 = 0 {
        if !used[j] {
          let cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
          if cur < minv[j] {
            minv[j] = cur
            way[j] = j0
          }
          if minv[j] < delta {
            continue minv[j], j
          }
        }
        continue delta, j1
      } nobreak {
        (delta, j1)
      } where {
        proof_invariant: j >= 1 && j <= m + 1,
        reasoning: (
          #|INVARIANT (Reduced costs):
          #|For each un-used column k in [1..j), minv[k] stores the minimum
          #|reduced cost of an alternating path from the current tree to k,
          #|and way[k] records the predecessor column on that path.
          #|
          #|delta/j1 track the smallest minv among un-used columns scanned so
          #|far, selecting the next column to enter the tree.
          #|MAINTENANCE:
          #|Updating minv/way for column j preserves the minimum reduced costs
          #|for the scanned prefix and keeps delta/j1 as the best candidate.
          #|TERMINATION:
          #|At j == m + 1, delta/j1 identify the globally best un-used column.
        ),
      }

      // Update potentials
      for j in 0..<=m {
        if used[j] {
          u[p[j]] = u[p[j]] + delta
          v[j] = v[j] - delta
        } else {
          minv[j] = minv[j] - delta
        }
      } where {
        proof_invariant: j >= 0 && j <= m + 1,
        reasoning: (
          #|INVARIANT (Feasible potentials):
          #|Updating u/v by delta preserves feasibility:
          #|u[i] + v[j] <= cost[i][j] for all assigned rows/columns, while
          #|minv for un-used columns decreases uniformly so the best candidate
          #|reaches zero reduced cost.
          #|MAINTENANCE:
          #|Adjusting u/v for used columns and minv for others keeps all
          #|reduced costs non-negative and maintains feasibility.
          #|TERMINATION:
          #|After the update, at least one new column has zero reduced cost.
        ),
      }
      if p[j1] == 0 {
        break j1
      } else {
        continue j1
      }
    } where {
      proof_invariant: j0 >= 0 && j0 <= m,
      reasoning: (
        #|INVARIANT (Alternating tree):
        #|used marks the columns currently in the alternating tree rooted at
        #|column 0; for any un-used column k, minv[k] is the minimum reduced
        #|cost edge from the tree to k, and way[k] stores its predecessor.
        #|MAINTENANCE:
        #|We add j0 to the tree, recompute the minimum reduced costs, update
        #|potentials by delta to preserve feasibility, and move to j1, the
        #|best next column candidate.
        #|TERMINATION:
        #|When p[j0] == 0, we have reached a free column and can augment.
      ),
    }

    // Augment along path
    for j = j0; j != 0; {
      let j1 = way[j]
      p[j] = p[j1]
      continue j1
    } where {
      proof_invariant: j >= 0 && j <= m,
      reasoning: (
        #|INVARIANT (Augment path):
        #|Along the suffix from the current column j to 0, p has been updated
        #|to shift the matching along the alternating path.
        #|MAINTENANCE:
        #|Assigning p[j] = p[j1] flips one edge of the alternating path and
        #|moves one step closer to column 0.
        #|TERMINATION:
        #|When j == 0, the augmentation is complete and matching size grows.
      ),
    }
  } where {
    proof_invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|HUNGARIAN ALGORITHM INVARIANT:
      #|After iteration i-1, p encodes a minimum-cost matching for rows
      #|1..i-1. Potentials u, v are feasible (u[i] + v[j] <= cost[i][j]) and
      #|tight on matched pairs (equality holds on assigned edges).
      #|
      #|The inner phase builds an alternating tree and augments along a
      #|zero reduced-cost path, extending the matching by one row.
      #|MAINTENANCE:
      #|Each iteration augments by one row using a zero reduced-cost path,
      #|preserving feasibility and optimality of the partial matching.
      #|TERMINATION:
      #|After i == n, all rows are matched and the assignment is optimal.
    ),
  }

  // Compute total cost
  let total_cost = for j in 1..<=m; total_cost = 0 {
    if p[j] > 0 && p[j] <= n {
      continue total_cost + cost[p[j] - 1][j - 1]
    }
    continue total_cost
  } nobreak {
    total_cost
  } where {
    proof_invariant: j >= 1 && j <= m + 1,
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
