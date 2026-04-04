// ============================================================================
// BICONNECTED COMPONENTS - Main Algorithm
// ============================================================================
//
// Public interface for computing biconnected components and articulation points.

///|
/// Compute all biconnected components and articulation points of an undirected
/// graph in O(V + E) time using a single DFS pass (Tarjan's algorithm).
///
/// Parameters:
/// - `n`: number of vertices; vertices are labeled `0` to `n-1`
/// - `edges`: undirected edges as `(u, v)` pairs; multi-edges and self-loops
///   are tolerated (self-loops are silently skipped by the edge-ID parent
///   check)
///
/// Returns a `BiconnectedResult` with:
/// - `components`: each biconnected component as a list of its edges;
///   a component of size 1 is a bridge; components are in no guaranteed order
/// - `articulation_points`: vertices whose removal would increase the number
///   of connected components; order is DFS-dependent, sort for stable output
///
/// Edge cases:
/// - `n <= 0` returns an empty result immediately.
/// - Out-of-range endpoints in `edges` are silently skipped.
/// - An isolated vertex (no incident edges) does not appear in any component.
/// - A disconnected graph is handled by iterating over all unvisited vertices
///   as DFS roots.
///
/// Algorithm sketch:
/// ```
///   1. Build adjacency list from edges (each edge gets its index as ID)
///   2. For each unvisited vertex, run DFS:
///      a. Assign disc[u] and initialise low[u] = disc[u]
///      b. For each tree edge (u, v): push edge, recurse, update low[u],
///         check articulation condition, extract component if low[v] >= disc[u]
///      c. For each back edge (u, w): push edge, update low[u] = min(low[u], disc[w])
///      d. Root rule: root is articulation iff it has >= 2 DFS children
///   3. Collect articulation flags into result array
/// ```
///
/// Example — triangle with a tail:
/// ```
///   Graph:  0 - 1 - 3
///            \ /
///             2
///
///   Edges: [(0,1), (1,2), (2,0), (1,3)]
///
///   Result:
///     components:          [{(1,3)}, {(0,1),(1,2),(2,0)}]  (order varies)
///     articulation_points: [1]
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
