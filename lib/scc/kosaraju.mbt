// ============================================================================
// SCC - Kosaraju's Algorithm
// ============================================================================
//
// Kosaraju's algorithm finds SCCs using two DFS passes:
//   1. First DFS: Record vertices in post-order (finish time)
//   2. Second DFS: Process in reverse order on transposed graph
//
// KEY INSIGHT:
// ```
//   In the transposed graph, edges are reversed.
//   If we start DFS from a vertex in a "sink" SCC (in original graph),
//   we can only reach vertices in the same SCC.
//
//   Processing in reverse finish order ensures we start from sink SCCs
//   and work our way up the condensation DAG.
// ```
//
// WHY IT WORKS:
// ```
//   Claim: In reverse post-order, vertices from source SCCs come first.
//
//   Proof sketch:
//     - If SCC A can reach SCC B (A->B), then in post-order traversal,
//       all vertices of A finish AFTER all vertices of B.
//     - So in reverse post-order, A comes before B.
//     - Processing in this order on the transpose:
//       * When we start from a vertex in A, we can't reach B
//         (because edge was A->B, now B->A, and B is already done)
//       * We only reach vertices in the same SCC
// ```
//
// COMPARISON WITH TARJAN:
// ```
//   Tarjan: Single DFS, uses low-link values
//   Kosaraju: Two DFS passes, simpler logic but needs transpose
//
//   Both are O(V + E) time.
// ```
//
// TIME: O(V + E)
// SPACE: O(V + E) for transpose

///|
/// Find all strongly connected components using Kosaraju's algorithm.
///
/// This is an alternative to `find_sccs` (Tarjan). Both return an equivalent
/// `SCCResult`; the SCC indices may differ between the two implementations
/// but the partitioning of vertices is the same.
///
/// The algorithm has three phases:
///
/// **Phase 1 — post-order traversal.**
/// Run DFS on the original graph and append each vertex to `order` after
/// all its descendants have been visited (post-order / finish order).
///
/// **Phase 2 — transpose.**
/// Build the reverse graph (`radj`) by flipping every edge `u -> v` into
/// `v -> u`.
///
/// **Phase 3 — SCC assignment.**
/// Process vertices in reverse finish order. For each unassigned vertex,
/// run DFS on the transpose graph. Because of the post-order property,
/// such a DFS can only reach vertices in the same SCC, so each DFS tree
/// in this phase identifies exactly one SCC.
///
/// After all SCCs are found, the condensation DAG is built the same way as
/// in Tarjan's implementation.
///
/// Parameters:
/// - `n`   : number of vertices (labelled `0` to `n - 1`).
/// - `adj` : adjacency list where `adj[v]` lists the out-neighbours of `v`.
///
/// Returns an `SCCResult` with the same structure as `find_sccs`.
///
/// Time: `O(V + E)`. Space: `O(V + E)` (transpose graph uses extra space).
pub fn find_sccs_kosaraju(n : Int, adj : Array[Array[Int]]) -> SCCResult {
  if n == 0 {
    return { num_sccs: 0, component: [], scc_sizes: [], scc_adj: [] }
  }

  // =========================================================================
  // PASS 1: Compute finish order
  // =========================================================================
  let visited = Array::make(n, false)
  let order : Array[Int] = []
  for v in 0..<n {
    if !visited[v] {
      dfs_order(v, adj, visited, order)
    }
  } where {
    proof_invariant: v >= 0 && v <= n,
    proof_reasoning: (
      #|INVARIANT (post-order construction):
      #|  Vertices [0..v) are processed. Every visited vertex appears
      #|  in 'order' exactly once, after all its descendants.
      #|
      #|POST-ORDER PROPERTY:
      #|  If u->w is an edge and both are in the same DFS tree,
      #|  then w appears before u in 'order'.
      #|
      #|MAINTENANCE:
      #|  DFS from unvisited v adds its entire reachable region.
      #|
      #|TERMINATION:
      #|  At v = n, 'order' contains all vertices in post-order.
    ),
  }

  // =========================================================================
  // TRANSPOSE: Build reverse graph
  // =========================================================================
  let radj : Array[Array[Int]] = Array::makei(n, _ => [])
  for u in 0..<n {
    for j in 0..<adj[u].length() {
      let v = adj[u][j]
      radj[v].push(u) // Reverse: u->v becomes v->u
    } where {
      proof_invariant: j >= 0 && j <= adj[u].length(),
      proof_reasoning: (
        #|INVARIANT (per-vertex transpose):
        #|  Edges adj[u][0..j) have been reversed into radj.
        #|
        #|MAINTENANCE:
        #|  Reverse one more edge.
        #|
        #|TERMINATION:
        #|  At j = deg(u), all edges from u are reversed.
      ),
    }
  } where {
    proof_invariant: u >= 0 && u <= n,
    proof_reasoning: (
      #|INVARIANT (full transpose):
      #|  All edges from vertices [0..u) are reversed in radj.
      #|
      #|MAINTENANCE:
      #|  Process all edges from vertex u.
      #|
      #|TERMINATION:
      #|  At u = n, radj is the complete transpose.
    ),
  }

  // =========================================================================
  // PASS 2: Assign SCCs in reverse finish order
  // =========================================================================
  let component = Array::make(n, -1)
  let scc_sizes : Array[Int] = []
  let scc_count = for i in n>..0; scc_count = 0 {
    let v = order[i]
    if component[v] == -1 {
      let size : Counter = { val: 0 }
      dfs_assign(v, radj, component, scc_count, size)
      scc_sizes.push(size.val)
      continue scc_count + 1
    }
    continue scc_count
  } nobreak {
    scc_count
  }

  // =========================================================================
  // Build condensation graph
  // =========================================================================
  let scc_adj : Array[Array[Int]] = Array::makei(scc_count, _ => [])
  for u in 0..<n {
    let comp_u = component[u]
    for j in 0..<adj[u].length() {
      let v = adj[u][j]
      let comp_v = component[v]
      guard comp_u != comp_v else { continue }

      // Check for duplicate edge using contains
      if !scc_adj[comp_u][:].contains(comp_v) {
        scc_adj[comp_u].push(comp_v)
      }
    } where {
      proof_invariant: j >= 0 && j <= adj[u].length(),
      proof_reasoning: (
        #|INVARIANT (edge processing):
        #|  Edges adj[u][0..j) checked for SCC crossings.
        #|
        #|MAINTENANCE:
        #|  Process one more edge.
        #|
        #|TERMINATION:
        #|  At j = deg(u), all edges from u checked.
      ),
    }
  } where {
    proof_invariant: u >= 0 && u <= n,
    proof_reasoning: (
      #|INVARIANT (condensation):
      #|  All edges from vertices [0..u) reflected in scc_adj.
      #|
      #|MAINTENANCE:
      #|  Process all edges from vertex u.
      #|
      #|TERMINATION:
      #|  At u = n, condensation complete.
    ),
  }
  { num_sccs: scc_count, component, scc_sizes, scc_adj }
}

