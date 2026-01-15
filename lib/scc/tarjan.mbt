// ============================================================================
// SCC - Tarjan's Algorithm
// ============================================================================
//
// Tarjan's algorithm finds all SCCs in a single DFS pass using discovery
// times and low-link values.
//
// KEY CONCEPTS:
// ```
//   disc[v]: Discovery time - when v was first visited in DFS
//   low[v]: Low-link value - minimum disc[] reachable from v's subtree
//
//   low[v] = min of:
//     1. disc[v] itself
//     2. disc[u] for any ancestor u reachable via back edge
//     3. low[w] for any DFS tree child w
// ```
//
// SCC ROOT DETECTION:
// ```
//   Vertex v is the root of its SCC iff disc[v] == low[v]
//
//   Why? If low[v] < disc[v], then v can reach an ancestor,
//   so v is not the "topmost" vertex of its SCC.
//   If low[v] == disc[v], no vertex in v's subtree can escape above v.
// ```
//
// STACK USAGE:
// ```
//   Push vertices when first visited.
//   When SCC root found (disc[v] == low[v]):
//     Pop all vertices above v (inclusive) → they form the SCC
//
//   The stack contains exactly the vertices in the current DFS path
//   and their descendants that haven't been assigned to an SCC yet.
// ```
//
// EXAMPLE:
// ```
//   Graph: 0 → 1 → 2 → 0, 2 → 3
//
//   DFS from 0:
//     Visit 0: disc[0]=0, low[0]=0, push 0
//     Visit 1: disc[1]=1, low[1]=1, push 1
//     Visit 2: disc[2]=2, low[2]=2, push 2
//       Edge 2→0: 0 on stack, low[2] = min(2,0) = 0
//       Edge 2→3: visit 3
//     Visit 3: disc[3]=3, low[3]=3, push 3
//       No edges, disc[3]==low[3] → pop {3} as SCC
//     Back to 2: low[2]=0
//     Back to 1: low[1] = min(1, low[2]) = 0
//     Back to 0: low[0]=0, disc[0]==low[0] → pop {2,1,0} as SCC
//
//   Result: SCCs = {{3}, {0,1,2}}
// ```
//
// TIME: O(V + E)
// SPACE: O(V)

///|
/// Find all SCCs using Tarjan's algorithm.
///
/// ALGORITHM:
/// ```
///   1. Initialize disc[], low[], stack
///   2. For each unvisited vertex, run tarjan_dfs
///   3. In DFS:
///      - Assign disc[v] and low[v]
///      - Push v to stack
///      - For each neighbor u:
///        * If unvisited: recurse, then low[v] = min(low[v], low[u])
///        * If on stack: low[v] = min(low[v], disc[u])
///      - If disc[v] == low[v]: pop SCC from stack
///   4. Build condensation graph from component assignments
/// ```
///
/// PARAMETERS:
///   - n: number of vertices
///   - adj: adjacency list (adj[v] = list of neighbors of v)
///
/// RETURNS:
///   SCCResult with component assignments and condensation graph
pub fn find_sccs(n : Int, adj : Array[Array[Int]]) -> SCCResult {
  if n == 0 {
    return { num_sccs: 0, component: [], scc_sizes: [], scc_adj: [] }
  }

  // Working arrays
  let disc = Array::make(n, -1) // Discovery time (-1 = unvisited)
  let low = Array::make(n, -1) // Low-link value
  let on_stack = Array::make(n, false) // Is vertex currently on stack?
  let component = Array::make(n, -1) // SCC assignment
  let stack : Array[Int] = [] // DFS stack
  let timer : Counter = { val: 0 } // Discovery time counter
  let scc_count : Counter = { val: 0 } // SCC ID counter
  let scc_sizes : Array[Int] = []

  // Run DFS from each unvisited vertex
  for v = 0; v < n; v = v + 1 {
    if disc[v] == -1 {
      tarjan_dfs(
        v, adj, disc, low, on_stack, stack, component, timer, scc_count, scc_sizes,
      )
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (full graph coverage):
      #|  Vertices [0..v) are fully processed:
      #|    - Each has disc[v] != -1
      #|    - Each was pushed and popped exactly once
      #|    - Each belongs to exactly one SCC
      #|
      #|WHY START FROM EACH VERTEX:
      #|  The graph may be disconnected. Starting DFS from each
      #|  unvisited vertex ensures we find all SCCs.
      #|
      #|MAINTENANCE:
      #|  If disc[v] == -1, tarjan_dfs visits v's entire reachable
      #|  region and assigns all vertices to SCCs.
      #|
      #|TERMINATION:
      #|  At v = n, all vertices processed.
    ),
  }

  // Build condensation graph (DAG of SCCs)
  let num_sccs = scc_count.val
  let scc_adj : Array[Array[Int]] = Array::makei(num_sccs, _ => [])

  // Add edges between SCCs (avoiding duplicates)
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
        #|  Edges adj[u][0..j) have been checked for SCC crossings.
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
      #|INVARIANT (condensation construction):
      #|  All edges from vertices [0..u) are reflected in scc_adj.
      #|
      #|MAINTENANCE:
      #|  Process all edges from vertex u.
      #|
      #|TERMINATION:
      #|  At u = n, condensation graph complete.
    ),
  }
  { num_sccs, component, scc_sizes, scc_adj }
}

