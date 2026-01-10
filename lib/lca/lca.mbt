// ============================================================================
// LCA (Lowest Common Ancestor) - Binary Lifting Algorithm
// ============================================================================
//
// LCA finds the deepest node that is an ancestor of both given nodes in a tree.
// Binary Lifting enables O(log n) queries after O(n log n) preprocessing.
//
// KEY INSIGHT: Precompute 2^k-th ancestors for each node. Any ancestor can be
// reached by combining powers of 2 (like binary representation of a number).
//
// BINARY LIFTING:
// up[v][k] = 2^k-th ancestor of node v
// up[v][0] = parent[v]
// up[v][k] = up[up[v][k-1]][k-1]  (2^k ancestor = 2^(k-1) ancestor of 2^(k-1) ancestor)
//
// EXAMPLE TREE:
//         0
//        /|\
//       1 2 3
//      / \
//     4   5
//
// up[4][0] = 1 (parent)
// up[4][1] = 0 (grandparent = up[up[4][0]][0] = up[1][0])
//
// LCA ALGORITHM:
// 1. Bring u and v to same depth by jumping with binary lifting
// 2. Binary search for LCA: jump together until parents differ
// 3. Return the parent (which is the LCA)
//
// INVARIANTS:
// 1. up[v][k] = 2^k-th ancestor of v (or -1 if doesn't exist)
// 2. depth[v] = distance from root to v
// 3. After equalization, u and v are at the same depth
//
// TIME COMPLEXITY: O(n log n) preprocessing, O(log n) per query
// SPACE COMPLEXITY: O(n log n)

///|
/// LCA data structure with binary lifting
priv struct LCA {
  n : Int
  log_n : Int
  up : Array[Array[Int]] // up[v][k] = 2^k-th ancestor
  depth : Array[Int]
  adj : Array[Array[Int]]
}

///|
fn compute_log(n : Int) -> Int {
  let mut log = 0
  let mut val = 1
  while val < n {
    log = log + 1
    val = val * 2
  }
  log + 1
}

///|
/// Create LCA structure from adjacency list (tree rooted at 0)
fn LCA::new(n : Int, edges : Array[(Int, Int)]) -> LCA {
  if n == 0 {
    return { n: 0, log_n: 0, up: [], depth: [], adj: [] }
  }

  let log_n = compute_log(n)
  let adj : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  }

  // Build adjacency list
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      adj[v].push(u)
    }
  }

  // Initialize arrays
  let depth = Array::make(n, 0)
  let up : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    up.push(Array::make(log_n, -1))
  }

  // DFS to compute depth and immediate parent
  let visited = Array::make(n, false)
  dfs_build(0, -1, 0, adj, depth, up, visited)

  // Build sparse table for binary lifting
  for k = 1; k < log_n; k = k + 1 {
    for v = 0; v < n; v = v + 1 {
      if up[v][k - 1] != -1 {
        up[v][k] = up[up[v][k - 1]][k - 1]
      }
    }
  } where {
    invariant: k >= 1 && k <= log_n,
    reasoning: "I: After DFS, up[v][0] = parent[v] for all v (base case: 2^0 = 1st ancestor). M: For level k, up[v][k] = up[up[v][k-1]][k-1]. This computes the 2^k-th ancestor by jumping to the 2^(k-1)-th ancestor, then jumping another 2^(k-1) steps. Proof: 2^(k-1) + 2^(k-1) = 2^k. If either jump is invalid (-1), up[v][k] remains -1. T: After k=log_n-1, up[v][k] correctly stores 2^k-th ancestor for all k in [0, log_n), enabling O(log n) ancestor queries.",
  }

  { n, log_n, up, depth, adj }
}

///|
fn dfs_build(
  v : Int,
  parent : Int,
  d : Int,
  adj : Array[Array[Int]],
  depth : Array[Int],
  up : Array[Array[Int]],
  visited : Array[Bool]
) -> Unit {
  visited[v] = true
  depth[v] = d
  up[v][0] = parent

  for i = 0; i < adj[v].length(); i = i + 1 {
    let u = adj[v][i]
    if not(visited[u]) {
      dfs_build(u, v, d + 1, adj, depth, up, visited)
    }
  }
}

