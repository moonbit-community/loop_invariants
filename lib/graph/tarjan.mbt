// ============================================================================
// TARJAN'S STRONGLY CONNECTED COMPONENTS ALGORITHM WITH LOOP INVARIANTS
// ============================================================================
//
// Tarjan's algorithm finds all Strongly Connected Components (SCCs) in a
// directed graph in O(V + E) time using a single DFS traversal.
//
// A STRONGLY CONNECTED COMPONENT is a maximal set of vertices such that
// there is a path from every vertex to every other vertex in the set.
//
// KEY CONCEPTS:
// 1. Discovery time (disc[v]): When vertex v was first visited
// 2. Low-link value (low[v]): Smallest discovery time reachable from v's subtree
// 3. Stack: Contains vertices in the current DFS path
//
// THE FUNDAMENTAL INVARIANT:
// A vertex v is the ROOT of an SCC iff disc[v] == low[v] after processing
// all its descendants. This means v cannot reach any vertex discovered
// earlier (outside its subtree) that's still on the stack.

// ============================================================================
// SCC FINDER USING TARJAN'S ALGORITHM
// ============================================================================

///|
priv struct TarjanSCC {
  graph : Array[Array[Int]] // Adjacency list
  n : Int
  disc : Array[Int] // Discovery time
  low : Array[Int] // Low-link value
  on_stack : Array[Bool] // Is vertex on stack?
  stack : Array[Int] // DFS stack
  mut time : Int // Global timer
  sccs : Array[Array[Int]] // Result: list of SCCs
}

///|
fn TarjanSCC::new(graph : Array[Array[Int]]) -> TarjanSCC {
  let n = graph.length()
  {
    graph,
    n,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    on_stack: Array::make(n, false),
    stack: [],
    time: 0,
    sccs: [],
  }
}

///|
/// The core DFS function that finds SCCs.
///
/// INVARIANTS:
/// 1. disc[v] = time when v was discovered (-1 if unvisited)
/// 2. low[v] = min disc[w] for all w reachable from v's subtree that are on stack
/// 3. on_stack[v] = true iff v is currently in the DFS stack
/// 4. Stack contains all vertices from root to current vertex
///
/// ROOT DETECTION:
/// After processing all neighbors, if disc[v] == low[v], then v is an SCC root.
/// All vertices from v to top of stack form this SCC.
#warnings("+missing_invariant+missing_reasoning")
fn TarjanSCC::dfs(self : TarjanSCC, v : Int) -> Unit {
  // Initialize discovery and low-link
  self.disc[v] = self.time
  self.low[v] = self.time
  self.time = self.time + 1
  self.stack.push(v)
  self.on_stack[v] = true
  // Process all neighbors
  let neighbors = self.graph[v]
  for i = 0 {
    if i >= neighbors.length() {
      break
    } else {
      let w = neighbors[i]
      if self.disc[w] == -1 {
        // Tree edge: w not yet visited
        self.dfs(w)
        // After returning, update low[v] with low[w]
        if self.low[w] < self.low[v] {
          self.low[v] = self.low[w]
        }
      } else if self.on_stack[w] {
        // Back edge to vertex on stack
        // Update low[v] with disc[w]
        if self.disc[w] < self.low[v] {
          self.low[v] = self.disc[w]
        }
      }
      // Cross edge to vertex not on stack: ignore (already in different SCC)
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|NEIGHBOR PROCESSING INVARIANT:
      #|After processing neighbor w, low[v] is updated to reflect paths
      #|through w that can reach earlier vertices on the stack.
      #|
      #|CASE 1 (Tree edge, disc[w] == -1):
      #|  w is unvisited, so we recurse.
      #|  After recursion, low[w] contains the minimum disc reachable from w.
      #|  We update low[v] = min(low[v], low[w]).
      #|
      #|CASE 2 (Back edge, on_stack[w]):
      #|  w is on the current DFS path (ancestor of v).
      #|  This creates a cycle: v can reach w's discovery time.
      #|  We update low[v] = min(low[v], disc[w]).
      #|
      #|CASE 3 (Cross edge, !on_stack[w]):
      #|  w was visited but is not on stack → already in a finished SCC.
      #|  We cannot use w to reach earlier stack vertices.
      #|  No update needed.
      #|
      #|CORRECTNESS: low[v] captures the earliest reachable stack vertex.
    ),
  }
  // Check if v is an SCC root
  if self.disc[v] == self.low[v] {
    // Pop all vertices until v to form this SCC
    let scc : Array[Int] = []
    for {
      let w = self.stack.pop().unwrap()
      self.on_stack[w] = false
      scc.push(w)
      if w == v {
        break
      }
    } where {
      invariant: self.on_stack[v],
      invariant: scc.all((x) => not(self.on_stack[x])),
      invariant: self.stack.length() + scc.length() <= self.n,
      reasoning: (
        #|SCC POP INVARIANT:
        #|The stack stores the current DFS path; the SCC rooted at v is a
        #|contiguous suffix of this stack. Each iteration pops one vertex from
        #|the top, marks it not-on-stack, and records it in scc.
        #|
        #|v stays on the stack until it is popped, so self.on_stack[v] holds
        #|for every iteration start. Popped vertices never return to the stack.
        #|
        #|Termination: v is on the stack and each iteration shrinks the stack,
        #|so we eventually pop v and break.
      ),
    }
    self.sccs.push(scc)
  }
}

