// ============================================================================
// EULER TOUR - Tree Linearization Technique
// ============================================================================
//
// Euler Tour converts a tree into a linear sequence, enabling range queries
// on subtrees using standard data structures like segment trees.
//
// KEY INSIGHT: By recording entry and exit times during DFS, subtrees become
// contiguous intervals in the tour array.
//
// TOUR TYPES:
// 1. Entry-only: Record node when entering (for subtree queries)
// 2. Entry-Exit: Record entry and exit (for LCA, path queries)
//
// PROPERTIES:
// - Subtree of node v: tour[entry[v]..exit[v]]
// - LCA(u,v): Node with minimum depth in tour[entry[u]..entry[v]]
//
// INVARIANTS:
// 1. entry[v] < exit[v] for all nodes
// 2. For ancestor u of v: entry[u] < entry[v] < exit[v] < exit[u]
// 3. Subtrees are contiguous intervals in the tour
//
// TIME COMPLEXITY: O(n) to build, O(1) for subtree range
// SPACE COMPLEXITY: O(n)

///|
/// Internal state for building a single-visit (entry-only) Euler tour.
///
/// Stores the adjacency list, per-node entry/exit times, the preorder
/// visit sequence, depths, parent pointers, and a running DFS timer.
priv struct EulerTour {
  adj : Array[Array[Int]]
  entry : Array[Int] // Entry time of each node
  exit : Array[Int] // Exit time of each node
  tour : Array[Int] // Euler tour sequence
  depth : Array[Int] // Depth of each node
  parent : Array[Int]
  mut timer : Int
}

///|
/// Allocate a fresh `EulerTour` for a tree with `n` nodes.
/// All times are initialised to 0; the adjacency list is empty.
fn EulerTour::new(n : Int) -> EulerTour {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  {
    adj,
    entry: Array::make(n, 0),
    exit: Array::make(n, 0),
    tour: [],
    depth: Array::make(n, 0),
    parent: Array::make(n, -1),
    timer: 0,
  }
}

///|
/// Add an undirected edge between nodes `u` and `v`.
fn EulerTour::add_edge(self : EulerTour, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Build Euler tour starting from root.
///
/// Resets the timer and tour sequence, then runs a recursive DFS from
/// `root` to populate `entry`, `exit`, `tour`, `depth`, and `parent`.
fn EulerTour::build(self : EulerTour, root : Int) -> Unit {
  self.timer = 0
  self.tour.clear()
  self.dfs(root, -1, 0)
}

///|
/// Recursive DFS that stamps entry/exit times and records preorder visit.
///
/// Parameters:
/// - `u`  – current node
/// - `p`  – parent node (`-1` at the root)
/// - `d`  – depth of `u` (root is 0)
fn EulerTour::dfs(self : EulerTour, u : Int, p : Int, d : Int) -> Unit {
  self.parent[u] = p
  self.depth[u] = d
  self.entry[u] = self.timer
  self.timer = self.timer + 1
  self.tour.push(u)
  for v in self.adj[u] {
    if v != p {
      self.dfs(v, u, d + 1)
    }
  }
  self.exit[u] = self.timer
}

///|
/// Return the half-open interval `[entry[v], exit[v])` that covers the
/// subtree of `v` in the tour array.
fn EulerTour::subtree_range(self : EulerTour, v : Int) -> (Int, Int) {
  (self.entry[v], self.exit[v])
}

///|
/// Return the number of nodes in the subtree rooted at `v`
/// (including `v` itself).
fn EulerTour::subtree_size(self : EulerTour, v : Int) -> Int {
  self.exit[v] - self.entry[v]
}

///|
/// Return `true` if `u` is an ancestor of `v` in the rooted tree.
///
/// A node is considered an ancestor of itself.
fn EulerTour::is_ancestor(self : EulerTour, u : Int, v : Int) -> Bool {
  self.entry[u] <= self.entry[v] && self.exit[v] <= self.exit[u]
}

///|
/// Return an array of all node IDs in the subtree of `v`, in tour order.
fn EulerTour::get_subtree(self : EulerTour, v : Int) -> Array[Int] {
  let result : Array[Int] = []
  let start = self.entry[v]
  let end = self.exit[v]
  for i in start..<end {
    result.push(self.tour[i])
  }
  result
}

///|
/// The result of a completed Euler tour.
///
/// After calling `build_euler_tour`, each field is indexed by node ID
/// (0-based).  All arrays have length `n`.
///
/// Fields:
/// - `entry`  – DFS entry (in-) time of each node
/// - `exit`   – DFS exit time of each node (exclusive upper bound for the
///              subtree slice `tour[entry[u]..exit[u]]`)
/// - `tour`   – nodes in preorder (each node appears exactly once)
/// - `depth`  – depth of each node; the root has depth 0
/// - `parent` – parent of each node; the root's parent is `-1`
pub struct EulerTourInfo {
  entry : Array[Int]
  exit : Array[Int]
  tour : Array[Int]
  depth : Array[Int]
  parent : Array[Int]
}

///|
/// Build an Euler tour of the tree described by `edges`, rooted at `root`.
///
/// Parameters:
/// - `n`     – number of nodes (labelled `0..n-1`)
/// - `edges` – undirected edges given as `(u, v)` pairs; edges outside the
///             valid node range `[0, n)` are silently ignored
/// - `root`  – root node; clamped to 0 if out of range
///
/// Returns an `EulerTourInfo` with all arrays of length `n`.
/// Returns an empty `EulerTourInfo` when `n <= 0`.
///
/// Time: O(n).  Space: O(n).
pub fn build_euler_tour(
  n : Int,
  edges : ArrayView[(Int, Int)],
  root : Int,
) -> EulerTourInfo {
  if n <= 0 {
    return { entry: [], exit: [], tour: [], depth: [], parent: [] }
  }
  let tree = EulerTour::new(n)
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      tree.add_edge(u, v)
    }
  }
  let r = if root >= 0 && root < n { root } else { 0 }
  tree.build(r)
  {
    entry: tree.entry,
    exit: tree.exit,
    tour: tree.tour,
    depth: tree.depth,
    parent: tree.parent,
  }
}

