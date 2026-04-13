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
//   - Bridge: An edge whose removal disconnects the graph; equivalently, a
//     biconnected component containing exactly one edge.
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
/// The result of a biconnected component decomposition.
///
/// Each field provides one view of the block structure of an undirected graph.
/// Both fields are populated by a single DFS pass and can be used independently.
///
/// `components` stores each block as a list of its edges `(u, v)`. Edges
/// appear in DFS-pop order within a component; component order is not
/// guaranteed. To extract vertex sets from a component, collect the distinct
/// endpoints of its edges.
///
/// `articulation_points` lists the vertices whose removal would disconnect the
/// graph. A vertex appears at most once. Order matches DFS discovery order;
/// sort the array if deterministic output is required.
///
/// A biconnected component of size 1 (one edge) is a bridge. A biconnected
/// component of size >= 2 contains a cycle and no internal articulation points.
///
/// Example usage:
/// ```
///   let res = biconnected_components(4, [(0,1),(1,2),(2,0),(1,3)][:])
///   // res.components = [[(1,3)], [(2,0),(1,2),(0,1)]]  (order varies)
///   // res.articulation_points = [1]
/// ```
pub(all) struct BiconnectedResult {
  components : Array[Array[(Int, Int)]]
  articulation_points : Array[Int]
} derive(Debug)

///|
/// Internal working state for Tarjan's biconnected component algorithm.
///
/// All mutable state is collected here so that `BiconnectedFinder::dfs` can
/// update it in place during the recursive DFS traversal.
///
/// Fields:
/// - `n`: number of vertices in the graph (vertices are labeled `0..n-1`)
/// - `adj`: adjacency list; `adj[u]` holds `(v, edge_id)` pairs for all
///   edges incident to `u`; each undirected edge appears in both directions
///   with the same `edge_id`
/// - `disc`: DFS discovery timestamp for each vertex; `-1` means unvisited
/// - `low`: low-link value for each vertex; see the invariant below
/// - `parent_edge`: the edge ID used to reach this vertex in DFS (`-1` for
///   the DFS root); used to avoid immediately retreating along the tree edge
/// - `edge_stack`: stack of edges accumulated during DFS; edges are popped
///   to form biconnected components when `low[v] >= disc[u]`
/// - `articulation`: boolean flag per vertex; `true` once the vertex is
///   confirmed as an articulation point
/// - `components`: collected biconnected components (grown throughout DFS)
/// - `timer`: monotonically increasing DFS timestamp counter
///
/// Low-link invariant:
/// ```
///   low[u] = minimum disc value reachable from u's DFS subtree via any
///            combination of tree edges followed by at most one back edge.
///
///   Computed incrementally:
///     low[u] = min(disc[u],
///                  min { low[v]   : (u,v) is a tree edge },
///                  min { disc[w]  : (u,w) is a back edge })
///
///   Consequence: if low[v] >= disc[u] for a tree edge (u,v), then v's
///   entire subtree is "trapped below" u and cannot reach u's ancestors.
///   Removing u would therefore disconnect v's subtree.
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
/// Allocate a fresh `BiconnectedFinder` for a graph with `n` vertices.
///
/// All discovery times are initialised to `-1` (unvisited). The adjacency
/// list, edge stack, and component array are empty. The timer starts at `0`.
/// Call `add_edge` to populate the graph before calling `run`.
fn BiconnectedFinder::new(n : Int) -> BiconnectedFinder {
  let adj : Array[Array[(Int, Int)]] = [| for _ in 0..<n => [] |]
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
/// Add an undirected edge between vertices `u` and `v` with the given `id`.
///
/// The edge is stored in both `adj[u]` and `adj[v]` so the DFS can traverse
/// it in either direction. Both entries carry the same `id`, which lets the
/// DFS skip the edge it arrived on (`eid == parent_edge`) without needing
/// to track the parent vertex explicitly. This is correct even when the
/// graph contains multiple edges between the same pair of vertices, because
/// each parallel edge receives a distinct `id`.
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
