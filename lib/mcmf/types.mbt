// ============================================================================
// MIN-COST MAX-FLOW - Type Definitions
// ============================================================================
//
// Find maximum flow with minimum total cost. Each edge has both capacity
// and cost per unit of flow.
//
// PROBLEM FORMULATION:
// ```
//   Given: Directed graph G = (V, E)
//          Edge capacities c(u, v)
//          Edge costs w(u, v)
//          Source s and sink t
//
//   Find: Flow f that maximizes total flow from s to t
//         while minimizing total cost Σ f(u,v) * w(u,v)
// ```
//
// ALGORITHM (SPFA-based):
// ```
//   1. Find shortest path (by cost) from source to sink using SPFA
//   2. Augment flow along this path
//   3. Repeat until no augmenting path exists
//
//   By always choosing the minimum cost path, we ensure that for any
//   given flow value, we achieve minimum cost.
// ```
//
// RESIDUAL GRAPH WITH COSTS:
// ```
//   For edge (u, v) with capacity c, flow f, cost w:
//
//   Forward edge:  residual = c - f, cost = +w
//   Backward edge: residual = f,     cost = -w
//
//   The negative cost on backward edges is crucial!
//   It allows us to "cancel" flow and get cost refund.
//
//   Example: If we pushed 1 unit through (u,v) at cost 5,
//   we can later push 1 unit backward at cost -5 to cancel.
// ```
//
// WHY MINIMUM COST PATH:
// ```
//   Claim: If we always augment along minimum cost path,
//          we get minimum cost for any flow value.
//
//   Proof sketch:
//   - Each augmentation increases flow by some amount
//   - If there were a cheaper way to achieve current flow,
//     we could have found it via negative cost cycles
//   - SPFA with negative edges finds true shortest paths
//     (no negative cycles in residual graph if no initial ones)
// ```
//
// APPLICATIONS:
//   - Assignment problem (bipartite matching with costs)
//   - Transportation problem
//   - Job scheduling with costs
//   - Network design optimization

///|
/// A sentinel value representing positive infinity for distances and capacities.
///
/// Used to initialise SPFA distance arrays so that any real path cost is
/// smaller. Also used as the starting bottleneck when scanning a path for its
/// minimum residual capacity.
///
/// Value equals `Int64::max_value / 2` to avoid overflow when adding two
/// distances together.
pub const MCMF_INF : Int64 = 4611686018427387903L

///|
/// One directed edge stored in the adjacency list of a `MinCostMaxFlow` graph.
///
/// Each call to `add_edge(u, v, cap, cost)` inserts two `MCMFEdge` records:
/// a forward edge in `adj[u]` and a reverse (residual) edge in `adj[v]`.
/// The two edges cross-reference each other through the `rev` field so that
/// augmenting flow on the forward edge can simultaneously update the backward
/// edge.
///
/// Fields:
/// - `to`   - destination vertex index
/// - `cap`  - maximum capacity of this edge
/// - `cost` - cost per unit of flow (negative for residual back-edges)
/// - `flow` - flow currently assigned; residual capacity = `cap - flow`
/// - `rev`  - index of the paired edge in `adj[to]`
///
/// Residual capacity rule:
/// ```
///   residual(e) = e.cap - e.flow   (must be > 0 to push more flow)
/// ```
pub(all) struct MCMFEdge {
  to : Int
  cap : Int64
  cost : Int64
  mut flow : Int64
  rev : Int // Index of reverse edge in adj[to]
}

///|
/// Min-Cost Max-Flow solver for a directed graph with capacitated, costed edges.
///
/// Build the graph by calling `add_edge` once per directed edge, then call
/// `compute` (or `compute_with_limit`) to obtain `(max_flow, min_cost)`.
///
/// Internally the solver uses SPFA (Shortest Path Faster Algorithm) to find
/// the cheapest augmenting path in the residual graph on each iteration.
///
/// Fields (all managed internally; exposed as `pub(all)` for inspection):
/// - `n`        - number of vertices; vertices are indexed `0..n-1`
/// - `adj`      - adjacency list; `adj[u]` holds all edges leaving `u`
/// - `dist`     - SPFA shortest-path distances from the current source
/// - `prev_v`   - previous vertex on the cheapest path to each vertex
/// - `prev_e`   - edge index in `adj[prev_v[v]]` used to reach vertex `v`
/// - `in_queue` - whether a vertex is currently enqueued in SPFA
///
/// Example (single edge):
/// ```
///   let g = MinCostMaxFlow::new(2)
///   g.add_edge(0, 1, 10L, 3L)   // cap 10, cost 3 per unit
///   let (flow, cost) = g.compute(0, 1)
///   // flow = 10, cost = 30
/// ```
pub(all) struct MinCostMaxFlow {
  n : Int
  adj : Array[Array[MCMFEdge]]
  dist : Array[Int64]
  prev_v : Array[Int]
  prev_e : Array[Int]
  in_queue : Array[Bool]
}

///|
/// Create a new `MinCostMaxFlow` instance for a graph with `n` vertices.
///
/// Vertices are labeled `0` through `n - 1`. No edges are added at
/// construction time; call `add_edge` to build the graph.
///
/// Parameters:
/// - `n` - number of vertices (must be >= 1)
///
/// Returns a solver with empty adjacency lists and zeroed auxiliary arrays.
pub fn MinCostMaxFlow::new(n : Int) -> MinCostMaxFlow {
  let adj : Array[Array[MCMFEdge]] = [| for _ in 0..<n => [] |]
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
/// Add a directed edge from vertex `u` to vertex `v` with the given capacity
/// and cost per unit of flow.
///
/// This method inserts two `MCMFEdge` records:
/// 1. A forward edge `(u -> v)` with capacity `cap` and cost `+cost`.
/// 2. A reverse (residual) edge `(v -> u)` with capacity `0` and cost `-cost`.
///
/// The reverse edge starts with zero capacity so no flow can traverse it
/// initially. As flow is pushed on the forward edge, the residual capacity of
/// the reverse edge grows, allowing the algorithm to cancel (undo) that flow
/// later at negative cost.
///
/// Parameters:
/// - `u`    - source vertex of the edge (0-indexed)
/// - `v`    - destination vertex of the edge (0-indexed)
/// - `cap`  - maximum flow that can be carried on this edge
/// - `cost` - cost charged per unit of flow sent along this edge
///
/// Multiple edges between the same pair of vertices are supported (parallel
/// edges). Each call adds an independent pair of forward/reverse edges.
pub fn MinCostMaxFlow::add_edge(
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
