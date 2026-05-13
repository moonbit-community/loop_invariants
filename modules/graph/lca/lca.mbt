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
/// Lowest Common Ancestor structure using binary lifting.
///
/// Stores a rooted tree (root = 0) with precomputed ancestor tables so that
/// LCA queries can be answered in O(log n) after O(n log n) preprocessing.
///
/// Fields:
/// - `n`      : number of nodes in the tree
/// - `log_n`  : height of the ancestor table, equal to ceil(log2(n)) + 1
/// - `up`     : sparse ancestor table; `up[v][k]` is the 2^k-th ancestor of
///              node `v`, or -1 when that ancestor does not exist
/// - `depth`  : `depth[v]` is the distance (number of edges) from the root
///              to node `v`
pub struct LCA {
  n : Int
  log_n : Int
  up : Array[Array[Int]] // up[v][k] = 2^k-th ancestor
  depth : Array[Int]
}

///|
/// Compute the smallest integer k such that 2^k >= n.
///
/// Used to determine the height of the binary lifting table so that every
/// ancestor reachable within the tree can be represented.
fn compute_log(n : Int) -> Int {
  for val = 1, log = 0; val < n; {
    continue val * 2, log + 1
  } nobreak {
    log + 1
  } where {
    proof_invariant: log >= 0,
    proof_invariant: val == 1 << log,
    proof_reasoning: (
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
/// Build an LCA structure for a tree with `n` nodes rooted at node 0.
///
/// `edges` is an unordered list of undirected edges `(u, v)`. The edges
/// must form a valid tree (connected, acyclic). Edges referencing nodes
/// outside `[0, n-1]` are silently ignored.
///
/// Time:  O(n log n)
/// Space: O(n log n)
///
/// Example:
/// ```
/// let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3)]
/// let lca = LCA(4, edges)
/// ```
pub fn LCA::LCA(n : Int, edges : Array[(Int, Int)]) -> LCA {
  if n == 0 {
    return { n: 0, log_n: 0, up: [], depth: [] }
  }
  let log_n = compute_log(n)
  // Use makei to create adjacency list - each element is an independent empty array
  let adj : Array[Array[Int]] = [ for _ in 0..<n => [] ]

  // Build adjacency list
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      adj[v].push(u)
    }
  }

  // Initialize arrays using makei
  let depth = Array::make(n, 0)
  let up : Array[Array[Int]] = [ for _ in 0..<n => Array::make(log_n, -1) ]

  // DFS to compute depth and immediate parent
  let visited = Array::make(n, false)
  dfs_build(0, -1, 0, adj, depth, up, visited)

  // Build sparse table for binary lifting
  for k in 1..<log_n {
    for v in 0..<n {
      if up[v][k - 1] != -1 {
        up[v][k] = up[up[v][k - 1]][k - 1]
      }
    } where {
      proof_invariant: v >= 0 && v <= n,
      proof_reasoning: (
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
    proof_invariant: k >= 1 && k <= log_n,
    proof_reasoning: (
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
/// Recursive DFS that initialises `depth` and the first row of the `up` table.
///
/// For each node `v` visited:
/// - `depth[v]` is set to the distance from the root.
/// - `up[v][0]` is set to `parent` (the immediate parent of `v`), or -1 for
///   the root.
///
/// Marking nodes in `visited` ensures each node is processed exactly once even
/// if the adjacency list contains back-edges.
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
  for u in adj[v] {
    if !visited[u] {
      dfs_build(u, v, d + 1, adj, depth, up, visited)
    }
  }
}

///|
/// Return the Lowest Common Ancestor of nodes `u` and `v`.
///
/// Returns -1 if either node is outside `[0, n-1]`.
/// Returns `u` (or `v`) directly when one node is an ancestor of the other.
///
/// Time: O(log n)
///
/// Algorithm:
/// 1. Bring the deeper node up to the same depth as the shallower node using
///    binary lifting on the depth difference.
/// 2. If the nodes are now equal, that node is the LCA.
/// 3. Otherwise, scan bit positions from high to low: jump both nodes up by
///    2^k whenever their 2^k-th ancestors differ. After this loop the LCA is
///    the immediate parent of either node.
///
/// Example:
/// ```
/// // Tree: 0 - 1 - 2
/// //            \- 3
/// let lca = LCA(4, [(0, 1), (1, 2), (1, 3)])
/// lca.query(2, 3) // returns 1
/// lca.query(0, 2) // returns 0
/// ```
pub fn LCA::query(self : LCA, u : Int, v : Int) -> Int {
  if u < 0 || u >= self.n || v < 0 || v >= self.n {
    return -1
  }

  // Ensure u is deeper
  let (curr_u, curr_v) = if self.depth[u] < self.depth[v] {
    (v, u)
  } else {
    (u, v)
  }
  let diff = self.depth[curr_u] - self.depth[curr_v]

  // Bring u to same level as v
  let curr_u = for k in 0..<self.log_n; curr_u = curr_u {
    if ((diff >> k) & 1) == 1 {
      continue self.up[curr_u][k]
    } else {
      continue curr_u
    }
  } nobreak {
    curr_u
  } where {
    proof_invariant: k >= 0 && k <= self.log_n,
    proof_reasoning: (
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
  let (curr_u, _) = for k in self.log_n>..0; curr_u = curr_u, curr_v = curr_v {
    if self.up[curr_u][k] != self.up[curr_v][k] {
      continue self.up[curr_u][k], self.up[curr_v][k]
    } else {
      continue curr_u, curr_v
    }
  } nobreak {
    (curr_u, curr_v)
  }

  // Parent of final position is LCA
  self.up[curr_u][0]
}

///|
/// Return the depth (distance from root) of node `v`.
///
/// Returns -1 if `v` is outside `[0, n-1]`.
fn LCA::get_depth(self : LCA, v : Int) -> Int {
  if v < 0 || v >= self.n {
    return -1
  }
  self.depth[v]
}

///|
/// Return the number of edges on the path between nodes `u` and `v`.
///
/// Uses the identity:
///   `dist(u, v) = depth[u] + depth[v] - 2 * depth[LCA(u, v)]`
///
/// Returns -1 if either node is outside `[0, n-1]`.
fn LCA::distance(self : LCA, u : Int, v : Int) -> Int {
  let lca = self.query(u, v)
  if lca == -1 {
    return -1
  }
  self.depth[u] + self.depth[v] - 2 * self.depth[lca]
}

///|
/// Return the k-th ancestor of node `v` (0-th ancestor is `v` itself).
///
/// Uses binary lifting: decompose `k` into powers of two and compose the
/// corresponding jumps from the `up` table.
///
/// Returns -1 if `v` is outside `[0, n-1]`, `k` is negative, or `v` has
/// fewer than `k` ancestors (i.e., the root is reached before k jumps).
fn LCA::kth_ancestor(self : LCA, v : Int, k : Int) -> Int {
  if v < 0 || v >= self.n || k < 0 {
    return -1
  }
  for bit in 0..<self.log_n; curr = v {
    if curr == -1 {
      continue curr
    } else if ((k >> bit) & 1) == 1 {
      continue self.up[curr][bit]
    } else {
      continue curr
    }
  } nobreak {
    curr
  } where {
    proof_invariant: bit >= 0 && bit <= self.log_n,
    proof_invariant: curr >= -1 && curr < self.n,
    proof_reasoning: (
      #|INVARIANT (binary lifting):
      #|Bits [0..bit) of k are processed; curr is the ancestor after those jumps.
      #|MAINTENANCE:
      #|If bit is set, jump 2^bit using up-table; otherwise keep curr unchanged.
      #|TERMINATION:
      #|At bit = log_n, curr is the k-th ancestor if it exists.
    ),
  }
}

///|
/// Return `true` if `u` is an ancestor of `v` (including `u == v`).
///
/// Equivalent to checking whether `LCA(u, v) == u`.
fn LCA::is_ancestor(self : LCA, u : Int, v : Int) -> Bool {
  self.query(u, v) == u
}

///|
/// Return the sequence of nodes on the unique path from `u` to `v`.
///
/// The path is returned as an array starting at `u`, passing through
/// `LCA(u, v)`, and ending at `v`. The LCA node appears exactly once.
///
/// Returns an empty array if either node is outside `[0, n-1]`.
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
    proof_invariant: curr >= 0 && curr < self.n,
    proof_reasoning: (
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
    proof_invariant: curr >= 0 && curr < self.n,
    proof_reasoning: (
      #|INVARIANT (v to LCA):
      #|path_v contains the nodes from v up to (but excluding) curr, and curr
      #|is the current ancestor on the path to lca.
      #|MAINTENANCE:
      #|Appending curr and moving to its parent advances one step toward lca.
      #|TERMINATION:
      #|When curr == lca, the upward path from v is fully collected.
    ),
  }

  // Combine paths: path_u + reversed path_v (without duplicating LCA)
  // Use copy() to start with path_u, then append reversed path_v
  let result = path_u.copy()
  result.append(path_v.rev())
  result
}

// ============================================================================
// LCA WITH WEIGHTED EDGES (for path queries)
// ============================================================================

///|
/// LCA structure extended with weighted edges for path-distance queries.
///
/// Stores an unweighted `LCA` for ancestor lookups together with
/// `dist_to_root[v]`, the sum of edge weights on the path from the root
/// to each node `v`. Weighted distance queries then reduce to:
///   `dist(u, v) = dist_to_root[u] + dist_to_root[v] - 2 * dist_to_root[LCA(u, v)]`
priv struct WeightedLCA {
  lca : LCA
  dist_to_root : Array[Int64] // Distance from root to each node
}

///|
/// Build a `WeightedLCA` for a weighted tree with `n` nodes rooted at 0.
///
/// `edges` is a list of triples `(u, v, weight)`. Edges outside `[0, n-1]`
/// are ignored. The topology is handed to `LCA::new`; a separate DFS
/// accumulates weighted distances from the root.
fn WeightedLCA::WeightedLCA(
  n : Int,
  edges : Array[(Int, Int, Int64)],
) -> WeightedLCA {
  if n == 0 {
    return { lca: LCA(0, []), dist_to_root: [] }
  }

  // Convert weighted edges to unweighted for LCA structure using map
  let unweighted_edges = edges[:].map(edge => (edge.0, edge.1))
  let lca = LCA(n, unweighted_edges)

  // Build weighted adjacency list
  let wadj : Array[Array[(Int, Int64)]] = [ for _ in 0..<n => [] ]
  for edge in edges {
    let (u, v, w) = edge
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
/// Recursive DFS that computes `dist_to_root` for a weighted tree.
///
/// `d` carries the accumulated weight from the root to the current node `v`.
/// Each unvisited neighbour is recursed into with its edge weight added.
fn dfs_dist(
  v : Int,
  d : Int64,
  wadj : Array[Array[(Int, Int64)]],
  dist : Array[Int64],
  visited : Array[Bool],
) -> Unit {
  visited[v] = true
  dist[v] = d
  for neighbor in wadj[v] {
    let (u, w) = neighbor
    if !visited[u] {
      dfs_dist(u, d + w, wadj, dist, visited)
    }
  }
}

///|
/// Return the total edge-weight on the path between `u` and `v`.
///
/// Computes `dist_to_root[u] + dist_to_root[v] - 2 * dist_to_root[LCA(u, v)]`.
/// Returns -1L if the underlying LCA query is invalid.
fn WeightedLCA::query_dist(self : WeightedLCA, u : Int, v : Int) -> Int64 {
  let lca = self.lca.query(u, v)
  if lca == -1 {
    return -1L
  }
  self.dist_to_root[u] + self.dist_to_root[v] - 2L * self.dist_to_root[lca]
}

///|
/// Return the LCA of `u` and `v` using the underlying unweighted structure.
///
/// Delegates directly to `LCA::query`; the edge weights have no effect on
/// which node is the LCA.
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
  let lca = LCA(6, edges)
  debug_inspect(lca.query(4, 5), content="1")
  debug_inspect(lca.query(4, 2), content="0")
  debug_inspect(lca.query(1, 5), content="1")
  debug_inspect(lca.query(0, 4), content="0")
}

///|
test "lca same node" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2)]
  let lca = LCA(3, edges)
  debug_inspect(lca.query(1, 1), content="1")
  debug_inspect(lca.query(0, 0), content="0")
}

///|
test "lca depth" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let lca = LCA(4, edges)
  debug_inspect(lca.get_depth(0), content="0")
  debug_inspect(lca.get_depth(1), content="1")
  debug_inspect(lca.get_depth(2), content="2")
  debug_inspect(lca.get_depth(3), content="3")
}

///|
test "lca distance" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let lca = LCA(5, edges)
  debug_inspect(lca.distance(3, 4), content="2")
  debug_inspect(lca.distance(3, 2), content="3")
  debug_inspect(lca.distance(0, 3), content="2")
}

///|
test "lca kth ancestor" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let lca = LCA(5, edges)
  debug_inspect(lca.kth_ancestor(4, 0), content="4")
  debug_inspect(lca.kth_ancestor(4, 1), content="3")
  debug_inspect(lca.kth_ancestor(4, 2), content="2")
  debug_inspect(lca.kth_ancestor(4, 4), content="0")
  debug_inspect(lca.kth_ancestor(4, 5), content="-1")
}

///|
test "lca is ancestor" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (0, 3)]
  let lca = LCA(4, edges)
  debug_inspect(lca.is_ancestor(0, 2), content="true")
  debug_inspect(lca.is_ancestor(1, 2), content="true")
  debug_inspect(lca.is_ancestor(3, 2), content="false")
  debug_inspect(lca.is_ancestor(2, 0), content="false")
}

