// ============================================================================
// BICONNECTED COMPONENTS - Tests
// ============================================================================

///|
/// Test basic biconnected component decomposition.
///
/// GRAPH:
/// ```
///   0 --- 1 --- 3
///   |     |
///   +-----2
///
///   Edges: (0,1), (1,2), (2,0), (1,3)
/// ```
///
/// STRUCTURE:
/// ```
///   Block 1: Triangle {0, 1, 2} with edges {(0,1), (1,2), (2,0)}
///   Block 2: Bridge {1, 3} with edge {(1,3)}
///
///   Articulation point: 1 (connects triangle to vertex 3)
/// ```
test "biconnected components basic" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let result = biconnected_components(4, edges[:])

  // Sort component sizes for comparison
  let sizes = result.components.map(c => c.length())
  sizes.sort_by((a, b) => a - b)
  inspect(sizes, content="[1, 3]") // Bridge has 1 edge, triangle has 3
  result.articulation_points.sort_by((a, b) => a - b)
  inspect(result.articulation_points, content="[1]")
}

///|
/// Test tree graph (every edge is a bridge).
///
/// GRAPH:
/// ```
///       0
///       |
///       1
///      / \
///     2   3
///
///   Edges: (0,1), (1,2), (1,3)
/// ```
///
/// STRUCTURE:
/// ```
///   Each edge is its own biconnected component (all are bridges).
///   Vertex 1 is articulation point (removing it disconnects 0 from 2,3).
/// ```
test "biconnected components tree" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (1, 3)]
  let result = biconnected_components(4, edges[:])

  // Each edge is a separate component
  let sizes = result.components.map(c => c.length())
  sizes.sort_by((a, b) => a - b)
  inspect(sizes, content="[1, 1, 1]")
  result.articulation_points.sort_by((a, b) => a - b)
  inspect(result.articulation_points, content="[1]")
}

///|
/// Test single cycle (no articulation points).
///
/// GRAPH:
/// ```
///   0 --- 1
///   |     |
///   3 --- 2
///
///   Edges: (0,1), (1,2), (2,3), (3,0)
/// ```
///
/// STRUCTURE:
/// ```
///   Entire graph is one biconnected component.
///   No articulation points (can remove any vertex and stay connected).
/// ```
test "biconnected components cycle" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
  let result = biconnected_components(4, edges[:])

  // One component with 4 edges
  inspect(result.components.length(), content="1")
  inspect(result.components[0].length(), content="4")

  // No articulation points in a cycle
  inspect(result.articulation_points, content="[]")
}

///|
/// Test disconnected graph.
///
/// GRAPH:
/// ```
///   Component 1: 0 - 1
///   Component 2: 2 - 3
/// ```
test "biconnected components disconnected" {
  let edges : Array[(Int, Int)] = [(0, 1), (2, 3)]
  let result = biconnected_components(4, edges[:])

  // Two components, each with one edge
  inspect(result.components.length(), content="2")

  // No articulation points (bridges don't create APs in 2-vertex components)
  inspect(result.articulation_points, content="[]")
}

///|
/// Test empty graph.
test "biconnected components empty" {
  let edges : Array[(Int, Int)] = []
  let result = biconnected_components(3, edges[:])
  inspect(result.components, content="[]")
  inspect(result.articulation_points, content="[]")
}

///|
/// Test graph with multiple articulation points.
///
/// GRAPH:
/// ```
///   0 --- 1 --- 2 --- 3
///         |     |
///         4     5
///
///   Forms a chain of biconnected components.
/// ```
test "biconnected components chain" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5)]
  let result = biconnected_components(6, edges[:])

  // Each edge is separate (linear chain = all bridges)
  inspect(result.components.length(), content="5")

  // Vertices 1 and 2 are articulation points
  result.articulation_points.sort_by((a, b) => a - b)
  inspect(result.articulation_points, content="[1, 2]")
}

///|
/// Test single vertex (edge case).
test "biconnected components single vertex" {
  let edges : Array[(Int, Int)] = []
  let result = biconnected_components(1, edges[:])
  inspect(result.components, content="[]")
  inspect(result.articulation_points, content="[]")
}
