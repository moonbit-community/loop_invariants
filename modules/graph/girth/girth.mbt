// ============================================================================
// GIRTH  -  shortest cycle in an undirected graph
// ============================================================================
//
// PROBLEM
//
// The **girth** of an undirected graph is the length of its shortest
// cycle (or `+infinity` for acyclic graphs).
//
// ALGORITHM
//
// For each vertex `s`, run BFS. Whenever an edge `(u, v)` is found
// such that `v` is already discovered AND `v` is not the BFS parent
// of `u`, a cycle of length `dist[u] + dist[v] + 1` is closed.
// Track the minimum over all such closings, across all sources.
//
//   girth = min over s of [min over (u, v) of dist[u] + dist[v] + 1]
//
// COMPLEXITY
//
//   Time : O(V * (V + E)) -- one BFS per vertex
//   Space: O(V + E)
//
// THE INVARIANT
//
//   "After running BFS from s, dist[v] equals the BFS distance from s
//    to v. Any back-edge or cross-edge (u, v) closes a cycle whose
//    length is dist[u] + dist[v] + 1."

///|
const INF : Int = 2147483647

///|
/// Girth of the undirected graph `adj`. Returns `-1` for acyclic
/// graphs.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Triangle: girth 3.
///   let adj = [[1, 2], [0, 2], [0, 1]]
///   @debug.assert_eq(@girth.girth(3, adj), 3)
/// }
/// ```
pub fn girth(n : Int, adj : Array[Array[Int]]) -> Int {
  let mut best = INF
  for s in 0..<n {
    let dist = Array::make(n, -1)
    let parent = Array::make(n, -1)
    let queue : Array[Int] = []
    dist[s] = 0
    queue.push(s)
    let mut head = 0
    while head < queue.length() {
      let u = queue[head]
      head = head + 1
      for v in adj[u] {
        if v < 0 || v >= n {
          continue
        }
        if dist[v] == -1 {
          dist[v] = dist[u] + 1
          parent[v] = u
          queue.push(v)
        } else if parent[u] != v {
          // Cycle closes here.
          let cycle_len = dist[u] + dist[v] + 1
          if cycle_len < best {
            best = cycle_len
          }
        }
      }
    }
  }
  if best == INF {
    -1
  } else {
    best
  }
}

///|
test "triangle girth 3" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 2], [0, 1]]
  @debug.assert_eq(girth(3, adj), 3)
}

///|
test "square girth 4" {
  let adj : Array[Array[Int]] = [[1, 3], [0, 2], [1, 3], [0, 2]]
  @debug.assert_eq(girth(4, adj), 4)
}

///|
test "path acyclic" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [1, 3], [2]]
  @debug.assert_eq(girth(4, adj), -1)
}

///|
test "Petersen graph girth 5" {
  // Petersen graph: 10 vertices, girth 5. Outer 5-cycle 0-1-2-3-4-0
  // connected to inner 5-star 5-6-7-8-9 via spokes; inner connects 5-7, 7-9, 9-6, 6-8, 8-5.
  let adj : Array[Array[Int]] = [
    [1, 4, 5],
    [0, 2, 6],
    [1, 3, 7],
    [2, 4, 8],
    [3, 0, 9],
    [0, 7, 8],
    [1, 8, 9],
    [2, 5, 9],
    [3, 5, 6],
    [4, 6, 7],
  ]
  @debug.assert_eq(girth(10, adj), 5)
}

///|
test "complete graph K4 girth 3" {
  let adj : Array[Array[Int]] = [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]]
  @debug.assert_eq(girth(4, adj), 3)
}

///|
test "single vertex" {
  @debug.assert_eq(girth(1, [[]]), -1)
}

///|
test "two components one cyclic" {
  // {0, 1} edge + {2, 3, 4} triangle.
  let adj : Array[Array[Int]] = [[1], [0], [3, 4], [2, 4], [2, 3]]
  @debug.assert_eq(girth(5, adj), 3)
}
