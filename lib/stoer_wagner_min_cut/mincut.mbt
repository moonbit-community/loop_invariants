// ============================================================================
// STOER-WAGNER MIN CUT - Main Algorithm
// ============================================================================
//
// The Stoer-Wagner algorithm finds the global minimum cut in an undirected
// weighted graph without specifying source/sink vertices.
//
// ALGORITHM OVERVIEW:
// ```
//   Repeat n-1 times (until only one supernode remains):
//     1. MAXIMUM ADJACENCY SEARCH:
//        Start with set A = {any alive vertex}.
//        Repeatedly add the alive vertex with the highest total edge weight
//        to A.  Let s = second-to-last added, t = last added.
//
//     2. PHASE CUT:
//        The cut {t} vs {all others} has weight w[t].
//        This equals the minimum s-t cut value for this phase.
//        Record it as a global candidate.
//
//     3. CONTRACT:
//        Merge t into s (combine into a single supernode).
//        Update adj so edges to t are redirected to s.
//        Mark t as no longer alive.
//
//   Return the minimum candidate seen across all n-1 phases.
// ```
//
// WHY IT WORKS:
// ```
//   Theorem (Stoer-Wagner 1997):
//     For the ordering produced by maximum adjacency search,
//     the last vertex t is such that w[t] equals the minimum s-t cut.
//
//   Key insight: If the global min cut separates s and t, we find it
//   in this phase.  If it does not separate s and t, contracting s and t
//   does not destroy that cut, so we find it in a later phase.
//
//   Therefore some phase will always find the global minimum cut.
// ```
//
// TIME COMPLEXITY: O(V^3) with simple adjacency matrix implementation.
//   (Can be improved to O(VE + V^2 log V) with a priority queue.)
// SPACE COMPLEXITY: O(V^2) for the adjacency matrix.

