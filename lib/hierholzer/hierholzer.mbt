// ============================================================================
// HIERHOLZER'S ALGORITHM - Eulerian Path/Circuit
// ============================================================================
//
// Finds an Eulerian path (visits every edge exactly once) or circuit
// (Eulerian path that starts and ends at same vertex) in a graph.
//
// EXISTENCE CONDITIONS:
// - Eulerian Circuit: All vertices have even degree
// - Eulerian Path: Exactly 0 or 2 vertices have odd degree
//   (path starts at one odd-degree vertex, ends at the other)
//
// ALGORITHM:
// 1. Start at appropriate vertex (odd degree for path, any for circuit)
// 2. Follow edges, removing them as we go, until stuck
// 3. Backtrack and insert sub-circuits at vertices with remaining edges
//
// KEY INSIGHT: When we get stuck, we've found a circuit. If there are
// remaining edges, they form sub-circuits that can be spliced in.
//
// INVARIANTS:
// 1. Each edge is visited exactly once
// 2. At any point, removed edges form a valid path/circuit
// 3. Vertices with remaining edges are on the current path
//
// TIME COMPLEXITY: O(E)
// SPACE COMPLEXITY: O(E)

///|
priv struct EulerGraph {
  n : Int
  adj : Array[Array[(Int, Int)]] // (neighbor, edge_id)
  edge_used : Array[Bool]
  edge_count : Int
}

///|
fn EulerGraph::new(n : Int) -> EulerGraph {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  { n, adj, edge_used: [], edge_count: 0 }
}

///|
fn EulerGraph::add_edge(self : EulerGraph, u : Int, v : Int) -> Unit {
  let edge_id = self.edge_count
  self.adj[u].push((v, edge_id))
  self.adj[v].push((u, edge_id))
  self.edge_used.push(false)
  // Manually increment edge_count by creating new struct
  // Actually we need to track this differently since edge_count is immutable
}

///|
priv struct EulerGraphMut {
  n : Int
  adj : Array[Array[(Int, Int)]] // (neighbor, edge_id)
  edge_used : Array[Bool]
  mut edge_count : Int
  adj_idx : Array[Int] // Current index in adjacency list for each vertex
}

///|
fn EulerGraphMut::new(n : Int) -> EulerGraphMut {
  let adj = Array::make(n, [])
  let adj_idx = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  { n, adj, edge_used: [], edge_count: 0, adj_idx }
}

///|
fn EulerGraphMut::add_undirected_edge(self : EulerGraphMut, u : Int, v : Int) -> Unit {
  let edge_id = self.edge_count
  self.adj[u].push((v, edge_id))
  self.adj[v].push((u, edge_id))
  self.edge_used.push(false)
  self.edge_count = self.edge_count + 1
}

///|
fn EulerGraphMut::add_directed_edge(self : EulerGraphMut, u : Int, v : Int) -> Unit {
  let edge_id = self.edge_count
  self.adj[u].push((v, edge_id))
  self.edge_used.push(false)
  self.edge_count = self.edge_count + 1
}

///|
fn EulerGraphMut::degree(self : EulerGraphMut, v : Int) -> Int {
  self.adj[v].length()
}

///|
/// Check if undirected graph has Eulerian path/circuit
fn EulerGraphMut::has_eulerian_path_undirected(self : EulerGraphMut) -> Bool {
  let mut odd_count = 0
  for i = 0; i < self.n; i = i + 1 {
    if self.degree(i) % 2 == 1 {
      odd_count = odd_count + 1
    }
  }
  // 0 odd vertices = circuit exists
  // 2 odd vertices = path exists
  odd_count == 0 || odd_count == 2
}

///|
/// Find start vertex for Eulerian path in undirected graph
fn EulerGraphMut::find_start_undirected(self : EulerGraphMut) -> Int? {
  let mut start = -1
  let mut odd_vertex = -1

  for i = 0; i < self.n; i = i + 1 {
    if self.degree(i) > 0 {
      if start < 0 {
        start = i
      }
      if self.degree(i) % 2 == 1 {
        odd_vertex = i
      }
    }
  }

  if start < 0 {
    return None // No edges
  }

  if odd_vertex >= 0 {
    Some(odd_vertex) // Start from odd-degree vertex for path
  } else {
    Some(start) // Any vertex for circuit
  }
}

