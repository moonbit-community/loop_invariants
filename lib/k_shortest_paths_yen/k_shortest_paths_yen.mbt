// ============================================================================
// YEN'S ALGORITHM - K Shortest Loopless Paths (Directed, Non-negative Weights)
// ============================================================================
//
// Yen's algorithm enumerates the k shortest simple (loopless) paths between
// a source and target by repeatedly deviating from previously found paths.
//
// HIGH-LEVEL STEPS:
// 1. Find the shortest path P0 (Dijkstra).
// 2. For each next path, take the previous shortest path and generate
//    "spur" deviations at each node along it.
// 3. Keep the smallest candidate among all deviations.
//
// INVARIANTS:
// 1. A stores the shortest paths found so far in non-decreasing cost order.
// 2. B stores unique candidate paths formed by deviating once from a prefix
//    of some path in A.
// 3. Each spur search avoids loops by blocking prefix nodes.
//
// TIME COMPLEXITY: O(k * n * (m log n)) in typical sparse cases
// SPACE COMPLEXITY: O(n + m)

///|
const INF64 : Int64 = 4611686018427387903L

///|
pub(all) struct KPath {
  nodes : Array[Int]
  cost : Int64
} derive(Show)

///|
fn has_prefix(path : Array[Int], prefix : Array[Int]) -> Bool {
  if prefix.length() > path.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if path[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn paths_equal(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
fn path_in_list(paths : Array[KPath], nodes : Array[Int]) -> Bool {
  for p in paths {
    if paths_equal(p.nodes, nodes) {
      return true
    }
  }
  false
}

///|
fn min_cost_index(paths : Array[KPath]) -> Int {
  let mut idx = -1
  let mut best = INF64
  for i in 0..<paths.length() {
    if paths[i].cost < best {
      best = paths[i].cost
      idx = i
    }
  }
  idx
}

///|
fn is_blocked_edge(blocked : Array[(Int, Int)], u : Int, v : Int) -> Bool {
  for edge in blocked {
    let (a, b) = edge
    if a == u && b == v {
      return true
    }
  }
  false
}

///|
fn build_adj(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
) -> Array[Array[(Int, Int64)]]? {
  let adj : Array[Array[(Int, Int64)]] = Array::makei(n, _ => [])
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, w) = edges[i]
    if w < 0L {
      return None
    }
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push((v, w))
    }
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (adj build):
      #|For each processed edge index < i, its non-negative weight edge is added
      #|to adj if endpoints are in range. Negative weights abort early.
      #|MAINTENANCE:
      #|Insert edge i into adj when valid; otherwise skip or return None.
      #|TERMINATION:
      #|At i = edges.length(), adj contains all valid edges.
    ),
  }
  Some(adj)
}

///|
fn min_edge_weight(
  adj : Array[Array[(Int, Int64)]],
  u : Int,
  v : Int,
) -> Int64? {
  if u < 0 || u >= adj.length() {
    return None
  }
  let mut best = INF64
  for edge in adj[u] {
    let (to, w) = edge
    if to == v && w < best {
      best = w
    }
  }
  if best == INF64 {
    None
  } else {
    Some(best)
  }
}

///|
fn path_cost(adj : Array[Array[(Int, Int64)]], nodes : Array[Int]) -> Int64? {
  if nodes.length() <= 1 {
    return Some(0L)
  }
  let mut total = 0L
  for i = 0; i + 1 < nodes.length(); i = i + 1 {
    let u = nodes[i]
    let v = nodes[i + 1]
    match min_edge_weight(adj, u, v) {
      None => return None
      Some(w) => total = total + w
    }
  } where {
    invariant: i >= 0 && i + 1 <= nodes.length(),
    reasoning: (
      #|INVARIANT (path cost):
      #|total equals the sum of weights along nodes[0..i], and all required edges
      #|for that prefix exist in adj.
      #|MAINTENANCE:
      #|Add the edge weight for (nodes[i], nodes[i+1]) to extend the sum.
      #|TERMINATION:
      #|At i = len-1, total is the full path cost.
    ),
  }
  Some(total)
}

///|
fn prefix_nodes(nodes : Array[Int], end_idx : Int) -> Array[Int] {
  let prefix : Array[Int] = []
  for i = 0; i <= end_idx; i = i + 1 {
    prefix.push(nodes[i])
  } where {
    invariant: i >= 0 && i <= end_idx + 1,
    reasoning: (
      #|INVARIANT (prefix build):
      #|prefix equals nodes[0..i) and preserves order.
      #|MAINTENANCE:
      #|Push nodes[i] to extend the prefix by one element.
      #|TERMINATION:
      #|At i = end_idx + 1, prefix has length end_idx + 1.
    ),
  }
  prefix
}

///|
fn combine_paths(root : Array[Int], spur : Array[Int]) -> Array[Int] {
  let combined : Array[Int] = []
  if root.length() > 0 {
    for i in 0..<(root.length() - 1) {
      combined.push(root[i])
    }
  }
  for v in spur {
    combined.push(v)
  }
  combined
}