///|
/// Find LCA of nodes u and v
/// TIME: O(log n)
///
/// ALGORITHM:
/// 1. Bring deeper node up to same level as shallower node
/// 2. Binary search: jump both nodes while their ancestors differ
/// 3. Return parent of final position (or position if already same)
fn LCA::query(self : LCA, u : Int, v : Int) -> Int {
  if u < 0 || u >= self.n || v < 0 || v >= self.n {
    return -1
  }

  // Ensure u is deeper
  let mut curr_u = u
  let mut curr_v = v
  if self.depth[curr_u] < self.depth[curr_v] {
    let temp = curr_u
    curr_u = curr_v
    curr_v = temp
  }

  let diff = self.depth[curr_u] - self.depth[curr_v]

  // Bring u to same level as v
  for k = 0; k < self.log_n; k = k + 1 {
    if ((diff >> k) & 1) == 1 {
      curr_u = self.up[curr_u][k]
    }
  } where {
    invariant: k >= 0 && k <= self.log_n,
    reasoning: "I: diff = depth[u] - depth[v] > 0; curr_u is at original position. M: If bit k of diff is set, jump curr_u up by 2^k steps using up[curr_u][k]. The total jump distance equals the binary representation of diff: sum of 2^k for all set bits. T: After processing all bits, curr_u has moved up by exactly diff levels, so depth[curr_u] = depth[curr_v]. Both nodes are now at the same level, ready for LCA binary search.",
  }

  if curr_u == curr_v {
    return curr_u
  }

  // Binary search for LCA - jump both nodes while their 2^k ancestors are different
  for k = self.log_n - 1; k >= 0; k = k - 1 {
    if self.up[curr_u][k] != self.up[curr_v][k] {
      curr_u = self.up[curr_u][k]
      curr_v = self.up[curr_v][k]
    }
  } where {
    invariant: k >= -1 && k < self.log_n,
    reasoning: "I: curr_u != curr_v (otherwise we returned early); LCA is a proper ancestor of both; distance from curr_u to LCA is < 2^log_n. M: For each k from high to low, if up[curr_u][k] != up[curr_v][k], the LCA is strictly above the 2^k-th ancestors, so we can safely jump both nodes up by 2^k. If they're equal, jumping would overshoot or reach LCA, so we skip. After bit k, both nodes are within 2^k steps of LCA. T: After k=0, both nodes are exactly 1 step below LCA (their parents are equal but they differ). Return up[curr_u][0] = LCA.",
  }

  // Parent of final position is LCA
  self.up[curr_u][0]
}

///|
/// Get depth of node
fn LCA::get_depth(self : LCA, v : Int) -> Int {
  if v < 0 || v >= self.n {
    return -1
  }
  self.depth[v]
}

///|
/// Get distance between two nodes
fn LCA::distance(self : LCA, u : Int, v : Int) -> Int {
  let lca = self.query(u, v)
  if lca == -1 {
    return -1
  }
  self.depth[u] + self.depth[v] - 2 * self.depth[lca]
}

///|
/// Get k-th ancestor of node v
fn LCA::kth_ancestor(self : LCA, v : Int, k : Int) -> Int {
  if v < 0 || v >= self.n || k < 0 {
    return -1
  }

  let mut curr = v
  for bit = 0; bit < self.log_n && curr != -1; bit = bit + 1 {
    if ((k >> bit) & 1) == 1 {
      curr = self.up[curr][bit]
    }
  }
  curr
}

///|
/// Check if u is ancestor of v
fn LCA::is_ancestor(self : LCA, u : Int, v : Int) -> Bool {
  self.query(u, v) == u
}

///|
/// Get path from u to v
fn LCA::get_path(self : LCA, u : Int, v : Int) -> Array[Int] {
  if u < 0 || u >= self.n || v < 0 || v >= self.n {
    return []
  }

  let lca = self.query(u, v)
  let path_u : Array[Int] = []
  let path_v : Array[Int] = []

  // Path from u to LCA
  let mut curr = u
  while curr != lca {
    path_u.push(curr)
    curr = self.up[curr][0]
  }
  path_u.push(lca)

  // Path from v to LCA
  curr = v
  while curr != lca {
    path_v.push(curr)
    curr = self.up[curr][0]
  }

  // Combine paths (path_u + reversed path_v without LCA)
  let result : Array[Int] = []
  for i = 0; i < path_u.length(); i = i + 1 {
    result.push(path_u[i])
  }
  for i = path_v.length() - 1; i >= 0; i = i - 1 {
    result.push(path_v[i])
  }
  result
}

// ============================================================================
// LCA WITH WEIGHTED EDGES (for path queries)
// ============================================================================

///|
priv struct WeightedLCA {
  lca : LCA
  dist_to_root : Array[Int64] // Distance from root to each node
}

///|
fn WeightedLCA::new(n : Int, edges : Array[(Int, Int, Int64)]) -> WeightedLCA {
  if n == 0 {
    return { lca: LCA::new(0, []), dist_to_root: [] }
  }

  // Convert weighted edges to unweighted for LCA structure
  let unweighted_edges : Array[(Int, Int)] = []
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, _) = edges[i]
    unweighted_edges.push((u, v))
  }

  let lca = LCA::new(n, unweighted_edges)

  // Build weighted adjacency list
  let wadj : Array[Array[(Int, Int64)]] = []
  for i = 0; i < n; i = i + 1 {
    wadj.push([])
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, w) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n {
      wadj[u].push((v, w))
      wadj[v].push((u, w))
    }
  }

  // DFS to compute distances
  let dist_to_root = Array::make(n, 0L)
  let visited = Array::make(n, false)
  dfs_dist(0, 0L, wadj, dist_to_root, visited)

  { lca, dist_to_root }
}

