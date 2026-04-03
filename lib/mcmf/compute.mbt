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
//     1. Find minimum residual capacity along path
//     2. Augment flow along path by this amount
//     3. Update total_flow and total_cost
//
//   Return (total_flow, total_cost)
// ```
//
// PATH AUGMENTATION:
// ```
//   Given path source -> v1 -> v2 -> ... -> sink:
//
//   1. Find bottleneck: min residual capacity on path
//   2. For each edge (u, v) on path:
//      - Forward edge: flow += bottleneck
//      - Reverse edge: flow -= bottleneck
//   3. Cost increase = bottleneck * dist[sink]
//      (dist[sink] = total cost to push 1 unit to sink)
// ```
//
// CORRECTNESS:
// ```
//   By always augmenting along minimum cost path:
//   - Each unit of flow uses cheapest available route
//   - Total cost is minimum for achieved flow value
// ```

///|
/// Compute min-cost max-flow from source to sink.
///
/// RETURNS: (max_flow, min_cost)
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
/// Compute min-cost max-flow with a flow limit.
///
/// Stops when either:
///   - Total flow reaches max_flow_limit, OR
///   - No more augmenting paths exist
///
/// RETURNS: (achieved_flow, total_cost)
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
