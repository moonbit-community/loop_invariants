// ============================================================================
// TOPOLOGICAL SORT (DFS) - Directed Acyclic Graph Ordering
// ============================================================================
//
// A topological order of a DAG is a linear ordering of vertices such that every
// directed edge (u -> v) goes from left to right (u appears before v).
//
// DFS METHOD:
// 1. Run DFS on unvisited vertices
// 2. When finishing a vertex, append it to an order list
// 3. Reverse the list to obtain a topological order
//
// CYCLE DETECTION:
// Use a color/state array:
//   0 = unvisited, 1 = visiting (in current DFS stack), 2 = done
// Encountering an edge to a visiting vertex indicates a cycle.
//
// INVARIANTS:
// 1. When a vertex is marked done, all its outgoing edges lead to done vertices.
// 2. The order list is a valid reverse topological order of finished vertices.
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V + E)

///|
/// Internal state for a single topological sort run.
///
/// Fields:
/// - `n`     — number of vertices (vertices are labelled 0 to n-1).
/// - `adj`   — adjacency list: `adj[u]` holds the successors of `u`.
/// - `state` — per-vertex DFS color: 0=unvisited, 1=visiting, 2=done.
/// - `order` — accumulates vertices in finish order (reversed at the end).
priv struct TopoSorter {
  n : Int
  adj : Array[Array[Int]]
  state : Array[Int]
  order : Array[Int]
}

///|
/// Creates a new `TopoSorter` for a graph with `n` vertices and no edges.
///
/// All vertices start in the unvisited state (state 0).
/// The finish list starts empty.
fn TopoSorter::new(n : Int) -> TopoSorter {
  let adj : Array[Array[Int]] = [ for _ in 0..<n => [] ]
  { n, adj, state: Array::make(n, 0), order: [] }
}

///|
/// Adds a directed edge `u -> v` to the adjacency list.
///
/// Both `u` and `v` must be valid vertex indices (0 to n-1).
/// Out-of-range indices are rejected by the public `topological_sort`
/// function before `add_edge` is called.
fn TopoSorter::add_edge(self : TopoSorter, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
}

///|
/// Runs a single DFS from vertex `u`, using the three-color state scheme.
///
/// State transitions during a call:
///   unvisited (0) -> visiting (1) -> done (2)
///
/// Returns `true` if the DFS completed without detecting a cycle.
/// Returns `false` immediately if any edge leads to a visiting vertex
/// (state 1), which indicates a back edge and therefore a cycle.
///
/// When the call returns `true`, `u` is appended to `self.order`.
/// The finish list therefore grows in post-order; reversing it yields a
/// valid topological order.
fn TopoSorter::dfs(self : TopoSorter, u : Int) -> Bool {
  self.state[u] = 1
  let ok = for v in self.adj[u] {
    if self.state[v] == 0 {
      if !self.dfs(v) {
        break false
      }
    } else if self.state[v] == 1 {
      break false
    }
  } nobreak {
    true
  }
  if !ok {
    return false
  }
  self.state[u] = 2
  self.order.push(u)
  true
}

///|
/// Runs DFS from every unvisited vertex and builds the topological order.
///
/// The outer loop visits vertices 0, 1, ..., n-1 in order.  Only unvisited
/// vertices trigger a new DFS call; vertices that were already reached as
/// part of an earlier call are skipped.
///
/// Loop invariant: at the start of iteration `v`, every vertex in `[0, v)`
/// has been processed successfully (state 2 or skipped due to cycle).
///
/// Returns `Some(order)` — the topological order — when no cycle is found.
/// Returns `None` as soon as a cycle is detected.
fn TopoSorter::sort(self : TopoSorter) -> Array[Int]? {
  let ok = for v in 0..<self.n {
    if self.state[v] == 0 {
      if !self.dfs(v) {
        break false
      }
    }
  } nobreak {
    true
  } where {
    proof_invariant: v >= 0 && v <= self.n,
    proof_reasoning: (
      #|INVARIANT (full coverage):
      #|Vertices in [0..v) have already been processed successfully.
      #|MAINTENANCE:
      #|If v is unvisited, run DFS; otherwise skip it. A detected cycle exits
      #|the loop immediately with false.
      #|TERMINATION:
      #|At v = n, all vertices are processed.
    ),
  }
  if !ok {
    None
  } else {
    self.order.rev_in_place()
    Some(self.order)
  }
}

///|
/// Returns a topological ordering of the vertices of a directed acyclic graph
/// (DAG), or `None` if the graph contains a cycle.
///
/// Parameters:
/// - `n`     — number of vertices, labelled 0 to `n-1`.
/// - `edges` — directed edges as `(u, v)` pairs, meaning vertex `u` must
///             appear before vertex `v` in the output.
///
/// Return value:
/// - `Some(order)` — a permutation of `[0, n-1]` in which every edge
///   `(u, v)` satisfies `position(u) < position(v)`.
/// - `None`        — the graph contains a directed cycle so no topological
///   order exists.
///
/// Edge cases:
/// - `n <= 0` returns `Some([])`.
/// - Edges whose endpoints are outside `[0, n)` are silently ignored.
///
/// Time:  `O(V + E)` where `V = n` and `E = edges.length()`.
/// Space: `O(V + E)` for the adjacency list and DFS state.
///
/// Example:
///
/// ```
/// // Chain: 0 -> 1 -> 2 -> 3
/// let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
/// @topological_sort_dfs.topological_sort(4, edges[:])
/// // => Some([0, 1, 2, 3])
/// ```
pub fn topological_sort(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]? {
  if n <= 0 {
    return Some([])
  }
  let sorter = TopoSorter::new(n)
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      sorter.add_edge(u, v)
    }
  }
  sorter.sort()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "topological sort basic" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let order = topological_sort(4, edges).unwrap()
  // Validate order by checking edge directions
  let pos = Array::make(4, 0)
  for i, v in order {
    pos[v] = i
  }
  let ok = edges.all(edge => {
    let (u, v) = edge
    pos[u] < pos[v]
  })
  inspect(ok, content="true")
}

///|
test "topological sort cycle" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  inspect(topological_sort(3, edges), content="None")
}
