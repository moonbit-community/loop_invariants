// ============================================================================
// STOER-WAGNER MIN CUT - Main Algorithm
// ============================================================================
//
// The Stoer-Wagner algorithm finds the global minimum cut in an undirected
// weighted graph without specifying source/sink vertices.
//
// ALGORITHM OVERVIEW:
// ```
//   Repeat n-1 times (until only one vertex remains):
//     1. MAXIMUM ADJACENCY SEARCH:
//        Build set A by repeatedly adding the vertex most connected to A
//        Let s = second-to-last vertex, t = last vertex
//
//     2. PHASE CUT:
//        The cut {t} vs {all others} has weight w[t]
//        This is a valid s-t cut (s ∈ A, t isolated)
//
//     3. CONTRACT:
//        Merge t into s (combine into supernode)
//        Update edge weights to reflect merged vertex
//
//   The minimum cut seen across all phases is the global min cut.
// ```
//
// WHY IT WORKS:
// ```
//   Theorem: The maximum adjacency search produces a cut where the last
//   vertex t is separated from the rest. This cut has weight equal to
//   the sum of edges from t.
//
//   Key insight: If the global min cut separates s and t, we'll find it
//   in this phase. If not, contracting s and t doesn't affect the min cut,
//   so we'll find it in a later phase.
// ```
//
// TIME COMPLEXITY: O(V³) with simple implementation
//   (Can be improved to O(VE + V² log V) with priority queue)
// SPACE COMPLEXITY: O(V²) for adjacency matrix

///|
/// Compute the global minimum cut using Stoer-Wagner algorithm.
///
/// ALGORITHM:
/// ```
///   FOR phase = 0 TO n-2:
///     1. Initialize w[v] = 0 for all v, A = ∅
///     2. REPEAT alive_count times:
///        - Select v with max w[v] among alive, not-in-A vertices
///        - Add v to A
///        - Update w[u] += adj[v][u] for all u not in A
///     3. The last vertex t defines cut weight w[t]
///     4. Contract t into second-to-last vertex s
///        (merge members, sum edge weights)
/// ```
///
/// PARAMETERS:
///   - n: number of vertices (labeled 0 to n-1)
///   - edges: undirected edges as (u, v, weight) triples
///
/// RETURNS:
///   Some(result) with minimum cut, or None if n <= 1
///
/// NOTE:
///   Edge weights should be non-negative.
///   Parallel edges are handled (weights summed).
///
/// EXAMPLE:
/// ```
///   Square graph:
///     0 ---1--- 1
///     |         |
///     1         1
///     |         |
///     3 ---1--- 2
///
///   Min cut separates one vertex from the rest.
///   Cut weight = 2 (e.g., cut = {0}, crossing edges 0-1 and 0-3)
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
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, w) = edges[i]
    guard u >= 0 && u < n && v >= 0 && v < n && u != v else { continue }
    adj[u][v] = adj[u][v] + w
    adj[v][u] = adj[v][u] + w
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
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
  let mut alive_count = n
  let mut best_weight = INF64
  let mut best_cut : Array[Int] = []

  // Step 2: Run n-1 phases of contraction
  for phase = 0; phase < n - 1; phase = phase + 1 {
    guard alive_count > 1 else { break }

    // Maximum Adjacency Search for this phase
    let added = Array::make(n, false) // Vertices added to set A
    let w = Array::make(n, 0L) // w[v] = weight from v to set A
    let mut prev = -1 // Previous vertex (will become s)
    for iter = 0; iter < alive_count; iter = iter + 1 {
      // Select vertex with maximum connection to A
      let sel = select_max_vertex(alive, added, w)
      guard sel >= 0 else { break }
      added[sel] = true

      // Last iteration: sel is t, prev is s
      if iter == alive_count - 1 {
        // Phase cut: {sel} vs everyone else
        let cut_weight = w[sel]
        if cut_weight < best_weight {
          best_weight = cut_weight
          best_cut = members[sel]
        }

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
        alive_count = alive_count - 1
        break
      }

      // Not last iteration: update w[] for remaining vertices
      for v in 0..<n {
        if alive[v] && not(added[v]) {
          w[v] = w[v] + adj[sel][v]
        }
      }
      prev = sel
    } where {
      invariant: iter >= 0 && iter <= alive_count,
      reasoning: (
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
  } where {
    invariant: phase >= 0 && phase <= n - 1 && alive_count >= 1,
    reasoning: (
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
