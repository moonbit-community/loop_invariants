// ============================================================================
// CENTROID DECOMPOSITION - Tree Divide and Conquer
// ============================================================================
//
// Centroid Decomposition recursively partitions a tree by removing centroids.
// A centroid is a node whose removal splits the tree into subtrees of size ≤ n/2.
//
// KEY INSIGHT: Every tree has at least one centroid, and removing it creates
// subtrees each of size ≤ n/2. This gives O(log n) decomposition depth.
//
// ALGORITHM:
// 1. Find centroid of current tree (node where max subtree size ≤ n/2)
// 2. Process centroid (solve subproblem rooted here)
// 3. Remove centroid and recursively decompose each subtree
//
// APPLICATIONS:
// - Distance queries on trees
// - Path counting problems
// - Tree center finding
//
// INVARIANTS:
// 1. Centroid splits tree into subtrees of size ≤ n/2
// 2. Decomposition depth is O(log n)
// 3. Each node appears in exactly one centroid's subproblem at each level
//
// TIME COMPLEXITY: O(n log n) for full decomposition
// SPACE COMPLEXITY: O(n)

///|
priv struct CentroidTree {
  n : Int
  adj : Array[Array[Int]]
  removed : Array[Bool]
  subtree_size : Array[Int]
  centroid_parent : Array[Int] // Parent in centroid tree
  centroid_depth : Array[Int] // Depth in centroid tree
}

///|
fn CentroidTree::new(n : Int) -> CentroidTree {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: "I: adj uninitialized. M: Create fresh array at each position. T: All vertices have independent adjacency lists.",
  }
  {
    n,
    adj,
    removed: Array::make(n, false),
    subtree_size: Array::make(n, 0),
    centroid_parent: Array::make(n, -1),
    centroid_depth: Array::make(n, 0),
  }
}

///|
fn CentroidTree::add_edge(self : CentroidTree, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Compute subtree sizes rooted at u, ignoring removed nodes
fn CentroidTree::compute_size(self : CentroidTree, u : Int, parent : Int) -> Int {
  self.subtree_size[u] = 1
  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]
    if v != parent && not(self.removed[v]) {
      self.subtree_size[u] = self.subtree_size[u] + self.compute_size(v, u)
    }
  }
  where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: "Accumulate subtree sizes by scanning all neighbors of u.",
  }
  self.subtree_size[u]
}

///|
/// Find centroid of subtree containing u
fn CentroidTree::find_centroid(self : CentroidTree, u : Int, parent : Int, tree_size : Int) -> Int {
  for i = 0; i < self.adj[u].length(); i = i + 1 {
    let v = self.adj[u][i]
    if v != parent && not(self.removed[v]) && self.subtree_size[v] > tree_size / 2 {
      return self.find_centroid(v, u, tree_size)
    }
  }
  where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: "Search neighbors to find a child subtree larger than half.",
  }
  u
}

///|
/// Decompose tree and build centroid tree
fn CentroidTree::decompose(self : CentroidTree, u : Int, parent : Int, depth : Int) -> Int {
  let tree_size = self.compute_size(u, -1)
  let centroid = self.find_centroid(u, -1, tree_size)

  self.removed[centroid] = true
  self.centroid_parent[centroid] = parent
  self.centroid_depth[centroid] = depth

  for i = 0; i < self.adj[centroid].length(); i = i + 1 {
    let v = self.adj[centroid][i]
    if not(self.removed[v]) {
      let _ = self.decompose(v, centroid, depth + 1)

    }
  } where {
    invariant: i >= 0 && i <= self.adj[centroid].length(),
    reasoning: "I: centroid found and marked removed. M: For each non-removed neighbor, recursively decompose its subtree. Since centroid is removed, neighbor's subtree has size ≤ tree_size/2. T: All subtrees decomposed, depth increases by 1 each level, giving O(log n) total depth.",
  }

  centroid
}

///|
fn CentroidTree::build(self : CentroidTree) -> Unit {
  if self.n > 0 {
    let _ = self.decompose(0, -1, 0)

  }
}

///|
/// Get centroid parent
fn CentroidTree::get_parent(self : CentroidTree, u : Int) -> Int {
  self.centroid_parent[u]
}

///|
/// Get depth in centroid tree
fn CentroidTree::get_depth(self : CentroidTree, u : Int) -> Int {
  self.centroid_depth[u]
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "centroid basic" {
  // Linear tree: 0 - 1 - 2 - 3 - 4
  let ct = CentroidTree::new(5)
  ct.add_edge(0, 1)
  ct.add_edge(1, 2)
  ct.add_edge(2, 3)
  ct.add_edge(3, 4)
  ct.build()

  // Centroid of linear tree of 5 nodes is node 2
  inspect(ct.get_depth(2), content="0") // Root of centroid tree
}

///|
test "centroid star" {
  // Star: 0 connected to 1,2,3,4
  let ct = CentroidTree::new(5)
  ct.add_edge(0, 1)
  ct.add_edge(0, 2)
  ct.add_edge(0, 3)
  ct.add_edge(0, 4)
  ct.build()

  // Center node 0 is the centroid
  inspect(ct.get_depth(0), content="0")
  inspect(ct.get_parent(0), content="-1")
}

///|
test "centroid single" {
  let ct = CentroidTree::new(1)
  ct.build()
  inspect(ct.get_depth(0), content="0")
  inspect(ct.get_parent(0), content="-1")
}

///|
test "centroid depth bound" {
  // Binary tree structure - depth should be O(log n)
  let ct = CentroidTree::new(7)
  ct.add_edge(0, 1)
  ct.add_edge(0, 2)
  ct.add_edge(1, 3)
  ct.add_edge(1, 4)
  ct.add_edge(2, 5)
  ct.add_edge(2, 6)
  ct.build()

  // Check all depths are reasonable (≤ log2(7) ≈ 3)
  let mut max_depth = 0
  for i = 0; i < 7; i = i + 1 {
    if ct.get_depth(i) > max_depth {
      max_depth = ct.get_depth(i)
    }
  }
  where {
    invariant: i >= 0 && i <= 7,
    reasoning: "Scan all nodes to track maximum centroid depth.",
  }
  inspect(max_depth <= 3, content="true")
}
