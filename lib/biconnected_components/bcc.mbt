// ============================================================================
// BICONNECTED COMPONENTS - Main Algorithm
// ============================================================================
//
// Public interface for computing biconnected components and articulation points.

///|
/// Compute biconnected components of an undirected graph.
///
/// ALGORITHM:
/// ```
///   1. Build adjacency list from edges
///   2. Run Tarjan's DFS on each connected component
///   3. Extract biconnected components and articulation points
/// ```
///
/// PARAMETERS:
///   - n: number of vertices (labeled 0 to n-1)
///   - edges: undirected edges as (u, v) pairs
///
/// RETURNS:
///   BiconnectedResult containing:
///   - components: Array of biconnected components (each as edge list)
///   - articulation_points: Array of articulation point vertex IDs
///
/// TIME: O(V + E)
/// SPACE: O(V + E)
///
/// EXAMPLE:
/// ```
///   Graph with triangle and bridge:
///     0 - 1 - 3
///     |   |
///     +---2
///
///   Edges: [(0,1), (1,2), (2,0), (1,3)]
///
///   Result:
///     components: [{(0,1), (1,2), (2,0)}, {(1,3)}]
///     articulation_points: [1]
///
///   Vertex 1 is articulation because removing it disconnects 3.
/// ```
pub fn biconnected_components(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> BiconnectedResult {
  if n <= 0 {
    return { components: [], articulation_points: [] }
  }
  let finder = BiconnectedFinder::new(n)

  // Build graph from edges - each edge gets its index as unique ID
  for i, edge in edges {
    let (u, v) = edge
    guard u >= 0 && u < n && v >= 0 && v < n else { continue }
    finder.add_edge(u, v, i)
  }

  // Run the algorithm
  finder.run()

  // Collect results
  let points = finder.collect_articulation_points()
  { components: finder.components, articulation_points: points }
}
