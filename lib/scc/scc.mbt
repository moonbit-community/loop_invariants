// ============================================================================
// STRONGLY CONNECTED COMPONENTS (SCC) - Tarjan's Algorithm
// ============================================================================
//
// A Strongly Connected Component (SCC) is a maximal set of vertices where
// every vertex is reachable from every other vertex in the set.
//
// KEY INSIGHT: SCCs form a DAG when contracted. Tarjan's algorithm finds
// SCCs in a single DFS pass using discovery times and low-link values.
//
// TARJAN'S ALGORITHM:
// - disc[v]: Discovery time of v (when first visited)
// - low[v]: Lowest discovery time reachable from v's subtree
// - A node is the root of an SCC if disc[v] == low[v]
//
// LOW-LINK VALUE:
// low[v] = min of:
//   1. disc[v] itself
//   2. disc[u] for any u on stack reachable via back edge
//   3. low[w] for any child w in DFS tree
//
// STACK USAGE:
// - Push vertex when first visited
// - Pop all vertices until current when SCC root is found
//
// EXAMPLE:
// Graph: 0 → 1 → 2 → 0 (cycle), 2 → 3
//
// DFS from 0:
// Visit 0: disc[0]=0, low[0]=0, push 0
// Visit 1: disc[1]=1, low[1]=1, push 1
// Visit 2: disc[2]=2, low[2]=2, push 2
//   - Edge 2→0: 0 on stack, low[2]=min(2,0)=0
//   - Edge 2→3: visit 3
// Visit 3: disc[3]=3, low[3]=3, push 3
//   - No outgoing edges, disc[3]==low[3], pop {3} as SCC
// Back to 2: low[2]=0
// Back to 1: low[1]=min(1,0)=0
// Back to 0: low[0]=0, disc[0]==low[0], pop {0,1,2} as SCC
//
// INVARIANTS:
// 1. disc[v] is assigned exactly once, in DFS order
// 2. low[v] is the minimum disc[] reachable from v's DFS subtree
// 3. Stack contains exactly the nodes in the current DFS path and their descendants
// 4. When disc[v] == low[v], all nodes above v in stack form an SCC
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V)

///|
/// Result of SCC computation
pub(all) struct SCCResult {
  num_sccs : Int
  component : Array[Int] // component[v] = SCC index of vertex v
  scc_sizes : Array[Int] // scc_sizes[i] = size of SCC i
  scc_adj : Array[Array[Int]] // Condensation graph (DAG of SCCs)
}

