// ============================================================================
// EDMONDS' ARBORESCENCE - Type Definitions
// ============================================================================
//
// Data structures for the Chu-Liu/Edmonds minimum arborescence algorithm.
//
// TERMINOLOGY:
//   - Arborescence: A directed tree where all edges point away from root
//                   (equivalently: every vertex except root has exactly one
//                   incoming edge, and all vertices are reachable from root)
//   - Minimum arborescence: Arborescence with minimum total edge weight
//
// APPLICATIONS:
//   - Network design with directed connections
//   - Dependency resolution with costs
//   - Optimal broadcast trees in networks

///|
/// Sentinel value for unreachable/no-edge.
/// Using a large value that won't overflow when added.
const INF64 : Int64 = 4611686018427387903L

///|
/// Directed edge with weight.
///
/// FIELDS:
///   - from: source vertex
///   - to: destination vertex
///   - weight: edge cost (can be negative in contracted graphs)
pub(all) struct Edge {
  from : Int
  to : Int
  weight : Int64
} derive(Debug)

///|
/// Result of minimum arborescence computation.
///
/// FIELDS:
///   - cost: total weight of the arborescence
///   - parent: parent[v] = predecessor of v in the arborescence
///             parent[root] = -1
///             parent[v] = -1 for unreachable vertices
///
/// STRUCTURE:
/// ```
///   The arborescence forms a tree rooted at the specified root.
///   Following parent pointers from any vertex leads to root.
///
///   Example for vertices {0, 1, 2, 3} with root=0:
///     parent = [-1, 0, 1, 1]
///
///     Means: 0 is root
///            1's parent is 0 (edge 0→1)
///            2's parent is 1 (edge 1→2)
///            3's parent is 1 (edge 1→3)
///
///         0
///         │
///         1
///        / \
///       2   3
/// ```
pub(all) struct Arborescence {
  cost : Int64
  parent : Array[Int]
} derive(Debug)
