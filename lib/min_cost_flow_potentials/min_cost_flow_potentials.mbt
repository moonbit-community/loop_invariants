// ============================================================================
// MIN-COST MAX-FLOW (SUCCESSIVE SHORTEST PATH WITH POTENTIALS)
// ============================================================================
//
// This algorithm repeatedly finds the cheapest augmenting path in the residual
// graph using Dijkstra with Johnson potentials. Potentials reweight edges so
// reduced costs stay non-negative, enabling Dijkstra even if the original
// graph has negative costs (assuming no negative cycles).
//
// TIME COMPLEXITY: O(F * (E log V))
// SPACE COMPLEXITY: O(V + E)

///|
const MCF_INF : Int64 = 4611686018427387903L

///|
pub struct Edge {
  to : Int
  cap : Int64
  cost : Int64
  mut flow : Int64
  rev : Int
}

///|
pub struct MinCostFlowPotentials {
  n : Int
  adj : Array[Array[Edge]]
  dist : Array[Int64]
  prev_v : Array[Int]
  prev_e : Array[Int]
}

// ============================================================================
// MIN-HEAP FOR DIJKSTRA
// ============================================================================

///|
priv struct HeapEntry {
  dist : Int64
  vertex : Int
}

///|
priv struct MinHeap {
  data : Array[HeapEntry]
}

///|
fn MinHeap::new() -> MinHeap {
  { data: [] }
}

///|
fn MinHeap::is_empty(self : MinHeap) -> Bool {
  self.data.length() == 0
}

///|
fn MinHeap::push(self : MinHeap, entry : HeapEntry) -> Unit {
  self.data.push(entry)
  let mut i = self.data.length() - 1
  while i > 0 {
    let parent = (i - 1) / 2
    if self.data[i].dist < self.data[parent].dist {
      let temp = self.data[i]
      self.data[i] = self.data[parent]
      self.data[parent] = temp
      i = parent
    } else {
      break
    }
  }
}

///|
fn MinHeap::pop(self : MinHeap) -> HeapEntry? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let result = self.data[0]
  let last = self.data[n - 1]
  let _ = self.data.pop()
  if self.data.length() > 0 {
    self.data[0] = last
    let mut i = 0
    let len = self.data.length()
    for {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let mut smallest = i
      if left < len && self.data[left].dist < self.data[smallest].dist {
        smallest = left
      }
      if right < len && self.data[right].dist < self.data[smallest].dist {
        smallest = right
      }
      if smallest == i {
        break
      }
      let temp = self.data[i]
      self.data[i] = self.data[smallest]
      self.data[smallest] = temp
      i = smallest
    } where {
      invariant: i >= 0 && i < len,
      reasoning: (
        #|INVARIANT (heapify down):
        #|All nodes except the path from root to i satisfy the heap order.
        #|MAINTENANCE:
        #|Swap with the smallest child to restore the heap property on the path.
        #|TERMINATION:
        #|When smallest == i, the heap property holds globally.
      ),
    }
  }
  Some(result)
}

// ============================================================================
// MIN-COST FLOW STRUCTURE
// ============================================================================

///|
/// Create a min-cost flow network with n vertices.
pub fn MinCostFlowPotentials::new(n : Int) -> MinCostFlowPotentials {
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
  }
}

///|
/// Add directed edge u -> v with capacity and cost.
pub fn MinCostFlowPotentials::add_edge(
  self : MinCostFlowPotentials,
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
fn MinCostFlowPotentials::dijkstra(
  self : MinCostFlowPotentials,
  source : Int,
  sink : Int,
  potential : Array[Int64],
) -> Bool {
  for i = 0; i < self.n; i = i + 1 {
    self.dist[i] = MCF_INF
    self.prev_v[i] = -1
    self.prev_e[i] = -1
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (reset arrays):
      #|dist/prev are reset for vertices in [0, i).
      #|MAINTENANCE:
      #|Clear state for vertex i.
      #|TERMINATION:
      #|At i = n, all vertices are reset for a fresh Dijkstra run.
    ),
  }
  let heap = MinHeap::new()
  self.dist[source] = 0L
  heap.push({ dist: 0L, vertex: source })
  while not(heap.is_empty()) {
    let entry = heap.pop().unwrap()
    let u = entry.vertex
    if entry.dist != self.dist[u] {
      continue
    }
    if u == sink {
      break
    }
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]
      if e.cap > e.flow {
        let reduced = e.cost + potential[u] - potential[e.to]
        let nd = self.dist[u] + reduced
        if nd < self.dist[e.to] {
          self.dist[e.to] = nd
          self.prev_v[e.to] = u
          self.prev_e[e.to] = i
          heap.push({ dist: nd, vertex: e.to })
        }
      }
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT (relax edges):
        #|All edges adj[u][0..i) have been considered for relaxation.
        #|MAINTENANCE:
        #|Relax edge i if residual capacity exists and reduced cost improves
        #|the tentative distance.
        #|TERMINATION:
        #|At i = deg(u), all outgoing residual edges are processed.
      ),
    }
  }
  self.dist[sink] < MCF_INF
}

