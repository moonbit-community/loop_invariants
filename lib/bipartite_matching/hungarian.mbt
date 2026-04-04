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
/// Hungarian algorithm (Kuhn's algorithm) for maximum bipartite matching.
/// Time complexity: O(V * E)
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
/// Try to find augmenting path from left vertex u
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
/// Find maximum matching size.
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
    reasoning: (
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
/// Get the matched pairs after running max_matching().
/// Returns array of (left_vertex, right_vertex) pairs.
pub fn Hungarian::get_matching(self : Hungarian) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for u in 0..<self.graph.n_left {
    if self.match_left[u] >= 0 {
      result.push((u, self.match_left[u]))
    }
  }
  result
}
