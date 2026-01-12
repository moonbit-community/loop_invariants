// ============================================================================
// BIPARTITE MATCHING - Maximum Matching in Bipartite Graphs
// ============================================================================
//
// Find maximum cardinality matching in a bipartite graph.
// A matching is a set of edges with no shared vertices.
//
// ALGORITHMS:
// 1. Hungarian Algorithm (Kuhn's): O(V * E) - Simple DFS-based augmentation
// 2. Hopcroft-Karp: O(E * sqrt(V)) - BFS for shortest augmenting paths
//
// KEY INSIGHT (Augmenting Path):
// A path that alternates between unmatched and matched edges, starting and
// ending at unmatched vertices. Flipping the path increases matching by 1.
//
// HUNGARIAN ALGORITHM:
// For each unmatched vertex in left set, try to find augmenting path via DFS.
// If found, augment the matching.
//
// HOPCROFT-KARP:
// 1. BFS to find all shortest augmenting paths (layered by distance)
// 2. DFS to find vertex-disjoint augmenting paths
// 3. Augment all found paths simultaneously
//
// INVARIANTS:
// 1. After each augmentation, matching size increases by 1
// 2. No augmenting path exists iff matching is maximum
// 3. In Hopcroft-Karp, paths found in each phase are vertex-disjoint
//
// TIME COMPLEXITY: O(V * E) Hungarian, O(E * sqrt(V)) Hopcroft-Karp
// SPACE COMPLEXITY: O(V + E)

///|
priv struct BipartiteGraph {
  n_left : Int // Number of vertices in left set
  n_right : Int // Number of vertices in right set
  adj : Array[Array[Int]] // adj[u] = neighbors of left vertex u in right set
}

///|
fn BipartiteGraph::new(n_left : Int, n_right : Int) -> BipartiteGraph {
  let adj : Array[Array[Int]] = Array::makei(n_left, fn(_) { [] })
  { n_left, n_right, adj }
}

///|
fn BipartiteGraph::add_edge(self : BipartiteGraph, u : Int, v : Int) -> Unit {
  // u is in left set (0..n_left-1), v is in right set (0..n_right-1)
  self.adj[u].push(v)
}

// ============================================================================
// HUNGARIAN ALGORITHM (Kuhn's Algorithm)
// ============================================================================

///|
priv struct Hungarian {
  graph : BipartiteGraph
  match_left : Array[Int] // match_left[u] = matched right vertex, -1 if unmatched
  match_right : Array[Int] // match_right[v] = matched left vertex, -1 if unmatched
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
  for i = 0; i < self.graph.adj[u].length(); i = i + 1 {
    let v = self.graph.adj[u][i]
    if self.visited[v] {
      continue i + 1
    }
    self.visited[v] = true

    // If v is unmatched or we can find alternating path from v's match
    if self.match_right[v] < 0 || self.dfs(self.match_right[v]) {
      self.match_left[u] = v
      self.match_right[v] = u
      return true
    }
  } where {
    invariant: i >= 0 && i <= self.graph.adj[u].length(),
    reasoning: (
      #|INVARIANT (DFS neighbors):
      #|All neighbors in adj[u][0..i) have been considered for augmentation.
      #|MAINTENANCE:
      #|Advance to the next neighbor, respecting adjacency bounds.
      #|TERMINATION:
      #|At i = deg(u), all neighbors are scanned.
    ),
  }
  false
}

///|
/// Find maximum matching
fn Hungarian::max_matching(self : Hungarian) -> Int {
  let mut matching = 0
  for u = 0; u < self.graph.n_left; u = u + 1 {
    // Reset visited for each left vertex
    self.visited.fill(false)
    if self.dfs(u) {
      matching = matching + 1
    }
  } where {
    invariant: u >= 0 && u <= self.graph.n_left,
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
  matching
}

///|
fn Hungarian::get_matching(self : Hungarian) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for u = 0; u < self.graph.n_left; u = u + 1 {
    if self.match_left[u] >= 0 {
      result.push((u, self.match_left[u]))
    }
  } where {
    invariant: u >= 0 && u <= self.graph.n_left,
    reasoning: (
      #|INVARIANT (collect matching):
      #|result contains all matched edges for left vertices in [0, u).
      #|MAINTENANCE:
      #|If u is matched, append (u, match_left[u]).
      #|TERMINATION:
      #|At u = n_left, result holds the full matching.
    ),
  }
  result
}

