// ============================================================================
// BICONNECTED COMPONENTS - Type Definitions
// ============================================================================
//
// Data structures for finding biconnected components and articulation points
// in undirected graphs using Tarjan's DFS algorithm.
//
// TERMINOLOGY:
//   - Biconnected Component (Block): A maximal subgraph where any two vertices
//     remain connected after removing any single vertex.
//   - Articulation Point (Cut Vertex): A vertex whose removal disconnects
//     the graph (or increases the number of connected components).
//   - Bridge: An edge whose removal disconnects the graph.
//
// KEY INSIGHT:
// ```
//   A biconnected component has NO articulation points inside it.
//   Equivalently: between any two vertices in a block, there exist
//   at least two vertex-disjoint paths.
//
//   Example:
//     Graph: 0 - 1 - 2       Block structure:
//            |   |             {0,1,2} form one block (triangle)
//            +---+             {1,3} form another block (bridge)
//                |
//                3
//
//     Vertex 1 is an articulation point (connects the two blocks).
// ```
//
// APPLICATIONS:
//   - Finding critical nodes in networks
//   - Graph redundancy analysis
//   - Network reliability

///|
/// Result of biconnected decomposition.
///
/// FIELDS:
///   - components: Array of biconnected components, each as list of edges
///   - articulation_points: Vertices whose removal disconnects the graph
///
/// EDGE REPRESENTATION:
/// ```
///   Each component is Array[(Int, Int)] where (u, v) is an edge.
///   Edges appear in DFS order within each component.
/// ```
pub(all) struct BiconnectedResult {
  components : Array[Array[(Int, Int)]]
  articulation_points : Array[Int]
} derive(Show)

///|
/// Internal working structure for Tarjan's algorithm.
///
/// FIELDS:
///   - n: number of vertices
///   - adj: adjacency list with (neighbor, edge_id) pairs
///   - disc: discovery time for each vertex (-1 if unvisited)
///   - low: low-link value for each vertex
///   - parent_edge: the edge ID used to reach this vertex in DFS
///   - edge_stack: stack of edges for component extraction
///   - articulation: whether each vertex is an articulation point
///   - components: collected biconnected components
///   - timer: current DFS timestamp
///
/// LOW-LINK VALUES (the key concept):
/// ```
///   low[u] = minimum discovery time reachable from u's subtree
///            using at most one back edge.
///
///   Computed as:
///     low[u] = min(disc[u],
///                  min { low[v] : v is tree child of u },
///                  min { disc[w] : w is back-edge ancestor of u })
///
///   When low[v] >= disc[u] for tree edge (u,v):
///     - v's subtree cannot "escape" above u
///     - Removing u would disconnect v's subtree
///     - u is an articulation point (unless u is root with one child)
/// ```
priv struct BiconnectedFinder {
  n : Int
  adj : Array[Array[(Int, Int)]]
  disc : Array[Int]
  low : Array[Int]
  parent_edge : Array[Int]
  edge_stack : Array[(Int, Int)]
  articulation : Array[Bool]
  components : Array[Array[(Int, Int)]]
  mut timer : Int
}

///|
/// Create a new biconnected component finder.
fn BiconnectedFinder::new(n : Int) -> BiconnectedFinder {
  let adj : Array[Array[(Int, Int)]] = Array::makei(n, _ => [])
  {
    n,
    adj,
    disc: Array::make(n, -1),
    low: Array::make(n, -1),
    parent_edge: Array::make(n, -1),
    edge_stack: [],
    articulation: Array::make(n, false),
    components: [],
    timer: 0,
  }
}

///|
/// Add an undirected edge to the graph.
///
/// Each edge is stored in both directions with the same edge ID.
/// This allows detecting the parent edge during DFS.
fn BiconnectedFinder::add_edge(
  self : BiconnectedFinder,
  u : Int,
  v : Int,
  id : Int,
) -> Unit {
  self.adj[u].push((v, id))
  self.adj[v].push((u, id))
}

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}
