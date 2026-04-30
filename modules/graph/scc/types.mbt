// ============================================================================
// STRONGLY CONNECTED COMPONENTS - Type Definitions
// ============================================================================
//
// Data structures for SCC computation algorithms.
//
// TERMINOLOGY:
//   - SCC (Strongly Connected Component): A maximal set of vertices where
//     every vertex is reachable from every other vertex in the set.
//   - Condensation Graph: The DAG formed by contracting each SCC to a single
//     vertex. Edges between SCCs are preserved.
//
// KEY PROPERTIES:
// ```
//   1. Every directed graph can be decomposed into SCCs
//   2. SCCs partition the vertex set (each vertex in exactly one SCC)
//   3. The condensation graph is always a DAG
//   4. A single vertex with no self-loop is its own SCC
// ```
//
// APPLICATIONS:
//   - 2-SAT solving (satisfiability)
//   - Detecting cycles in dependency graphs
//   - Compiler optimization (control flow analysis)
//   - Social network analysis

///|
/// Mutable integer counter used as a shared, incrementable value passed
/// by reference across recursive DFS calls.
///
/// Used for the discovery-time timer in Tarjan's algorithm and for
/// counting how many SCCs have been identified so far.
priv struct Counter {
  mut val : Int
}

///|
/// Result returned by both `find_sccs` and `find_sccs_kosaraju`.
///
/// All four fields are consistent with each other: they describe the same
/// SCC decomposition of the input graph.
///
/// Fields:
/// - `num_sccs`  : total number of strongly connected components.
/// - `component` : `component[v]` is the SCC index (0 to `num_sccs - 1`)
///                 of vertex `v`. Vertices in the same SCC share an index.
/// - `scc_sizes` : `scc_sizes[i]` is the number of vertices in SCC `i`.
///                 The sizes sum to `n` (total vertex count).
/// - `scc_adj`   : condensation DAG adjacency list. `scc_adj[i]` contains
///                 the indices of SCCs that SCC `i` has a directed edge into.
///                 Self-loops and duplicate edges are excluded.
///
/// SCC numbering (Tarjan):
/// ```
///   SCCs are numbered in the order they are completed during DFS.
///   Sink SCCs (no outgoing SCC edges) receive lower indices.
///   Source SCCs receive higher indices.
///   This matches reverse topological order on the condensation DAG.
/// ```
///
/// Example for graph `0->1->2->0, 2->3`:
/// ```
///   num_sccs  = 2
///   component = [1, 1, 1, 0]   // vertices 0,1,2 in SCC 1; vertex 3 in SCC 0
///   scc_sizes = [1, 3]          // SCC 0 has 1 vertex; SCC 1 has 3 vertices
///   scc_adj   = [[], [0]]       // SCC 1 -> SCC 0; SCC 0 has no outgoing edges
/// ```
pub(all) struct SCCResult {
  num_sccs : Int
  component : Array[Int]
  scc_sizes : Array[Int]
  scc_adj : Array[Array[Int]]
} derive(Debug)
