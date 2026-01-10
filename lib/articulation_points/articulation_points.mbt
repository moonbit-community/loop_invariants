// ============================================================================
// ARTICULATION POINTS - Cut Vertices in Graphs
// ============================================================================
//
// An articulation point (cut vertex) is a vertex whose removal disconnects the graph.
// Uses Tarjan's DFS algorithm similar to bridge finding.
//
// KEY INSIGHT: A vertex u is an articulation point if:
// 1. u is root of DFS tree and has 2+ children, OR
// 2. u is not root and has a child v where no vertex in subtree of v
//    has a back edge to an ancestor of u (low[v] >= disc[u])
//
// ALGORITHM:
// 1. DFS with discovery times
// 2. Track low[v] = min discovery time reachable from subtree of v
// 3. Apply articulation point conditions
//
// INVARIANTS:
// 1. disc[u] < disc[v] for all tree edges (u, v)
// 2. low[u] <= disc[u] for all vertices
// 3. low[u] = min(disc[u], disc[w]) for back edge (u, w), min(low[v]) for tree edge (u, v)
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V)

///|
priv struct ArticulationFinder {
  n : Int
  adj : Array[Array[Int]]
  disc : Array[Int]
  low : Array[Int]
  parent : Array[Int]
  is_ap : Array[Bool]
  mut timer : Int
}

///|
fn ArticulationFinder::new(n : Int) -> ArticulationFinder {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  {
    n,
    adj,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    parent: Array::make(n, -1),
    is_ap: Array::make(n, false),
    timer: 0,
  }
}

///|
fn ArticulationFinder::add_edge(self : ArticulationFinder, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
fn ArticulationFinder::dfs(self : ArticulationFinder, u : Int) -> Unit {
  self.disc[u] = self.timer
  self.low[u] = self.timer
  self.timer = self.timer + 1

  let mut children = 0

  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]

    if self.disc[v] < 0 {
      // Tree edge
      children = children + 1
      self.parent[v] = u
      self.dfs(v)

      // Update low value
      if self.low[v] < self.low[u] {
        self.low[u] = self.low[v]
      }

      // Check articulation point condition for non-root
      if self.parent[u] >= 0 && self.low[v] >= self.disc[u] {
        self.is_ap[u] = true
      }
    } else if v != self.parent[u] {
      // Back edge
      if self.disc[v] < self.low[u] {
        self.low[u] = self.disc[v]
      }
    }
  }

  // Root is AP if it has 2+ children
  if self.parent[u] < 0 && children > 1 {
    self.is_ap[u] = true
  }
}

///|
/// Find all articulation points
fn ArticulationFinder::find_articulation_points(
  self : ArticulationFinder
) -> Array[Int] {
  // Reset state
  for i = 0; i < self.n; i = i + 1 {
    self.disc[i] = -1
    self.low[i] = -1
    self.parent[i] = -1
    self.is_ap[i] = false
  }
  self.timer = 0

  // Run DFS from all unvisited vertices (handles disconnected graphs)
  for i = 0; i < self.n; i = i + 1 {
    if self.disc[i] < 0 {
      self.dfs(i)
    }
  }

  // Collect articulation points
  let result : Array[Int] = []
  for i = 0; i < self.n; i = i + 1 {
    if self.is_ap[i] {
      result.push(i)
    }
  }
  result
}

///|
/// Count number of articulation points
fn ArticulationFinder::count_articulation_points(self : ArticulationFinder) -> Int {
  self.find_articulation_points().length()
}

// ============================================================================
// BICONNECTED COMPONENTS
// ============================================================================

///|
priv struct BiconnectedComponents {
  n : Int
  adj : Array[Array[Int]]
  disc : Array[Int]
  low : Array[Int]
  parent : Array[Int]
  stack : Array[(Int, Int)] // Edge stack
  components : Array[Array[(Int, Int)]]
  mut timer : Int
}

///|
fn BiconnectedComponents::new(n : Int) -> BiconnectedComponents {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  {
    n,
    adj,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    parent: Array::make(n, -1),
    stack: [],
    components: [],
    timer: 0,
  }
}

///|
fn BiconnectedComponents::add_edge(self : BiconnectedComponents, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
fn BiconnectedComponents::dfs(self : BiconnectedComponents, u : Int) -> Unit {
  self.disc[u] = self.timer
  self.low[u] = self.timer
  self.timer = self.timer + 1

  let mut children = 0

  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]

    if self.disc[v] < 0 {
      children = children + 1
      self.parent[v] = u
      self.stack.push((u, v))
      self.dfs(v)

      if self.low[v] < self.low[u] {
        self.low[u] = self.low[v]
      }

      // Found biconnected component
      if (self.parent[u] < 0 && children > 1) ||
        (self.parent[u] >= 0 && self.low[v] >= self.disc[u]) {
        let component : Array[(Int, Int)] = []
        while self.stack.length() > 0 {
          let edge = self.stack.pop()
          match edge {
            Some((a, b)) => {
              component.push((a, b))
              if a == u && b == v {
                break
              }
            }
            None => break
          }
        }
        self.components.push(component)
      }
    } else if v != self.parent[u] && self.disc[v] < self.disc[u] {
      // Back edge (only push if going to ancestor)
      self.stack.push((u, v))
      if self.disc[v] < self.low[u] {
        self.low[u] = self.disc[v]
      }
    }
  }
}