///|
/// Find all SCCs using Tarjan's algorithm
/// Returns SCCResult with component assignments and condensation graph
///
/// ALGORITHM:
/// 1. DFS with discovery times and low-link values
/// 2. Maintain stack of vertices in current DFS path
/// 3. When disc[v] == low[v], pop SCC from stack
pub fn find_sccs(n : Int, adj : Array[Array[Int]]) -> SCCResult {
  if n == 0 {
    return { num_sccs: 0, component: [], scc_sizes: [], scc_adj: [] }
  }
  let disc = Array::make(n, -1)
  let low = Array::make(n, -1)
  let on_stack = Array::make(n, false)
  let component = Array::make(n, -1)
  let stack : Array[Int] = []
  let timer : Counter = { val: 0 }
  let scc_count : Counter = { val: 0 }
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
      #|INVARIANT (Full coverage):
      #|Vertices in [0..v) are fully processed: each has disc != -1, was pushed
      #|and popped exactly once, and belongs to exactly one SCC.
      #|
      #|If disc[v] == -1, v is the root of a new DFS tree, which discovers and
      #|assigns all vertices in that connected region. This guarantees all SCCs
      #|are found even when the graph is disconnected.
      #|
      #|Termination: v increases to n, so every vertex is either visited or
      #|skipped as already visited. Total cost is O(V+E).
    ),
  }

  // Build condensation graph (DAG of SCCs)
  let num_sccs = scc_count.val
  let scc_adj : Array[Array[Int]] = []
  for _ in 0..<num_sccs {
    scc_adj.push([])
  }

  // Add edges between SCCs (avoiding duplicates with set-like approach)
  for u = 0; u < n; u = u + 1 {
    let comp_u = component[u]
    for j = 0; j < adj[u].length(); j = j + 1 {
      let v = adj[u][j]
      let comp_v = component[v]
      if comp_u != comp_v {
        // Check if edge already exists
        let mut exists = false
        for k = 0; k < scc_adj[comp_u].length(); k = k + 1 {
          if scc_adj[comp_u][k] == comp_v {
            exists = true
            break
          }
        } where {
          invariant: k >= 0 && k <= scc_adj[comp_u].length(),
          reasoning: (
            #|INVARIANT (Duplicate check):
            #|exists is true iff comp_v appears in scc_adj[comp_u][0..k).
            #|By scanning the current adjacency list, we ensure each SCC edge
            #|is inserted at most once, keeping the condensation graph simple.
          ),
        }
        if not(exists) {
          scc_adj[comp_u].push(comp_v)
        }
      }
    } where {
      invariant: j >= 0 && j <= adj[u].length(),
      reasoning: (
        #|INVARIANT (Outgoing SCC edges):
        #|For fixed u, neighbors in adj[u][0..j) have been processed. For each
        #|edge u -> v crossing components, we add comp_u -> comp_v once.
        #|After j reaches deg(u), all outgoing SCC edges from u are recorded.
      ),
    }
  } where {
    invariant: u >= 0 && u <= n,
    reasoning: (
      #|INVARIANT (Condensation construction):
      #|All edges originating from vertices [0..u) have been considered, so
      #|scc_adj contains every SCC edge induced by those vertices. The loop
      #|finishes once all vertices have been scanned.
    ),
  }
  { num_sccs, component, scc_sizes, scc_adj }
}

///|
priv struct Counter {
  mut val : Int
}

///|
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
  // Initialize discovery time and low-link value
  disc[v] = timer.val
  low[v] = timer.val
  timer.val = timer.val + 1
  stack.push(v)
  on_stack[v] = true

  // Explore neighbors
  // INVARIANT: low[v] is min disc[] reachable from v's subtree so far
  for i = 0; i < adj[v].length(); i = i + 1 {
    let u = adj[v][i]
    if disc[u] == -1 {
      // Tree edge: recurse
      tarjan_dfs(
        u, adj, disc, low, on_stack, stack, component, timer, scc_count, scc_sizes,
      )
      // After returning, update low[v]
      if low[u] < low[v] {
        low[v] = low[u]
      }
    } else if on_stack[u] {
      // Back edge to ancestor on stack
      if disc[u] < low[v] {
        low[v] = disc[u]
      }
    }
    // Cross edge to finished vertex - ignore
  } where {
    invariant: i >= 0 && i <= adj[v].length(),
    reasoning: (
      #|INVARIANT (Low-link maintenance):
      #|After processing neighbors[0..i), low[v] equals the minimum discovery
      #|time reachable from v via any path that stays within the current DFS
      #|stack. This includes:
      #|  - disc[v] itself,
      #|  - low[u] for tree edges v -> u already explored,
      #|  - disc[u] for back edges to on-stack ancestors.
      #|
      #|Edges to finished vertices are ignored because they lead to other SCCs
      #|and cannot reduce low[v] inside the current SCC.
      #|
      #|When the loop ends, low[v] is final. If low[v] == disc[v], v is the
      #|root of its SCC, so the stack suffix up to v forms one component.
    ),
  }

  // If v is root of SCC (disc[v] == low[v])
  // INVARIANT: All vertices above v in stack belong to same SCC
  if disc[v] == low[v] {
    let scc_id = scc_count.val
    scc_count.val = scc_count.val + 1
    let mut size = 0

    // Pop all vertices until v
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
      invariant: stack.length() > 0 && size >= 0,
      reasoning: (
        #|INVARIANT (SCC pop):
        #|All vertices popped so far belong to the SCC rooted at v, are removed
        #|from the stack, and are labeled with scc_id. size counts how many
        #|vertices have been assigned to this SCC.
        #|
        #|We stop exactly when v is popped, which is the root with
        #|disc[v] == low[v]. The popped suffix is contiguous in the stack,
        #|so no vertex is skipped or assigned twice.
      ),
    }
    scc_sizes.push(size)
  }
}

