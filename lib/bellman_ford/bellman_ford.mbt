// ============================================================================
// BELLMAN-FORD ALGORITHM - Single Source Shortest Paths with Negative Edges
// ============================================================================
//
// Bellman-Ford finds shortest paths from a source to all vertices, handling
// negative edge weights and detecting negative cycles.
//
// ALGORITHM:
// 1. Initialize dist[source] = 0, dist[others] = infinity
// 2. Relax all edges V-1 times
// 3. Check for negative cycles (one more relaxation round)
//
// KEY INSIGHT: After k iterations, dist[v] is the shortest path using at most
// k edges. Since shortest paths have at most V-1 edges, V-1 iterations suffice.
//
// INVARIANTS:
// 1. After iteration i, dist[v] = shortest path to v using ≤ i edges
// 2. If no negative cycle exists, dist values converge after V-1 iterations
// 3. If relaxation possible after V-1 iterations, negative cycle exists
//
// TIME COMPLEXITY: O(V * E)
// SPACE COMPLEXITY: O(V)

///|
const BF_INF : Int64 = 4611686018427387903L // Large value but allows addition without overflow

///|
const BF_INF_INT : Int = 0x3fffffff

///|
pub struct BellmanFord {
  n : Int
  edges : Array[(Int, Int, Int64)] // (from, to, weight)
  dist : Array[Int64]
  parent : Array[Int]
  has_negative_cycle : Bool
}

///|
/// Create a Bellman-Ford solver for a graph with vertices 0..n-1.
pub fn BellmanFord::new(n : Int) -> BellmanFord {
  {
    n,
    edges: [],
    dist: Array::make(n, BF_INF),
    parent: Array::make(n, -1),
    has_negative_cycle: false,
  }
}

///|
/// Add a directed edge (from -> to) with an Int64 weight.
pub fn BellmanFord::add_edge(
  self : BellmanFord,
  from : Int,
  to : Int,
  weight : Int64,
) -> Unit {
  self.edges.push((from, to, weight))
}

///|
/// Run Bellman-Ford from a source vertex and compute shortest paths.
/// The returned value includes distances, parents, and negative-cycle flag.
pub fn BellmanFord::compute(self : BellmanFord, source : Int) -> BellmanFord {
  // Initialize distances
  self.dist.fill(BF_INF)
  self.parent.fill(-1)
  self.dist[source] = 0L

  // Relax all edges V-1 times
  for iter = 0; iter < self.n - 1; iter = iter + 1 {
    let mut any_relaxed = false
    for edge in self.edges {
      let (u, v, w) = edge
      if self.dist[u] < BF_INF && self.dist[u] + w < self.dist[v] {
        self.dist[v] = self.dist[u] + w
        self.parent[v] = u
        any_relaxed = true
      }
    }
    // Early termination if no relaxation happened
    if not(any_relaxed) {
      break
    }
  } where {
    invariant: iter >= 0 && iter <= self.n - 1,
    reasoning: (
      #|INVARIANT (Bellman-Ford):
      #|After iter iterations, dist[v] is the shortest path using at most iter
      #|edges; dist[source] = 0 and others are upper bounds.
      #|MAINTENANCE:
      #|Relax all edges; any shorter path with <= iter+1 edges is discovered.
      #|TERMINATION:
      #|After V-1 iterations, all simple shortest paths are found (no simple
      #|path uses more than V-1 edges).
    ),
  }

  // Check for negative cycles
  let has_negative_cycle = self.edges.any(edge => {
    let (u, v, w) = edge
    self.dist[u] < BF_INF && self.dist[u] + w < self.dist[v]
  })
  {
    n: self.n,
    edges: self.edges,
    dist: self.dist,
    parent: self.parent,
    has_negative_cycle,
  }
}

///|
/// Convenience wrapper that returns Int distances and negative-cycle flag.
pub fn bellman_ford(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
  src : Int,
) -> (Array[Int], Bool) {
  if n <= 0 {
    return ([], false)
  }
  let dist = Array::make(n, BF_INF_INT)
  if src < 0 || src >= n {
    return (dist, false)
  }
  let solver = BellmanFord::new(n)
  for edge in edges {
    let (u, v, w) = edge
    solver.add_edge(u, v, w.to_int64())
  }
  let result = solver.compute(src)
  for i in 0..<n {
    if result.dist[i] != BF_INF {
      dist[i] = result.dist[i].to_int()
    }
  }
  (dist, result.has_negative_cycle())
}

///|
/// Return the shortest distance to v, or None if unreachable/out of range.
pub fn BellmanFord::get_distance(self : BellmanFord, v : Int) -> Int64? {
  if v < 0 || v >= self.n || self.dist[v] == BF_INF {
    None
  } else {
    Some(self.dist[v])
  }
}

///|
/// True if a negative cycle is reachable after running compute.
pub fn BellmanFord::has_negative_cycle(self : BellmanFord) -> Bool {
  self.has_negative_cycle
}

///|
/// Reconstruct path from source to target, or None if unreachable.
pub fn BellmanFord::get_path(self : BellmanFord, target : Int) -> Array[Int]? {
  if target < 0 || target >= self.n || self.dist[target] == BF_INF {
    return None
  }
  let path : Array[Int] = []
  for current = target; current >= 0; {
    path.push(current)
    continue self.parent[current]
  } where {
    invariant: current >= -1,
    reasoning: (
      #|INVARIANT (path traversal):
      #|path contains vertices from target back to current's predecessor.
      #|MAINTENANCE:
      #|Push current vertex and follow parent pointer.
      #|TERMINATION:
      #|parent[source] = -1, so we eventually reach -1.
    ),
  }

  // Reverse path
  path.rev_in_place()
  Some(path)
}

