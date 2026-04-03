// ============================================================================
// STOER-WAGNER MIN CUT - Type Definitions
// ============================================================================
//
// Data structures for the Stoer-Wagner global minimum cut algorithm.
//
// TERMINOLOGY:
//   - Cut: A partition of vertices into two non-empty sets S and T
//   - Cut Weight: Sum of edge weights crossing between S and T
//   - Min Cut: The cut with minimum weight across all possible cuts
//   - s-t Cut: A cut where s is in S and t is in T
//
// KEY INSIGHT:
// ```
//   The global min cut is the minimum over all s-t cuts for all pairs (s,t).
//   Stoer-Wagner cleverly finds this without explicitly trying all pairs.
//
//   Instead, it uses "maximum adjacency search" to find a specific s-t cut
//   in each phase, then contracts s and t into a supernode. The minimum
//   cut seen across all phases is the global minimum.
// ```
//
// APPLICATIONS:
//   - Network reliability (minimum edge failure to disconnect)
//   - Image segmentation
//   - Clustering

///|
/// Large value representing infinity (for finding minimum).
const INF64 : Int64 = 4611686018427387903L

///|
/// Result of minimum cut computation.
///
/// FIELDS:
///   - weight: total weight of edges crossing the cut
///   - cut: one side of the cut (array of original vertex IDs)
///
/// NOTE:
/// ```
///   The other side of the cut is all vertices NOT in cut[].
///   The cut weight is the sum of edge weights between these two sides.
/// ```
pub(all) struct MinCutResult {
  weight : Int64
  cut : Array[Int]
} derive(Show)

///|
/// Select the vertex with maximum w[] value among alive, non-added vertices.
///
/// This is the core of maximum adjacency search:
/// ```
///   At each step, select the vertex most tightly connected to the
///   current set A (measured by total edge weight to A).
/// ```
///
/// PARAMETERS:
///   - alive: which vertices are still active (not contracted)
///   - added: which vertices have been added to set A this phase
///   - w: w[v] = total edge weight from v to current set A
///
/// RETURNS:
///   Index of selected vertex, or -1 if none available
fn select_max_vertex(
  alive : Array[Bool],
  added : Array[Bool],
  w : Array[Int64],
) -> Int {
  let (sel, _) = for v in 0..<w.length(); sel = -1, best = -1L {
    if alive[v] && !added[v] {
      if sel == -1 || w[v] > best {
        continue v, w[v]
      }
    }
    continue sel, best
  } nobreak {
    (sel, best)
  }
  sel
}

///|
/// Append all elements from source to target.
///
/// Used when contracting vertices: merge member lists.
fn append_members(target : Array[Int], source : Array[Int]) -> Unit {
  for v in source {
    target.push(v)
  }
}