///|
/// Hierholzer's algorithm for undirected graph
fn EulerGraphMut::find_eulerian_path_undirected(self : EulerGraphMut) -> Array[Int]? {
  if not(self.has_eulerian_path_undirected()) {
    return None
  }

  match self.find_start_undirected() {
    None => Some([])
    Some(start) => {
      let path : Array[Int] = []
      let stack : Array[Int] = [start]

      while stack.length() > 0 {
        let v = stack[stack.length() - 1]

        // Find unused edge
        let mut found = false
        while self.adj_idx[v] < self.adj[v].length() {
          let (u, edge_id) = self.adj[v][self.adj_idx[v]]
          self.adj_idx[v] = self.adj_idx[v] + 1

          if not(self.edge_used[edge_id]) {
            self.edge_used[edge_id] = true
            stack.push(u)
            found = true
            break
          }
        }

        if not(found) {
          path.push(stack.pop().unwrap_or(-1))
        }
      }

      // Reverse to get correct order
      let result : Array[Int] = []
      for i = path.length() - 1; i >= 0; i = i - 1 {
        result.push(path[i])
      }
      Some(result)
    }
  }
}

// ============================================================================
// DIRECTED GRAPH VERSION
// ============================================================================

///|
priv struct DirectedEulerGraph {
  n : Int
  adj : Array[Array[(Int, Int)]] // (neighbor, edge_id)
  edge_used : Array[Bool]
  mut edge_count : Int
  adj_idx : Array[Int]
  in_degree : Array[Int]
  out_degree : Array[Int]
}

///|
fn DirectedEulerGraph::new(n : Int) -> DirectedEulerGraph {
  let adj = Array::make(n, [])
  let adj_idx = Array::make(n, 0)
  let in_degree = Array::make(n, 0)
  let out_degree = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  { n, adj, edge_used: [], edge_count: 0, adj_idx, in_degree, out_degree }
}

///|
fn DirectedEulerGraph::add_edge(self : DirectedEulerGraph, u : Int, v : Int) -> Unit {
  let edge_id = self.edge_count
  self.adj[u].push((v, edge_id))
  self.edge_used.push(false)
  self.edge_count = self.edge_count + 1
  self.out_degree[u] = self.out_degree[u] + 1
  self.in_degree[v] = self.in_degree[v] + 1
}

///|
/// Check if directed graph has Eulerian path/circuit
fn DirectedEulerGraph::has_eulerian_path(self : DirectedEulerGraph) -> Bool {
  let mut start_count = 0 // out - in = 1
  let mut end_count = 0   // in - out = 1

  for i = 0; i < self.n; i = i + 1 {
    let diff = self.out_degree[i] - self.in_degree[i]
    if diff == 1 {
      start_count = start_count + 1
    } else if diff == -1 {
      end_count = end_count + 1
    } else if diff != 0 {
      return false
    }
  }

  // Either all balanced (circuit) or exactly one start and one end (path)
  (start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1)
}

///|
/// Find start vertex for Eulerian path in directed graph
fn DirectedEulerGraph::find_start(self : DirectedEulerGraph) -> Int? {
  let mut start = -1
  let mut special_start = -1

  for i = 0; i < self.n; i = i + 1 {
    if self.out_degree[i] > 0 {
      if start < 0 {
        start = i
      }
      if self.out_degree[i] - self.in_degree[i] == 1 {
        special_start = i
      }
    }
  }

  if start < 0 {
    return None
  }

  if special_start >= 0 {
    Some(special_start)
  } else {
    Some(start)
  }
}

