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
/// Sentinel distance value used internally to represent "infinity" (unreachable).
/// Chosen so that `BF_INF + BF_INF` does not overflow Int64.
const BF_INF : Int64 = 4611686018427387903L // Large value but allows addition without overflow

///|
/// Sentinel distance value for the Int-based convenience wrapper.
const BF_INF_INT : Int = 0x3fffffff

///|
/// A Bellman-Ford solver for single-source shortest paths on a directed
/// weighted graph with vertices labelled `0..n-1`.
///
/// Fields:
/// - `n`: number of vertices
/// - `edges`: list of directed edges `(from, to, weight)`
/// - `dist`: shortest-distance array, populated by `compute`
/// - `parent`: predecessor array for path reconstruction, populated by `compute`
/// - `has_negative_cycle`: set to `true` by `compute` when a negative cycle
///   reachable from the source is found
pub struct BellmanFord {
  n : Int
  edges : Array[(Int, Int, Int64)] // (from, to, weight)
  dist : Array[Int64]
  parent : Array[Int]
  has_negative_cycle : Bool
}

///|
/// Create a new Bellman-Ford solver for a graph with `n` vertices labelled
/// `0..n-1`.
///
/// Parameters:
/// - `n`: total number of vertices in the graph (must be >= 1)
///
/// Returns a fresh `BellmanFord` with no edges. Use `add_edge` to populate
/// the graph, then call `compute` to run the algorithm.
///
/// Time complexity: O(n).
pub fn BellmanFord::BellmanFord(n : Int) -> BellmanFord {
  {
    n,
    edges: [],
    dist: Array::make(n, BF_INF),
    parent: Array::make(n, -1),
    has_negative_cycle: false,
  }
}

///|
/// Add a directed edge `from -> to` with the given `weight` to the graph.
///
/// Parameters:
/// - `from`: source vertex index (`0 <= from < n`)
/// - `to`: destination vertex index (`0 <= to < n`)
/// - `weight`: edge weight; may be negative
///
/// Edges are stored in insertion order and processed in that order during
/// relaxation. Self-loops and parallel edges are accepted.
///
/// Time complexity: O(1) amortised.
pub fn BellmanFord::add_edge(
  self : BellmanFord,
  from : Int,
  to : Int,
  weight : Int64,
) -> Unit {
  self.edges.push((from, to, weight))
}