///|
/// Find all SCCs in the graph.
#warnings("+missing_invariant+missing_reasoning")
fn TarjanSCC::find_sccs(self : TarjanSCC) -> Unit {
  for v = 0 {
    if v >= self.n {
      break
    } else {
      if self.disc[v] == -1 {
        self.dfs(v)
      }
      continue v + 1
    }
  } where {
    invariant: v >= 0 && v <= self.n,
    reasoning: (
      #|MAIN LOOP INVARIANT:
      #|After processing vertex v, all vertices 0..v-1 that were reachable
      #|from already-processed starting points have been assigned to SCCs.
      #|
      #|The graph may be disconnected, so we must start DFS from each
      #|unvisited vertex to cover all SCCs.
    ),
  }
}

///|
/// Convenience function to find SCCs in a graph.
fn find_strongly_connected_components(
  graph : Array[Array[Int]],
) -> Array[Array[Int]] {
  let tarjan = TarjanSCC::new(graph)
  tarjan.find_sccs()
  tarjan.sccs
}

///|
test "tarjan_basic" {
  // Graph with 3 SCCs:
  // SCC1: {0, 1, 2} - cycle: 0 → 1 → 2 → 0
  // SCC2: {3, 4} - cycle: 3 → 4 → 3
  // SCC3: {5} - single vertex
  // Edges: 2 → 3, 4 → 5 (connecting SCCs)
  let graph : Array[Array[Int]] = [
    [1], // 0 → 1
    [2], // 1 → 2
    [0, 3], // 2 → 0, 2 → 3
    [4], // 3 → 4
    [3, 5], // 4 → 3, 4 → 5
    [],
  ] // 5
  let sccs = find_strongly_connected_components(graph)
  // Should have 3 SCCs
  assert_eq(sccs.length(), 3)
  // SCCs are found in reverse topological order
  // SCC containing 5 should be first (no outgoing edges to other SCCs)
  // Then SCC containing 3,4
  // Then SCC containing 0,1,2
}

///|
test "tarjan_single_scc" {
  // Complete graph on 4 vertices - one big SCC
  let graph : Array[Array[Int]] = [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]]
  let sccs = find_strongly_connected_components(graph)
  assert_eq(sccs.length(), 1)
  assert_eq(sccs[0].length(), 4)
}

///|
test "tarjan_dag" {
  // DAG: each vertex is its own SCC
  // 0 → 1 → 2 → 3
  let graph : Array[Array[Int]] = [[1], [2], [3], []]
  let sccs = find_strongly_connected_components(graph)
  assert_eq(sccs.length(), 4)
}