///|
/// Compute min-cost max-flow from source to sink.
pub fn MinCostFlowPotentials::compute(
  self : MinCostFlowPotentials,
  source : Int,
  sink : Int,
) -> (Int64, Int64) {
  self.compute_with_limit(source, sink, MCF_INF)
}

///|
/// Compute min-cost flow with a flow limit.
pub fn MinCostFlowPotentials::compute_with_limit(
  self : MinCostFlowPotentials,
  source : Int,
  sink : Int,
  flow_limit : Int64,
) -> (Int64, Int64) {
  let potential = Array::make(self.n, 0L)
  let mut total_flow = 0L
  let mut total_cost = 0L
  for iter = 0; total_flow < flow_limit; iter = iter + 1 {
    if not(self.dijkstra(source, sink, potential)) {
      break
    }

    // Shortest path cost in original weights (before updating potentials).
    let path_cost = self.dist[sink] + potential[sink] - potential[source]
    for i = 0; i < self.n; i = i + 1 {
      if self.dist[i] < MCF_INF {
        potential[i] = potential[i] + self.dist[i]
      }
    } where {
      invariant: i >= 0 && i <= self.n,
      reasoning: (
        #|INVARIANT (potential update):
        #|potentials for vertices in [0, i) have been updated with their
        #|shortest reduced distances, preserving non-negative reduced costs.
        #|MAINTENANCE:
        #|Add dist[i] to potential[i] when reachable.
        #|TERMINATION:
        #|At i = n, all reachable vertices have updated potentials.
      ),
    }
    let mut add_flow = flow_limit - total_flow
    let mut v = sink
    for steps = 0; v != source; steps = steps + 1 {
      let u = self.prev_v[v]
      let idx = self.prev_e[v]
      let residual = self.adj[u][idx].cap - self.adj[u][idx].flow
      if residual < add_flow {
        add_flow = residual
      }
      v = u
    } where {
      invariant: steps >= 0 && add_flow > 0L,
      reasoning: (
        #|INVARIANT (bottleneck search):
        #|add_flow is the minimum residual capacity along the suffix of the
        #|shortest path processed so far.
        #|MAINTENANCE:
        #|Update add_flow with the residual of the next edge on the path.
        #|TERMINATION:
        #|When v reaches source, add_flow is the bottleneck capacity.
      ),
    }
    v = sink
    for steps = 0; v != source; steps = steps + 1 {
      let u = self.prev_v[v]
      let idx = self.prev_e[v]
      self.adj[u][idx].flow = self.adj[u][idx].flow + add_flow
      let rev = self.adj[u][idx].rev
      self.adj[v][rev].flow = self.adj[v][rev].flow - add_flow
      v = u
    } where {
      invariant: steps >= 0,
      reasoning: (
        #|INVARIANT (augment path):
        #|Flow has been augmented by add_flow on the processed suffix of the
        #|shortest path, maintaining skew symmetry via reverse edges.
        #|MAINTENANCE:
        #|Update the next edge on the path and move v toward source.
        #|TERMINATION:
        #|At v = source, the entire path is augmented.
      ),
    }
    total_flow = total_flow + add_flow
    total_cost = total_cost + add_flow * path_cost
  } where {
    invariant: iter >= 0 && total_flow >= 0L,
    reasoning: (
      #|INVARIANT (successive shortest paths):
      #|total_flow and total_cost describe a min-cost flow for the amount sent
      #|so far. Potentials ensure non-negative reduced costs, so each iteration
      #|augments along a cheapest residual path.
      #|MAINTENANCE:
      #|Run Dijkstra with reduced costs, augment by the bottleneck, and update
      #|potentials to preserve reduced-cost non-negativity.
      #|TERMINATION:
      #|Loop stops when flow_limit is reached or no augmenting path exists.
    ),
  }
  (total_flow, total_cost)
}
