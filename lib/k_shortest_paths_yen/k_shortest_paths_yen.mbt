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
} derive(Debug)

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
  let (idx, _) = for i in 0..<paths.length(); idx = -1, best = INF64 {
    if paths[i].cost < best {
      continue i, paths[i].cost
    }
    continue idx, best
  } nobreak {
    (idx, best)
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
  for edge in edges {
    let (u, v, w) = edge
    if w < 0L {
      return None
    }
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push((v, w))
    }
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
  let best = for edge in adj[u]; best = INF64 {
    let (to, w) = edge
    if to == v && w < best {
      continue w
    }
    continue best
  } nobreak {
    best
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
  let last = nodes.length() - 1
  for i in 0..<last; total = 0L {
    let u = nodes[i]
    let v = nodes[i + 1]
    match min_edge_weight(adj, u, v) {
      None => break None
      Some(w) => continue total + w
    }
  } nobreak {
    Some(total)
  }
}

///|
fn prefix_nodes(nodes : Array[Int], end_idx : Int) -> Array[Int] {
  let prefix : Array[Int] = []
  for i in 0..<=end_idx {
    prefix.push(nodes[i])
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
      if !blocked_nodes[u] &&
        !blocked_nodes[v] &&
        !is_blocked_edge(blocked_edges, u, v) {
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
  for kth in 1..<k {
    let prev = a_paths[kth - 1]
    if prev.nodes.length() <= 1 {
      break
    }
    for i in 0..<(prev.nodes.length() - 1) {
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
      for j in 0..<(root.length() - 1) {
        blocked_nodes[root[j]] = true
      }
      let spur_node = root[root.length() - 1]
      let spur = shortest_path_filtered(
        n, edges, blocked_nodes, blocked_edges, spur_node, target,
      )
      if spur is Some(spur_path) {
        let total_nodes = combine_paths(root, spur_path.nodes)
        let candidate = { nodes: total_nodes, cost: root_cost + spur_path.cost }
        if !path_in_list(b_candidates, candidate.nodes) &&
          !path_in_list(a_paths, candidate.nodes) {
          b_candidates.push(candidate)
        }
      }
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

///|
test "yen path cost uses lightest parallel edge" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L), (0, 1, 2L), (1, 2, 1L)]
  let adj = build_adj(3, edges[:]).unwrap()
  inspect(path_cost(adj, [0, 1, 2]).unwrap(), content="3")
}