// ============================================================================
// SPFA (Shortest Path Faster Algorithm) - Optimized Bellman-Ford
// ============================================================================

///|
priv struct SPFA {
  n : Int
  adj : Array[Array[(Int, Int64)]] // (neighbor, weight)
  dist : Array[Int64]
  in_queue : Array[Bool]
  count : Array[Int] // Number of times vertex entered queue (for cycle detection)
}

///|
fn SPFA::new(n : Int) -> SPFA {
  let adj : Array[Array[(Int, Int64)]] = Array::makei(n, _ => [])
  {
    n,
    adj,
    dist: Array::make(n, BF_INF),
    in_queue: Array::make(n, false),
    count: Array::make(n, 0),
  }
}

///|
fn SPFA::add_edge(self : SPFA, from : Int, to : Int, weight : Int64) -> Unit {
  self.adj[from].push((to, weight))
}

///|
/// Returns None if negative cycle detected, Some(distances) otherwise
fn SPFA::compute(self : SPFA, source : Int) -> Array[Int64]? {
  self.dist.fill(BF_INF)
  self.in_queue.fill(false)
  self.count.fill(0)
  self.dist[source] = 0L
  let queue : Array[Int] = [source]
  self.in_queue[source] = true
  self.count[source] = 1
  let mut front = 0
  while queue.get(front) is Some(u) {
    self.in_queue[u] = false
    for i = 0; i < self.adj[u].length(); i = i + 1 {
      let (v, w) = self.adj[u][i]
      if self.dist[u] + w < self.dist[v] {
        self.dist[v] = self.dist[u] + w
        if not(self.in_queue[v]) {
          queue.push(v)
          self.in_queue[v] = true
          self.count[v] = self.count[v] + 1
          // If vertex entered queue more than n times, negative cycle exists
          if self.count[v] >= self.n {
            return None
          }
        }
      }
    } where {
      invariant: i >= 0 && i <= self.adj[u].length(),
      reasoning: (
        #|INVARIANT (SPFA relax):
        #|All neighbors in adj[u][0..i) have been considered for relaxation.
        #|MAINTENANCE:
        #|Relax edge to neighbor i and enqueue if improved.
        #|TERMINATION:
        #|At i = deg(u), all outgoing edges from u are processed.
      ),
    }
    front = front + 1
  }
  Some(self.dist)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "bellman_ford basic" {
  let bf = BellmanFord::new(5)
  bf.add_edge(0, 1, 6L)
  bf.add_edge(0, 2, 7L)
  bf.add_edge(1, 2, 8L)
  bf.add_edge(1, 3, 5L)
  bf.add_edge(1, 4, -4L)
  bf.add_edge(2, 3, -3L)
  bf.add_edge(2, 4, 9L)
  bf.add_edge(3, 1, -2L)
  bf.add_edge(4, 3, 7L)
  let result = bf.compute(0)
  inspect(result.get_distance(0), content="Some(0)")
  inspect(result.get_distance(1), content="Some(2)")
  inspect(result.get_distance(2), content="Some(7)")
  inspect(result.get_distance(3), content="Some(4)")
  inspect(result.get_distance(4), content="Some(-2)")
  inspect(result.has_negative_cycle(), content="false")
}

///|
test "bellman_ford wrapper" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (0, 2, 5),
    (2, 3, 1),
  ]
  let (dist, neg) = bellman_ford(4, edges[:], 0)
  inspect(dist, content="[0, 1, 3, 4]")
  inspect(neg, content="false")
}

///|
test "bellman_ford wrapper negative cycle" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, -2), (2, 1, -2)]
  let (_dist, neg) = bellman_ford(3, edges[:], 0)
  inspect(neg, content="true")
}

///|
test "bellman_ford negative cycle" {
  let bf = BellmanFord::new(3)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(1, 2, -1L)
  bf.add_edge(2, 0, -1L) // Creates negative cycle: 0->1->2->0 = -1
  let result = bf.compute(0)
  inspect(result.has_negative_cycle(), content="true")
}

///|
test "bellman_ford disconnected" {
  let bf = BellmanFord::new(4)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(2, 3, 1L)
  let result = bf.compute(0)
  inspect(result.get_distance(1), content="Some(1)")
  inspect(result.get_distance(2), content="None")
  inspect(result.get_distance(3), content="None")
}

///|
test "bellman_ford path reconstruction" {
  let bf = BellmanFord::new(4)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(1, 2, 2L)
  bf.add_edge(2, 3, 3L)
  let result = bf.compute(0)
  inspect(result.get_path(3), content="Some([0, 1, 2, 3])")
}

///|
test "spfa basic" {
  let spfa = SPFA::new(5)
  spfa.add_edge(0, 1, 6L)
  spfa.add_edge(0, 2, 7L)
  spfa.add_edge(1, 2, 8L)
  spfa.add_edge(1, 3, 5L)
  spfa.add_edge(1, 4, -4L)
  spfa.add_edge(2, 3, -3L)
  spfa.add_edge(2, 4, 9L)
  spfa.add_edge(3, 1, -2L)
  spfa.add_edge(4, 3, 7L)
  let result = spfa.compute(0)
  guard result is Some(dist) else { fail("Expected distances") }
  inspect(dist[0], content="0")
  inspect(dist[1], content="2")
  inspect(dist[4], content="-2")
}

///|
test "spfa negative cycle" {
  let spfa = SPFA::new(3)
  spfa.add_edge(0, 1, 1L)
  spfa.add_edge(1, 2, -1L)
  spfa.add_edge(2, 0, -1L)
  inspect(spfa.compute(0), content="None")
}