///|
fn BiconnectedComponents::find_components(
  self : BiconnectedComponents
) -> Array[Array[(Int, Int)]] {
  // Reset
  for i = 0; i < self.n; i = i + 1 {
    self.disc[i] = -1
    self.low[i] = -1
    self.parent[i] = -1
  }
  self.stack.clear()
  self.components.clear()
  self.timer = 0

  for i = 0; i < self.n; i = i + 1 {
    if self.disc[i] < 0 {
      self.dfs(i)
      // Pop remaining edges as a component
      if self.stack.length() > 0 {
        let component : Array[(Int, Int)] = []
        while self.stack.length() > 0 {
          match self.stack.pop() {
            Some(edge) => component.push(edge)
            None => ()
          }
        }
        if component.length() > 0 {
          self.components.push(component)
        }
      }
    }
  }

  self.components
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "articulation_points basic" {
  let finder = ArticulationFinder::new(5)
  // Graph:
  //   0---1---2
  //       |   |
  //       3---4
  finder.add_edge(0, 1)
  finder.add_edge(1, 2)
  finder.add_edge(1, 3)
  finder.add_edge(2, 4)
  finder.add_edge(3, 4)

  let aps = finder.find_articulation_points()
  // Vertex 1 is an articulation point (removing it disconnects 0)
  inspect(aps.contains(1), content="true")
}

///|
test "articulation_points chain" {
  let finder = ArticulationFinder::new(4)
  // Chain: 0 - 1 - 2 - 3
  finder.add_edge(0, 1)
  finder.add_edge(1, 2)
  finder.add_edge(2, 3)

  let aps = finder.find_articulation_points()
  // Vertices 1 and 2 are articulation points
  inspect(aps.length(), content="2")
  inspect(aps.contains(1), content="true")
  inspect(aps.contains(2), content="true")
}

///|
test "articulation_points cycle" {
  let finder = ArticulationFinder::new(4)
  // Cycle: 0 - 1 - 2 - 3 - 0
  finder.add_edge(0, 1)
  finder.add_edge(1, 2)
  finder.add_edge(2, 3)
  finder.add_edge(3, 0)

  let aps = finder.find_articulation_points()
  // No articulation points in a cycle
  inspect(aps.length(), content="0")
}

///|
test "articulation_points star" {
  let finder = ArticulationFinder::new(5)
  // Star: 0 connected to 1, 2, 3, 4
  finder.add_edge(0, 1)
  finder.add_edge(0, 2)
  finder.add_edge(0, 3)
  finder.add_edge(0, 4)

  let aps = finder.find_articulation_points()
  // Center vertex 0 is the only articulation point
  inspect(aps.length(), content="1")
  inspect(aps[0], content="0")
}

///|
test "articulation_points complete" {
  let finder = ArticulationFinder::new(4)
  // Complete graph K4
  for i = 0; i < 4; i = i + 1 {
    for j = i + 1; j < 4; j = j + 1 {
      finder.add_edge(i, j)
    }
  }

  let aps = finder.find_articulation_points()
  // No articulation points in complete graph
  inspect(aps.length(), content="0")
}

///|
test "articulation_points single" {
  let finder = ArticulationFinder::new(1)
  let aps = finder.find_articulation_points()
  inspect(aps.length(), content="0")
}

///|
test "articulation_points pair" {
  let finder = ArticulationFinder::new(2)
  finder.add_edge(0, 1)

  let aps = finder.find_articulation_points()
  // Both vertices are articulation points (removing either disconnects)
  // Actually for a pair, neither is an AP since removal leaves 1 vertex
  inspect(aps.length(), content="0")
}

///|
test "biconnected_components basic" {
  let bc = BiconnectedComponents::new(5)
  bc.add_edge(0, 1)
  bc.add_edge(1, 2)
  bc.add_edge(2, 0) // Triangle
  bc.add_edge(2, 3)
  bc.add_edge(3, 4)
  bc.add_edge(4, 2) // Another triangle

  let components = bc.find_components()
  inspect(components.length() >= 1, content="true")
}

///|
test "count_articulation_points" {
  let finder = ArticulationFinder::new(7)
  //     0
  //    / \
  //   1   2
  //   |   |
  //   3---4
  //       |
  //       5
  //       |
  //       6
  finder.add_edge(0, 1)
  finder.add_edge(0, 2)
  finder.add_edge(1, 3)
  finder.add_edge(2, 4)
  finder.add_edge(3, 4)
  finder.add_edge(4, 5)
  finder.add_edge(5, 6)

  let count = finder.count_articulation_points()
  inspect(count >= 2, content="true") // At least 4 and 5 are APs
}
