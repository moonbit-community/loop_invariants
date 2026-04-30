// ============================================================================
// HOPCROFT-KARP ALGORITHM
// ============================================================================
//
// Faster algorithm for maximum bipartite matching using BFS + DFS.
//
// ALGORITHM:
// 1. BFS to find all shortest augmenting paths (layered by distance)
// 2. DFS to find vertex-disjoint augmenting paths
// 3. Augment all found paths simultaneously
// 4. Repeat until no augmenting paths exist
//
// KEY INSIGHT:
// By processing all shortest augmenting paths in each phase, we reduce
// the number of phases to O(sqrt(V)), giving overall O(E * sqrt(V)).
//
// INVARIANTS:
// 1. After each augmentation, matching size increases by 1
// 2. No augmenting path exists iff matching is maximum
// 3. Paths found in each phase are vertex-disjoint
//
// TIME COMPLEXITY: O(E * sqrt(V))
// SPACE COMPLEXITY: O(V + E)

///|
const HK_INF : Int = 2147483647

///|
/// State for the Hopcroft-Karp algorithm for maximum bipartite matching.
///
/// The algorithm alternates between two phases until no augmenting path
/// exists:
///
/// 1. **BFS phase**: builds a layered (level) graph from all unmatched left
///    vertices. Layers alternate between unmatched and matched edges. BFS
///    stops as soon as any unmatched right vertex is reached. This guarantees
///    that only shortest augmenting paths are considered in the current phase.
///
/// 2. **DFS phase**: traverses the layered graph from each unmatched left
///    vertex, augmenting along valid layer-respecting paths. Vertices that
///    lead to dead ends are marked with `dist = HK_INF` to prevent revisiting
///    within the same phase.
///
/// Fields:
/// - `match_left[u]`  : right vertex matched to left vertex `u`, or `-1`
/// - `match_right[v]` : left vertex matched to right vertex `v`, or `-1`
/// - `dist[u]`        : BFS layer of left vertex `u` in the current phase;
///                      `dist[n_left]` serves as a sentinel for unmatched
///                      right vertices
///
/// Create via `BipartiteGraph::hopcroft_karp()`.
///
/// Time complexity: O(E * sqrt(V)).
/// Space complexity: O(V + E).
struct HopcroftKarp {
  graph : BipartiteGraph
  match_left : Array[Int]
  match_right : Array[Int]
  dist : Array[Int]
}

///|
fn HopcroftKarp::HopcroftKarp(graph : BipartiteGraph) -> HopcroftKarp {
  {
    graph,
    match_left: Array::make(graph.n_left, -1),
    match_right: Array::make(graph.n_right, -1),
    dist: Array::make(graph.n_left + 1, 0),
  }
}

///|
/// BFS phase: build a layered graph over left vertices reachable from
/// unmatched left vertices via alternating (unmatched then matched) edges.
///
/// Unmatched left vertices start at layer 0. An unmatched right vertex is
/// represented by the sentinel index `n_left`. Returns `true` if at least one
/// unmatched right vertex was reached (i.e., an augmenting path exists).
///
/// After this call, `dist[u]` contains the BFS layer for each reachable left
/// vertex, and `dist[n_left]` holds the layer of the first unmatched right
/// vertex reached (or `HK_INF` if none was found).
fn HopcroftKarp::bfs(self : HopcroftKarp) -> Bool {
  let queue : @queue.Queue[Int] = @queue.new()
  for u in 0..<self.graph.n_left {
    if self.match_left[u] < 0 {
      self.dist[u] = 0
      queue.push(u)
    } else {
      self.dist[u] = HK_INF
    }
  }
  self.dist[self.graph.n_left] = HK_INF // Sentinel for unmatched
  let _ = for popped = queue.pop() {
    match popped {
      None => break ()
      Some(u) => {
        if self.dist[u] < self.dist[self.graph.n_left] {
          for v in self.graph.adj[u] {
            let next = if self.match_right[v] < 0 {
              self.graph.n_left
            } else {
              self.match_right[v]
            }
            if self.dist[next] == HK_INF {
              self.dist[next] = self.dist[u] + 1
              if next < self.graph.n_left {
                queue.push(next)
              }
            }
          }
        }
        continue queue.pop()
      }
    }
  }
  self.dist[self.graph.n_left] != HK_INF
}

///|
/// DFS phase: attempt to find and augment a path from left vertex `u` that
/// follows the layered graph produced by the most recent BFS phase.
///
/// Only edges to right vertices whose matched partner lies exactly one layer
/// deeper are followed (`dist[next] == dist[u] + 1`). When the sentinel index
/// `n_left` is reached, an unmatched right vertex has been found and the path
/// is augmented on the way back.
///
/// Left vertices that lead to dead ends are marked `dist[u] = HK_INF` to
/// prune them for subsequent DFS calls within the same phase.
///
/// Returns `true` if an augmenting path was found and the matching updated.
fn HopcroftKarp::dfs(self : HopcroftKarp, u : Int) -> Bool {
  if u >= self.graph.n_left {
    return true // Reached unmatched right vertex
  }
  for v in self.graph.adj[u] {
    let next = if self.match_right[v] < 0 {
      self.graph.n_left
    } else {
      self.match_right[v]
    }
    if self.dist[next] == self.dist[u] + 1 {
      if self.dfs(next) {
        self.match_right[v] = u
        self.match_left[u] = v
        return true
      }
    }
  }
  self.dist[u] = HK_INF // Mark as visited
  false
}