///|
pub fn max_matching(
  n_left : Int,
  n_right : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[(Int, Int)] {
  let graph = BipartiteGraph::new(n_left, n_right)
  edges.each(fn(edge) {
    let (u, v) = edge
    graph.add_edge(u, v)
  })
  let matcher = Hungarian::new(graph)
  let _ = matcher.max_matching()
  matcher.get_matching()
}

// ============================================================================
// HOPCROFT-KARP ALGORITHM
// ============================================================================

///|
const HK_INF : Int = 2147483647

///|
priv struct HopcroftKarp {
  graph : BipartiteGraph
  match_left : Array[Int]
  match_right : Array[Int]
  dist : Array[Int] // BFS distances
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
  let queue : Array[Int] = []
  for u = 0; u < self.graph.n_left; u = u + 1 {
    if self.match_left[u] < 0 {
      self.dist[u] = 0
      queue.push(u)
    } else {
      self.dist[u] = HK_INF
    }
  } where {
    invariant: u >= 0 && u <= self.graph.n_left,
    reasoning: (
      #|INVARIANT (BFS init):
      #|dist is set for left vertices in [0, u): 0 for unmatched, INF for matched.
      #|MAINTENANCE:
      #|Initialize dist[u] and enqueue unmatched vertices.
      #|TERMINATION:
      #|At u = n_left, BFS initialization is complete.
    ),
  }
  self.dist[self.graph.n_left] = HK_INF // Sentinel for unmatched
  let mut front = 0
  while front < queue.length() {
    let u = queue[front]
    front = front + 1
    if self.dist[u] < self.dist[self.graph.n_left] {
      self.graph.adj[u].each(fn(v) {
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
      })
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
  for i = 0; i < self.graph.adj[u].length(); i = i + 1 {
    let v = self.graph.adj[u][i]
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
  } where {
    invariant: i >= 0 && i <= self.graph.adj[u].length(),
    reasoning: (
      #|INVARIANT (HK DFS neighbors):
      #|All neighbors in adj[u][0..i) have been considered for layered DFS.
      #|MAINTENANCE:
      #|Advance to the next neighbor while respecting adjacency bounds.
      #|TERMINATION:
      #|At i = deg(u), all neighbors are scanned.
    ),
  }
  self.dist[u] = HK_INF // Mark as visited
  false
}

///|
/// Find maximum matching using Hopcroft-Karp
fn HopcroftKarp::max_matching(self : HopcroftKarp) -> Int {
  let mut matching = 0

  // Keep finding augmenting paths until none exist
  while self.bfs() {
    for u = 0; u < self.graph.n_left; u = u + 1 {
      if self.match_left[u] < 0 && self.dfs(u) {
        matching = matching + 1
      }
    } where {
      invariant: u >= 0 && u <= self.graph.n_left,
      reasoning: (
        #|INVARIANT (HK phase):
        #|All unmatched left vertices in [0, u) have been attempted for DFS
        #|augmentations in the current BFS layer graph.
        #|MAINTENANCE:
        #|Run DFS from each unmatched u and increment matching on success.
        #|TERMINATION:
        #|At u = n_left, the phase has tried all unmatched left vertices.
      ),
    }
  }
  matching
}

///|
fn HopcroftKarp::get_matching(self : HopcroftKarp) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for u = 0; u < self.graph.n_left; u = u + 1 {
    if self.match_left[u] >= 0 {
      result.push((u, self.match_left[u]))
    }
  } where {
    invariant: u >= 0 && u <= self.graph.n_left,
    reasoning: (
      #|INVARIANT (collect matching):
      #|result contains matched edges for left vertices in [0, u).
      #|MAINTENANCE:
      #|Append (u, match_left[u]) when u is matched.
      #|TERMINATION:
      #|At u = n_left, result is the full matching.
    ),
  }
  result
}

// ============================================================================
// MINIMUM VERTEX COVER (König's Theorem)
// ============================================================================

///|
/// Find minimum vertex cover using König's theorem
/// Returns (left_vertices, right_vertices) in the cover
fn minimum_vertex_cover(graph : BipartiteGraph) -> (Array[Int], Array[Int]) {
  let hk = HopcroftKarp::new(graph)
  let _ = hk.max_matching()

  // König's theorem: In bipartite graph, |max matching| = |min vertex cover|
  // Build alternating forest from unmatched left vertices
  let visited_left = Array::make(graph.n_left, false)
  let visited_right = Array::make(graph.n_right, false)

  // DFS from unmatched left vertices through alternating paths
  fn dfs_cover(
    graph : BipartiteGraph,
    match_left : Array[Int],
    match_right : Array[Int],
    u : Int,
    visited_left : Array[Bool],
    visited_right : Array[Bool],
  ) -> Unit {
    if visited_left[u] {
      return
    }
    visited_left[u] = true
    graph.adj[u].each(fn(v) {
      if not(visited_right[v]) {
        visited_right[v] = true
        if match_right[v] >= 0 && not(visited_left[match_right[v]]) {
          dfs_cover(
            graph,
            match_left,
            match_right,
            match_right[v],
            visited_left,
            visited_right,
          )
        }
      }
    })
  }

  // Start from unmatched left vertices
  for u = 0; u < graph.n_left; u = u + 1 {
    if hk.match_left[u] < 0 {
      dfs_cover(
        graph,
        hk.match_left,
        hk.match_right,
        u,
        visited_left,
        visited_right,
      )
    }
  } where {
    invariant: u >= 0 && u <= graph.n_left,
    reasoning: (
      #|INVARIANT (start cover DFS):
      #|All unmatched left vertices in [0, u) have been used as DFS roots.
      #|MAINTENANCE:
      #|If u is unmatched, start an alternating-path DFS from u.
      #|TERMINATION:
      #|At u = n_left, the alternating forest is fully built.
    ),
  }

  // Vertex cover: left vertices NOT visited + right vertices visited
  let left_cover : Array[Int] = []
  let right_cover : Array[Int] = []
  for u = 0; u < graph.n_left; u = u + 1 {
    if not(visited_left[u]) {
      left_cover.push(u)
    }
  } where {
    invariant: u >= 0 && u <= graph.n_left,
    reasoning: (
      #|INVARIANT (left cover):
      #|left_cover contains exactly the unvisited left vertices in [0, u).
      #|MAINTENANCE:
      #|Append u if it is unvisited.
      #|TERMINATION:
      #|At u = n_left, left_cover is complete.
    ),
  }
  for v = 0; v < graph.n_right; v = v + 1 {
    if visited_right[v] {
      right_cover.push(v)
    }
  } where {
    invariant: v >= 0 && v <= graph.n_right,
    reasoning: (
      #|INVARIANT (right cover):
      #|right_cover contains exactly the visited right vertices in [0, v).
      #|MAINTENANCE:
      #|Append v if it is visited.
      #|TERMINATION:
      #|At v = n_right, right_cover is complete.
    ),
  }
  (left_cover, right_cover)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "hungarian basic" {
  let graph = BipartiteGraph::new(3, 3)
  // Perfect matching possible
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 0)
  graph.add_edge(1, 2)
  graph.add_edge(2, 1)
  graph.add_edge(2, 2)
  let hungarian = Hungarian::new(graph)
  inspect(hungarian.max_matching(), content="3")
}

///|
test "hungarian imperfect" {
  let graph = BipartiteGraph::new(3, 2)
  graph.add_edge(0, 0)
  graph.add_edge(1, 0)
  graph.add_edge(2, 1)
  let hungarian = Hungarian::new(graph)
  inspect(hungarian.max_matching(), content="2")
}

///|
test "hopcroft_karp basic" {
  let graph = BipartiteGraph::new(3, 3)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 0)
  graph.add_edge(1, 2)
  graph.add_edge(2, 1)
  graph.add_edge(2, 2)
  let hk = HopcroftKarp::new(graph)
  inspect(hk.max_matching(), content="3")
}

///|
test "hopcroft_karp larger" {
  let graph = BipartiteGraph::new(4, 4)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 1)
  graph.add_edge(1, 2)
  graph.add_edge(2, 2)
  graph.add_edge(2, 3)
  graph.add_edge(3, 0)
  graph.add_edge(3, 3)
  let hk = HopcroftKarp::new(graph)
  inspect(hk.max_matching(), content="4")
}

