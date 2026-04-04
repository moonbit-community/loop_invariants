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
/// Mutable counter for timestamps and SCC IDs.
priv struct Counter {
  mut val : Int
}

///|
/// Result of SCC computation.
///
/// FIELDS:
///   - num_sccs: total number of SCCs found
///   - component: component[v] = SCC index of vertex v (0 to num_sccs-1)
///   - scc_sizes: scc_sizes[i] = number of vertices in SCC i
///   - scc_adj: condensation graph (DAG of SCCs)
///
/// SCC NUMBERING:
/// ```
///   Tarjan's algorithm numbers SCCs in reverse topological order
///   (sink SCCs get lower numbers).
///
///   Kosaraju's algorithm also produces a valid numbering where
///   if there's an edge from SCC i to SCC j, then i > j in Tarjan's
///   numbering (or the reverse in some implementations).
/// ```
///
/// CONDENSATION GRAPH:
/// ```
///   scc_adj[i] contains all SCCs j such that there exists an edge
///   from some vertex in SCC i to some vertex in SCC j.
///
///   Example:
///     Original: 0→1→2→0, 2→3
///     SCCs: {0,1,2}=SCC0, {3}=SCC1
///     Condensation: SCC0 → SCC1
/// ```
pub(all) struct SCCResult {
  num_sccs : Int
  component : Array[Int]
  scc_sizes : Array[Int]
  scc_adj : Array[Array[Int]]
} derive(Debug)