///|
/// Hierholzer's algorithm for directed graph
fn DirectedEulerGraph::find_eulerian_path(self : DirectedEulerGraph) -> Array[Int]? {
  if not(self.has_eulerian_path()) {
    return None
  }

  match self.find_start() {
    None => Some([])
    Some(start) => {
      let path : Array[Int] = []
      let stack : Array[Int] = [start]

      while stack.length() > 0 {
        let v = stack[stack.length() - 1]

        let mut found = false
        while self.adj_idx[v] < self.adj[v].length() {
          let (u, edge_id) = self.adj[v][self.adj_idx[v]]
          self.adj_idx[v] = self.adj_idx[v] + 1

          if not(self.edge_used[edge_id]) {
            self.edge_used[edge_id] = true
            stack.push(u)
            found = true
            break
          }
        }

        if not(found) {
          path.push(stack.pop().unwrap_or(-1))
        }
      }

      // Reverse
      let result : Array[Int] = []
      for i = path.length() - 1; i >= 0; i = i - 1 {
        result.push(path[i])
      }
      Some(result)
    }
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "eulerian circuit undirected" {
  // Triangle: 0-1-2-0
  let g = EulerGraphMut::new(3)
  g.add_undirected_edge(0, 1)
  g.add_undirected_edge(1, 2)
  g.add_undirected_edge(2, 0)

  match g.find_eulerian_path_undirected() {
    Some(path) => {
      // Should visit 4 vertices (3 edges + return)
      inspect(path.length(), content="4")
      // Should start and end at same vertex
      inspect(path[0] == path[path.length() - 1], content="true")
    }
    None => fail("Expected Eulerian circuit")
  }
}

///|
test "eulerian path undirected" {
  // Path: 0-1-2
  let g = EulerGraphMut::new(3)
  g.add_undirected_edge(0, 1)
  g.add_undirected_edge(1, 2)

  match g.find_eulerian_path_undirected() {
    Some(path) => {
      inspect(path.length(), content="3")
      // Should start at 0 or 2 (odd degree vertices)
      inspect((path[0] == 0 && path[2] == 2) || (path[0] == 2 && path[2] == 0), content="true")
    }
    None => fail("Expected Eulerian path")
  }
}

///|
test "no eulerian path undirected" {
  // Graph with 4 odd-degree vertices
  let g = EulerGraphMut::new(4)
  g.add_undirected_edge(0, 1)
  g.add_undirected_edge(2, 3)

  inspect(g.find_eulerian_path_undirected() is None, content="true")
}

///|
test "eulerian circuit directed" {
  // Directed triangle: 0->1->2->0
  let g = DirectedEulerGraph::new(3)
  g.add_edge(0, 1)
  g.add_edge(1, 2)
  g.add_edge(2, 0)

  match g.find_eulerian_path() {
    Some(path) => {
      inspect(path.length(), content="4")
      inspect(path[0] == path[path.length() - 1], content="true")
    }
    None => fail("Expected Eulerian circuit")
  }
}

///|
test "eulerian path directed" {
  // Directed path: 0->1->2
  let g = DirectedEulerGraph::new(3)
  g.add_edge(0, 1)
  g.add_edge(1, 2)

  match g.find_eulerian_path() {
    Some(path) => {
      inspect(path.length(), content="3")
      inspect(path[0], content="0")
      inspect(path[2], content="2")
    }
    None => fail("Expected Eulerian path")
  }
}

///|
test "complex eulerian circuit" {
  // Figure-8 graph
  let g = EulerGraphMut::new(5)
  g.add_undirected_edge(0, 1)
  g.add_undirected_edge(1, 2)
  g.add_undirected_edge(2, 0)
  g.add_undirected_edge(0, 3)
  g.add_undirected_edge(3, 4)
  g.add_undirected_edge(4, 0)

  match g.find_eulerian_path_undirected() {
    Some(path) => {
      // 6 edges means 7 vertices in path
      inspect(path.length(), content="7")
      inspect(path[0] == path[path.length() - 1], content="true")
    }
    None => fail("Expected Eulerian circuit")
  }
}

///|
test "empty graph" {
  let g = EulerGraphMut::new(3)
  match g.find_eulerian_path_undirected() {
    Some(path) => inspect(path.length(), content="0")
    None => fail("Empty graph should return empty path")
  }
}

///|
test "single vertex" {
  let g = EulerGraphMut::new(1)
  match g.find_eulerian_path_undirected() {
    Some(path) => inspect(path.length(), content="0")
    None => fail("Single vertex should return empty path")
  }
}