///|
test "lca get path" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let lca = LCA(5, edges)
  let path = lca.get_path(3, 4)
  debug_inspect(path.length(), content="3") // 3 -> 1 -> 4
}

///|
test "lca linear tree" {
  // Linear tree: 0 - 1 - 2 - 3 - 4
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let lca = LCA(5, edges)
  debug_inspect(lca.query(2, 4), content="2")
  debug_inspect(lca.query(1, 4), content="1")
  debug_inspect(lca.query(0, 4), content="0")
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
  let lca = LCA(7, edges)
  debug_inspect(lca.query(3, 4), content="1")
  debug_inspect(lca.query(5, 6), content="2")
  debug_inspect(lca.query(3, 6), content="0")
  debug_inspect(lca.query(4, 5), content="0")
}

///|
test "weighted lca" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 10L),
    (0, 2, 20L),
    (1, 3, 5L),
    (1, 4, 15L),
  ]
  let wlca = WeightedLCA(5, edges)
  debug_inspect(wlca.query_dist(3, 4), content="20") // 5 + 15
  debug_inspect(wlca.query_dist(3, 2), content="35") // 5 + 10 + 20
  debug_inspect(wlca.query_lca(3, 4), content="1")
}

///|
test "lca empty" {
  let lca = LCA(0, [])
  debug_inspect(lca.query(0, 0), content="-1")
}

///|
test "lca single node" {
  let lca = LCA(1, [])
  debug_inspect(lca.query(0, 0), content="0")
  debug_inspect(lca.get_depth(0), content="0")
}

///|
test "lca invalid queries" {
  let edges : Array[(Int, Int)] = [(0, 1)]
  let lca = LCA(2, edges)
  debug_inspect(lca.query(-1, 0), content="-1")
  debug_inspect(lca.query(0, 10), content="-1")
  debug_inspect(lca.get_depth(-1), content="-1")
}

///|
test "compute log" {
  debug_inspect(compute_log(1), content="1")
  debug_inspect(compute_log(2), content="2")
  debug_inspect(compute_log(4), content="3")
  debug_inspect(compute_log(8), content="4")
  debug_inspect(compute_log(7), content="4")
}