///|
/// DFS pass 1: visit all vertices reachable from `v` and append each one to
/// `order` in post-order (after all its descendants).
///
/// The resulting `order` array has the property that if there is an edge
/// `u -> w` and both vertices are in the same DFS tree, then `w` appears
/// before `u` in `order`.  Processing vertices in the reverse of this order
/// during pass 2 guarantees we visit source SCCs before sink SCCs on the
/// transpose graph.
///
/// Parameters:
/// - `v`       : current vertex being visited.
/// - `adj`     : original adjacency list.
/// - `visited` : boolean flags to skip already-visited vertices.
/// - `order`   : accumulates vertices in post-order.
fn dfs_order(
  v : Int,
  adj : Array[Array[Int]],
  visited : Array[Bool],
  order : Array[Int],
) -> Unit {
  visited[v] = true
  for i in 0..<adj[v].length() {
    let u = adj[v][i]
    if !visited[u] {
      dfs_order(u, adj, visited, order)
    }
  } where {
    proof_invariant: i >= 0 && i <= adj[v].length(),
    proof_reasoning: (
      #|INVARIANT (DFS traversal):
      #|  Neighbors adj[v][0..i) are processed.
      #|  Their entire subtrees are visited and in 'order'.
      #|
      #|MAINTENANCE:
      #|  Recurse on unvisited neighbor.
      #|
      #|TERMINATION:
      #|  At i = deg(v), all descendants visited.
    ),
  }

  // Append v AFTER all descendants (post-order)
  order.push(v)
}

///|
/// DFS pass 2: assign vertex `v` and all vertices reachable from it in the
/// **transpose** graph to SCC `scc_id`.
///
/// Because pass 2 processes vertices in reverse finish order, any neighbour
/// reachable in the transpose that belongs to a different SCC will already
/// have been assigned (`component[u] != -1`) and will be skipped.  This
/// guarantees that each call to `dfs_assign` labels exactly one SCC.
///
/// Parameters:
/// - `v`         : current vertex being assigned.
/// - `radj`      : transpose adjacency list (edges reversed).
/// - `component` : SCC assignment array; `-1` means unassigned.
/// - `scc_id`    : the SCC index to assign to `v` and its reachable set.
/// - `size`      : mutable counter incremented for each assigned vertex.
fn dfs_assign(
  v : Int,
  radj : Array[Array[Int]],
  component : Array[Int],
  scc_id : Int,
  size : Counter,
) -> Unit {
  component[v] = scc_id
  size.val = size.val + 1
  for i in 0..<radj[v].length() {
    let u = radj[v][i]
    if component[u] == -1 {
      dfs_assign(u, radj, component, scc_id, size)
    }
  } where {
    proof_invariant: i >= 0 && i <= radj[v].length(),
    proof_reasoning: (
      #|INVARIANT (SCC assignment):
      #|  Neighbors radj[v][0..i) in the same SCC are assigned.
      #|
      #|WHY ONLY SAME SCC:
      #|  We process in reverse finish order. Any vertex from a
      #|  different SCC that v could reach (in transpose) would
      #|  have been processed already.
      #|
      #|MAINTENANCE:
      #|  Recurse on unassigned neighbor.
      #|
      #|TERMINATION:
      #|  At i = deg(v), entire SCC labeled.
    ),
  }
}