///|
/// Compute the global minimum cut of an undirected weighted graph.
///
/// The **global minimum cut** is the cheapest way to partition all vertices
/// into two non-empty groups, where cost is the total weight of edges
/// crossing between the groups.
///
/// This implements the Stoer-Wagner algorithm (1997):
///
/// ```
/// Algorithm sketch:
///   Build adjacency matrix from edges.
///   FOR phase = 0 TO n-2:
///     1. Maximum adjacency search:
///        w[v] = 0 for all alive v,  A = empty set
///        FOR iter = 0 TO alive_count-1:
///          - pick v = argmax w[v] among alive vertices not in A
///          - add v to A
///          - for all alive u not in A: w[u] += adj[v][u]
///        s = second-to-last added,  t = last added
///     2. Phase cut weight = w[t]
///        (total edge weight from t to A, equals min s-t cut)
///     3. Contract: merge t into s
///        adj[s][u] += adj[t][u] for all alive u != s, t
///        members[s] += members[t]
///        alive[t] = false
///   Global min cut = minimum phase cut weight seen.
/// ```
///
/// Parameters:
/// - `n`: number of vertices, labeled 0 to n-1.
/// - `edges`: undirected edges as `(u, v, weight)` triples.
///   Each edge is counted once (the algorithm uses it in both directions).
///   Parallel edges between the same pair of vertices are summed.
///   Self-loops and out-of-range vertices are silently ignored.
///
/// Returns:
/// - `None` if `n <= 1` (a cut requires at least two vertices).
/// - `Some(result)` otherwise, where `result.weight` is the minimum cut
///   weight and `result.cut` is the set of original vertex IDs on one side.
///
/// Edge weights must be non-negative for the algorithm to be correct.
///
/// Example (square graph, unit weights):
/// ```
///   0 ---1--- 1
///   |         |
///   1         1
///   |         |
///   3 ---1--- 2
///
///   Min cut weight = 2.
///   One side: {3}  (crossing edges: 3-0 and 3-2)
/// ```
pub fn stoer_wagner_min_cut(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
) -> MinCutResult? {
  // Need at least 2 vertices for a cut
  if n <= 1 {
    return None
  }

  // Step 1: Build adjacency matrix
  // Using matrix for O(1) edge weight lookup
  // Parallel edges are summed
  let adj : Array[Array[Int64]] = Array::makei(n, _ => Array::make(n, 0L))
  for i in 0..<edges.length() {
    let (u, v, w) = edges[i]
    guard u >= 0 && u < n && v >= 0 && v < n && u != v else { continue }
    adj[u][v] = adj[u][v] + w
    adj[v][u] = adj[v][u] + w
  } where {
    proof_invariant: i >= 0 && i <= edges.length(),
    proof_reasoning: (
      #|INVARIANT (adjacency matrix):
      #|  For edges[0..i), their weights are accumulated in adj[][].
      #|  adj[u][v] = adj[v][u] = sum of weights for edges between u and v.
      #|
      #|WHY SUM PARALLEL EDGES:
      #|  Multiple edges between same vertices act as a single edge
      #|  with combined capacity for min cut purposes.
      #|
      #|MAINTENANCE:
      #|  Add weight to both adj[u][v] and adj[v][u] (symmetric).
      #|
      #|TERMINATION:
      #|  At i = edges.length(), full adjacency matrix built.
    ),
  }

  // alive[v] = true if vertex v hasn't been contracted yet
  let alive = Array::make(n, true)

  // members[v] = original vertices represented by supernode v
  let members : Array[Array[Int]] = Array::makei(n, i => [i])
  let empty_cut : Array[Int] = []

  // Step 2: Run n-1 phases of contraction
  let (_, best_weight, best_cut) = for phase = 0, alive_count = n, best_weight = INF64, best_cut = empty_cut; phase <
                                      n - 1; {
    if alive_count <= 1 {
      break (alive_count, best_weight, best_cut)
    }

    // Maximum Adjacency Search for this phase
    let added = Array::make(n, false) // Vertices added to set A
    let w = Array::make(n, 0L) // w[v] = weight from v to set A
    let (alive_count, phase_weight, phase_cut) = for iter = 0, prev = -1
                                                     iter < alive_count
                                                     iter = iter + 1 {
      // Select vertex with maximum connection to A
      let sel = select_max_vertex(alive, added, w)
      if sel < 0 {
        break (alive_count, INF64, empty_cut)
      }
      added[sel] = true

      // Last iteration: sel is t, prev is s
      if iter == alive_count - 1 {
        // Phase cut: {sel} vs everyone else
        let cut_weight = w[sel]
        let phase_cut = members[sel]

        // Contract sel into prev (if prev exists)
        if prev >= 0 {
          // Merge edge weights: edges to sel become edges to prev
          for v in 0..<n {
            guard alive[v] && v != prev && v != sel else { continue }
            adj[prev][v] = adj[prev][v] + adj[sel][v]
            adj[v][prev] = adj[prev][v]
          }
          // Merge member lists
          append_members(members[prev], members[sel])
        }

        // Remove sel from consideration
        alive[sel] = false
        break (alive_count - 1, cut_weight, phase_cut)
      }

      // Not last iteration: update w[] for remaining vertices
      for v in 0..<n {
        if alive[v] && !added[v] {
          w[v] = w[v] + adj[sel][v]
        }
      }
      continue iter + 1, sel
    } nobreak {
      (alive_count, INF64, empty_cut)
    } where {
      proof_invariant: iter >= 0 && iter <= alive_count,
      proof_reasoning: (
        #|INVARIANT (maximum adjacency search):
        #|  Let A = {v : added[v] = true}.
        #|  |A| = iter at the start of each iteration.
        #|
        #|  For any alive vertex u ∉ A:
        #|    w[u] = Σ adj[v][u] for all v ∈ A
        #|         = total edge weight from u to set A
        #|
        #|  prev = most recently added vertex (or -1 if iter = 0)
        #|
        #|WHY MAX ADJACENCY WORKS:
        #|  By always selecting the most connected vertex:
        #|  1. We build a "tight" ordering of vertices
        #|  2. The last vertex t is maximally connected to A-{s}
        #|  3. The cut {t} has weight = w[t] = connection to A
        #|  4. This is a valid s-t cut by construction
        #|
        #|MAINTENANCE:
        #|  Select max w[] vertex, add to A, update w[] for others.
        #|
        #|TERMINATION:
        #|  At iter = alive_count - 1, we have s = prev, t = sel.
      ),
    }
    let (best_weight, best_cut) = if phase_weight < best_weight {
      (phase_weight, phase_cut)
    } else {
      (best_weight, best_cut)
    }
    continue phase + 1, alive_count, best_weight, best_cut
  } nobreak {
    (alive_count, best_weight, best_cut)
  } where {
    proof_invariant: phase >= 0 && phase <= n - 1 && alive_count >= 1,
    proof_reasoning: (
      #|INVARIANT (contraction phases):
      #|  After phase k, exactly k+1 original vertices have been contracted.
      #|  alive_count = n - (k+1) = remaining supernodes.
      #|
      #|  For alive vertices u ≠ v:
      #|    adj[u][v] = total original edge weight between
      #|                members[u] and members[v]
      #|
      #|  members[u] = set of original vertices in supernode u
      #|
      #|  best_weight = minimum cut weight seen in phases 0..k
      #|  best_cut = corresponding cut side (original vertices)
      #|
      #|GLOBAL MIN CUT PROPERTY:
      #|  The global min cut either:
      #|  1. Separates s and t in some phase → found in that phase
      #|  2. Doesn't separate s and t → contracting preserves it
      #|
      #|  So we're guaranteed to find it in some phase.
      #|
      #|MAINTENANCE:
      #|  Each phase finds a valid cut, compares to best, contracts.
      #|
      #|TERMINATION:
      #|  After n-1 phases, one supernode remains, all cuts checked.
    ),
  }
  if best_weight == INF64 {
    None
  } else {
    Some({ weight: best_weight, cut: best_cut })
  }
}
