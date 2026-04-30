// ============================================================================
// MIN-COST MAX-FLOW - Computation
// ============================================================================
//
// Main algorithm for computing minimum cost maximum flow.
//
// ALGORITHM:
// ```
//   total_flow = 0
//   total_cost = 0
//
//   While SPFA finds path from source to sink:
//     1. Find minimum residual capacity along path (bottleneck)
//     2. Augment flow along path by bottleneck amount
//     3. Update total_flow and total_cost
//
//   Return (total_flow, total_cost)
// ```
//
// PATH AUGMENTATION:
// ```
//   Given path source -> v1 -> v2 -> ... -> sink:
//
//   1. Find bottleneck: min(cap - flow) over all edges on path
//   2. For each edge (u, v) on path:
//      - Forward edge: flow += bottleneck
//      - Reverse edge: flow -= bottleneck  (increases its residual)
//   3. Cost increase = bottleneck * dist[sink]
//      (dist[sink] = total cost to push 1 unit to sink via this path)
// ```
//
// CORRECTNESS:
// ```
//   By always augmenting along minimum cost path:
//   - Each unit of flow uses cheapest available route at that moment
//   - The residual graph allows cancellation via negative cost back-edges
//   - Combined, this gives minimum cost for every intermediate flow value
// ```

///|
/// Compute the minimum-cost maximum flow from `source` to `sink`.
///
/// The algorithm iterates until no augmenting path exists in the residual
/// graph:
/// 1. Call `spfa(source, sink)` to find the cheapest residual path.
/// 2. Determine the bottleneck (minimum residual capacity on the path).
/// 3. Push `bottleneck` units along the path, updating forward and reverse
///    edge flows.
/// 4. Accumulate `bottleneck * dist[sink]` into the running cost.
///
/// Parameters:
/// - `source` - index of the source vertex
/// - `sink`   - index of the sink vertex
///
/// Returns `(max_flow, min_cost)` where:
/// - `max_flow` is the total flow pushed from `source` to `sink`
/// - `min_cost` is the minimum total cost of that flow
///
/// Note: all flow is pushed; use `compute_with_limit` to cap the flow.
pub fn MinCostMaxFlow::compute(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
) -> (Int64, Int64) {
  // Main loop: find and augment minimum cost paths
  for total_flow = 0L, total_cost = 0L {
    if !self.spfa(source, sink) {
      break (total_flow, total_cost)
    }

    // Step 1: Find minimum residual capacity along path
    let path_flow = for v = sink, path_flow = MCMF_INF; v != source; {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      let residual = self.adj[u][e_idx].cap - self.adj[u][e_idx].flow
      let path_flow = if residual < path_flow { residual } else { path_flow }
      continue u, path_flow
    } nobreak {
      path_flow
    }

    // Step 2: Augment flow along path
    let _ = for v = sink; v != source; {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]

      // Update forward edge
      self.adj[u][e_idx].flow = self.adj[u][e_idx].flow + path_flow

      // Update reverse edge (for potential flow cancellation)
      let rev_idx = self.adj[u][e_idx].rev
      self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
      continue u
    }

    // Step 3: Update totals
    // dist[sink] is cost per unit of flow to reach sink
    continue total_flow + path_flow, total_cost + path_flow * self.dist[sink]
  }
}

///|
/// Compute min-cost flow from `source` to `sink`, stopping once `max_flow_limit`
/// units have been sent or no more augmenting paths exist.
///
/// This is useful when the caller only needs a specific amount of flow (for
/// example, exactly `k` workers assigned in an assignment problem) rather than
/// the full maximum flow.
///
/// The algorithm is identical to `compute` except that:
/// - The initial bottleneck for each path is clamped to
///   `min(residual_capacity, remaining_limit)` so the total never exceeds
///   `max_flow_limit`.
/// - The loop exits early once `total_flow >= max_flow_limit`.
///
/// Parameters:
/// - `source`          - index of the source vertex
/// - `sink`            - index of the sink vertex
/// - `max_flow_limit`  - maximum total flow to send; must be >= 0
///
/// Returns `(achieved_flow, total_cost)` where:
/// - `achieved_flow <= max_flow_limit`
/// - `total_cost`    is the minimum cost for `achieved_flow` units
pub fn MinCostMaxFlow::compute_with_limit(
  self : MinCostMaxFlow,
  source : Int,
  sink : Int,
  max_flow_limit : Int64,
) -> (Int64, Int64) {
  for total_flow = 0L, total_cost = 0L {
    if total_flow >= max_flow_limit {
      break (total_flow, total_cost)
    }
    if !self.spfa(source, sink) {
      break (total_flow, total_cost)
    }

    // Limit path flow to not exceed remaining limit
    let remaining = max_flow_limit - total_flow
    let path_flow = for v = sink, path_flow = (if remaining < MCMF_INF {
                            remaining
                          } else {
                            MCMF_INF
                          }); v != source; {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      let residual = self.adj[u][e_idx].cap - self.adj[u][e_idx].flow
      let path_flow = if residual < path_flow { residual } else { path_flow }
      continue u, path_flow
    } nobreak {
      path_flow
    }

    // Augment flow
    let _ = for v = sink; v != source; {
      let u = self.prev_v[v]
      let e_idx = self.prev_e[v]
      self.adj[u][e_idx].flow = self.adj[u][e_idx].flow + path_flow
      let rev_idx = self.adj[u][e_idx].rev
      self.adj[v][rev_idx].flow = self.adj[v][rev_idx].flow - path_flow
      continue u
    }

    continue total_flow + path_flow, total_cost + path_flow * self.dist[sink]
  }
}
