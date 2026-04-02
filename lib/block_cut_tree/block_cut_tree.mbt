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
/// Block-cut tree representation.
pub struct BlockCutTree {
  original_vertices : Int
  component_count : Int
  adj : Array[Array[Int]]
}

///|
/// Build the block-cut tree of an undirected graph.
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
  let adj = Array::makei(total, _ => [])
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
