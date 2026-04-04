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
/// A directed edge in the input graph.
///
/// Edges are the primitive input to `min_arborescence`. Multiple edges between
/// the same pair of vertices are permitted; the algorithm retains all of them
/// because contraction can change which one is cheapest.
///
/// The `weight` field may be negative after contraction (internal use only).
/// For user-supplied graphs, non-negative weights are recommended.
///
/// Example:
/// ```
///   let e : Edge = { from: 0, to: 1, weight: 7L }
///   // Represents the directed edge 0 →(7)→ 1
/// ```
pub(all) struct Edge {
  /// Source vertex of the edge (0-indexed).
  from : Int
  /// Destination vertex of the edge (0-indexed).
  to : Int
  /// Cost of traversing this edge.
  weight : Int64
} derive(Debug)

///|
/// The result of a minimum arborescence computation.
///
/// An `Arborescence` encodes a directed spanning tree rooted at a fixed vertex.
/// Every non-root vertex has exactly one incoming edge, and all vertices are
/// reachable from the root by following edges forward.
///
/// ## Fields
///
/// - `cost`   — Total weight of all chosen edges.
/// - `parent` — `parent[v]` is the predecessor of `v` in the tree.
///              `parent[root]` is always `-1`.
///
/// ## Recovering the edge list
///
/// ```
///   for v in 0..<n {
///     if v != root {
///       // edge parent[v] → v is in the arborescence
///     }
///   }
/// ```
///
/// ## Example
///
/// ```
/// // vertices {0,1,2,3}, root = 0
/// // parent = [-1, 0, 1, 1]
/// //
/// //     0
/// //     |
/// //     1
/// //    / \
/// //   2   3
/// //
/// // cost = w(0→1) + w(1→2) + w(1→3)
/// ```
pub(all) struct Arborescence {
  /// Total weight of the chosen arborescence edges.
  cost : Int64
  /// `parent[v]` = predecessor of `v`; `-1` for the root.
  parent : Array[Int]
} derive(Debug)
