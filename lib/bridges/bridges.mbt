// ============================================================================
// ARTICULATION POINTS AND BRIDGES - Graph Connectivity
// ============================================================================
//
// Articulation points (cut vertices) are vertices whose removal disconnects
// the graph. Bridges (cut edges) are edges whose removal disconnects the graph.
//
// ALGORITHM (Tarjan's):
// Use DFS with discovery times and low values:
// - disc[u] = discovery time of vertex u
// - low[u] = minimum disc reachable from subtree of u via back edges
//
// ARTICULATION POINT RULES:
// 1. Root is articulation point if it has ≥ 2 children in DFS tree
// 2. Non-root u is articulation point if it has child v with low[v] >= disc[u]
//    (no back edge from v's subtree goes above u)
//
// BRIDGE RULE:
// Edge (u, v) is bridge if low[v] > disc[u]
// (no back edge from v's subtree reaches u or above)
//
// INVARIANTS:
// 1. low[u] = min(disc[u], disc[w]) for all back edges (u,w) and min(low[v]) for tree edges
// 2. disc values are unique and increasing
// 3. In DFS tree, parent edge is not counted in low calculation for bridges
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V)

///|
priv struct BridgeFinder {
  n : Int
  adj : Array[Array[Int]]
  disc : Array[Int]
  low : Array[Int]
  parent : Array[Int]
  mut timer : Int
  articulation_points : Array[Bool]
  bridges : Array[(Int, Int)]
}

///|
fn BridgeFinder::new(n : Int) -> BridgeFinder {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  {
    n,
    adj,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    parent: Array::make(n, -1),
    timer: 0,
    articulation_points: Array::make(n, false),
    bridges: [],
  }
}

///|
fn BridgeFinder::add_edge(self : BridgeFinder, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
fn BridgeFinder::dfs(self : BridgeFinder, u : Int, p : Int) -> Unit {
  self.disc[u] = self.timer
  self.low[u] = self.timer
  self.timer = self.timer + 1
  self.parent[u] = p
  let children = for i = 0, children = 0; i < self.adj[u].length(); {
    let v = self.adj[u][i]
    if self.disc[v] < 0 {
      // Tree edge
      self.dfs(v, u)

      // Update low[u] from child
      if self.low[v] < self.low[u] {
        self.low[u] = self.low[v]
      }

      // Check for articulation point (non-root case)
      if p >= 0 && self.low[v] >= self.disc[u] {
        self.articulation_points[u] = true
      }

      // Check for bridge
      if self.low[v] > self.disc[u] {
        self.bridges.push((u, v))
      }
      continue i + 1, children + 1
    } else if v != p {
      // Back edge (not to parent)
      if self.disc[v] < self.low[u] {
        self.low[u] = self.disc[v]
      }
      continue i + 1, children
    } else {
      continue i + 1, children
    }
  } else {
    children
  } where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: (
      #|INVARIANT (Tarjan DFS):
      #|disc[u] and low[u] are set, and neighbors in adj[u][0..i) have been
      #|processed with low[u] updated accordingly.
      #|MAINTENANCE:
      #|For tree edges, recurse and propagate low values; for back edges, update
      #|low[u] using disc[v]. Check articulation and bridge conditions per child.
      #|TERMINATION:
      #|At i = deg(u), low[u] reflects the minimum reachable discovery time from
      #|u's subtree, enabling correct bridge/articulation detection.
    ),
  }

  // Root articulation point check
  if p < 0 && children > 1 {
    self.articulation_points[u] = true
  }
}

///|
fn BridgeFinder::find(self : BridgeFinder) -> Unit {
  for i = 0; i < self.n; i = i + 1 {
    if self.disc[i] < 0 {
      self.dfs(i, -1)
    }
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (component scan):
      #|All vertices in [0, i) have been assigned to a DFS tree.
      #|MAINTENANCE:
      #|If vertex i is unvisited, start a DFS to cover its component.
      #|TERMINATION:
      #|At i = n, all connected components have been processed.
    ),
  }
}

