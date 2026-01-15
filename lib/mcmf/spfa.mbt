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
//   1. Initialize dist[source] = 0, all others = infinity
//   2. Maintain queue of vertices to process
//   3. For each vertex u in queue:
//      - For each edge (u, v) with residual capacity:
//        - If dist[u] + cost(u,v) < dist[v]:
//          - Update dist[v]
//          - Record path (prev_v[v] = u, prev_e[v] = edge_index)
//          - Add v to queue if not already there
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
/// SPFA to find minimum cost path from source to sink.
///
/// RETURNS: true if sink is reachable from source in residual graph
///
/// SIDE EFFECTS:
///   Updates dist[], prev_v[], prev_e[] for path reconstruction
pub fn MinCostMaxFlow::spfa(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
) -> Bool {
  // Reset all arrays
  for i = 0; i < self.n; i = i + 1 {
    self.dist[i] = MCMF_INF
    self.prev_v[i] = -1
    self.prev_e[i] = -1
    self.in_queue[i] = false
  } where {
    invariant: i >= 0 &&
    i <= self.n &&
    self.dist.length() == self.n &&
    self.prev_v.length() == self.n &&
    self.prev_e.length() == self.n &&
    self.in_queue.length() == self.n,
    reasoning: (
      #|INVARIANT (SPFA reset):
      #|  Arrays are reset for vertices [0..i).
      #|
      #|RESET VALUES:
      #|  dist = INF (unreachable)
      #|  prev_v = -1 (no predecessor)
      #|  prev_e = -1 (no edge)
      #|  in_queue = false (not queued)
      #|
      #|MAINTENANCE:
      #|  Reset vertex i.
      #|
      #|TERMINATION:
      #|  At i = n, all vertices are reset.
    ),
  }

  // Initialize source
  self.dist[source] = 0L
  let queue : Array[Int] = [source]
  self.in_queue[source] = true

  // Main SPFA loop
  let mut front = 0
  while queue.get(front) is Some(u) {
    self.in_queue[u] = false

    // Relax all outgoing edges
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let e = self.adj[u][i]

      // Check if edge has residual capacity and offers improvement
      if e.cap > e.flow && self.dist[u] + e.cost < self.dist[e.to] {
        // Found shorter path to e.to
        self.dist[e.to] = self.dist[u] + e.cost
        self.prev_v[e.to] = u
        self.prev_e[e.to] = i

        // Add to queue if not already there
        if not(self.in_queue[e.to]) {
          queue.push(e.to)
          self.in_queue[e.to] = true
        }
      }
    } where {
      invariant: i >= 0 &&
      i <= self.adj[u].length() &&
      self.dist[u] < MCMF_INF &&
      self.prev_v.length() == self.n,
      reasoning: (
        #|INVARIANT (SPFA relax):
        #|  Edges adj[u][0..i) have been considered for relaxation.
        #|
        #|RELAXATION CONDITION:
        #|  - Edge must have residual capacity (cap > flow)
        #|  - New path must be shorter (dist[u] + cost < dist[to])
        #|
        #|CORRECTNESS:
        #|  SPFA correctly handles negative edge weights.
        #|  Each vertex can be enqueued multiple times but
        #|  converges when no more improvements possible.
        #|
        #|MAINTENANCE:
        #|  Process edge i, update dist/prev/queue as needed.
        #|
        #|TERMINATION:
        #|  At i = deg(u), all edges from u are processed.
      ),
    }
    front = front + 1
  }

  // Return true if sink is reachable
  self.dist[sink] < MCMF_INF
}