///|
fn dfs_dist(
  v : Int,
  d : Int64,
  wadj : Array[Array[(Int, Int64)]],
  dist : Array[Int64],
  visited : Array[Bool]
) -> Unit {
  visited[v] = true
  dist[v] = d

  for i = 0; i < wadj[v].length(); i = i + 1 {
    let (u, w) = wadj[v][i]
    if not(visited[u]) {
      dfs_dist(u, d + w, wadj, dist, visited)
    }
  }
}

///|
/// Query weighted distance between u and v
fn WeightedLCA::query_dist(self : WeightedLCA, u : Int, v : Int) -> Int64 {
  let lca = self.lca.query(u, v)
  if lca == -1 {
    return -1L
  }
  self.dist_to_root[u] + self.dist_to_root[v] - 2L * self.dist_to_root[lca]
}

///|
fn WeightedLCA::query_lca(self : WeightedLCA, u : Int, v : Int) -> Int {
  self.lca.query(u, v)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "lca basic" {
  // Tree:
  //       0
  //      /|\
  //     1 2 3
  //    /\
  //   4  5
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (1, 5)]
  let lca = LCA::new(6, edges)

  inspect(lca.query(4, 5), content="1")
  inspect(lca.query(4, 2), content="0")
  inspect(lca.query(1, 5), content="1")
  inspect(lca.query(0, 4), content="0")
}

///|
test "lca same node" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2)]
  let lca = LCA::new(3, edges)

  inspect(lca.query(1, 1), content="1")
  inspect(lca.query(0, 0), content="0")
}

///|
test "lca depth" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let lca = LCA::new(4, edges)

  inspect(lca.get_depth(0), content="0")
  inspect(lca.get_depth(1), content="1")
  inspect(lca.get_depth(2), content="2")
  inspect(lca.get_depth(3), content="3")
}

///|
test "lca distance" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let lca = LCA::new(5, edges)

  inspect(lca.distance(3, 4), content="2")
  inspect(lca.distance(3, 2), content="3")
  inspect(lca.distance(0, 3), content="2")
}

///|
test "lca kth ancestor" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let lca = LCA::new(5, edges)

  inspect(lca.kth_ancestor(4, 0), content="4")
  inspect(lca.kth_ancestor(4, 1), content="3")
  inspect(lca.kth_ancestor(4, 2), content="2")
  inspect(lca.kth_ancestor(4, 4), content="0")
  inspect(lca.kth_ancestor(4, 5), content="-1")
}

///|
test "lca is ancestor" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (0, 3)]
  let lca = LCA::new(4, edges)

  inspect(lca.is_ancestor(0, 2), content="true")
  inspect(lca.is_ancestor(1, 2), content="true")
  inspect(lca.is_ancestor(3, 2), content="false")
  inspect(lca.is_ancestor(2, 0), content="false")
}

///|
test "lca get path" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let lca = LCA::new(5, edges)

  let path = lca.get_path(3, 4)
  inspect(path.length(), content="3") // 3 -> 1 -> 4
}

///|
test "lca linear tree" {
  // Linear tree: 0 - 1 - 2 - 3 - 4
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let lca = LCA::new(5, edges)

  inspect(lca.query(2, 4), content="2")
  inspect(lca.query(1, 4), content="1")
  inspect(lca.query(0, 4), content="0")
}

///|
test "lca binary tree" {
  // Complete binary tree
  //        0
  //       / \
  //      1   2
  //     /|   |\
  //    3 4  5 6
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
  let lca = LCA::new(7, edges)

  inspect(lca.query(3, 4), content="1")
  inspect(lca.query(5, 6), content="2")
  inspect(lca.query(3, 6), content="0")
  inspect(lca.query(4, 5), content="0")
}

///|
test "weighted lca" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 10L),
    (0, 2, 20L),
    (1, 3, 5L),
    (1, 4, 15L),
  ]
  let wlca = WeightedLCA::new(5, edges)

  inspect(wlca.query_dist(3, 4), content="20") // 5 + 15
  inspect(wlca.query_dist(3, 2), content="35") // 5 + 10 + 20
  inspect(wlca.query_lca(3, 4), content="1")
}

///|
test "lca empty" {
  let lca = LCA::new(0, [])
  inspect(lca.query(0, 0), content="-1")
}

///|
test "lca single node" {
  let lca = LCA::new(1, [])
  inspect(lca.query(0, 0), content="0")
  inspect(lca.get_depth(0), content="0")
}

///|
test "lca invalid queries" {
  let edges : Array[(Int, Int)] = [(0, 1)]
  let lca = LCA::new(2, edges)

  inspect(lca.query(-1, 0), content="-1")
  inspect(lca.query(0, 10), content="-1")
  inspect(lca.get_depth(-1), content="-1")
}

///|
test "compute log" {
  inspect(compute_log(1), content="1")
  inspect(compute_log(2), content="2")
  inspect(compute_log(4), content="3")
  inspect(compute_log(8), content="4")
  inspect(compute_log(7), content="4")
}
