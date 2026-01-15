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
priv struct TopoSorter {
  n : Int
  adj : Array[Array[Int]]
  state : Array[Int]
  order : Array[Int]
}

///|
fn TopoSorter::new(n : Int) -> TopoSorter {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (adj init):
      #|adj[0..i) are initialized empty lists.
      #|MAINTENANCE:
      #|Assign a fresh list to adj[i].
      #|TERMINATION:
      #|At i = n, all adjacency lists are ready.
    ),
  }
  { n, adj, state: Array::make(n, 0), order: [] }
}

///|
fn TopoSorter::add_edge(self : TopoSorter, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
}

///|
fn TopoSorter::dfs(self : TopoSorter, u : Int) -> Bool {
  self.state[u] = 1
  let mut ok = true
  for i = 0; i < self.adj[u].length(); i = i + 1 {
    if ok {
      let v = self.adj[u][i]
      if self.state[v] == 0 {
        if not(self.dfs(v)) {
          ok = false
        }
      } else if self.state[v] == 1 {
        ok = false
      }
    }
  } where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: (
      #|INVARIANT (DFS scan):
      #|For neighbors in adj[u][0..i), either they are fully processed (state=2)
      #|or a cycle has been detected and ok is false.
      #|MAINTENANCE:
      #|Recursing on an unvisited neighbor preserves the invariant; encountering
      #|state=1 marks a back edge and sets ok=false.
      #|TERMINATION:
      #|At i = deg(u), all outgoing edges from u are checked.
    ),
    invariant: ok || self.state[u] == 1,
    reasoning: (
      #|INVARIANT (cycle flag):
      #|If ok is false, a back edge has been seen in this DFS, so the graph is
      #|not a DAG. If ok is true, no such edge has been encountered so far.
      #|MAINTENANCE:
      #|ok is only set to false when a back edge is detected.
      #|TERMINATION:
      #|The flag correctly indicates whether the current DFS subtree is acyclic.
    ),
  }
  if not(ok) {
    return false
  }
  self.state[u] = 2
  self.order.push(u)
  true
}

///|
fn TopoSorter::sort(self : TopoSorter) -> Array[Int]? {
  let mut ok = true
  for v = 0; v < self.n; v = v + 1 {
    if self.state[v] == 0 {
      if not(self.dfs(v)) {
        ok = false
        break
      }
    }
  } where {
    invariant: v >= 0 && v <= self.n,
    reasoning: (
      #|INVARIANT (full coverage):
      #|Vertices in [0..v) are either processed (state=2) or a cycle has been
      #|detected and ok is false.
      #|MAINTENANCE:
      #|If v is unvisited, run DFS; otherwise skip it. A detected cycle flips ok.
      #|TERMINATION:
      #|At v = n, all vertices are processed or ok=false indicates a cycle.
    ),
  }
  if not(ok) {
    None
  } else {
    self.order.rev_in_place()
    Some(self.order)
  }
}

///|
/// Topological sort using DFS. Returns None if the graph has a cycle.
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
  let order = topological_sort(4, edges[:]).unwrap()
  // Validate order by checking edge directions
  let pos = Array::make(4, 0)
  for i, v in order {
    pos[v] = i
  }
  let ok = edges.all(fn(edge) {
    let (u, v) = edge
    pos[u] < pos[v]
  })
  inspect(ok, content="true")
}

///|
test "topological sort cycle" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  inspect(topological_sort(3, edges[:]), content="None")
}
