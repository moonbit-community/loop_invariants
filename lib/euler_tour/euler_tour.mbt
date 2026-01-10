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
priv struct EulerTour {
  n : Int
  adj : Array[Array[Int]]
  entry : Array[Int] // Entry time of each node
  exit : Array[Int] // Exit time of each node
  tour : Array[Int] // Euler tour sequence
  depth : Array[Int] // Depth of each node
  parent : Array[Int]
  mut timer : Int
}

///|
fn EulerTour::new(n : Int) -> EulerTour {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  {
    n,
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
fn EulerTour::add_edge(self : EulerTour, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Build Euler tour starting from root
fn EulerTour::build(self : EulerTour, root : Int) -> Unit {
  self.timer = 0
  self.tour.clear()
  self.dfs(root, -1, 0)
}

///|
/// DFS to build tour
fn EulerTour::dfs(self : EulerTour, u : Int, p : Int, d : Int) -> Unit {
  self.parent[u] = p
  self.depth[u] = d
  self.entry[u] = self.timer
  self.timer = self.timer + 1
  self.tour.push(u)

  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]
    if v != p {
      self.dfs(v, u, d + 1)
    }
  }

  self.exit[u] = self.timer
}

///|
/// Get subtree range [entry, exit) for node v
fn EulerTour::subtree_range(self : EulerTour, v : Int) -> (Int, Int) {
  (self.entry[v], self.exit[v])
}

///|
/// Get subtree size
fn EulerTour::subtree_size(self : EulerTour, v : Int) -> Int {
  self.exit[v] - self.entry[v]
}

///|
/// Check if u is ancestor of v
fn EulerTour::is_ancestor(self : EulerTour, u : Int, v : Int) -> Bool {
  self.entry[u] <= self.entry[v] && self.exit[v] <= self.exit[u]
}

///|
/// Get nodes in subtree of v
fn EulerTour::get_subtree(self : EulerTour, v : Int) -> Array[Int] {
  let result : Array[Int] = []
  let start = self.entry[v]
  let end = self.exit[v]
  for i = start; i < end; i = i + 1 {
    result.push(self.tour[i])
  }
  result
}

// ============================================================================
// EULER TOUR WITH LCA SUPPORT
// ============================================================================

///|
priv struct EulerTourLCA {
  n : Int
  adj : Array[Array[Int]]
  first : Array[Int] // First occurrence in tour
  euler : Array[Int] // Euler tour (with revisits)
  depth : Array[Int] // Depth at each position in euler tour
  mut sparse : Array[Array[Int]] // Sparse table for RMQ
  log : Array[Int]
}

///|
fn EulerTourLCA::new(n : Int) -> EulerTourLCA {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  }
  {
    n,
    adj,
    first: Array::make(n, -1),
    euler: [],
    depth: [],
    sparse: [],
    log: Array::make(2 * n + 1, 0),
  }
}

///|
fn EulerTourLCA::add_edge(self : EulerTourLCA, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
fn EulerTourLCA::dfs_euler(self : EulerTourLCA, u : Int, p : Int, d : Int) -> Unit {
  self.first[u] = self.euler.length()
  self.euler.push(u)
  self.depth.push(d)

  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]
    if v != p {
      self.dfs_euler(v, u, d + 1)
      self.euler.push(u)
      self.depth.push(d)
    }
  }
}

///|
/// Build Euler tour and sparse table for LCA
fn EulerTourLCA::build(self : EulerTourLCA, root : Int) -> Unit {
  self.euler.clear()
  self.depth.clear()
  self.dfs_euler(root, -1, 0)

  let m = self.euler.length()

  // Precompute log values
  for i = 2; i <= m; i = i + 1 {
    self.log[i] = self.log[i / 2] + 1
  }

  // Build sparse table for minimum depth
  let k = self.log[m] + 1
  self.sparse = Array::make(k, [])
  for i = 0; i < k; i = i + 1 {
    self.sparse[i] = Array::make(m, 0)
  }

  // Initialize with indices
  for i = 0; i < m; i = i + 1 {
    self.sparse[0][i] = i
  }

  // Fill sparse table
  for j = 1; j < k; j = j + 1 {
    let len = 1 << j
    for i = 0; i + len <= m; i = i + 1 {
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
/// Query LCA of two nodes
fn EulerTourLCA::lca(self : EulerTourLCA, u : Int, v : Int) -> Int {
  let mut l = self.first[u]
  let mut r = self.first[v]
  if l > r {
    let tmp = l
    l = r
    r = tmp
  }
  r = r + 1

  let len = r - l
  let k = self.log[len]
  let left = self.sparse[k][l]
  let right = self.sparse[k][r - (1 << k)]

  if self.depth[left] <= self.depth[right] {
    self.euler[left]
  } else {
    self.euler[right]
  }
}

///|
/// Get distance between two nodes
fn EulerTourLCA::distance(self : EulerTourLCA, u : Int, v : Int) -> Int {
  let ancestor = self.lca(u, v)
  self.depth[self.first[u]] + self.depth[self.first[v]] -
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
  for i = 0; i < 5; i = i + 1 {
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
  inspect(subtree.length(), content="3")
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