///|
/// Tarjan's DFS: discover SCCs rooted in current DFS subtree.
///
/// ALGORITHM:
/// ```
///   1. Assign disc[v] = low[v] = timer++
///   2. Push v to stack, mark on_stack[v]
///   3. For each neighbor u:
///      - Unvisited: recurse, then low[v] = min(low[v], low[u])
///      - On stack: low[v] = min(low[v], disc[u])  (back edge)
///      - Finished: ignore (cross edge to other SCC)
///   4. If disc[v] == low[v]: pop all vertices until v → one SCC
/// ```
fn tarjan_dfs(
  v : Int,
  adj : Array[Array[Int]],
  disc : Array[Int],
  low : Array[Int],
  on_stack : Array[Bool],
  stack : Array[Int],
  component : Array[Int],
  timer : Counter,
  scc_count : Counter,
  scc_sizes : Array[Int],
) -> Unit {
  // Step 1: Initialize discovery time and low-link
  disc[v] = timer.val
  low[v] = timer.val
  timer.val = timer.val + 1

  // Step 2: Push to stack
  stack.push(v)
  on_stack[v] = true

  // Step 3: Explore neighbors
  for i = 0; i < adj[v].length(); i = i + 1 {
    let u = adj[v][i]
    if disc[u] == -1 {
      // Tree edge: recurse
      tarjan_dfs(
        u, adj, disc, low, on_stack, stack, component, timer, scc_count, scc_sizes,
      )
      // After returning, update low[v] from child
      if low[u] < low[v] {
        low[v] = low[u]
      }
    } else if on_stack[u] {
      // Back edge to ancestor currently on stack
      if disc[u] < low[v] {
        low[v] = disc[u]
      }
    }
    // Cross edge to finished vertex → ignore (leads to other SCC)
  } where {
    invariant: i >= 0 && i <= adj[v].length(),
    reasoning: (
      #|INVARIANT (low-link computation):
      #|  After processing adj[v][0..i), low[v] equals the minimum
      #|  discovery time reachable from v through those edges while
      #|  staying within the current stack.
      #|
      #|THREE EDGE TYPES:
      #|  1. Tree edge (disc[u] == -1):
      #|     Recurse, then low[v] = min(low[v], low[u])
      #|     Child's reachable ancestors are also v's.
      #|
      #|  2. Back edge (on_stack[u]):
      #|     low[v] = min(low[v], disc[u])
      #|     Direct path to ancestor u.
      #|
      #|  3. Cross edge (disc[u] != -1, not on_stack):
      #|     Ignore - leads to already-finished SCC.
      #|
      #|MAINTENANCE:
      #|  Process one more neighbor, updating low[v].
      #|
      #|TERMINATION:
      #|  At i = deg(v), low[v] is finalized.
    ),
  }

  // Step 4: Check if v is SCC root
  if disc[v] == low[v] {
    let scc_id = scc_count.val
    scc_count.val = scc_count.val + 1
    let mut size = 0

    // Pop all vertices until v (inclusive) → they form the SCC
    for {
      let u = stack[stack.length() - 1]
      let _ = stack.pop()
      on_stack[u] = false
      component[u] = scc_id
      size = size + 1
      if u == v {
        break
      }
    } where {
      invariant: stack.length() >= 0 && size >= 0,
      reasoning: (
        #|INVARIANT (SCC extraction):
        #|  All popped vertices belong to the SCC rooted at v.
        #|  They are removed from stack and assigned to scc_id.
        #|
        #|WHY THIS IS CORRECT:
        #|  When disc[v] == low[v], no vertex in v's subtree can
        #|  reach above v. All vertices pushed after v (and still
        #|  on stack) are in v's SCC.
        #|
        #|MAINTENANCE:
        #|  Pop one vertex, assign to SCC.
        #|
        #|TERMINATION:
        #|  Stop when v itself is popped.
      ),
    }
    scc_sizes.push(size)
  }
}
