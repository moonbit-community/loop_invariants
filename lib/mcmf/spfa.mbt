// ============================================================================
// MIN-COST MAX-FLOW - SPFA (Shortest Path Faster Algorithm)
// ============================================================================
//
// SPFA finds shortest paths in graphs with negative edge weights.
// It's a queue-based Bellman-Ford variant that's efficient in practice.
//
// WHY SPFA FOR MCMF:
// ```
//   The residual graph has negative cost edges (for flow cancellation).
//   Standard Dijkstra doesn't work with negative edges.
//   SPFA handles negative edges correctly.
//
//   In MCMF context:
//   - dist[v] = minimum cost to push flow from source to v
//   - prev_v[v], prev_e[v] = path to reconstruct augmenting path
// ```
//
// ALGORITHM:
// ```
//   1. Initialize dist[source] = 0, all others = MCMF_INF
//   2. Maintain queue of vertices to process
//   3. For each vertex u dequeued:
//      - For each edge (u, v) with residual capacity > 0:
//        - If dist[u] + cost(u,v) < dist[v]:
//          - Update dist[v]
//          - Record path: prev_v[v] = u, prev_e[v] = edge_index
//          - Enqueue v if not already present
//   4. Continue until queue is empty
// ```
//
// TIME COMPLEXITY:
// ```
//   Worst case: O(VE) per SPFA call
//   Average case: O(E) (much faster in practice)
//   Total MCMF: O(VEF) where F is max flow value
// ```

///|
/// Find the minimum-cost path from `source` to `sink` in the current residual
/// graph using SPFA (Shortest Path Faster Algorithm).
///
/// SPFA is a queue-based relaxation algorithm that handles negative edge
/// weights, which appear on backward (residual) edges in the MCMF graph.
/// It is equivalent to Bellman-Ford but skips re-processing vertices whose
/// distance has not changed, giving much better average-case performance.
///
/// After this function returns `true`, the arrays `dist`, `prev_v`, and
/// `prev_e` record the cheapest path tree rooted at `source`:
/// - `dist[v]`   - minimum cost to reach vertex `v` from `source`
/// - `prev_v[v]` - the vertex before `v` on the cheapest path
/// - `prev_e[v]` - the index in `adj[prev_v[v]]` of the edge entering `v`
///
/// Parameters:
/// - `source` - starting vertex for the shortest-path search
/// - `sink`   - target vertex; reachability is the return value
///
/// Returns `true` if `sink` is reachable from `source` through edges that
/// have positive residual capacity; `false` otherwise.
///
/// Side effects: resets and updates `dist`, `prev_v`, `prev_e`, `in_queue`.
pub fn MinCostMaxFlow::spfa(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
) -> Bool {
  // Reset all arrays
  self.dist.fill(MCMF_INF)
  self.prev_v.fill(-1)
  self.prev_e.fill(-1)
  self.in_queue.fill(false)

  // Initialize source
  self.dist[source] = 0L
  let queue : Array[Int] = [source]
  self.in_queue[source] = true

  // Main SPFA loop
  for front = 0; queue.get(front) is Some(u); {
    self.in_queue[u] = false

    // Relax all outgoing edges
    for i in 0..<self.adj[u].length() {
      let e = self.adj[u][i]

      // Check if edge has residual capacity and offers improvement
      if e.cap > e.flow && self.dist[u] + e.cost < self.dist[e.to] {
        // Found shorter path to e.to
        self.dist[e.to] = self.dist[u] + e.cost
        self.prev_v[e.to] = u
        self.prev_e[e.to] = i

        // Add to queue if not already there
        if !self.in_queue[e.to] {
          queue.push(e.to)
          self.in_queue[e.to] = true
        }
      }
    }
    continue front + 1
  }

  // Return true if sink is reachable
  self.dist[sink] < MCMF_INF
}