///|
fn shortest_path_filtered(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  blocked_nodes : Array[Bool],
  blocked_edges : Array[(Int, Int)],
  source : Int,
  target : Int,
) -> KPath? {
  if source < 0 || source >= n || target < 0 || target >= n {
    return None
  }
  if source == target {
    return Some({ nodes: [source], cost: 0L })
  }
  let graph = @dijkstra.Graph::new(n)
  for edge in edges {
    let (u, v, w) = edge
    if w < 0L {
      return None
    }
    if u >= 0 && u < n && v >= 0 && v < n {
      if not(blocked_nodes[u]) &&
        not(blocked_nodes[v]) &&
        not(is_blocked_edge(blocked_edges, u, v)) {
        graph.add_edge(u, v, w)
      }
    }
  }
  let result = @dijkstra.dijkstra(graph, source)
  let nodes = @dijkstra.reconstruct_path(result, target)
  if nodes.length() == 0 {
    None
  } else {
    Some({ nodes, cost: result.dist[target] })
  }
}

///|
/// Compute up to k shortest loopless paths from source to target.
/// Returns an empty array for invalid inputs or when no path exists.
pub fn yen_k_shortest_paths(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source : Int,
  target : Int,
  k : Int,
) -> Array[KPath] {
  if n <= 0 || k <= 0 || source < 0 || source >= n || target < 0 || target >= n {
    return []
  }
  if source == target {
    return [{ nodes: [source], cost: 0L }]
  }
  let adj = match build_adj(n, edges) {
    None => return []
    Some(a) => a
  }
  let first = shortest_path_filtered(
    n,
    edges,
    Array::make(n, false),
    [],
    source,
    target,
  )
  if first is None {
    return []
  }
  let a_paths : Array[KPath] = [first.unwrap()]
  let b_candidates : Array[KPath] = []
  for kth = 1; kth < k; kth = kth + 1 {
    let prev = a_paths[kth - 1]
    if prev.nodes.length() <= 1 {
      break
    }
    for i = 0; i < prev.nodes.length() - 1; i = i + 1 {
      let root = prefix_nodes(prev.nodes, i)
      let root_cost = match path_cost(adj, root) {
        None => continue
        Some(c) => c
      }
      let blocked_edges : Array[(Int, Int)] = []
      for p in a_paths {
        if p.nodes.length() > i && has_prefix(p.nodes, root) {
          blocked_edges.push((p.nodes[i], p.nodes[i + 1]))
        }
      }
      let blocked_nodes = Array::make(n, false)
      for j = 0; j < root.length() - 1; j = j + 1 {
        blocked_nodes[root[j]] = true
      } where {
        invariant: j >= 0 && j <= root.length() - 1,
        reasoning: (
          #|INVARIANT (block prefix nodes):
          #|blocked_nodes marks exactly root[0..j) as unavailable for the spur
          #|path, ensuring loopless concatenation with the root prefix.
          #|MAINTENANCE:
          #|Mark root[j] as blocked to extend the forbidden prefix.
          #|TERMINATION:
          #|At j = root.length() - 1, all nodes before the spur node are blocked.
        ),
      }
      let spur_node = root[root.length() - 1]
      let spur = shortest_path_filtered(
        n, edges, blocked_nodes, blocked_edges, spur_node, target,
      )
      if spur is Some(spur_path) {
        let total_nodes = combine_paths(root, spur_path.nodes)
        let candidate = { nodes: total_nodes, cost: root_cost + spur_path.cost }
        if not(path_in_list(b_candidates, candidate.nodes)) &&
          not(path_in_list(a_paths, candidate.nodes)) {
          b_candidates.push(candidate)
        }
      }
    } where {
      invariant: i >= 0 && i <= prev.nodes.length() - 1,
      reasoning: (
        #|INVARIANT (spur generation):
        #|For each spur index in [0..i), all candidate paths formed by deviating
        #|at that index from the previous shortest path have been generated and
        #|added to B if unique. Each candidate is loopless because prefix nodes
        #|before the spur are blocked.
        #|MAINTENANCE:
        #|Construct root prefix, block conflicting edges from A, compute spur
        #|path, and append a new candidate if it exists.
        #|TERMINATION:
        #|At i = len-1, all spur deviations of the previous path are explored.
      ),
    }
    if b_candidates.length() == 0 {
      break
    }
    let idx = min_cost_index(b_candidates)
    if idx < 0 {
      break
    }
    a_paths.push(b_candidates[idx])
    let _ = b_candidates.remove(idx)

  } where {
    invariant: kth >= 1 && kth <= k,
    reasoning: (
      #|INVARIANT (Yen outer loop):
      #|A contains the shortest loopless paths found so far in non-decreasing
      #|order of cost. B contains unique candidate paths not yet chosen.
      #|MAINTENANCE:
      #|Generate spur deviations from the latest path, then select the smallest
      #|candidate from B as the next shortest path.
      #|TERMINATION:
      #|Stop when k paths are found or no candidates remain.
    ),
  }
  a_paths
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "yen k shortest paths" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 3, 1L),
    (0, 2, 3L),
    (2, 3, 2L),
    (1, 2, 1L),
  ]
  let paths = yen_k_shortest_paths(4, edges[:], 0, 3, 3)
  inspect(paths.length(), content="3")
  inspect(paths[0].cost, content="2")
  inspect(paths[1].cost, content="4")
  inspect(paths[2].cost, content="5")
}

///|
test "yen no path" {
  let edges : Array[(Int, Int, Int64)] = []
  let paths = yen_k_shortest_paths(3, edges[:], 0, 2, 2)
  inspect(paths.length(), content="0")
}
