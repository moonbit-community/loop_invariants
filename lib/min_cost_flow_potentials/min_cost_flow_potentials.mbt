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
/// Sentinel value used as infinity for distances and flow limits.
/// Chosen as `Int64::max_value / 2` to prevent overflow when adding two
/// distances together.
const MCF_INF : Int64 = 4611686018427387903L

///|
/// A single directed edge in the flow network, stored in an adjacency list.
///
/// Both the forward edge and its corresponding reverse (residual) edge are
/// represented as `Edge` values. The reverse edge is found via
/// `adj[to][rev]`.
///
/// The usable residual capacity of this edge is `cap - flow`.  For a reverse
/// edge that was added automatically by `add_edge`, `cap` starts at `0` and
/// `flow` starts at `0`; flow is decreased (made negative) as the forward
/// edge is augmented, so `cap - flow` correctly reflects the cancellation
/// capacity.
pub struct Edge {
  /// Destination vertex index.
  to : Int
  /// Maximum capacity of this edge.
  cap : Int64
  /// Cost per unit of flow on this edge.  Reverse edges carry `-cost`.
  cost : Int64
  /// Current flow sent along this edge.  Residual capacity = `cap - flow`.
  mut flow : Int64
  /// Index of the reverse edge in `adj[to]`.
  rev : Int
}

