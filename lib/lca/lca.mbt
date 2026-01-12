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
pub struct LCA {
  n : Int
  log_n : Int
  up : Array[Array[Int]] // up[v][k] = 2^k-th ancestor
  depth : Array[Int]
}

///|
fn compute_log(n : Int) -> Int {
  for val = 1, log = 0; val < n; {
    continue val * 2, log + 1
  } else {
    log + 1
  } where {
    invariant: val >= 1,
    invariant: log >= 0,
    reasoning: (
      #|INVARIANT (power-of-two growth):
      #|val equals 2^log and is the smallest power of two checked so far.
      #|MAINTENANCE:
      #|Each step doubles val and increments log, preserving val = 2^log.
      #|TERMINATION:
      #|val grows exponentially, so eventually val >= n and the loop ends.
    ),
  }
}

///|
/// Create LCA structure from edges (tree rooted at 0).
pub fn LCA::new(n : Int, edges : Array[(Int, Int)]) -> LCA {
  if n == 0 {
    return { n: 0, log_n: 0, up: [], depth: [] }
  }
  let log_n = compute_log(n)
  let adj : Array[Array[Int]] = []
  for _ in 0..<n {
    adj.push([])
  }

  // Build adjacency list
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      adj[v].push(u)
    }
  }

  // Initialize arrays
  let depth = Array::make(n, 0)
  let up : Array[Array[Int]] = []
  for _ in 0..<n {
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
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (Level k table fill):
        #|After processing vertices [0..v), up[x][k] is computed for all x < v.
        #|We use the recurrence up[v][k] = up[up[v][k-1]][k-1] when the
        #|2^(k-1)-th ancestor exists, yielding the 2^k-th ancestor.
        #|MAINTENANCE:
        #|Each vertex v uses two 2^(k-1) jumps to fill its 2^k ancestor,
        #|preserving correctness for the processed prefix.
        #|TERMINATION:
        #|At v == n, level k is fully populated.
      ),
    }
  } where {
    invariant: k >= 1 && k <= log_n,
    reasoning: (
      #|INVARIANT (Binary lifting table):
      #|After completing level k-1, up[v][t] is correct for all t < k.
      #|Level k is computed by composing two jumps of length 2^(k-1):
      #|  up[v][k] = up[up[v][k-1]][k-1].
      #|If either jump is invalid, up[v][k] stays -1. This builds all
      #|2^k ancestors needed for O(log n) queries.
      #|MAINTENANCE:
      #|Each k uses only already-correct level k-1, so correctness carries up.
      #|TERMINATION:
      #|At k == log_n, all powers of two needed for queries are built.
    ),
  }
  { n, log_n, up, depth }
}

///|
fn dfs_build(
  v : Int,
  parent : Int,
  d : Int,
  adj : Array[Array[Int]],
  depth : Array[Int],
  up : Array[Array[Int]],
  visited : Array[Bool],
) -> Unit {
  visited[v] = true
  depth[v] = d
  up[v][0] = parent
  for i = 0; i < adj[v].length(); i = i + 1 {
    let u = adj[v][i]
    if not(visited[u]) {
      dfs_build(u, v, d + 1, adj, depth, up, visited)
    }
  } where {
    invariant: i >= 0 && i <= adj[v].length(),
    reasoning: (
      #|INVARIANT (DFS expansion):
      #|After processing neighbors [0..i), every vertex reachable from v
      #|through those neighbors has been visited, with depth and parent set.
      #|This ensures the DFS tree is built consistently and without revisits.
      #|MAINTENANCE:
      #|Each recursive call fully explores a child subtree before i advances.
      #|TERMINATION:
      #|At i == adj[v].length(), all descendants of v are processed.
    ),
  }
}