// ============================================================================
// KOSARAJU'S ALGORITHM (Alternative approach)
// ============================================================================
//
// Kosaraju's algorithm also finds SCCs in O(V + E) but uses two DFS passes:
// 1. First DFS: compute finish times (post-order)
// 2. Second DFS: process vertices in reverse finish order on reversed graph
//
// WHY IT WORKS:
// In the reversed graph, an SCC remains an SCC.
// Processing in reverse finish order ensures we start from "sink" SCCs
// (SCCs with no outgoing edges to other SCCs).

///|
priv struct KosarajuSCC {
  graph : Array[Array[Int]]
  reversed : Array[Array[Int]]
  n : Int
  visited : Array[Bool]
  finish_order : Array[Int]
  sccs : Array[Array[Int]]
}

///|
#warnings("-missing_invariant-missing_reasoning")
fn KosarajuSCC::new(graph : Array[Array[Int]]) -> KosarajuSCC {
  let n = graph.length()
  // Build reversed graph
  let reversed : Array[Array[Int]] = Array::make(n, [])
  for v in 0..<n {
    reversed[v] = []
  }
  for v in 0..<n {
    for w in graph[v] {
      reversed[w].push(v)
    }
  }
  {
    graph,
    reversed,
    n,
    visited: Array::make(n, false),
    finish_order: [],
    sccs: [],
  }
}

///|
/// First DFS: record finish order (post-order traversal).
#warnings("+missing_invariant+missing_reasoning")
fn KosarajuSCC::dfs1(self : KosarajuSCC, v : Int) -> Unit {
  self.visited[v] = true
  let neighbors = self.graph[v]
  for i = 0 {
    if i >= neighbors.length() {
      break
    } else {
      let w = neighbors[i]
      if not(self.visited[w]) {
        self.dfs1(w)
      }
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|Standard DFS visiting all unvisited neighbors.
    ),
  }
  // Post-order: add to finish order after processing all descendants
  self.finish_order.push(v)
}

///|
/// Second DFS: collect SCC on reversed graph.
#warnings("+missing_invariant+missing_reasoning")
fn KosarajuSCC::dfs2(self : KosarajuSCC, v : Int, scc : Array[Int]) -> Unit {
  self.visited[v] = true
  scc.push(v)
  let neighbors = self.reversed[v]
  for i = 0 {
    if i >= neighbors.length() {
      break
    } else {
      let w = neighbors[i]
      if not(self.visited[w]) {
        self.dfs2(w, scc)
      }
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|DFS on reversed graph collects all vertices in same SCC.
      #|
      #|WHY THIS WORKS:
      #|If u and v are in same SCC: u ⟷ v in original graph.
      #|So u ⟷ v in reversed graph too.
      #|Therefore, DFS from any SCC vertex reaches all SCC vertices.
    ),
  }
}

///|
/// Find all SCCs using Kosaraju's algorithm.
#warnings("+missing_invariant+missing_reasoning")
fn KosarajuSCC::find_sccs(self : KosarajuSCC) -> Unit {
  // Pass 1: DFS to get finish order
  for v = 0 {
    if v >= self.n {
      break
    } else {
      if not(self.visited[v]) {
        self.dfs1(v)
      }
      continue v + 1
    }
  } where {
    invariant: v >= 0 && v <= self.n,
    reasoning: (
      #|First pass builds finish_order using post-order traversal.
    ),
  }
  // Reset visited for pass 2
  for v = 0 {
    if v >= self.n {
      break
    } else {
      self.visited[v] = false
      continue v + 1
    }
  } where {
    invariant: v >= 0 && v <= self.n,
    reasoning: (
      #|Reset visited array for second pass.
    ),
  }
  // Pass 2: DFS in reverse finish order on reversed graph
  for i = self.finish_order.length() - 1 {
    if i < 0 {
      break
    } else {
      let v = self.finish_order[i]
      if not(self.visited[v]) {
        let scc : Array[Int] = []
        self.dfs2(v, scc)
        self.sccs.push(scc)
      }
      continue i - 1
    }
  } where {
    invariant: i >= -1 && i < self.finish_order.length(),
    reasoning: (
      #|SECOND PASS INVARIANT:
      #|Processing in reverse finish order ensures we start from "sink" SCCs.
      #|
      #|WHY REVERSE FINISH ORDER?
      #|If SCC A has edge to SCC B, then A finishes after B in DFS1.
      #|Processing A first (reverse order) on reversed graph means
      #|the edge B→A (in reversed graph) won't cross SCC boundaries
      #|because B is already finished.
      #|
      #|CORRECTNESS:
      #|Each DFS2 call discovers exactly one SCC because:
      #|1. All vertices in an SCC are mutually reachable (in reversed graph too)
      #|2. We can't escape to other SCCs due to processing order
    ),
  }
}