// ============================================================================
// KOSARAJU'S ALGORITHM (Alternative)
// ============================================================================

///|
/// Find SCCs using Kosaraju's algorithm
/// Alternative approach using two DFS passes
///
/// ALGORITHM:
/// 1. First DFS: Record finish times in order
/// 2. Transpose graph
/// 3. Second DFS: Process vertices in reverse finish order
pub fn find_sccs_kosaraju(n : Int, adj : Array[Array[Int]]) -> SCCResult {
  if n == 0 {
    return { num_sccs: 0, component: [], scc_sizes: [], scc_adj: [] }
  }
  let visited = Array::make(n, false)
  let order : Array[Int] = []

  // First DFS: fill order by finish time
  for v = 0; v < n; v = v + 1 {
    if not(visited[v]) {
      dfs_order(v, adj, visited, order)
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (Finish order):
      #|After processing vertices [0..v), every visited vertex is appended to
      #|order in post-order (after all its descendants). Thus for any edge
      #|u -> w discovered so far, u appears after w in order.
      #|
      #|This property ensures SCCs are ordered by decreasing finish time:
      #|if SCC A can reach SCC B, then every vertex in A finishes after all
      #|vertices in B. The second pass will therefore start from sink SCCs.
    ),
  }

  // Transpose graph
  let radj : Array[Array[Int]] = []
  for _ in 0..<n {
    radj.push([])
  }
  for u = 0; u < n; u = u + 1 {
    for j = 0; j < adj[u].length(); j = j + 1 {
      let v = adj[u][j]
      radj[v].push(u)
    } where {
      invariant: j >= 0 && j <= adj[u].length(),
      reasoning: (
        #|INVARIANT (Transpose per vertex):
        #|For fixed u, edges adj[u][0..j) have been reversed into radj,
        #|so each original edge u -> v becomes v -> u in the transpose.
      ),
    }
  } where {
    invariant: u >= 0 && u <= n,
    reasoning: (
      #|INVARIANT (Full transpose):
      #|All edges from vertices [0..u) have been reversed into radj.
      #|After u reaches n, radj is exactly the transpose of adj.
    ),
  }

  // Second DFS: process in reverse finish order
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
      #|INVARIANT (Second pass correctness):
      #|Vertices with finish-order index > i are already assigned to SCCs.
      #|We process the next unassigned vertex v with the largest remaining
      #|finish time and run DFS on the transposed graph.
      #|
      #|Because of finish-order properties, this DFS cannot reach vertices in
      #|a different SCC that were not already assigned. Thus it collects
      #|exactly v's SCC, and we assign all of them the current scc_count.
      #|
      #|Processing in reverse finish order yields SCCs in reverse topological
      #|order of the condensation DAG.
    ),
  }

  // Build condensation graph
  let scc_adj : Array[Array[Int]] = []
  for _ in 0..<scc_count {
    scc_adj.push([])
  }
  for u = 0; u < n; u = u + 1 {
    let comp_u = component[u]
    for j = 0; j < adj[u].length(); j = j + 1 {
      let v = adj[u][j]
      let comp_v = component[v]
      if comp_u != comp_v {
        let mut exists = false
        for k = 0; k < scc_adj[comp_u].length(); k = k + 1 {
          if scc_adj[comp_u][k] == comp_v {
            exists = true
            break
          }
        } where {
          invariant: k >= 0 && k <= scc_adj[comp_u].length(),
          reasoning: (
            #|INVARIANT (Duplicate check):
            #|exists is true iff comp_v already appears in scc_adj[comp_u][0..k).
            #|This prevents parallel edges in the condensation graph.
          ),
        }
        if not(exists) {
          scc_adj[comp_u].push(comp_v)
        }
      }
    } where {
      invariant: j >= 0 && j <= adj[u].length(),
      reasoning: (
        #|INVARIANT (Outgoing SCC edges):
        #|For fixed u, neighbors in adj[u][0..j) have been processed. Each edge
        #|u -> v crossing components contributes a single edge comp_u -> comp_v.
      ),
    }
  } where {
    invariant: u >= 0 && u <= n,
    reasoning: (
      #|INVARIANT (Condensation construction):
      #|All edges from vertices [0..u) have been mapped to SCC edges.
      #|After u reaches n, scc_adj is the full condensation DAG.
    ),
  }
  { num_sccs: scc_count, component, scc_sizes, scc_adj }
}