///|
/// Find LCA of nodes u and v.
/// TIME: O(log n)
///
/// ALGORITHM:
/// 1. Bring deeper node up to same level as shallower node
/// 2. Binary search: jump both nodes while their ancestors differ
/// 3. Return parent of final position (or position if already same)
pub fn LCA::query(self : LCA, u : Int, v : Int) -> Int {
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
    reasoning: (
      #|INVARIANT (Leveling by bits):
      #|After processing bits [0..k), curr_u has been lifted by the sum of
      #|2^t for all processed bits t that are set in diff. The remaining
      #|height difference equals diff with the lower k bits cleared.
      #|
      #|When the loop ends, curr_u is lifted by exactly diff levels, so
      #|depth[curr_u] == depth[curr_v].
      #|MAINTENANCE:
      #|If bit k is set, we jump 2^k; otherwise we skip, preserving the
      #|remaining height difference invariant.
      #|TERMINATION:
      #|At k == log_n, all bits of diff are applied and depths match.
    ),
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
    reasoning: (
      #|INVARIANT (Binary lift toward LCA):
      #|curr_u and curr_v remain at the same depth and still below the LCA.
      #|If their 2^k ancestors differ, then the LCA is above both, so lifting
      #|by 2^k preserves correctness. If the ancestors are equal, lifting
      #|would skip over the LCA, so we keep them in place.
      #|
      #|After finishing, curr_u and curr_v are distinct children of the LCA,
      #|so up[curr_u][0] is the answer.
      #|MAINTENANCE:
      #|Lifting only when ancestors differ keeps both nodes strictly below
      #|the LCA while reducing their distance to it.
      #|TERMINATION:
      #|When k drops below 0, no larger lift is possible and the parent is LCA.
    ),
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
  } where {
    invariant: bit >= 0 && bit <= self.log_n,
    invariant: curr >= 0 && curr < self.n,
    reasoning: (
      #|INVARIANT (binary lifting):
      #|Bits [0..bit) of k are processed; curr is the ancestor after those jumps.
      #|MAINTENANCE:
      #|If bit is set, jump 2^bit using up-table; otherwise keep curr unchanged.
      #|TERMINATION:
      #|At bit = log_n, curr is the k-th ancestor if it exists.
    ),
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
  for curr = u; curr != lca; {
    path_u.push(curr)
    continue self.up[curr][0]
  } where {
    invariant: curr >= 0 && curr < self.n,
    reasoning: (
      #|INVARIANT (u to LCA):
      #|path_u contains the nodes from u up to (but excluding) curr, and curr
      #|is the current ancestor on the path to lca.
      #|MAINTENANCE:
      #|Appending curr and moving to its parent advances one step toward lca.
      #|TERMINATION:
      #|When curr == lca, the upward path from u is fully collected.
    ),
  }
  path_u.push(lca)

  // Path from v to LCA
  for curr = v; curr != lca; {
    path_v.push(curr)
    continue self.up[curr][0]
  } where {
    invariant: curr >= 0 && curr < self.n,
    reasoning: (
      #|INVARIANT (v to LCA):
      #|path_v contains the nodes from v up to (but excluding) curr, and curr
      #|is the current ancestor on the path to lca.
      #|MAINTENANCE:
      #|Appending curr and moving to its parent advances one step toward lca.
      #|TERMINATION:
      #|When curr == lca, the upward path from v is fully collected.
    ),
  }

  // Combine paths (path_u + reversed path_v without LCA)
  let result : Array[Int] = []
  for i = 0; i < path_u.length(); i = i + 1 {
    result.push(path_u[i])
  } where {
    invariant: i >= 0 && i <= path_u.length(),
    reasoning: (
      #|INVARIANT (path_u append):
      #|result contains path_u[0..i) in order.
      #|MAINTENANCE:
      #|Push path_u[i] to extend the prefix.
      #|TERMINATION:
      #|At i = path_u.length(), the u->LCA path is fully appended.
    ),
  }
  for i = path_v.length() - 1; i >= 0; i = i - 1 {
    result.push(path_v[i])
  } where {
    invariant: i >= -1 && i < path_v.length(),
    reasoning: (
      #|INVARIANT (path_v append):
      #|result already has path_u; we append path_v in reverse to reach v.
      #|MAINTENANCE:
      #|Push path_v[i], moving upward toward v without duplicating the LCA.
      #|TERMINATION:
      #|At i = -1, the full u->v path is constructed.
    ),
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
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (strip weights):
      #|unweighted_edges contains edges[0..i) without weights.
      #|MAINTENANCE:
      #|Push (u, v) for edges[i], discarding the weight.
      #|TERMINATION:
      #|At i = edges.length(), all weighted edges are stripped.
    ),
  }
  let lca = LCA::new(n, unweighted_edges)

  // Build weighted adjacency list
  let wadj : Array[Array[(Int, Int64)]] = []
  for i = 0; i < n; i = i + 1 {
    wadj.push([])
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init weighted adj):
      #|wadj[0..i) are initialized as empty adjacency lists.
      #|MAINTENANCE:
      #|Push a fresh empty list for vertex i.
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, w) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n {
      wadj[u].push((v, w))
      wadj[v].push((u, w))
    }
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (add weighted edges):
      #|All valid edges in edges[0..i) are added to wadj in both directions.
      #|MAINTENANCE:
      #|Insert (u, v, w) into both adjacency lists when endpoints are valid.
      #|TERMINATION:
      #|At i = edges.length(), the weighted graph is fully built.
    ),
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
  visited : Array[Bool],
) -> Unit {
  visited[v] = true
  dist[v] = d
  for i = 0; i < wadj[v].length(); i = i + 1 {
    let (u, w) = wadj[v][i]
    if not(visited[u]) {
      dfs_dist(u, d + w, wadj, dist, visited)
    }
  } where {
    invariant: i >= 0 && i <= wadj[v].length(),
    reasoning: (
      #|INVARIANT (dfs neighbors):
      #|Neighbors wadj[v][0..i) have been explored; dist values are set for them.
      #|MAINTENANCE:
      #|Recurse into unvisited neighbor u, adding edge weight w to the distance.
      #|TERMINATION:
      #|At i = deg(v), all neighbors of v are processed.
    ),
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
  let edges : Array[(Int, Int)] = [
    (0, 1),
    (0, 2),
    (1, 3),
    (1, 4),
    (2, 5),
    (2, 6),
  ]
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