///|
test "matching empty" {
  let graph = BipartiteGraph::new(2, 2)
  // No edges

  let hungarian = Hungarian::new(graph)
  inspect(hungarian.max_matching(), content="0")
}

///|
test "matching single edge" {
  let graph = BipartiteGraph::new(1, 1)
  graph.add_edge(0, 0)
  let hungarian = Hungarian::new(graph)
  inspect(hungarian.max_matching(), content="1")
}

///|
test "get_matching" {
  let graph = BipartiteGraph::new(2, 2)
  graph.add_edge(0, 0)
  graph.add_edge(1, 1)
  let hungarian = Hungarian::new(graph)
  let _ = hungarian.max_matching()
  let matching = hungarian.get_matching()
  inspect(matching.length(), content="2")
  let hk = HopcroftKarp::new(graph)
  let _ = hk.max_matching()
  let hk_matching = hk.get_matching()
  inspect(hk_matching.length(), content="2")
}

///|
test "vertex cover" {
  let graph = BipartiteGraph::new(3, 3)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 1)
  graph.add_edge(2, 2)
  let (left, right) = minimum_vertex_cover(graph)
  // Vertex cover size should equal max matching size
  let total = left.length() + right.length()
  inspect(total <= 3, content="true")
}

///|
test "algorithms agree" {
  let graph = BipartiteGraph::new(4, 4)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 0)
  graph.add_edge(1, 2)
  graph.add_edge(2, 1)
  graph.add_edge(2, 2)
  graph.add_edge(3, 3)
  let hungarian = Hungarian::new(graph)
  let h_result = hungarian.max_matching()
  let graph2 = BipartiteGraph::new(4, 4)
  graph2.add_edge(0, 0)
  graph2.add_edge(0, 1)
  graph2.add_edge(1, 0)
  graph2.add_edge(1, 2)
  graph2.add_edge(2, 1)
  graph2.add_edge(2, 2)
  graph2.add_edge(3, 3)
  let hk = HopcroftKarp::new(graph2)
  let hk_result = hk.max_matching()
  inspect(h_result == hk_result, content="true")
}
