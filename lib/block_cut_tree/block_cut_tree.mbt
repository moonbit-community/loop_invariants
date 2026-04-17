// ============================================================================
// BLOCK-CUT TREE - Articulation Points and Biconnected Components
// ============================================================================
//
// The block-cut tree is a bipartite graph between original vertices and
// biconnected components. Component nodes connect to every vertex that belongs
// to that component. Articulation points appear in multiple components.
//
// Node indexing:
// - Original vertices: 0 .. n-1
// - Component nodes: n .. n + c - 1
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V + E)

///|
/// The block-cut tree of an undirected graph.
///
/// The block-cut tree is a bipartite tree (or forest for disconnected graphs)
/// with two kinds of nodes:
///
/// - **Vertex nodes** (indices `0 .. original_vertices - 1`): one per original
///   graph vertex.
/// - **Block nodes** (indices `original_vertices .. original_vertices +
///   component_count - 1`): one per biconnected component.
///
/// An edge in `adj` connects a block node to each vertex it contains. Because
/// the graph is bipartite, no two vertex nodes are adjacent and no two block
/// nodes are adjacent.
///
/// Example — triangle with a tail (n=4, c=2):
/// ```
///       0    2
///        \  /
///        B0(4)          B0 contains {0,1,2}
///          |
///          1            vertex 1 is the articulation point
///          |
///        B1(5)          B1 contains {1,3}
///          |
///          3
/// ```
pub struct BlockCutTree {
  /// Number of original graph vertices. Vertex nodes use indices `0` to
  /// `original_vertices - 1` in `adj`.
  original_vertices : Int
  /// Number of biconnected components found. Block nodes use indices
  /// `original_vertices` to `original_vertices + component_count - 1` in
  /// `adj`.
  component_count : Int
  /// Adjacency list of the block-cut tree. Has length
  /// `original_vertices + component_count`.
  ///
  /// - `adj[v]` for a vertex node `v` lists all block nodes that contain `v`.
  /// - `adj[b]` for a block node `b` lists all vertex nodes in that block.
  ///
  /// The list is undirected: `b in adj[v]` if and only if `v in adj[b]`.
  adj : Array[Array[Int]]
}

///|
/// Build the block-cut tree for an undirected graph with `n` vertices.
///
/// Parameters:
/// - `n`: number of vertices, labelled `0 .. n-1`.
/// - `edges`: undirected edges as `(u, v)` pairs; multi-edges are allowed.
///
/// Returns a `BlockCutTree` whose node index layout is:
/// ```
///   0 .. n-1        original vertex nodes
///   n .. n+c-1      block (biconnected component) nodes
/// ```
/// where `c` is the number of biconnected components discovered.
///
/// The returned adjacency list `adj` is undirected: block node `n + i`
/// lists exactly the vertices in component `i`, and each such vertex lists
/// `n + i` in its own adjacency entry.
///
/// A vertex is an **articulation point** exactly when its degree in `adj`
/// is greater than 1 (it connects to more than one block node).
///
/// Example:
/// ```mbt nocheck
/// let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
/// let tree = @block_cut_tree.build_block_cut_tree(4, edges[:])
/// // two components: the triangle {0,1,2} and the bridge {1,3}
/// assert_eq!(tree.component_count, 2)
/// // block node 4 or 5 covers the triangle; the other covers the bridge
/// ```
///
/// Edge cases:
/// - `n <= 0` returns an empty `BlockCutTree` with no vertices or blocks.
/// - A graph with no edges returns `component_count = 0`.
/// - A disconnected graph returns one sub-forest per connected component;
///   `component_count` is the total number of blocks across all components.
pub fn build_block_cut_tree(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> BlockCutTree {
  if n <= 0 {
    return { original_vertices: 0, component_count: 0, adj: [] }
  }
  let result = @biconnected_components.biconnected_components(n, edges)
  let comps = result.components
  let c = comps.length()
  let total = n + c
  let adj = [ for _ in 0..<total => [] ]
  for ci in 0..<c {
    let comp_edges = comps[ci]
    let in_comp = Array::make(n, false)
    let vertices : Array[Int] = []
    for edge in comp_edges {
      let (u, v) = edge
      if !in_comp[u] {
        in_comp[u] = true
        vertices.push(u)
      }
      if !in_comp[v] {
        in_comp[v] = true
        vertices.push(v)
      }
    }
    let comp_node = n + ci
    for v in vertices {
      adj[comp_node].push(v)
      adj[v].push(comp_node)
    }
  }
  { original_vertices: n, component_count: c, adj }
}
