// ============================================================================
// EDMONDS' ARBORESCENCE - Helper Functions
// ============================================================================
//
// Utility functions for cycle detection, reachability, and cost computation.

///|
/// Find one cycle in the parent graph, if any exists.
///
/// After the greedy selection step, each non-root vertex `v` stores
/// `parent[v]` — the source of the cheapest edge into `v`. Following these
/// pointers may lead to a directed cycle that is entirely disconnected from the
/// root, which is exactly what needs to be contracted.
///
/// ## Algorithm
///
/// For each starting vertex `v`, follow parent pointers and mark every visited
/// vertex with `v`'s ID. As soon as we arrive at a vertex already marked with
/// `v`'s ID we have found a cycle. We then walk around that cycle once more to
/// collect its members.
///
/// ```
/// // Example parent array (root = 0):
/// //   parent = [-1, 2, 1, 2]
/// //
/// // Starting from v = 1:
/// //   visit 1  (mark 1 with id=1)
/// //   visit 2  (mark 2 with id=1)
/// //   arrive at 1  → seen[1] == 1  → cycle found: {1, 2}
/// ```
///
/// ## Parameters
///
/// - `n`      — Number of vertices.
/// - `root`   — Root vertex; cycles cannot include the root.
/// - `parent` — `parent[v]` = chosen predecessor of `v` (-1 if none).
///
/// ## Returns
///
/// An `Array[Int]` containing the vertices of one cycle, in traversal order.
/// Returns an empty array when no cycle exists.
fn find_cycle(n : Int, root : Int, parent : Array[Int]) -> Array[Int] {
  // seen[v] = ID of the vertex that started this traversal (-1 = unvisited)
  let seen = Array::make(n, -1)
  for v in 0..<n {
    // Skip root and unreachable vertices
    guard v != root && parent[v] != -1 else { continue }

    // Follow parent pointers, marking with v's ID
    let cur = for cur = v; cur != -1 && cur != root && seen[cur] == -1; {
      seen[cur] = v
      continue parent[cur]
    } nobreak {
      cur
    }

    // Check if we found a cycle (revisited vertex marked with same ID)
    if cur != -1 && cur != root && seen[cur] == v {
      // Extract the cycle starting from cur
      let cycle : Array[Int] = []
      let start = cur
      cycle.push(start)
      for x = parent[start]; x != start; {
        cycle.push(x)
        continue parent[x]
      }
      return cycle
    }
  }
  [] // No cycle found
}

///|
/// Determine which vertices are reachable from `root` via a forward BFS.
///
/// This is the first safety check in `min_arborescence`: if any vertex cannot
/// be reached from the root, no arborescence exists and the algorithm returns
/// `None` immediately.
///
/// ## Algorithm
///
/// Standard iterative BFS using an index into a growing `stack` array (avoiding
/// explicit queue allocation):
///
/// ```
/// // Adjacency-list BFS
/// //   queue = [root]
/// //   while queue not empty:
/// //     u = dequeue
/// //     for each edge u → v:
/// //       if v not seen: mark and enqueue
/// ```
///
/// ## Parameters
///
/// - `n`     — Number of vertices (vertices labeled 0 to n-1).
/// - `edges` — All directed edges in the graph.
/// - `root`  — The starting vertex for BFS.
///
/// ## Returns
///
/// `Array[Bool]` of length `n` where element `v` is `true` iff `v` is
/// reachable from `root`.
fn build_reachable(n : Int, edges : Array[Edge], root : Int) -> Array[Bool] {
  // Build adjacency list for forward edges
  let adj : Array[Array[Int]] = [ for _ in 0..<n => [] ]
  for e in edges {
    adj[e.from].push(e.to)
  }

  // BFS from root
  let seen = Array::make(n, false)
  let stack : Array[Int] = [root]
  seen[root] = true
  for idx = 0; idx < stack.length(); {
    let u = stack[idx]
    for v in adj[u] {
      if !seen[v] {
        seen[v] = true
        stack.push(v)
      }
    }
    continue idx + 1
  }
  seen
}

///|
/// Sum the minimum incoming edge cost for every vertex in `cycle`.
///
/// When the algorithm contracts a cycle `C`, all edges *inside* `C` (the
/// cheapest incoming edge of each cycle member) are tentatively kept. One of
/// those edges will later be replaced by the external edge that breaks into
/// `C`. The cycle cost is added back to the contracted sub-problem's cost
/// during expansion so that the final total reflects the true edge weights.
///
/// ## Formula
///
/// ```
/// cycle_cost(in_cost, C) = sum of in_cost[v] for v in C
/// ```
///
/// ## Parameters
///
/// - `in_cost` — `in_cost[v]` = weight of the cheapest edge entering `v`.
/// - `cycle`   — Vertices that form the cycle.
///
/// ## Returns
///
/// The sum of `in_cost[v]` for all `v` in `cycle`.
fn cycle_cost(in_cost : Array[Int64], cycle : Array[Int]) -> Int64 {
  cycle.fold(init=0L, (total, v) => total + in_cost[v])
}