///|
/// Convenience wrapper that returns the three most-used arrays directly.
///
/// Equivalent to calling `build_euler_tour` and unpacking `entry`, `exit`,
/// and `tour`.  Use `build_euler_tour` when you also need `depth` or
/// `parent`.
///
/// Returns `(entry, exit, tour)` – all arrays of length `n`.
pub fn euler_tour(
  n : Int,
  edges : ArrayView[(Int, Int)],
  root : Int,
) -> (Array[Int], Array[Int], Array[Int]) {
  let info = build_euler_tour(n, edges, root)
  (info.entry, info.exit, info.tour)
}

///|
/// Return the DFS entry time of node `v`.
///
/// Returns `-1` if `v` is out of bounds.
pub fn EulerTourInfo::entry(self : EulerTourInfo, v : Int) -> Int {
  if v < 0 || v >= self.entry.length() {
    -1
  } else {
    self.entry[v]
  }
}

///|
/// Return the DFS exit time of node `v`.
///
/// The exit time is the exclusive upper bound of the subtree slice:
/// `tour[entry[v]..exit[v]]` contains exactly the nodes of `v`'s subtree.
///
/// Returns `-1` if `v` is out of bounds.
pub fn EulerTourInfo::exit(self : EulerTourInfo, v : Int) -> Int {
  if v < 0 || v >= self.exit.length() {
    -1
  } else {
    self.exit[v]
  }
}

///|
/// Return the number of nodes in the subtree rooted at `v`
/// (including `v` itself).
///
/// Computed as `exit[v] - entry[v]` in O(1).
/// Returns 0 if `v` is out of bounds.
pub fn EulerTourInfo::subtree_size(self : EulerTourInfo, v : Int) -> Int {
  if v < 0 || v >= self.entry.length() {
    0
  } else {
    self.exit[v] - self.entry[v]
  }
}

///|
/// Return `true` if `u` is an ancestor of `v` in the rooted tree.
///
/// Uses the containment property of DFS intervals:
/// `u` is an ancestor of `v` iff `entry[u] <= entry[v]` and
/// `exit[v] <= exit[u]`.  A node is an ancestor of itself.
///
/// Returns `false` if either index is out of bounds.
pub fn EulerTourInfo::is_ancestor(
  self : EulerTourInfo,
  u : Int,
  v : Int,
) -> Bool {
  if u < 0 || v < 0 || u >= self.entry.length() || v >= self.entry.length() {
    false
  } else {
    self.entry[u] <= self.entry[v] && self.exit[v] <= self.exit[u]
  }
}