///|
/// Run the Bellman-Ford algorithm from `source` and return an updated
/// `BellmanFord` value whose `dist`, `parent`, and `has_negative_cycle`
/// fields reflect the result.
///
/// The algorithm performs up to `n - 1` relaxation rounds over all edges.
/// An early-exit optimisation stops as soon as a full round produces no
/// improvement, which is safe because distances are already final at that
/// point.
///
/// After `n - 1` rounds (or early exit), one additional round is performed
/// to check for negative cycles: if any edge can still be relaxed, a
/// negative cycle reachable from `source` exists and `has_negative_cycle`
/// is set to `true`.
///
/// Parameters:
/// - `source`: index of the source vertex (`0 <= source < n`)
///
/// Returns the same solver struct with updated `dist`, `parent`, and
/// `has_negative_cycle` fields. Unreachable vertices retain the internal
/// infinity sentinel; use `get_distance` to obtain an `Option` value.
///
/// Time complexity: O(V * E) in the worst case, O(E) with early exit.
/// Space complexity: O(V).
pub fn BellmanFord::compute(self : BellmanFord, source : Int) -> BellmanFord {
  // Initialize distances
  self.dist.fill(BF_INF)
  self.parent.fill(-1)
  self.dist[source] = 0L

  // Relax all edges V-1 times
  for _ in 0..<(self.n - 1) {
    let any_relaxed = for edge in self.edges; any_relaxed = false {
      let (u, v, w) = edge
      if self.dist[u] < BF_INF && self.dist[u] + w < self.dist[v] {
        self.dist[v] = self.dist[u] + w
        self.parent[v] = u
        continue true
      } else {
        continue any_relaxed
      }
    } nobreak {
      any_relaxed
    }
    // Early termination if no relaxation happened
    if !any_relaxed {
      break
    }
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
/// Convenience wrapper around `BellmanFord` that accepts `Int` edge weights
/// and returns `Int` distances alongside a negative-cycle flag.
///
/// This function constructs a fresh solver, adds all provided edges, runs
/// `compute`, and converts the Int64 internal distances back to `Int`.
/// Unreachable vertices are represented by the sentinel `0x3fffffff` in the
/// returned array.
///
/// Parameters:
/// - `n`: number of vertices (vertices are labelled `0..n-1`)
/// - `edges`: slice of `(from, to, weight)` triples; weights may be negative
/// - `src`: source vertex index
///
/// Returns a tuple `(dist, has_negative_cycle)` where:
/// - `dist` is an array of length `n` with the shortest distance from `src`
///   to each vertex (or `0x3fffffff` if unreachable)
/// - `has_negative_cycle` is `true` if a negative cycle reachable from `src`
///   was detected
///
/// If `n <= 0` an empty array is returned. If `src` is out of range, all
/// distances are left at the infinity sentinel.
///
/// Time complexity: O(V * E). Space complexity: O(V + E).
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
  let solver = BellmanFord(n)
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
/// Return the shortest distance from the last source used in `compute` to
/// vertex `v`, or `None` if `v` is unreachable, out of range, or `compute`
/// has not been called yet.
///
/// Parameters:
/// - `v`: target vertex index
///
/// Returns `Some(distance)` as an `Int64`, or `None`.
///
/// Time complexity: O(1).
pub fn BellmanFord::get_distance(self : BellmanFord, v : Int) -> Int64? {
  if v < 0 || v >= self.n || self.dist[v] == BF_INF {
    None
  } else {
    Some(self.dist[v])
  }
}

///|
/// Return `true` if `compute` detected a negative cycle reachable from the
/// source, `false` otherwise.
///
/// A negative cycle is a directed cycle whose edge weights sum to a negative
/// value. When one exists, shortest paths to vertices that can reach the
/// cycle are undefined (they would decrease without bound).
///
/// This field is meaningful only after `compute` has been called; it is
/// `false` in a freshly constructed `BellmanFord`.
///
/// Time complexity: O(1).
pub fn BellmanFord::has_negative_cycle(self : BellmanFord) -> Bool {
  self.has_negative_cycle
}

///|
/// Reconstruct the shortest path from the last source used in `compute` to
/// `target`, or return `None` if `target` is unreachable or out of range.
///
/// The path is built by following `parent` pointers from `target` back to
/// the source, then reversing the result.
///
/// Parameters:
/// - `target`: destination vertex index
///
/// Returns `Some(path)` where `path` is an array of vertex indices starting
/// at the source and ending at `target`, or `None` if no path exists.
///
/// Note: if `has_negative_cycle` is `true`, `get_path` may still return a
/// path; however, that path is not guaranteed to be a true shortest path
/// because the distances are not meaningful in the presence of a negative
/// cycle.
///
/// Time complexity: O(V) for path reconstruction.
pub fn BellmanFord::get_path(self : BellmanFord, target : Int) -> Array[Int]? {
  if target < 0 || target >= self.n || self.dist[target] == BF_INF {
    return None
  }
  let path : Array[Int] = []
  for current = target; current >= 0; {
    path.push(current)
    continue self.parent[current]
  } where {
    proof_invariant: current >= -1,
    proof_reasoning: (
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
fn SPFA::SPFA(n : Int) -> SPFA {
  let adj : Array[Array[(Int, Int64)]] = [ for _ in 0..<n => [] ]
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
  let _ = for front = 0 {
    match queue.get(front) {
      None => break ()
      Some(u) => {
        self.in_queue[u] = false
        for edge in self.adj[u] {
          let (v, w) = edge
          if self.dist[u] + w < self.dist[v] {
            self.dist[v] = self.dist[u] + w
            if !self.in_queue[v] {
              queue.push(v)
              self.in_queue[v] = true
              self.count[v] = self.count[v] + 1
              // If vertex entered queue more than n times, negative cycle exists
              if self.count[v] >= self.n {
                return None
              }
            }
          }
        }
        continue front + 1
      }
    }
  }
  Some(self.dist)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "bellman_ford basic" {
  let bf = BellmanFord(5)
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
  let (dist, neg) = bellman_ford(4, edges, 0)
  inspect(dist, content="[0, 1, 3, 4]")
  inspect(neg, content="false")
}

///|
test "bellman_ford wrapper negative cycle" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, -2), (2, 1, -2)]
  let (_dist, neg) = bellman_ford(3, edges, 0)
  inspect(neg, content="true")
}

///|
test "bellman_ford negative cycle" {
  let bf = BellmanFord(3)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(1, 2, -1L)
  bf.add_edge(2, 0, -1L) // Creates negative cycle: 0->1->2->0 = -1
  let result = bf.compute(0)
  inspect(result.has_negative_cycle(), content="true")
}

///|
test "bellman_ford disconnected" {
  let bf = BellmanFord(4)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(2, 3, 1L)
  let result = bf.compute(0)
  inspect(result.get_distance(1), content="Some(1)")
  inspect(result.get_distance(2), content="None")
  inspect(result.get_distance(3), content="None")
}

///|
test "bellman_ford path reconstruction" {
  let bf = BellmanFord(4)
  bf.add_edge(0, 1, 1L)
  bf.add_edge(1, 2, 2L)
  bf.add_edge(2, 3, 3L)
  let result = bf.compute(0)
  inspect(result.get_path(3), content="Some([0, 1, 2, 3])")
}

///|
test "spfa basic" {
  let spfa = SPFA(5)
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
  let spfa = SPFA(3)
  spfa.add_edge(0, 1, 1L)
  spfa.add_edge(1, 2, -1L)
  spfa.add_edge(2, 0, -1L)
  inspect(spfa.compute(0), content="None")
}
