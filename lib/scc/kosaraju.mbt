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
//     - If SCC A can reach SCC B (A→B), then in post-order traversal,
//       all vertices of A finish AFTER all vertices of B.
//     - So in reverse post-order, A comes before B.
//     - Processing in this order on the transpose:
//       * When we start from a vertex in A, we can't reach B
//         (because edge was A→B, now B→A, and B is already done)
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
/// Find SCCs using Kosaraju's algorithm.
///
/// ALGORITHM:
/// ```
///   PASS 1: Compute finish order
///     Run DFS, append vertices to 'order' in post-order
///
///   TRANSPOSE:
///     Build reverse graph (all edges flipped)
///
///   PASS 2: Assign SCCs
///     Process vertices in reverse finish order
///     Each DFS on transpose finds exactly one SCC
/// ```
///
/// PARAMETERS:
///   - n: number of vertices
///   - adj: adjacency list
///
/// RETURNS:
///   SCCResult with same structure as Tarjan's
pub fn find_sccs_kosaraju(n : Int, adj : Array[Array[Int]]) -> SCCResult {
  if n == 0 {
    return { num_sccs: 0, component: [], scc_sizes: [], scc_adj: [] }
  }

  // =========================================================================
  // PASS 1: Compute finish order
  // =========================================================================
  let visited = Array::make(n, false)
  let order : Array[Int] = []
  for v = 0; v < n; v = v + 1 {
    if not(visited[v]) {
      dfs_order(v, adj, visited, order)
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (post-order construction):
      #|  Vertices [0..v) are processed. Every visited vertex appears
      #|  in 'order' exactly once, after all its descendants.
      #|
      #|POST-ORDER PROPERTY:
      #|  If u→w is an edge and both are in the same DFS tree,
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
  for u = 0; u < n; u = u + 1 {
    for j = 0; j < adj[u].length(); j = j + 1 {
      let v = adj[u][j]
      radj[v].push(u) // Reverse: u→v becomes v→u
    } where {
      invariant: j >= 0 && j <= adj[u].length(),
      reasoning: (
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
    invariant: u >= 0 && u <= n,
    reasoning: (
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
  let mut scc_count = 0
  for i = n - 1; i >= 0; i = i - 1 {
    let v = order[i]
    if component[v] == -1 {
      let size : Counter = { val: 0 }
      dfs_assign(v, radj, component, scc_count, size)
      scc_sizes.push(size.val)
      scc_count = scc_count + 1
    }
  } where {
    invariant: i >= -1 && i <= n - 1,
    reasoning: (
      #|INVARIANT (SCC assignment):
      #|  Vertices with finish-order index > i are assigned to SCCs.
      #|
      #|WHY REVERSE ORDER WORKS:
      #|  Processing from highest finish time means we start at
      #|  "source" SCCs in the original graph (which are "sinks"
      #|  in the transpose).
      #|
      #|  DFS on transpose from v reaches exactly v's SCC because:
      #|  - In original: if v's SCC can reach another SCC, that SCC
      #|    finished earlier (lower index in order)
      #|  - In transpose: edges are reversed, so we can't reach
      #|    those already-processed SCCs
      #|
      #|MAINTENANCE:
      #|  Each dfs_assign labels exactly one SCC.
      #|
      #|TERMINATION:
      #|  At i < 0, all vertices assigned.
    ),
  }

  // =========================================================================
  // Build condensation graph
  // =========================================================================
  let scc_adj : Array[Array[Int]] = Array::makei(scc_count, _ => [])
  for u = 0; u < n; u = u + 1 {
    let comp_u = component[u]
    for j = 0; j < adj[u].length(); j = j + 1 {
      let v = adj[u][j]
      let comp_v = component[v]
      guard comp_u != comp_v else { continue }

      // Check for duplicate edge using contains
      if not(scc_adj[comp_u][:].contains(comp_v)) {
        scc_adj[comp_u].push(comp_v)
      }
    } where {
      invariant: j >= 0 && j <= adj[u].length(),
      reasoning: (
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
    invariant: u >= 0 && u <= n,
    reasoning: (
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
/// First DFS: Record vertices in post-order.
fn dfs_order(
  v : Int,
  adj : Array[Array[Int]],
  visited : Array[Bool],
  order : Array[Int],
) -> Unit {
  visited[v] = true
  for i = 0; i < adj[v].length(); i = i + 1 {
    let u = adj[v][i]
    if not(visited[u]) {
      dfs_order(u, adj, visited, order)
    }
  } where {
    invariant: i >= 0 && i <= adj[v].length(),
    reasoning: (
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
/// Second DFS: Assign all reachable vertices to current SCC.
fn dfs_assign(
  v : Int,
  radj : Array[Array[Int]],
  component : Array[Int],
  scc_id : Int,
  size : Counter,
) -> Unit {
  component[v] = scc_id
  size.val = size.val + 1
  for i = 0; i < radj[v].length(); i = i + 1 {
    let u = radj[v][i]
    if component[u] == -1 {
      dfs_assign(u, radj, component, scc_id, size)
    }
  } where {
    invariant: i >= 0 && i <= radj[v].length(),
    reasoning: (
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
