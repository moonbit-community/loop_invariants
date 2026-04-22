// ============================================================================
// DINIC'S ALGORITHM - Type Definitions
// ============================================================================
//
// Dinic's algorithm finds maximum flow using blocking flows in layered graphs.
// It is faster than Ford-Fulkerson and Edmonds-Karp for many practical cases.
//
// ALGORITHM OVERVIEW:
// ```
//   1. Build level graph using BFS from source.
//      (Only edges to strictly higher levels are included.)
//
//   2. Find blocking flow using DFS.
//      (Saturate at least one edge on every s-t path.)
//
//   3. Repeat until the sink is unreachable in the residual graph.
// ```
//
// KEY INSIGHT - BLOCKING FLOW:
// ```
//   A blocking flow saturates at least one edge on every s-t path
//   in the level graph.  After finding a blocking flow:
//
//   - The level graph is "blocked" (no augmenting path remains).
//   - We must rebuild the level graph via BFS.
//   - The BFS distance from s to t strictly increases.
//   - At most O(V) phases are therefore needed.
// ```
//
// VISUAL EXAMPLE:
// ```
//   Original network:        Level graph (after BFS):
//
//     s --5--> a --3--> t       Level 0    Level 1    Level 2
//      \       |                  s ──────► a ────────► t
//       2      4                   \──────► b ─────────/
//        \     v
//         --> b --2--> t       (Only forward edges; no back/same-level edges.)
//
//   Blocking flow saturates edges:
//   - s→a→t: push 3 (saturates a→t)
//   - s→b→t: push 2 (saturates s→b and b→t)
// ```
//
// TIME COMPLEXITY:
// ```
//   O(V^2 * E) for general graphs
//   O(E * sqrt(V)) for unit-capacity graphs
//   O(E * sqrt(V)) for bipartite matching
// ```
//
// SPACE COMPLEXITY: O(V + E)
//
// APPLICATIONS:
//   - Maximum bipartite matching
//   - Minimum cut problems
//   - Project selection (profit maximisation)
//   - Image segmentation

///|
/// Infinity sentinel used as the initial `pushed` value in DFS.
///
/// Must be strictly larger than the maximum possible flow in any network
/// passed to this implementation.  The value equals `Int64::max_value / 2`
/// so that arithmetic on it does not overflow.
pub const DINIC_INF : Int64 = 4611686018427387903L

///|
/// A single directed edge in the flow network.
///
/// Each real edge `(u, v, cap)` is stored as a pair of `DinicEdge` entries:
///
/// ```
///   adj[u][i]   = { to: v,  cap: cap, flow: 0,  rev: j }   (forward edge)
///   adj[v][j]   = { to: u,  cap: 0,   flow: 0,  rev: i }   (reverse edge)
/// ```
///
/// The **residual capacity** of an edge is `cap - flow`.
/// For the reverse edge, `cap == 0` and `flow` can become negative, which
/// models the ability to "undo" flow sent on the forward direction.
///
/// Fields:
/// - `to`   : destination vertex index
/// - `cap`  : original capacity of the edge
/// - `flow` : flow currently assigned to the edge (mutable)
/// - `rev`  : index of the paired reverse edge in `adj[to]`
pub(all) struct DinicEdge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int // Index of reverse edge
}

///|
/// Dinic's algorithm state for a flow network with `n` vertices.
///
/// Create with `Dinic::new`, populate with `add_edge`, then call `max_flow`.
///
/// Fields:
/// - `n`     : number of vertices (vertices are labelled `0..n-1`)
/// - `adj`   : adjacency list; `adj[u]` holds all `DinicEdge` records for `u`
/// - `level` : BFS distance from the source vertex (-1 if unreachable)
/// - `iter`  : current-arc pointer per vertex, reset at the start of each
///             BFS phase to skip already-exhausted edges during DFS
///
/// Edge storage invariant:
/// ```
///   For every call add_edge(u, v, cap):
///     adj[u] gains a forward edge  (to=v,  cap=cap, flow=0)
///     adj[v] gains a reverse edge  (to=u,  cap=0,   flow=0)
///   The two edges point to each other via their `rev` fields.
///
///   Pushing flow f on (u, v):
///     adj[u][i].flow  += f
///     adj[v][rev].flow -= f   (negative ⟹ residual on the reverse arc)
/// ```
pub(all) struct Dinic {
  n : Int
  adj : Array[Array[DinicEdge]]
  level : Array[Int]
  iter : Array[Int] // Current edge pointer for each vertex
}

///|
/// Create a new `Dinic` instance for a graph with `n` vertices.
///
/// Vertices are numbered `0` to `n-1`.  No edges are added; use
/// `add_edge` to build the network before calling `max_flow`.
pub fn Dinic::new(n : Int) -> Dinic {
  let adj = [ for _ in 0..<n => [] ]
  { n, adj, level: Array::make(n, 0), iter: Array::make(n, 0) }
}

///|
/// Add a directed edge from `from` to `to` with capacity `cap`.
///
/// Simultaneously inserts the paired reverse edge (capacity 0) so that the
/// residual graph can be maintained without a separate data structure.
///
/// Multiple calls with the same `(from, to)` pair create **parallel** edges,
/// each tracked independently (their capacities are not merged).
///
/// Steps:
/// ```
///   1. Record the current lengths of adj[to] and adj[from]
///      as the indices where the new reverse / forward edges will land.
///   2. Append forward edge to adj[from]: (to, cap, flow=0, rev=j)
///   3. Append reverse edge to adj[to]:   (from, 0,  flow=0, rev=i)
/// ```
pub fn Dinic::add_edge(self : Dinic, from : Int, to : Int, cap : Int64) -> Unit {
  let rev_from = self.adj[to].length()
  let rev_to = self.adj[from].length()
  self.adj[from].push({ to, cap, flow: 0L, rev: rev_from })
  self.adj[to].push({ to: from, cap: 0L, flow: 0L, rev: rev_to })
}