///|
fn find_sccs_kosaraju(graph : Array[Array[Int]]) -> Array[Array[Int]] {
  let kosaraju = KosarajuSCC::new(graph)
  kosaraju.find_sccs()
  kosaraju.sccs
}

///|
test "kosaraju_basic" {
  // Same graph as tarjan_basic
  let graph : Array[Array[Int]] = [[1], [2], [0, 3], [4], [3, 5], []]
  let sccs = find_sccs_kosaraju(graph)
  assert_eq(sccs.length(), 3)
}

// ============================================================================
// ARTICULATION POINTS (CUT VERTICES)
// ============================================================================
//
// An articulation point is a vertex whose removal disconnects the graph.
//
// TARJAN'S INSIGHT APPLIES HERE TOO:
// Vertex v is an articulation point iff:
// 1. v is the root of DFS tree with 2+ children, OR
// 2. v has a child w where low[w] >= disc[v]
//    (no back edge from w's subtree bypasses v)

///|
priv struct ArticulationFinder {
  graph : Array[Array[Int]]
  n : Int
  disc : Array[Int]
  low : Array[Int]
  parent : Array[Int]
  is_ap : Array[Bool] // Is articulation point?
  mut time : Int
}

///|
fn ArticulationFinder::new(graph : Array[Array[Int]]) -> ArticulationFinder {
  let n = graph.length()
  {
    graph,
    n,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    parent: Array::make(n, -1),
    is_ap: Array::make(n, false),
    time: 0,
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn ArticulationFinder::dfs(self : ArticulationFinder, v : Int) -> Unit {
  let mut children = 0
  self.disc[v] = self.time
  self.low[v] = self.time
  self.time = self.time + 1
  let neighbors = self.graph[v]
  for i = 0 {
    if i >= neighbors.length() {
      break
    } else {
      let w = neighbors[i]
      if self.disc[w] == -1 {
        // Tree edge
        children = children + 1
        self.parent[w] = v
        self.dfs(w)
        // Update low value
        if self.low[w] < self.low[v] {
          self.low[v] = self.low[w]
        }
        // Check articulation point condition
        if self.parent[v] == -1 && children > 1 {
          // Root with 2+ children
          self.is_ap[v] = true
        }
        if self.parent[v] != -1 && self.low[w] >= self.disc[v] {
          // Non-root with child that can't bypass v
          self.is_ap[v] = true
        }
      } else if w != self.parent[v] {
        // Back edge (not to parent in undirected graph)
        if self.disc[w] < self.low[v] {
          self.low[v] = self.disc[w]
        }
      }
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|ARTICULATION POINT DETECTION:
      #|
      #|For non-root vertex v with child w:
      #|  If low[w] >= disc[v], then w's subtree has no back edge to
      #|  any ancestor of v. Removing v disconnects w's subtree.
      #|
      #|For root vertex v:
      #|  If v has 2+ children in DFS tree, removing v disconnects them.
      #|  (Children can't reach each other without going through root)
      #|
      #|LOW-LINK UPDATE:
      #|  - Tree edge: low[v] = min(low[v], low[w])
      #|  - Back edge: low[v] = min(low[v], disc[w])
      #|
      #|Note: We skip the parent edge in undirected graphs to avoid
      #|treating the edge we came from as a back edge.
    ),
  }
}

///|
#warnings("-missing_invariant-missing_reasoning")
fn find_articulation_points(graph : Array[Array[Int]]) -> Array[Int] {
  let finder = ArticulationFinder::new(graph)
  for v in 0..<finder.n {
    if finder.disc[v] == -1 {
      finder.dfs(v)
    }
  }
  let aps : Array[Int] = []
  for v in 0..<finder.n {
    if finder.is_ap[v] {
      aps.push(v)
    }
  }
  aps
}

///|
test "articulation_points" {
  // Graph: 0 -- 1 -- 2 -- 3
  //             |    |
  //             4 -- 5
  // Articulation points: 1, 2
  let graph : Array[Array[Int]] = [
    [1], // 0
    [0, 2, 4], // 1
    [1, 3, 5], // 2
    [2], // 3
    [1, 5], // 4
    [2, 4], // 5
  ]
  let aps = find_articulation_points(graph)
  // Should find 1 and 2 as articulation points
  assert_eq(aps.length(), 2)
}

// ============================================================================
// BRIDGES (CUT EDGES)
// ============================================================================
//
// A bridge is an edge whose removal disconnects the graph.
//
// Edge (u, v) is a bridge iff low[v] > disc[u]
// (v's subtree has no back edge to u or any ancestor of u)

///|
priv struct BridgeFinder {
  graph : Array[Array[Int]]
  n : Int
  disc : Array[Int]
  low : Array[Int]
  parent : Array[Int]
  bridges : Array[(Int, Int)]
  mut time : Int
}

///|
fn BridgeFinder::new(graph : Array[Array[Int]]) -> BridgeFinder {
  let n = graph.length()
  {
    graph,
    n,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    parent: Array::make(n, -1),
    bridges: [],
    time: 0,
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn BridgeFinder::dfs(self : BridgeFinder, v : Int) -> Unit {
  self.disc[v] = self.time
  self.low[v] = self.time
  self.time = self.time + 1
  let neighbors = self.graph[v]
  for i = 0 {
    if i >= neighbors.length() {
      break
    } else {
      let w = neighbors[i]
      if self.disc[w] == -1 {
        self.parent[w] = v
        self.dfs(w)
        if self.low[w] < self.low[v] {
          self.low[v] = self.low[w]
        }
        // Bridge condition: stricter than articulation point
        if self.low[w] > self.disc[v] {
          self.bridges.push((v, w))
        }
      } else if w != self.parent[v] {
        if self.disc[w] < self.low[v] {
          self.low[v] = self.disc[w]
        }
      }
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|BRIDGE DETECTION:
      #|
      #|Edge (v, w) is a bridge iff low[w] > disc[v].
      #|
      #|This means: the lowest discovery time reachable from w's subtree
      #|is still greater than v's discovery time.
      #|
      #|In other words: there's no back edge from w's subtree to v or
      #|any ancestor of v. The ONLY way to reach v from w is through
      #|edge (v, w), making it a bridge.
      #|
      #|DIFFERENCE FROM ARTICULATION POINT:
      #|  - Articulation: low[w] >= disc[v] (includes equality)
      #|  - Bridge: low[w] > disc[v] (strictly greater)
      #|
      #|If low[w] == disc[v], there's a back edge to v itself,
      #|so the edge (v, w) is part of a cycle and NOT a bridge.
    ),
  }
}

///|
#warnings("-missing_invariant-missing_reasoning")
fn find_bridges(graph : Array[Array[Int]]) -> Array[(Int, Int)] {
  let finder = BridgeFinder::new(graph)
  for v in 0..<finder.n {
    if finder.disc[v] == -1 {
      finder.dfs(v)
    }
  }
  finder.bridges
}

///|
test "bridges" {
  // Graph: 0 -- 1 -- 2 -- 3
  //             |    |
  //             4 -- 5
  // Bridges: (0,1), (2,3)
  let graph : Array[Array[Int]] = [
    [1],
    [0, 2, 4],
    [1, 3, 5],
    [2],
    [1, 5],
    [2, 4],
  ]
  let bridges = find_bridges(graph)
  // Should find 2 bridges
  assert_eq(bridges.length(), 2)
}

// ============================================================================
// TOPOLOGICAL SORT VIA DFS (with cycle detection)
// ============================================================================
//
// In a DAG, topological order = reverse of DFS finish times.
// If we detect a back edge during DFS, the graph has a cycle.

///|
priv struct TopologicalSort {
  graph : Array[Array[Int]]
  n : Int
  state : Array[Int] // 0: unvisited, 1: visiting, 2: visited
  result : Array[Int]
  mut has_cycle : Bool
}

///|
fn TopologicalSort::new(graph : Array[Array[Int]]) -> TopologicalSort {
  let n = graph.length()
  { graph, n, state: Array::make(n, 0), result: [], has_cycle: false }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn TopologicalSort::dfs(self : TopologicalSort, v : Int) -> Unit {
  if self.has_cycle {
    return
  }
  self.state[v] = 1 // Visiting
  let neighbors = self.graph[v]
  for i = 0 {
    if i >= neighbors.length() || self.has_cycle {
      break
    } else {
      let w = neighbors[i]
      if self.state[w] == 1 {
        // Back edge: cycle detected
        self.has_cycle = true
      } else if self.state[w] == 0 {
        self.dfs(w)
      }
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|CYCLE DETECTION:
      #|If we reach a vertex with state 1 (currently being visited),
      #|we've found a back edge, which means a cycle exists.
      #|
      #|THREE STATES:
      #|  0 (unvisited): Not yet reached
      #|  1 (visiting): On current DFS path (ancestors)
      #|  2 (visited): Completely processed
      #|
      #|A back edge goes from current vertex to a visiting vertex.
    ),
  }
  self.state[v] = 2 // Visited
  self.result.push(v) // Post-order
}

///|
#warnings("-missing_invariant-missing_reasoning")
fn topological_sort_dfs(graph : Array[Array[Int]]) -> Array[Int]? {
  let ts = TopologicalSort::new(graph)
  for v in 0..<ts.n {
    if ts.state[v] == 0 {
      ts.dfs(v)
    }
  }
  if ts.has_cycle {
    None
  } else {
    // Reverse to get topological order
    Some(ts.result.rev())
  }
}

///|
test "topological_sort" {
  // DAG: 0 → 1 → 2
  //      ↓
  //      3 → 4
  let graph : Array[Array[Int]] = [
    [1, 3], // 0 → 1, 3
    [2], // 1 → 2
    [], // 2
    [4], // 3 → 4
    [],
  ] // 4
  let result = topological_sort_dfs(graph)
  guard result is Some(order) else { panic() }
  assert_eq(order.length(), 5)
  // 0 should come before 1, 3
  // 1 should come before 2
  // 3 should come before 4
}

///|
test "topological_sort_cycle" {
  // Graph with cycle: 0 → 1 → 2 → 0
  let graph : Array[Array[Int]] = [[1], [2], [0]]
  let result = topological_sort_dfs(graph)
  assert_true(result is None) // Cycle detected
}

// ============================================================================
// WHY TARJAN'S ALGORITHM WORKS: DEEP INSIGHT
// ============================================================================
//
// THE KEY INVARIANT:
// After DFS from vertex v completes, low[v] equals the minimum discovery time
// of any vertex reachable from v that is still on the stack.
//
// WHY disc[v] == low[v] MEANS v IS AN SCC ROOT:
//
// 1. If low[v] < disc[v]:
//    Some vertex in v's subtree can reach a vertex discovered before v
//    that's still on the stack. This means v is not the root - there's
//    an earlier vertex in the same SCC.
//
// 2. If low[v] == disc[v]:
//    No vertex in v's subtree can reach any vertex discovered before v
//    that's still on the stack. This means:
//    - v is the first vertex of its SCC to be discovered
//    - All vertices discovered after v that are in the same SCC are
//      currently on the stack (between v and the top)
//
// THE STACK INVARIANT:
// At any point during DFS, the stack contains a path from the first
// visited vertex to the current vertex, with each vertex being the
// root of some subtree. When we pop vertices for an SCC, we're removing
// exactly the vertices that form a strongly connected component.
//
// COMPLEXITY: O(V + E)
// - Each vertex is visited once (pushed/popped from stack once)
// - Each edge is examined once
// - Low-link updates are O(1)