///|
/// Run the Hopcroft-Karp algorithm and return the maximum matching size.
///
/// Each iteration is one BFS+DFS phase. The BFS builds a layered graph of
/// shortest augmenting paths; the DFS finds and applies all vertex-disjoint
/// augmenting paths within that layered graph. The number of phases is
/// O(sqrt(V)), giving the overall O(E * sqrt(V)) complexity.
///
/// After this call, `get_matching()` returns the individual matched pairs and
/// `min_vertex_cover()` returns the minimum vertex cover.
///
/// Example:
/// ```
/// let graph = BipartiteGraph(4, 4)
/// graph.add_edge(0, 0)
/// graph.add_edge(1, 1)
/// graph.add_edge(2, 2)
/// graph.add_edge(3, 3)
/// let matcher = graph.hopcroft_karp()
/// let size = matcher.max_matching() // 4
/// ```
pub fn HopcroftKarp::max_matching(self : HopcroftKarp) -> Int {
  // Keep finding augmenting paths until none exist
  for matching = 0; self.bfs(); {
    let phase_matches = for u = 0, count = 0; u < self.graph.n_left; {
      let new_count = if self.match_left[u] < 0 && self.dfs(u) {
        count + 1
      } else {
        count
      }
      continue u + 1, new_count
    } nobreak {
      count
    } where {
      proof_invariant: u >= 0 && u <= self.graph.n_left,
      proof_reasoning: (
        #|INVARIANT (HK phase):
        #|All unmatched left vertices in [0, u) have been attempted for DFS
        #|augmentations in the current BFS layer graph.
        #|MAINTENANCE:
        #|Run DFS from each unmatched u and increment count on success.
        #|TERMINATION:
        #|At u = n_left, the phase has tried all unmatched left vertices.
      ),
    }
    continue matching + phase_matches
  } nobreak {
    matching
  } where {
    proof_invariant: matching >= 0,
    proof_reasoning: (
      #|INVARIANT (HK phases):
      #|matching accumulates successful augmentations from previous phases.
      #|MAINTENANCE:
      #|Each phase runs BFS, then attempts DFS from unmatched vertices.
      #|TERMINATION:
      #|BFS returns false when no augmenting path exists.
    ),
  }
}

///|
/// Return the matched pairs as an array of `(left_vertex, right_vertex)`.
///
/// Must be called after `max_matching()`. Returns only the pairs that are
/// part of the maximum matching; unmatched left vertices are omitted.
///
/// The order of pairs reflects the left-vertex index order and is stable.
///
/// Example:
/// ```
/// let graph = BipartiteGraph(2, 2)
/// graph.add_edge(0, 0)
/// graph.add_edge(1, 1)
/// let matcher = graph.hopcroft_karp()
/// let _ = matcher.max_matching()
/// let pairs = matcher.get_matching() // [(0, 0), (1, 1)]
/// ```
pub fn HopcroftKarp::get_matching(self : HopcroftKarp) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = [
    for u in 0..<self.graph.n_left if self.match_left[u] >= 0 => {
      (u, self.match_left[u])
    }
  ]
  result
}

///|
/// Compute the minimum vertex cover using König's theorem.
///
/// A **vertex cover** is a set of vertices such that every edge in the graph
/// has at least one endpoint in the set. König's theorem states that in any
/// bipartite graph the minimum vertex cover size equals the maximum matching
/// size.
///
/// This method calls `max_matching()` internally, so it is safe to call
/// directly without a preceding `max_matching()` call.
///
/// The cover is constructed from the maximum matching via an alternating DFS
/// from all unmatched left vertices:
/// - Left vertices **not** reachable in the alternating forest are in the cover.
/// - Right vertices **reachable** in the alternating forest are in the cover.
///
/// Returns `(left_cover, right_cover)` where each array contains the vertex
/// indices belonging to the cover on that side.
///
/// Example:
/// ```
/// let graph = BipartiteGraph(3, 3)
/// graph.add_edge(0, 0)
/// graph.add_edge(0, 1)
/// graph.add_edge(1, 1)
/// graph.add_edge(2, 2)
/// let matcher = graph.hopcroft_karp()
/// let (left_cover, right_cover) = matcher.min_vertex_cover()
/// // left_cover.length() + right_cover.length() == matcher.max_matching()
/// ```
pub fn HopcroftKarp::min_vertex_cover(
  self : HopcroftKarp,
) -> (Array[Int], Array[Int]) {
  let _ = self.max_matching()
  let graph = self.graph
  // König's theorem: In bipartite graph, |max matching| = |min vertex cover|
  // Build alternating forest from unmatched left vertices
  let visited_left = Array::make(graph.n_left, false)
  let visited_right = Array::make(graph.n_right, false)

  // DFS from unmatched left vertices through alternating paths
  fn dfs_cover(
    graph : BipartiteGraph,
    match_right : Array[Int],
    u : Int,
    visited_left : Array[Bool],
    visited_right : Array[Bool],
  ) -> Unit {
    if visited_left[u] {
      return
    }
    visited_left[u] = true
    for v in graph.adj[u] {
      if !visited_right[v] {
        visited_right[v] = true
        if match_right[v] >= 0 && !visited_left[match_right[v]] {
          dfs_cover(
            graph,
            match_right,
            match_right[v],
            visited_left,
            visited_right,
          )
        }
      }
    }
  }

  // Start from unmatched left vertices
  for u in 0..<graph.n_left {
    if self.match_left[u] < 0 {
      dfs_cover(graph, self.match_right, u, visited_left, visited_right)
    }
  }

  // Vertex cover: left vertices NOT visited + right vertices visited
  let left_cover : Array[Int] = []
  let right_cover : Array[Int] = []
  for u in 0..<graph.n_left {
    if !visited_left[u] {
      left_cover.push(u)
    }
  }
  for v in 0..<graph.n_right {
    if visited_right[v] {
      right_cover.push(v)
    }
  }
  (left_cover, right_cover)
}
