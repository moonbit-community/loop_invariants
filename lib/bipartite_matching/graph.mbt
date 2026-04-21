// ============================================================================
// BIPARTITE GRAPH - Graph Builder for Bipartite Matching
// ============================================================================
//
// A bipartite graph has two disjoint vertex sets: left and right.
// Edges only connect vertices from different sets.
//
// Left vertices are numbered 0..n_left-1
// Right vertices are numbered 0..n_right-1

///|
/// Bipartite graph representation used as input for both the Hungarian and
/// Hopcroft-Karp matching algorithms.
///
/// The graph stores an adjacency list indexed by left-vertex ID. Each entry
/// lists the right-vertex IDs reachable from that left vertex.
///
/// Left vertices are numbered `0..n_left-1`.
/// Right vertices are numbered `0..n_right-1`.
///
/// Build the graph with `new`, populate it with `add_edge`, then create a
/// matcher via `hungarian()` or `hopcroft_karp()`.
struct BipartiteGraph {
  n_left : Int
  n_right : Int
  adj : Array[Array[Int]]
}

///|
/// Create a new empty bipartite graph with `n_left` left vertices and
/// `n_right` right vertices.
///
/// All adjacency lists start empty. Use `add_edge` to add edges before
/// running any matching algorithm.
///
/// Parameters:
/// - `n_left`  : number of left vertices (labeled `0..n_left-1`)
/// - `n_right` : number of right vertices (labeled `0..n_right-1`)
///
/// Example:
/// ```
/// let graph = BipartiteGraph(3, 3)
/// graph.add_edge(0, 0)
/// graph.add_edge(1, 1)
/// let size = graph.hungarian().max_matching()
/// ```
pub fn BipartiteGraph::BipartiteGraph(
  n_left : Int,
  n_right : Int,
) -> BipartiteGraph {
  let adj : Array[Array[Int]] = [ for _ in 0..<n_left => [] ]
  { n_left, n_right, adj }
}

///|
/// Add a directed edge from left vertex `u` to right vertex `v`.
///
/// Parameters:
/// - `u` : index in the left vertex set, must be in `0..n_left-1`
/// - `v` : index in the right vertex set, must be in `0..n_right-1`
///
/// Duplicate edges are allowed but may slow down DFS-based matching.
/// This method does not validate that `u` or `v` are in range; callers
/// must ensure indices are valid.
pub fn BipartiteGraph::add_edge(
  self : BipartiteGraph,
  u : Int,
  v : Int,
) -> Unit {
  // u is in left set (0..n_left-1), v is in right set (0..n_right-1)
  self.adj[u].push(v)
}

///|
/// Create a Hungarian algorithm matcher bound to this graph.
///
/// The returned `Hungarian` value holds the matching state. Call
/// `max_matching()` on it to run the algorithm and obtain the matching size,
/// or `get_matching()` to retrieve the individual pairs.
///
/// Time complexity: O(V * E) where V = n_left + n_right and E = edge count.
/// Suitable for small to medium graphs. For large graphs prefer
/// `hopcroft_karp()`.
pub fn BipartiteGraph::hungarian(self : BipartiteGraph) -> Hungarian {
  Hungarian(self)
}

///|
/// Create a Hopcroft-Karp algorithm matcher bound to this graph.
///
/// The returned `HopcroftKarp` value holds the matching state. Call
/// `max_matching()` to run the algorithm, `get_matching()` to retrieve
/// pairs, or `min_vertex_cover()` to compute the minimum vertex cover via
/// König's theorem.
///
/// Time complexity: O(E * sqrt(V)) where V = n_left + n_right and E = edge
/// count. Faster than Hungarian for large sparse graphs.
pub fn BipartiteGraph::hopcroft_karp(self : BipartiteGraph) -> HopcroftKarp {
  HopcroftKarp(self)
}