///|
/// Return the preorder tour array (nodes in DFS visit order).
///
/// Each node appears exactly once.  The position of node `u` in this array
/// is `entry[u]`.
pub fn EulerTourInfo::tour(self : EulerTourInfo) -> Array[Int] {
  self.tour
}

///|
/// Return the nodes in `v`'s subtree in tour (preorder) order.
///
/// The slice `tour[entry[v]..exit[v]]` is copied into a fresh array.
/// Returns an empty array if `v` is out of bounds.
pub fn EulerTourInfo::subtree_nodes(
  self : EulerTourInfo,
  v : Int,
) -> Array[Int] {
  if v < 0 || v >= self.entry.length() {
    return []
  }
  let result : Array[Int] = []
  let start = self.entry[v]
  let end = self.exit[v]
  for i in start..<end {
    result.push(self.tour[i])
  }
  result
}

// ============================================================================
// EULER TOUR WITH LCA SUPPORT
// ============================================================================

///|
/// Internal state for the full (entry-and-exit) Euler tour used for LCA.
///
/// The full tour visits each node once on entry and once on exit per child,
/// producing a sequence of length `2n - 1`.  A sparse table over the depths
/// in this sequence enables O(1) LCA queries after O(n log n) preprocessing.
priv struct EulerTourLCA {
  adj : Array[Array[Int]]
  first : Array[Int] // First occurrence in tour
  euler : Array[Int] // Euler tour (with revisits)
  depth : Array[Int] // Depth at each position in euler tour
  mut sparse : Array[Array[Int]] // Sparse table for RMQ
  log : Array[Int]
}

///|
/// Allocate a fresh `EulerTourLCA` for a tree with `n` nodes.
fn EulerTourLCA::new(n : Int) -> EulerTourLCA {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  {
    adj,
    first: Array::make(n, -1),
    euler: [],
    depth: [],
    sparse: [],
    log: Array::make(2 * n + 1, 0),
  }
}

