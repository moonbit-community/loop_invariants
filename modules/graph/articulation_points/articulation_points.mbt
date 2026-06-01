// ============================================================================
// ARTICULATION POINTS (CUT VERTICES)  -  Tarjan 1972
// ============================================================================
//
// PROBLEM
//
// In an undirected graph, an **articulation point** (cut vertex) is a
// vertex whose removal increases the number of connected components.
//
// Distinct from **bridges** (cut edges) -- a graph can have no bridges
// but still have cut vertices, and vice versa.
//
// CHARACTERISATION (Tarjan)
//
// During a DFS, maintain
//
//   disc[v]  = discovery time of v
//   low[v]   = min(disc[v], disc[w] for back-edge v -> w not via parent,
//              low[c] for child c of v in the DFS tree)
//
// Vertex `v` is an articulation point iff:
//   1. `v` is the DFS root and has at least 2 children in the DFS tree; OR
//   2. `v` is non-root and has a child `c` with `low[c] >= disc[v]`
//      (the subtree below `c` cannot reach above `v` via back edges).
//
// COMPLEXITY
//
//   Time : O(V + E)
//   Space: O(V) for disc, low, parent, ap flag.
//
// THE INVARIANT
//
//   "During DFS at vertex v, low[v] equals the lowest discovery time
//    reachable from v using zero or more tree edges followed by at
//    most one back edge."

///|
/// Compute the articulation points of an undirected graph.
///
/// `adj[u]` is the adjacency list of `u`. For undirected edges, each
/// edge should appear in both endpoints' lists. The graph may be
/// disconnected.
///
/// Returns a sorted array of articulation-point vertex indices.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 0 - 1 - 2 path: 1 is the only articulation point.
///   let adj = [[1], [0, 2], [1]]
///   @debug.assert_eq(@articulation_points.find(3, adj), [1])
/// }
/// ```
pub fn find(n : Int, adj : Array[Array[Int]]) -> Array[Int] {
  let disc = Array::make(n, -1)
  let low = Array::make(n, 0)
  let parent = Array::make(n, -1)
  let is_ap = Array::make(n, false)
  let timer = { val: 0 }
  for start in 0..<n {
    if disc[start] == -1 {
      dfs(start, adj, disc, low, parent, is_ap, timer)
    }
  }
  let res : Array[Int] = []
  for v in 0..<n {
    if is_ap[v] {
      res.push(v)
    }
  }
  res
}

///|
priv struct Counter {
  mut val : Int
}

///|
fn dfs(
  u : Int,
  adj : Array[Array[Int]],
  disc : Array[Int],
  low : Array[Int],
  parent : Array[Int],
  is_ap : Array[Bool],
  timer : Counter,
) -> Unit {
  disc[u] = timer.val
  low[u] = timer.val
  timer.val = timer.val + 1
  let mut children = 0
  for v in adj[u] {
    if v < 0 || v >= adj.length() {
      continue
    }
    if disc[v] == -1 {
      parent[v] = u
      children = children + 1
      dfs(v, adj, disc, low, parent, is_ap, timer)
      if low[v] < low[u] {
        low[u] = low[v]
      }
      // Non-root rule.
      if parent[u] != -1 && low[v] >= disc[u] {
        is_ap[u] = true
      }
    } else if v != parent[u] {
      // Back edge.
      if disc[v] < low[u] {
        low[u] = disc[v]
      }
    }
  }
  // Root rule.
  if parent[u] == -1 && children > 1 {
    is_ap[u] = true
  }
}

///|
test "ap path graph" {
  // 0 - 1 - 2 - 3 - 4
  let adj : Array[Array[Int]] = [[1], [0, 2], [1, 3], [2, 4], [3]]
  @debug.assert_eq(find(5, adj), [1, 2, 3])
}

///|
test "ap triangle has none" {
  // 0 - 1 - 2 - 0
  let adj : Array[Array[Int]] = [[1, 2], [0, 2], [0, 1]]
  @debug.assert_eq(find(3, adj), [])
}

///|
test "ap bowtie shape" {
  // Two triangles sharing vertex 0: {0,1,2} and {0,3,4}.
  // 0 is the articulation point.
  let adj : Array[Array[Int]] = [[1, 2, 3, 4], [0, 2], [0, 1], [0, 4], [0, 3]]
  @debug.assert_eq(find(5, adj), [0])
}

///|
test "ap star center" {
  // 0 in the middle of star with 4 leaves.
  let adj : Array[Array[Int]] = [[1, 2, 3, 4], [0], [0], [0], [0]]
  @debug.assert_eq(find(5, adj), [0])
}

///|
test "ap single vertex" {
  let adj : Array[Array[Int]] = [[]]
  @debug.assert_eq(find(1, adj), [])
}

///|
test "ap disconnected components" {
  // {0,1} edge + {2,3,4} triangle.
  let adj : Array[Array[Int]] = [[1], [0], [3, 4], [2, 4], [2, 3]]
  @debug.assert_eq(find(5, adj), [])
}

///|
test "ap bridge endpoints not necessarily APs" {
  // 0 - 1 - 2 with extra edge 1 - 3 (still chain): 1 is AP.
  let adj : Array[Array[Int]] = [[1], [0, 2, 3], [1], [1]]
  @debug.assert_eq(find(4, adj), [1])
}

///|
test "ap complete graph K4 has none" {
  let adj : Array[Array[Int]] = [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]]
  @debug.assert_eq(find(4, adj), [])
}
