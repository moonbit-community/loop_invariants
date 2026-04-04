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
/// Hopcroft-Karp algorithm for maximum bipartite matching.
/// Time complexity: O(E * sqrt(V)) - faster than Hungarian for large graphs.
struct HopcroftKarp {
  graph : BipartiteGraph
  match_left : Array[Int]
  match_right : Array[Int]
  dist : Array[Int]
}

///|
fn HopcroftKarp::new(graph : BipartiteGraph) -> HopcroftKarp {
  {
    graph,
    match_left: Array::make(graph.n_left, -1),
    match_right: Array::make(graph.n_right, -1),
    dist: Array::make(graph.n_left + 1, 0),
  }
}

///|
/// BFS to build layered graph
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
/// DFS to find augmenting path
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
/// Find maximum matching size using Hopcroft-Karp.
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
      reasoning: (
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
    reasoning: (
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
/// Get the matched pairs after running max_matching().
/// Returns array of (left_vertex, right_vertex) pairs.
pub fn HopcroftKarp::get_matching(self : HopcroftKarp) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for u in 0..<self.graph.n_left {
    if self.match_left[u] >= 0 {
      result.push((u, self.match_left[u]))
    }
  }
  result
}

///|
/// Find minimum vertex cover using König's theorem.
/// Calls max_matching() to ensure the matching is maximum.
/// Returns (left_vertices, right_vertices) that form the cover.
/// The size of minimum vertex cover equals maximum matching size.
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
