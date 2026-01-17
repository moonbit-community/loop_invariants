// ============================================================================
// EDMONDS' ARBORESCENCE - Helper Functions
// ============================================================================
//
// Utility functions for cycle detection, reachability, and cost computation.

///|
/// Find a cycle in the parent graph, if one exists.
///
/// ALGORITHM:
/// ```
///   For each vertex v:
///     Follow parent pointers until:
///       1. Reach root → no cycle through v
///       2. Reach -1 → no cycle through v
///       3. Reach a vertex seen in THIS traversal → found cycle!
///
///   The "seen in this traversal" check is key:
///     - Mark vertices with the current v's ID
///     - If we revisit a vertex marked with same ID → cycle
/// ```
///
/// WHY THIS WORKS:
/// ```
///   When selecting minimum incoming edges, cycles can form.
///   Example:
///     Edges: 0→1 (cost 1), 1→2 (cost 1), 2→1 (cost 1)
///     Root: 0
///
///     Min incoming for 1: could be 0→1 or 2→1
///     Min incoming for 2: 1→2
///
///     If we pick 2→1, we get cycle: 1 → 2 → 1
/// ```
///
/// PARAMETERS:
///   - n: number of vertices
///   - root: the root vertex (cycles cannot include root)
///   - parent: parent[v] = chosen predecessor of v
///
/// RETURNS:
///   Array of vertices forming the cycle, or empty if no cycle.
///   The cycle is returned in traversal order.
fn find_cycle(n : Int, root : Int, parent : Array[Int]) -> Array[Int] {
  // seen[v] = ID of the vertex that started this traversal (-1 = unvisited)
  let seen = Array::make(n, -1)
  for v in 0..<n {
    // Skip root and unreachable vertices
    guard v != root && parent[v] != -1 else { continue }

    // Follow parent pointers, marking with v's ID
    let mut cur = v
    while cur != -1 && cur != root && seen[cur] == -1 {
      seen[cur] = v
      cur = parent[cur]
    }

    // Check if we found a cycle (revisited vertex marked with same ID)
    if cur != -1 && cur != root && seen[cur] == v {
      // Extract the cycle starting from cur
      let cycle : Array[Int] = []
      let start = cur
      cycle.push(start)
      let mut x = parent[start]
      while x != start {
        cycle.push(x)
        x = parent[x]
      }
      return cycle
    }
  }
  [] // No cycle found
}

///|
/// Build reachability from root using BFS.
///
/// ALGORITHM:
/// ```
///   Standard BFS from root:
///     1. Start with root in queue, marked as seen
///     2. For each vertex u in queue:
///        - For each edge u→v:
///          - If v not seen, mark and enqueue
///     3. Return seen array
/// ```
///
/// PARAMETERS:
///   - n: number of vertices
///   - edges: all directed edges
///   - root: starting vertex
///
/// RETURNS:
///   Array[Bool] where result[v] = true iff v is reachable from root
fn build_reachable(n : Int, edges : Array[Edge], root : Int) -> Array[Bool] {
  // Build adjacency list for forward edges
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  for e in edges {
    adj[e.from].push(e.to)
  }

  // BFS from root
  let seen = Array::make(n, false)
  let stack : Array[Int] = [root]
  seen[root] = true
  let mut idx = 0
  while idx < stack.length() {
    let u = stack[idx]
    for v in adj[u] {
      if not(seen[v]) {
        seen[v] = true
        stack.push(v)
      }
    }
    idx = idx + 1
  }
  seen
}

///|
/// Compute total cost of cycle edges.
///
/// PARAMETERS:
///   - in_cost: minimum incoming edge cost for each vertex
///   - cycle: vertices forming the cycle
///
/// RETURNS:
///   Sum of in_cost[v] for all v in cycle.
///
/// WHY THIS MATTERS:
/// ```
///   When we contract a cycle, we're committing to using all
///   the cycle's edges EXCEPT one (the one we replace with
///   an external edge entering the cycle).
///
///   The cycle cost is added to the contracted solution's cost
///   to get the true total cost.
/// ```
fn cycle_cost(in_cost : Array[Int64], cycle : Array[Int]) -> Int64 {
  cycle.fold(init=0L, (total, v) => total + in_cost[v])
}
