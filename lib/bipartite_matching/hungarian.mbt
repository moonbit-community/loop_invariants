// ============================================================================
// HUNGARIAN ALGORITHM (Kuhn's Algorithm)
// ============================================================================
//
// Simple DFS-based augmenting path algorithm for maximum bipartite matching.
//
// ALGORITHM:
// For each unmatched vertex in left set, try to find augmenting path via DFS.
// If found, augment the matching.
//
// KEY INSIGHT (Augmenting Path):
// A path that alternates between unmatched and matched edges, starting and
// ending at unmatched vertices. Flipping the path increases matching by 1.
//
// INVARIANTS:
// 1. After each augmentation, matching size increases by 1
// 2. No augmenting path exists iff matching is maximum
//
// TIME COMPLEXITY: O(V * E)
// SPACE COMPLEXITY: O(V + E)

///|
/// State for the Hungarian (Kuhn's) algorithm for maximum bipartite matching.
///
/// The algorithm performs a DFS from each unmatched left vertex in turn,
/// looking for an augmenting path. When one is found the matching is updated
/// and the count increases by one. A `visited` array prevents the DFS from
/// revisiting right vertices within a single left-vertex attempt.
///
/// - `match_left[u]`  : right vertex matched to left vertex `u`, or `-1`
/// - `match_right[v]` : left vertex matched to right vertex `v`, or `-1`
/// - `visited[v]`     : true if right vertex `v` was seen in the current DFS
///
/// Create via `BipartiteGraph::hungarian()`.
///
/// Time complexity: O(V * E).
/// Space complexity: O(V + E).
struct Hungarian {
  graph : BipartiteGraph
  match_left : Array[Int]
  match_right : Array[Int]
  visited : Array[Bool]
}

///|
fn Hungarian::new(graph : BipartiteGraph) -> Hungarian {
  {
    graph,
    match_left: Array::make(graph.n_left, -1),
    match_right: Array::make(graph.n_right, -1),
    visited: Array::make(graph.n_right, false),
  }
}

///|
/// Attempt to find an augmenting path starting from left vertex `u` using DFS.
///
/// Traverses neighbours of `u` in the adjacency list. For each unvisited
/// right vertex `v`:
/// - If `v` is unmatched, augment immediately.
/// - If `v` is matched to some left vertex `w`, recurse from `w` to see
///   whether `w` can be rerouted.
///
/// Returns `true` if an augmenting path was found and the matching updated.
/// The `visited` array must be reset to `false` before each top-level call.
fn Hungarian::dfs(self : Hungarian, u : Int) -> Bool {
  for v in self.graph.adj[u] {
    if self.visited[v] {
      continue
    }
    self.visited[v] = true

    // If v is unmatched or we can find alternating path from v's match
    if self.match_right[v] < 0 || self.dfs(self.match_right[v]) {
      self.match_left[u] = v
      self.match_right[v] = u
      break true
    }
  } nobreak {
    false
  }
}

///|
/// Run the Hungarian algorithm and return the maximum matching size.
///
/// Iterates over every left vertex `u` in order. For each `u` the `visited`
/// array is cleared and a DFS augmentation is attempted. The result is the
/// total number of successful augmentations.
///
/// After this call, `get_matching()` returns the individual matched pairs.
///
/// Example:
/// ```
/// let graph = BipartiteGraph::new(3, 3)
/// graph.add_edge(0, 0)
/// graph.add_edge(1, 1)
/// graph.add_edge(2, 2)
/// let matcher = graph.hungarian()
/// let size = matcher.max_matching() // 3
/// ```
pub fn Hungarian::max_matching(self : Hungarian) -> Int {
  for u = 0, matching = 0; u < self.graph.n_left; {
    // Reset visited for each left vertex
    self.visited.fill(false)
    let new_matching = if self.dfs(u) { matching + 1 } else { matching }
    continue u + 1, new_matching
  } nobreak {
    matching
  } where {
    proof_invariant: u >= 0 && u <= self.graph.n_left,
    proof_reasoning: (
      #|INVARIANT (Kuhn augmentation):
      #|matching counts the number of successful augmentations for processed
      #|left vertices in [0, u).
      #|MAINTENANCE:
      #|Attempt to find an augmenting path from u; if found, increase matching.
      #|TERMINATION:
      #|At u = n_left, no more augmenting paths remain, so matching is maximum.
    ),
  }
}

///|
/// Return the matched pairs as an array of `(left_vertex, right_vertex)`.
///
/// Must be called after `max_matching()`. Returns only the pairs that are
/// part of the maximum matching; unmatched left vertices are omitted.
///
/// The order of pairs reflects DFS traversal order and is not guaranteed to
/// be stable across runs with different edge insertion orders.
///
/// Example:
/// ```
/// let graph = BipartiteGraph::new(2, 2)
/// graph.add_edge(0, 0)
/// graph.add_edge(1, 1)
/// let matcher = graph.hungarian()
/// let _ = matcher.max_matching()
/// let pairs = matcher.get_matching() // [(0, 0), (1, 1)]
/// ```
pub fn Hungarian::get_matching(self : Hungarian) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = [|
    for u in 0..<self.graph.n_left if self.match_left[u] >= 0 => {
      (u, self.match_left[u])
    }
  |]
  result
}
