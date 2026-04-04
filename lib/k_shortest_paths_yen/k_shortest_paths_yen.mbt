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
/// Sentinel value used in place of infinity for Int64 distance comparisons.
/// Equal to `Int64::max_value() / 2` to avoid overflow in arithmetic.
const INF64 : Int64 = 4611686018427387903L

///| A single simple path in the graph, storing the sequence of visited nodes
/// and the total edge weight.
///
/// `nodes` is in traversal order from source to target. `cost` is the sum of
/// edge weights along that sequence.
pub(all) struct KPath {
  /// Ordered sequence of node indices from source to target.
  nodes : Array[Int]
  /// Total weight of all edges along `nodes`.
  cost : Int64
} derive(Debug)

///| Return `true` when `prefix` is an exact leading sub-sequence of `path`.
///
/// Used to identify which previously found paths share the same root as the
/// current spur candidate, so that their outgoing edges can be blocked.
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

///| Return `true` when arrays `a` and `b` contain identical elements in the
/// same order.
///
/// Used as an equality predicate for node-sequence arrays where structural
/// equality is needed but the arrays are heap-allocated.
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

///| Return `true` when any path in `paths` has the same node sequence as
/// `nodes`.
///
/// Used to prevent duplicate entries in the candidate set `B` and to skip
/// candidates that are already recorded in the accepted set `A`.
fn path_in_list(paths : Array[KPath], nodes : Array[Int]) -> Bool {
  for p in paths {
    if paths_equal(p.nodes, nodes) {
      return true
    }
  }
  false
}

///| Return the index of the `KPath` with the smallest `cost` in `paths`.
///
/// Returns `-1` when `paths` is empty.  Used instead of a priority queue to
/// pop the best candidate from the candidate set `B`.
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

///| Return `true` when the directed edge `(u, v)` appears in `blocked`.
///
/// Called for every edge in the original graph before adding it to the
/// temporary spur-search graph, so that edges that would recreate a previously
/// accepted path with the same root prefix are suppressed.
fn is_blocked_edge(blocked : Array[(Int, Int)], u : Int, v : Int) -> Bool {
  for edge in blocked {
    let (a, b) = edge
    if a == u && b == v {
      return true
    }
  }
  false
}

///| Build a plain adjacency-list representation of the graph.
///
/// Returns `None` if any edge weight is negative (Dijkstra requires
/// non-negative weights) or if any endpoint is out of range `[0, n)`.
/// Valid edges are stored as `(neighbor, weight)` pairs in `adj[u]`.
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

///| Return the minimum weight of any directed edge from `u` to `v` in the
/// adjacency list `adj`, or `None` when no such edge exists.
///
/// The minimum is taken because parallel edges are allowed; the algorithm
/// always uses the cheapest option when computing root-path cost.
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

///| Compute the total edge cost of the path described by `nodes` using the
/// adjacency list `adj`.
///
/// Returns `Some(total)` when every consecutive pair `(nodes[i], nodes[i+1])`
/// has at least one edge in `adj`, or `None` if any hop is missing.
/// Paths with a single node have cost `0`.
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

///| Extract the prefix of `nodes` up to and including index `end_idx`
/// (inclusive).
///
/// The resulting slice becomes the "root path" used when computing spur
/// candidates.  It always contains at least the source node.
fn prefix_nodes(nodes : Array[Int], end_idx : Int) -> Array[Int] {
  let prefix : Array[Int] = []
  for i in 0..<=end_idx {
    prefix.push(nodes[i])
  }
  prefix
}

///| Concatenate a root path and a spur path into one complete candidate path.
///
/// The last element of `root` is the spur node, which is the first element of
/// `spur`, so it must not be duplicated.  The function therefore appends all
/// of `root` except its last element, followed by the entirety of `spur`.
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

///| Find the shortest path from `source` to `target` in a temporarily
/// restricted version of the graph.
///
/// Edges listed in `blocked_edges` and edges incident to any node flagged
/// `true` in `blocked_nodes` are excluded from the Dijkstra run.  This is
/// used during spur generation to enforce:
///
/// - That root-prefix nodes are not revisited (guaranteeing simple paths).
/// - That edges which would duplicate an already-accepted path are suppressed.
///
/// Returns `None` when `source` or `target` is out of range, any edge weight
/// is negative, or no path exists in the filtered graph.
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

///| Compute up to `k` shortest loopless (simple) paths from `source` to
/// `target` in a directed, non-negatively weighted graph with `n` nodes.
///
/// The graph is given as a flat edge list `edges` where each entry is a tuple
/// `(u, v, weight)`.  Parallel edges are allowed; the algorithm uses the
/// cheapest parallel edge when computing root-path costs.
///
/// The returned array is sorted in non-decreasing order of `cost`.  Fewer than
/// `k` paths are returned when the graph has fewer than `k` distinct simple
/// paths from `source` to `target`.
///
/// Returns an empty array when:
/// - `n <= 0` or `k <= 0`
/// - `source` or `target` is outside `[0, n)`
/// - any edge weight is negative
/// - no path exists from `source` to `target`
///
/// ## Algorithm
///
/// Yen's algorithm works in two phases:
///
/// 1. **Bootstrap**: find the single shortest path with Dijkstra; add it to
///    the accepted list `A`.
/// 2. **Iteration**: for each subsequent path slot, iterate over every node
///    of the last accepted path as a potential spur node.  At each spur node:
///    - The "root path" is the prefix of the previous path up to that node.
///    - Edges that would recreate an already-accepted path sharing the same
///      root prefix are blocked.
///    - Root-prefix nodes (except the spur node itself) are blocked to
///      prevent cycles.
///    - Dijkstra finds the cheapest continuation ("spur path") from the spur
///      node to `target` in the restricted graph.
///    - The candidate `root + spur` is added to the heap `B` if not already
///      present.
///    - The cheapest candidate in `B` is moved to `A`.
///
/// ## Complexity
///
/// `O(k * n * (m + n log n))` where `n` is the number of vertices and `m` is
/// the number of edges.
///
/// ## Example
///
/// ```mbt check
/// ///|
/// test "yen k shortest paths" {
///   let edges : Array[(Int, Int, Int64)] = [
///     (0, 1, 1L),
///     (1, 3, 1L),
///     (0, 2, 3L),
///     (2, 3, 2L),
///     (1, 2, 1L),
///   ]
///   let paths = @k_shortest_paths_yen.yen_k_shortest_paths(4, edges[:], 0, 3, 3)
///   inspect(paths[0].cost, content="2")
///   inspect(paths[1].cost, content="4")
///   inspect(paths[2].cost, content="5")
/// }
/// ```
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
