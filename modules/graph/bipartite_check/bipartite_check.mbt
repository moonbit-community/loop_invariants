// ============================================================================
// BIPARTITENESS CHECK  -  via BFS 2-coloring
// ============================================================================
//
// PROBLEM
//
// A simple undirected graph is **bipartite** iff its vertex set can be
// 2-coloured such that every edge has endpoints of different colors.
// Equivalently: it contains no odd cycle (König 1936).
//
// ALGORITHM
//
// BFS each connected component. Color the source `0`; when visiting a
// neighbour, assign the opposite color. If we ever see a previously-
// coloured neighbour with the **same** color as the current vertex, the
// graph has an odd cycle and is not bipartite.
//
// COMPLEXITY
//
//   Time : O(V + E)
//   Space: O(V) for the color array and queue.
//
// THE INVARIANT
//
//   "At every BFS step, the edge being traversed is between two
//    vertices whose colours differ. Equivalently, the coloring agreed
//    upon so far yields a valid 2-coloring of the visited subgraph."

///|
/// Result of the bipartiteness check.
///
/// - `is_bipartite` : true iff the graph admits a 2-coloring.
/// - `color`        : `0` or `1` per vertex if bipartite, or `-1` for
///                    isolated/disconnected vertices that did not appear
///                    in the source component. When `is_bipartite` is
///                    false, the array contents are undefined.
/// - `odd_cycle_edge`: when not bipartite, a pair `(u, v)` such that
///                    `u` and `v` were assigned the same colour --
///                    a witness of an odd cycle.
pub(all) struct BipartiteResult {
  is_bipartite : Bool
  color : Array[Int]
  odd_cycle_edge : (Int, Int)?
}

///|
/// Test whether an undirected graph is bipartite. `adj[u]` is the list
/// of vertices adjacent to `u`. For undirected graphs, each edge `{u, v}`
/// should appear in both `adj[u]` and `adj[v]`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Square cycle 0 -1 -2 -3 -0 is bipartite.
///   let adj = [[1, 3], [0, 2], [1, 3], [0, 2]]
///   @debug.assert_eq(@bipartite_check.is_bipartite(4, adj).is_bipartite, true)
/// }
/// ```
pub fn is_bipartite(n : Int, adj : Array[Array[Int]]) -> BipartiteResult {
  let color = Array::make(n, -1)
  let queue : Array[Int] = []
  let mut witness : (Int, Int)? = None
  for start in 0..<n {
    if color[start] != -1 {
      continue
    }
    color[start] = 0
    queue.push(start)
    let mut head = 0
    while head < queue.length() {
      let u = queue[head]
      head = head + 1
      for v in adj[u] {
        if v < 0 || v >= n {
          continue
        }
        if color[v] == -1 {
          color[v] = 1 - color[u]
          queue.push(v)
        } else if color[v] == color[u] {
          witness = Some((u, v))
          return { is_bipartite: false, color, odd_cycle_edge: witness, }
        }
      }
    }
  }
  { is_bipartite: true, color, odd_cycle_edge: None, }
}

///|
test "bipartite even cycle" {
  // 4-cycle: 0 -1 -2 -3 -0
  let adj = [[1, 3], [0, 2], [1, 3], [0, 2]]
  let r = is_bipartite(4, adj)
  @debug.assert_eq(r.is_bipartite, true)
}

///|
test "bipartite odd cycle is not" {
  // Triangle 0 -1 -2 -0
  let adj = [[1, 2], [0, 2], [0, 1]]
  let r = is_bipartite(3, adj)
  @debug.assert_eq(r.is_bipartite, false)
  // Some witness exists.
  @debug.assert_eq(r.odd_cycle_edge != None, true)
}

///|
test "bipartite tree" {
  // A tree is always bipartite.
  //   0 -1, 0 -2, 1 -3, 1 -4, 2 -5
  let adj = [[1, 2], [0, 3, 4], [0, 5], [1], [1], [2]]
  @debug.assert_eq(is_bipartite(6, adj).is_bipartite, true)
}

///|
test "bipartite disconnected" {
  // Two components: a triangle and an edge.
  let adj = [[1, 2], [0, 2], [0, 1], [4], [3]]
  @debug.assert_eq(is_bipartite(5, adj).is_bipartite, false)
}

///|
test "bipartite empty" {
  let r = is_bipartite(0, [])
  @debug.assert_eq(r.is_bipartite, true)
  @debug.assert_eq(r.color.length(), 0)
}

///|
test "bipartite single vertex" {
  let r = is_bipartite(1, [[]])
  @debug.assert_eq(r.is_bipartite, true)
  @debug.assert_eq(r.color[0], 0)
}

///|
test "bipartite colours form a valid 2-colouring" {
  let adj = [[1, 3], [0, 2, 4], [1, 5], [0, 4], [1, 3, 5], [2, 4]]
  let r = is_bipartite(6, adj)
  @debug.assert_eq(r.is_bipartite, true)
  // For every edge, endpoint colours differ.
  for u in 0..<6 {
    for v in adj[u] {
      @debug.assert_eq(r.color[u] != r.color[v], true)
    }
  }
}

///|
test "bipartite king's path" {
  // A path graph is bipartite. 0 -1 -2 -3 -4
  let adj = [[1], [0, 2], [1, 3], [2, 4], [3]]
  @debug.assert_eq(is_bipartite(5, adj).is_bipartite, true)
}