///|
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
      #|INVARIANT (DFS expansion):
      #|After processing neighbors[0..i), all vertices reachable from v through
      #|those neighbors are marked visited and will appear before v in order.
    ),
  }
  order.push(v)
}

///|
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
      #|After processing neighbors[0..i), every vertex reachable from v via
      #|those edges has component == scc_id. The DFS assigns exactly the
      #|vertices in this SCC and no others.
    ),
  }
}

// ============================================================================
// 2-SAT SOLVER USING SCC
// ============================================================================

///|
/// 2-SAT problem structure
priv struct TwoSAT {
  n : Int // Number of variables
  adj : Array[Array[Int]] // Implication graph
}

///|
/// Create a new 2-SAT instance with n variables
fn TwoSAT::new(n : Int) -> TwoSAT {
  let adj : Array[Array[Int]] = []
  for _ in 0..<(2 * n) {
    adj.push([])
  }
  { n, adj }
}

///|
/// Convert variable and sign to vertex index
/// x: variable (0 to n-1), neg: true if negated
fn var_to_vertex(n : Int, x : Int, neg : Bool) -> Int {
  if neg {
    x + n
  } else {
    x
  }
}

///|
/// Add clause (a OR b)
/// Equivalent to: NOT a => b AND NOT b => a
fn TwoSAT::add_clause(
  self : TwoSAT,
  a : Int,
  neg_a : Bool,
  b : Int,
  neg_b : Bool,
) -> Unit {
  // NOT a => b
  let from_a = var_to_vertex(self.n, a, not(neg_a))
  let to_b = var_to_vertex(self.n, b, neg_b)
  self.adj[from_a].push(to_b)

  // NOT b => a
  let from_b = var_to_vertex(self.n, b, not(neg_b))
  let to_a = var_to_vertex(self.n, a, neg_a)
  self.adj[from_b].push(to_a)
}

