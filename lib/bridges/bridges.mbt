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
// 1. Root is articulation point if it has >= 2 children in DFS tree
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
/// Internal state for Tarjan's bridge/articulation-point DFS.
///
/// Fields:
/// - `n`                  - number of vertices
/// - `adj`                - adjacency lists
/// - `disc`               - DFS discovery timestamps; -1 means unvisited
/// - `low`                - low-link values (minimum disc reachable via back edges)
/// - `parent`             - DFS parent of each vertex; -1 for the root
/// - `timer`              - monotonically increasing DFS clock
/// - `articulation_points` - boolean flags, one per vertex
/// - `bridges`            - collected bridge edges in DFS discovery order
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
/// Create a new `BridgeFinder` for a graph with `n` vertices and no edges.
/// All discovery timestamps are initialised to -1 (unvisited).
fn BridgeFinder::new(n : Int) -> BridgeFinder {
  let adj : Array[Array[Int]] = [| for _ in 0..<n => [] |]
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
/// Add the undirected edge `(u, v)` to the adjacency lists.
/// Both directions are recorded so that DFS traverses the edge from either end.
fn BridgeFinder::add_edge(self : BridgeFinder, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Run the DFS from vertex `u` with DFS parent `p` (`p = -1` at the root).
///
/// At entry `disc[u]` is set to the current timer value and `low[u]` is
/// initialised to the same value.  For each neighbour `v`:
///
/// - **Tree edge** (`disc[v] < 0`): recurse into `v`, then pull `low[v]` up
///   into `low[u]`.  Apply the bridge rule and the non-root articulation-point
///   rule after returning.
/// - **Back edge** (`v != p`): update `low[u] = min(low[u], disc[v])`.
/// - **Parent edge** (`v == p`): skip to avoid treating the undirected parent
///   edge as a back edge.
///
/// After all neighbours are processed, apply the root articulation-point rule
/// if `p < 0` and the DFS-child count is >= 2.
fn BridgeFinder::dfs(self : BridgeFinder, u : Int, p : Int) -> Unit {
  self.disc[u] = self.timer
  self.low[u] = self.timer
  self.timer = self.timer + 1
  self.parent[u] = p
  let children = for i in 0..<self.adj[u].length(); children = 0 {
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
      continue children + 1
    } else if v != p {
      // Back edge (not to parent)
      if self.disc[v] < self.low[u] {
        self.low[u] = self.disc[v]
      }
      continue children
    } else {
      continue children
    }
  } nobreak {
    children
  }

  // Root articulation point check
  if p < 0 && children > 1 {
    self.articulation_points[u] = true
  }
}

///|
/// Launch DFS from every unvisited vertex so that disconnected graphs are
/// handled correctly.  After this call `disc`, `low`, `articulation_points`,
/// and `bridges` are fully populated.
fn BridgeFinder::find(self : BridgeFinder) -> Unit {
  for i in 0..<self.n {
    if self.disc[i] < 0 {
      self.dfs(i, -1)
    }
  }
}

///|
/// Return the indices of all articulation points found after `find()`.
/// The vertices are listed in DFS discovery order.
fn BridgeFinder::get_articulation_points(self : BridgeFinder) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<self.n {
    if self.articulation_points[i] {
      result.push(i)
    }
  }
  result
}

///|
/// Return the list of bridge edges found after `find()`.
/// Each bridge `(u, v)` is reported with `u` being the DFS parent.
/// The list is in DFS discovery order.
fn BridgeFinder::get_bridges(self : BridgeFinder) -> Array[(Int, Int)] {
  self.bridges
}

///|
/// Return `true` if vertex `u` is an articulation point after `find()`.
/// Returns `false` for out-of-range indices.
fn BridgeFinder::is_articulation_point(self : BridgeFinder, u : Int) -> Bool {
  if u < 0 || u >= self.n {
    return false
  }
  self.articulation_points[u]
}

///|
/// Find all bridge edges in an undirected graph.
///
/// A bridge is an edge whose removal increases the number of connected
/// components.  Equivalently, edge `(u, v)` is a bridge when there is no
/// back edge from `v`'s DFS subtree that reaches `u` or any ancestor of `u`.
///
/// Parameters:
/// - `n`     - number of vertices; vertices are labelled `0..n-1`
/// - `edges` - undirected edges as `(u, v)` pairs (each edge listed once)
///
/// Returns an array of bridge edges `(u, v)` in DFS discovery order where
/// `u` is the DFS parent.  Sort the result if deterministic output is needed.
///
/// Time complexity: O(V + E).  Space complexity: O(V + E).
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
/// Find all articulation points (cut vertices) in an undirected graph.
///
/// An articulation point is a vertex whose removal increases the number of
/// connected components.  Two rules determine articulation points:
///
/// - **Root rule**: the DFS root is an articulation point iff it has 2 or more
///   DFS children.
/// - **Non-root rule**: a non-root vertex `u` is an articulation point if it
///   has a DFS child `v` with `low[v] >= disc[u]`, meaning `v`'s subtree
///   cannot bypass `u` via a back edge.
///
/// Parameters:
/// - `n`     - number of vertices; vertices are labelled `0..n-1`
/// - `edges` - undirected edges as `(u, v)` pairs (each edge listed once)
///
/// Returns an array of articulation-point vertex indices in ascending order
/// of vertex index (iterated 0..n-1 after DFS).  Sort if a different order
/// is required.
///
/// Time complexity: O(V + E).  Space complexity: O(V + E).
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