///|
/// Min-cost max-flow solver using successive shortest paths with Johnson's
/// potential technique.
///
/// **Usage pattern**
///
/// ```
/// let mcf = MinCostFlowPotentials::new(n)   // n vertices, 0-indexed
/// mcf.add_edge(u, v, cap, cost)             // add directed edges
/// let (flow, cost) = mcf.compute(src, sink) // solve
/// ```
///
/// **Algorithm overview**
///
/// Each iteration runs Dijkstra on *reduced costs* (original cost reweighted
/// by Johnson potentials) to find the cheapest augmenting path in the residual
/// graph.  After augmenting, potentials are updated so that all residual edges
/// continue to have non-negative reduced cost, keeping future Dijkstra runs
/// correct.
///
/// **Requirement**: all original edge costs must be non-negative.  If your
/// graph contains negative-cost edges, initialise potentials with a
/// Bellman-Ford pass first or use the SPFA-based `mcmf` package.
pub struct MinCostFlowPotentials {
  /// Number of vertices in the graph.
  n : Int
  /// Adjacency list.  `adj[u]` holds all edges (including reverse edges)
  /// that originate at vertex `u`.
  adj : Array[Array[Edge]]
  /// Shortest-path distances in reduced-cost space, reused each Dijkstra call.
  dist : Array[Int64]
  /// `prev_v[v]` is the predecessor vertex of `v` on the shortest path found
  /// by the most recent Dijkstra call.
  prev_v : Array[Int]
  /// `prev_e[v]` is the index into `adj[prev_v[v]]` of the edge leading to
  /// `v` on the shortest path found by the most recent Dijkstra call.
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
fn MinHeap::push(self : MinHeap, entry : HeapEntry) -> Unit {
  self.data.push(entry)
  let _ = for i = self.data.length() - 1; i > 0; {
    let parent = (i - 1) / 2
    if self.data[i].dist < self.data[parent].dist {
      let temp = self.data[i]
      self.data[i] = self.data[parent]
      self.data[parent] = temp
      continue parent
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
    let len = self.data.length()
    let _ = for i = 0 {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let smallest = if left < len && self.data[left].dist < self.data[i].dist {
        left
      } else {
        i
      }
      let smallest = if right < len &&
        self.data[right].dist < self.data[smallest].dist {
        right
      } else {
        smallest
      }
      if smallest == i {
        break
      }
      let temp = self.data[i]
      self.data[i] = self.data[smallest]
      self.data[smallest] = temp
      continue smallest
    } where {
      proof_invariant: i >= 0 && i < len,
      proof_reasoning: (
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
/// Create a min-cost flow network with `n` vertices numbered `0..n-1`.
///
/// All internal arrays are pre-allocated to size `n`.  Edges are added
/// separately with `add_edge`.
///
/// Parameters:
/// - `n`: number of vertices (must be >= 1).
pub fn MinCostFlowPotentials::new(
  n : Int,
) -> MinCostFlowPotentials {
  let adj : Array[Array[Edge]] = [ for _ in 0..<n => [] ]
  {
    n,
    adj,
    dist: Array::make(n, 0L),
    prev_v: Array::make(n, -1),
    prev_e: Array::make(n, -1),
  }
}

///|
/// Add a directed edge `u -> v` with the given capacity and cost per unit of
/// flow.
///
/// A reverse (residual) edge `v -> u` with capacity `0` and cost `-cost` is
/// automatically added so the algorithm can cancel flow later.
///
/// Parameters:
/// - `u`: source vertex of the edge (0-indexed).
/// - `v`: destination vertex of the edge (0-indexed).
/// - `cap`: maximum flow that can pass through this edge.
/// - `cost`: cost per unit of flow; must be non-negative for the Dijkstra
///   variant to be correct without a Bellman-Ford initialisation step.
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
  for i in 0..<self.n {
    self.dist[i] = MCF_INF
    self.prev_v[i] = -1
    self.prev_e[i] = -1
  }
  let heap = MinHeap::new()
  self.dist[source] = 0L
  heap.push({ dist: 0L, vertex: source })
  let _ = for popped = heap.pop() {
    match popped {
      None => break ()
      Some(entry) => {
        let u = entry.vertex
        if entry.dist != self.dist[u] {
          continue heap.pop()
        }
        if u == sink {
          break ()
        }
        for i in 0..<self.adj[u].length() {
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
        }
        continue heap.pop()
      }
    }
  }
  self.dist[sink] < MCF_INF
}

///|
/// Compute the minimum-cost maximum flow from `source` to `sink`.
///
/// Equivalent to `compute_with_limit(source, sink, Int64::max_value / 2)`.
///
/// Returns a tuple `(flow, cost)` where:
/// - `flow` is the total units of flow delivered from `source` to `sink`.
/// - `cost` is the minimum total cost of that flow.
///
/// Parameters:
/// - `source`: index of the source vertex.
/// - `sink`: index of the sink vertex.
pub fn MinCostFlowPotentials::compute(
  self : MinCostFlowPotentials,
  source : Int,
  sink : Int,
) -> (Int64, Int64) {
  self.compute_with_limit(source, sink, MCF_INF)
}

///|
/// Compute the minimum-cost flow from `source` to `sink`, sending at most
/// `flow_limit` units in total.
///
/// The algorithm runs successive shortest-path iterations.  Each iteration:
/// 1. Runs Dijkstra on reduced costs (edge costs reweighted by Johnson
///    potentials) to find the cheapest augmenting path.
/// 2. Augments flow along that path by the bottleneck residual capacity,
///    capped at the remaining flow budget.
/// 3. Updates potentials so that all residual edges keep non-negative
///    reduced cost for the next iteration.
///
/// The loop terminates when either `flow_limit` is reached or no augmenting
/// path exists in the residual graph.
///
/// Returns a tuple `(flow, cost)` where:
/// - `flow` is the total units of flow delivered (at most `flow_limit`).
/// - `cost` is the minimum total cost of that flow.
///
/// Parameters:
/// - `source`: index of the source vertex.
/// - `sink`: index of the sink vertex.
/// - `flow_limit`: upper bound on the total flow to send.
pub fn MinCostFlowPotentials::compute_with_limit(
  self : MinCostFlowPotentials,
  source : Int,
  sink : Int,
  flow_limit : Int64,
) -> (Int64, Int64) {
  let potential = Array::make(self.n, 0L)
  let (total_flow, total_cost) = for iter = 0, total_flow = 0L, total_cost = 0L; total_flow <
                                    flow_limit; {
    if !self.dijkstra(source, sink, potential) {
      break (total_flow, total_cost)
    }

    // Shortest path cost in original weights (before updating potentials).
    let path_cost = self.dist[sink] + potential[sink] - potential[source]
    for i in 0..<self.n {
      if self.dist[i] < MCF_INF {
        potential[i] = potential[i] + self.dist[i]
      }
    }
    let add_flow = for steps = 0, v = sink, add_flow = flow_limit - total_flow; v !=
                      source; {
      let u = self.prev_v[v]
      let idx = self.prev_e[v]
      let residual = self.adj[u][idx].cap - self.adj[u][idx].flow
      let add_flow = if residual < add_flow { residual } else { add_flow }
      continue steps + 1, u, add_flow
    } nobreak {
      add_flow
    } where {
      proof_invariant: steps >= 0 && add_flow > 0L,
      proof_reasoning: (
        #|INVARIANT (bottleneck search):
        #|add_flow is the minimum residual capacity along the suffix of the
        #|shortest path processed so far.
        #|MAINTENANCE:
        #|Update add_flow with the residual of the next edge on the path.
        #|TERMINATION:
        #|When v reaches source, add_flow is the bottleneck capacity.
      ),
    }
    let _ = for steps = 0, v = sink; v != source; {
      let u = self.prev_v[v]
      let idx = self.prev_e[v]
      self.adj[u][idx].flow = self.adj[u][idx].flow + add_flow
      let rev = self.adj[u][idx].rev
      self.adj[v][rev].flow = self.adj[v][rev].flow - add_flow
      continue steps + 1, u
    } where {
      proof_invariant: steps >= 0,
      proof_reasoning: (
        #|INVARIANT (augment path):
        #|Flow has been augmented by add_flow on the processed suffix of the
        #|shortest path, maintaining skew symmetry via reverse edges.
        #|MAINTENANCE:
        #|Update the next edge on the path and move v toward source.
        #|TERMINATION:
        #|At v = source, the entire path is augmented.
      ),
    }
    continue iter + 1, total_flow + add_flow, total_cost + add_flow * path_cost
  } nobreak {
    (total_flow, total_cost)
  } where {
    proof_invariant: iter >= 0 && total_flow >= 0L,
    proof_reasoning: (
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