///|
fn BridgeFinder::get_articulation_points(self : BridgeFinder) -> Array[Int] {
  let result : Array[Int] = []
  for i = 0; i < self.n; i = i + 1 {
    if self.articulation_points[i] {
      result.push(i)
    }
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (collect APs):
      #|result contains articulation points among vertices in [0, i).
      #|MAINTENANCE:
      #|Append i if it is marked as an articulation point.
      #|TERMINATION:
      #|At i = n, result lists all articulation points.
    ),
  }
  result
}

///|
fn BridgeFinder::get_bridges(self : BridgeFinder) -> Array[(Int, Int)] {
  self.bridges
}

///|
fn BridgeFinder::is_articulation_point(self : BridgeFinder, u : Int) -> Bool {
  if u < 0 || u >= self.n {
    return false
  }
  self.articulation_points[u]
}

///|
/// Find all bridge edges in an undirected graph with n vertices.
/// Returns edges (u, v) whose removal disconnects the graph.
pub fn find_bridges(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[(Int, Int)] {
  let finder = BridgeFinder::new(n)
  for edge in edges {
    let (u, v) = edge
    finder.add_edge(u, v)
  }
  finder.find()
  finder.get_bridges()
}

///|
/// Find all articulation points in an undirected graph with n vertices.
pub fn articulation_points(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[Int] {
  let finder = BridgeFinder::new(n)
  for edge in edges {
    let (u, v) = edge
    finder.add_edge(u, v)
  }
  finder.find()
  finder.get_articulation_points()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "bridges basic" {
  //     0
  //    /|\
  //   1-2-3
  //       |
  //       4
  let bf = BridgeFinder::new(5)
  bf.add_edge(0, 1)
  bf.add_edge(0, 2)
  bf.add_edge(1, 2)
  bf.add_edge(2, 3)
  bf.add_edge(3, 4)
  bf.find()

  // Bridges: (2,3) and (3,4)
  inspect(bf.get_bridges().length(), content="2")

  // Articulation points: 2 and 3
  let aps = bf.get_articulation_points()
  inspect(aps.length(), content="2")
}

///|
test "bridges cycle" {
  // Complete cycle: no bridges, no articulation points
  let bf = BridgeFinder::new(4)
  bf.add_edge(0, 1)
  bf.add_edge(1, 2)
  bf.add_edge(2, 3)
  bf.add_edge(3, 0)
  bf.find()
  inspect(bf.get_bridges().length(), content="0")
  inspect(bf.get_articulation_points().length(), content="0")
}

///|
test "bridges linear" {
  // Linear: 0 - 1 - 2 - 3
  // All edges are bridges, 1 and 2 are articulation points
  let bf = BridgeFinder::new(4)
  bf.add_edge(0, 1)
  bf.add_edge(1, 2)
  bf.add_edge(2, 3)
  bf.find()
  inspect(bf.get_bridges().length(), content="3")
  inspect(bf.get_articulation_points().length(), content="2")
}

///|
test "bridges star" {
  // Star: center is articulation point
  let bf = BridgeFinder::new(5)
  bf.add_edge(0, 1)
  bf.add_edge(0, 2)
  bf.add_edge(0, 3)
  bf.add_edge(0, 4)
  bf.find()
  inspect(bf.is_articulation_point(0), content="true")
  inspect(bf.get_bridges().length(), content="4")
}

///|
test "bridges single" {
  let bf = BridgeFinder::new(1)
  bf.find()
  inspect(bf.get_bridges().length(), content="0")
  inspect(bf.get_articulation_points().length(), content="0")
}

///|
test "bridges two components" {
  let bf = BridgeFinder::new(4)
  bf.add_edge(0, 1)
  bf.add_edge(2, 3)
  bf.find()
  inspect(bf.get_bridges().length(), content="2")
}