///|
/// Add an undirected edge between nodes `u` and `v`.
fn EulerTourLCA::add_edge(self : EulerTourLCA, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// DFS that records the full Euler walk (node revisited after each child).
///
/// Parameters:
/// - `u` – current node
/// - `p` – parent node (`-1` at the root)
/// - `d` – depth of `u`
fn EulerTourLCA::dfs_euler(
  self : EulerTourLCA,
  u : Int,
  p : Int,
  d : Int,
) -> Unit {
  self.first[u] = self.euler.length()
  self.euler.push(u)
  self.depth.push(d)
  for v in self.adj[u] {
    if v != p {
      self.dfs_euler(v, u, d + 1)
      self.euler.push(u)
      self.depth.push(d)
    }
  }
}

///|
/// Build the full Euler tour and the sparse table for O(1) RMQ.
///
/// The sparse table stores indices into `euler`/`depth` rather than values,
/// with ties broken in favour of the left entry.
///
/// Time: O(n log n).  Space: O(n log n).
fn EulerTourLCA::build(self : EulerTourLCA, root : Int) -> Unit {
  self.euler.clear()
  self.depth.clear()
  self.dfs_euler(root, -1, 0)
  let m = self.euler.length()

  // Precompute log values
  for i in 2..<=m {
    self.log[i] = self.log[i / 2] + 1
  }

  // Build sparse table for minimum depth
  let k = self.log[m] + 1
  self.sparse = Array::makei(k, _ => Array::make(m, 0))

  // Initialize with indices
  for i in 0..<m {
    self.sparse[0][i] = i
  }

  // Fill sparse table
  for j in 1..<k {
    let len = 1 << j
    let limit = m - len + 1
    for i in 0..<limit {
      let left = self.sparse[j - 1][i]
      let right = self.sparse[j - 1][i + (1 << (j - 1))]
      if self.depth[left] <= self.depth[right] {
        self.sparse[j][i] = left
      } else {
        self.sparse[j][i] = right
      }
    }
  }
}

///|
/// Return the LCA (Lowest Common Ancestor) of nodes `u` and `v`.
///
/// Finds the node with minimum depth in the Euler tour between the first
/// occurrences of `u` and `v`, using the precomputed sparse table.
///
/// Time: O(1) after `build`.
fn EulerTourLCA::lca(self : EulerTourLCA, u : Int, v : Int) -> Int {
  let left = self.first[u]
  let right = self.first[v]
  let (l, r) = if left <= right { (left, right) } else { (right, left) }
  let r_exclusive = r + 1
  let len = r_exclusive - l
  let k = self.log[len]
  let left = self.sparse[k][l]
  let right = self.sparse[k][r_exclusive - (1 << k)]
  if self.depth[left] <= self.depth[right] {
    self.euler[left]
  } else {
    self.euler[right]
  }
}

///|
/// Return the number of edges on the path between nodes `u` and `v`.
///
/// Uses the LCA to compute `depth[u] + depth[v] - 2 * depth[lca(u, v)]`.
fn EulerTourLCA::distance(self : EulerTourLCA, u : Int, v : Int) -> Int {
  let ancestor = self.lca(u, v)
  self.depth[self.first[u]] +
  self.depth[self.first[v]] -
  2 * self.depth[self.first[ancestor]]
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "euler_tour basic" {
  let et = EulerTour::new(5)
  // Tree: 0 - 1 - 2
  //           |
  //           3 - 4
  et.add_edge(0, 1)
  et.add_edge(1, 2)
  et.add_edge(1, 3)
  et.add_edge(3, 4)
  et.build(0)

  // Check entry < exit
  for i in 0..<5 {
    inspect(et.entry[i] < et.exit[i], content="true")
  }
}

///|
test "euler_tour subtree" {
  let et = EulerTour::new(5)
  et.add_edge(0, 1)
  et.add_edge(0, 2)
  et.add_edge(1, 3)
  et.add_edge(1, 4)
  et.build(0)

  // Subtree of 1 should include 1, 3, 4
  let subtree = et.get_subtree(1)
  let (start, end) = et.subtree_range(1)
  inspect(subtree.length(), content="3")
  inspect(end - start, content="3")
  inspect(subtree.contains(1), content="true")
  inspect(subtree.contains(3), content="true")
  inspect(subtree.contains(4), content="true")
}

///|
test "euler_tour ancestor" {
  let et = EulerTour::new(4)
  // 0 -> 1 -> 2 -> 3
  et.add_edge(0, 1)
  et.add_edge(1, 2)
  et.add_edge(2, 3)
  et.build(0)
  inspect(et.is_ancestor(0, 3), content="true")
  inspect(et.is_ancestor(1, 3), content="true")
  inspect(et.is_ancestor(3, 1), content="false")
  inspect(et.is_ancestor(2, 2), content="true") // Node is ancestor of itself
}

///|
test "euler_tour_lca basic" {
  let et = EulerTourLCA::new(5)
  //       0
  //      / \
  //     1   2
  //    / \
  //   3   4
  et.add_edge(0, 1)
  et.add_edge(0, 2)
  et.add_edge(1, 3)
  et.add_edge(1, 4)
  et.build(0)
  inspect(et.lca(3, 4), content="1")
  inspect(et.lca(3, 2), content="0")
  inspect(et.lca(1, 4), content="1")
  inspect(et.lca(0, 3), content="0")
}

///|
test "euler_tour_lca distance" {
  let et = EulerTourLCA::new(5)
  et.add_edge(0, 1)
  et.add_edge(0, 2)
  et.add_edge(1, 3)
  et.add_edge(1, 4)
  et.build(0)
  inspect(et.distance(3, 4), content="2") // 3 -> 1 -> 4
  inspect(et.distance(3, 2), content="3") // 3 -> 1 -> 0 -> 2
  inspect(et.distance(0, 0), content="0")
}

///|
test "euler_tour single node" {
  let et = EulerTour::new(1)
  et.build(0)
  inspect(et.subtree_size(0), content="1")
  inspect(et.is_ancestor(0, 0), content="true")
}

///|
test "euler_tour_lca chain" {
  let et = EulerTourLCA::new(4)
  // 0 - 1 - 2 - 3
  et.add_edge(0, 1)
  et.add_edge(1, 2)
  et.add_edge(2, 3)
  et.build(0)
  inspect(et.lca(0, 3), content="0")
  inspect(et.lca(1, 3), content="1")
  inspect(et.lca(2, 3), content="2")
  inspect(et.distance(0, 3), content="3")
}

///|
test "euler_tour depth" {
  let et = EulerTour::new(4)
  et.add_edge(0, 1)
  et.add_edge(1, 2)
  et.add_edge(2, 3)
  et.build(0)
  inspect(et.depth[0], content="0")
  inspect(et.depth[1], content="1")
  inspect(et.depth[2], content="2")
  inspect(et.depth[3], content="3")
}
