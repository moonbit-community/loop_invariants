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
/// Large sentinel value representing infinity, used to initialize the best
/// cut weight before any phase is processed.
///
/// Chosen as the largest positive Int64 value that avoids overflow when
/// compared or printed.
const INF64 : Int64 = 4611686018427387903L

///|
/// Result returned by `stoer_wagner_min_cut`.
///
/// Describes the global minimum cut of an undirected weighted graph:
/// the cheapest way to split all vertices into two non-empty groups.
///
/// Fields:
/// - `weight`: total weight of the edges that cross the cut.
/// - `cut`: the vertices on one side of the cut (original 0-based IDs).
///
/// The other side is the complement: all vertices NOT in `cut`.
///
/// Example:
/// ```
/// Graph:
///   0 ---1--- 1
///   |         |
///   1         1
///   |         |
///   3 ---1--- 2
///
/// A possible result:  weight = 2,  cut = [3]
/// Crossing edges:  3-0 (weight 1) and 3-2 (weight 1)
/// The complement side is {0, 1, 2}.
/// ```
pub(all) struct MinCutResult {
  weight : Int64
  cut : Array[Int]
} derive(Debug)

///|
/// Select the vertex with the maximum `w` value among alive, not-yet-added
/// vertices.
///
/// This is the inner loop of maximum adjacency search (also called
/// "maximum cardinality search"). At each step, the vertex most strongly
/// connected to the current set A is chosen next.
///
/// Parameters:
/// - `alive`: `alive[v]` is true if vertex `v` has not been contracted away.
/// - `added`: `added[v]` is true if vertex `v` has already been placed in A.
/// - `w`: `w[v]` is the total edge weight from `v` to the current set A.
///
/// Returns the index of the chosen vertex, or -1 if no eligible vertex
/// exists (all alive vertices are already in A, or none are alive).
///
/// ```
/// Example (alive = [T,T,T,T], added = [T,F,F,F], w = [-,1,0,2]):
///   Eligible: 1 (w=1), 2 (w=0), 3 (w=2)
///   Returns: 3  (highest w)
/// ```
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
/// Append all elements of `source` to `target` in order.
///
/// Used during vertex contraction: when supernode `t` is merged into
/// supernode `s`, all original vertices tracked by `t` are moved into
/// the member list of `s`.
///
/// After this call, `target` contains its original elements followed
/// by all elements of `source`. `source` is not modified.
fn append_members(target : Array[Int], source : Array[Int]) -> Unit {
  for v in source {
    target.push(v)
  }
}