///|
/// Solve 2-SAT and return variable assignments
/// Returns None if unsatisfiable
fn TwoSAT::solve(self : TwoSAT) -> Array[Bool]? {
  let result = find_sccs(2 * self.n, self.adj)

  // Check satisfiability: x and NOT x must be in different SCCs
  for x in 0..<self.n {
    if result.component[x] == result.component[x + self.n] {
      return None // x and NOT x in same SCC - unsatisfiable
    }
  }

  // Assign values: x = true if x's SCC has higher index than NOT x's SCC
  // (SCCs are numbered in reverse topological order by Tarjan's)
  let assignment = Array::make(self.n, false)
  for x in 0..<self.n {
    assignment[x] = result.component[x] > result.component[x + self.n]
  }
  Some(assignment)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "scc single cycle" {
  // 0 → 1 → 2 → 0 (single SCC)
  let adj : Array[Array[Int]] = [[1], [2], [0]]
  let result = find_sccs(3, adj)
  inspect(result.num_sccs, content="1")
  inspect(result.component[0] == result.component[1], content="true")
  inspect(result.component[1] == result.component[2], content="true")
}

///|
test "scc two components" {
  // 0 → 1, 2 → 3 (two separate edges, no cycles)
  let adj : Array[Array[Int]] = [[1], [], [3], []]
  let result = find_sccs(4, adj)
  inspect(result.num_sccs, content="4") // Each node is its own SCC
}

///|
test "scc with dag" {
  // 0 → 1 → 2 → 0, 2 → 3
  // SCC: {0,1,2}, {3}
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let result = find_sccs(4, adj)
  inspect(result.num_sccs, content="2")
  // {0,1,2} should be in same SCC
  inspect(result.component[0] == result.component[1], content="true")
  inspect(result.component[1] == result.component[2], content="true")
  // {3} should be different
  inspect(result.component[2] != result.component[3], content="true")
}

///|
test "scc kosaraju same result" {
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let tarjan = find_sccs(4, adj)
  let kosaraju = find_sccs_kosaraju(4, adj)
  inspect(tarjan.num_sccs == kosaraju.num_sccs, content="true")
}

///|
test "scc condensation graph" {
  // 0 → 1 → 2 → 0, 2 → 3
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let result = find_sccs(4, adj)

  // Condensation graph should have edge from {0,1,2}'s SCC to {3}'s SCC
  let scc_012 = result.component[0]
  let scc_3 = result.component[3]
  let mut has_edge = false
  for i in 0..<result.scc_adj[scc_012].length() {
    if result.scc_adj[scc_012][i] == scc_3 {
      has_edge = true
    }
  }
  inspect(has_edge, content="true")
}

///|
test "scc empty" {
  let adj : Array[Array[Int]] = []
  let result = find_sccs(0, adj)
  inspect(result.num_sccs, content="0")
}

///|
test "scc single vertex" {
  let adj : Array[Array[Int]] = [[]]
  let result = find_sccs(1, adj)
  inspect(result.num_sccs, content="1")
  inspect(result.component[0], content="0")
}

///|
test "scc self loop" {
  let adj : Array[Array[Int]] = [[0]]
  let result = find_sccs(1, adj)
  inspect(result.num_sccs, content="1")
}

///|
test "two sat satisfiable" {
  // (x0 OR x1) AND (NOT x0 OR x1) AND (x0 OR NOT x1)
  let sat = TwoSAT::new(2)
  sat.add_clause(0, false, 1, false) // x0 OR x1
  sat.add_clause(0, true, 1, false) // NOT x0 OR x1
  sat.add_clause(0, false, 1, true) // x0 OR NOT x1
  match sat.solve() {
    Some(assignment) =>
      // x0=true, x1=true satisfies all clauses
      inspect(assignment.length(), content="2")
    None => fail("Should be satisfiable")
  }
}

///|
test "two sat unsatisfiable" {
  // (x0 OR x0) AND (NOT x0 OR NOT x0) = x0 AND NOT x0
  let sat = TwoSAT::new(1)
  sat.add_clause(0, false, 0, false) // x0 OR x0 = x0
  sat.add_clause(0, true, 0, true) // NOT x0 OR NOT x0 = NOT x0
  match sat.solve() {
    Some(_) => fail("Should be unsatisfiable")
    None => ()
  }
}

///|
test "scc sizes" {
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let result = find_sccs(4, adj)

  // Total sizes should equal n
  let mut total = 0
  for i = 0; i < result.scc_sizes.length(); i = i + 1 {
    total = total + result.scc_sizes[i]
  } where {
    invariant: i >= 0 && i <= result.scc_sizes.length(),
    reasoning: (
      #|INVARIANT (sum sizes):
      #|total equals the sum of scc_sizes for indices in [0, i).
      #|MAINTENANCE:
      #|Add scc_sizes[i] to the running total.
      #|TERMINATION:
      #|At i = scc_sizes.length(), total equals n.
    ),
  }
  inspect(total, content="4")
}

///|
test "scc complex" {
  // Two cycles connected
  // 0 → 1 → 0, 2 → 3 → 2, 1 → 2
  let adj : Array[Array[Int]] = [[1], [0, 2], [3], [2]]
  let result = find_sccs(4, adj)
  inspect(result.num_sccs, content="2")
  // {0,1} same SCC
  inspect(result.component[0] == result.component[1], content="true")
  // {2,3} same SCC
  inspect(result.component[2] == result.component[3], content="true")
}
