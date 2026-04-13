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
/// Internal representation of the tree used during centroid decomposition.
///
/// Fields:
/// - `n`: number of nodes (vertices are labelled 0..n-1)
/// - `adj`: adjacency list; `adj[u]` contains all neighbours of `u`
/// - `removed`: marks nodes that have already been chosen as a centroid and
///   must be skipped in subsequent size/centroid computations
/// - `subtree_size`: scratch array; reused each time `compute_size` is called
/// - `centroid_parent`: result array; `centroid_parent[v]` is the centroid
///   parent of `v` in the centroid tree, or `-1` for the root
/// - `centroid_depth`: result array; `centroid_depth[v]` is the depth of `v`
///   in the centroid tree (root has depth 0)
priv struct CentroidTree {
  n : Int
  adj : Array[Array[Int]]
  removed : Array[Bool]
  subtree_size : Array[Int]
  centroid_parent : Array[Int] // Parent in centroid tree
  centroid_depth : Array[Int] // Depth in centroid tree
}

///|
/// Allocate a fresh `CentroidTree` for `n` nodes with no edges.
fn CentroidTree::new(n : Int) -> CentroidTree {
  let adj = [| for _ in 0..<n => [] |]
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
/// Add an undirected edge between nodes `u` and `v`.
///
/// Both endpoints must satisfy `0 <= u, v < n`; the caller is responsible for
/// bounds checking before calling this function.
fn CentroidTree::add_edge(self : CentroidTree, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Compute subtree sizes rooted at `u`, treating `parent` as the incoming
/// node (so the edge to `parent` is not traversed) and skipping any node
/// that has already been removed as a centroid.
///
/// After the call, `self.subtree_size[u]` equals the number of live nodes
/// in the component reachable from `u` without going through `parent`.
///
/// Returns `self.subtree_size[u]`.
fn CentroidTree::compute_size(
  self : CentroidTree,
  u : Int,
  parent : Int,
) -> Int {
  self.subtree_size[u] = 1
  for v in self.adj[u] {
    if v != parent && !self.removed[v] {
      self.subtree_size[u] = self.subtree_size[u] + self.compute_size(v, u)
    }
  }
  self.subtree_size[u]
}

///|
/// Find the centroid of the component containing `u`, given that the total
/// live size of that component is `tree_size`.
///
/// A node is the centroid when none of its live children has a subtree
/// larger than `tree_size / 2` (integer division). The parent component,
/// whose size equals `tree_size - self.subtree_size[u]`, is implicitly
/// handled by the same bound.
///
/// Precondition: `compute_size` must have been called on this component
/// before `find_centroid` so that `self.subtree_size` is up to date.
fn CentroidTree::find_centroid(
  self : CentroidTree,
  u : Int,
  parent : Int,
  tree_size : Int,
) -> Int {
  // Check if any child subtree has more than half the nodes
  for v in self.adj[u] {
    if v != parent && !self.removed[v] && self.subtree_size[v] > tree_size / 2 {
      return self.find_centroid(v, u, tree_size)
    }
  }
  // No child exceeds half, so u is the centroid
  u
}

///|
/// Recursively decompose the component that contains node `u` and build the
/// centroid tree.
///
/// - `u`: any live node in the current component (used as the starting point
///   for size computation)
/// - `parent`: the centroid parent to assign to the centroid found in this
///   component; pass `-1` for the root call
/// - `depth`: the centroid-tree depth to assign to the centroid found here
///
/// Returns the centroid of the current component so callers can use it if
/// needed.
fn CentroidTree::decompose(
  self : CentroidTree,
  u : Int,
  parent : Int,
  depth : Int,
) -> Int {
  let tree_size = self.compute_size(u, -1)
  let centroid = self.find_centroid(u, -1, tree_size)
  self.removed[centroid] = true
  self.centroid_parent[centroid] = parent
  self.centroid_depth[centroid] = depth
  for v in self.adj[centroid] {
    if !self.removed[v] {
      let _ = self.decompose(v, centroid, depth + 1)
    }
  }
  centroid
}

///|
/// Run the full centroid decomposition starting from node 0 (any node works
/// for an undirected tree). After this call `centroid_parent` and
/// `centroid_depth` are fully populated.
///
/// Does nothing when `n == 0`.
fn CentroidTree::build(self : CentroidTree) -> Unit {
  if self.n > 0 {
    let _ = self.decompose(0, -1, 0)
  }
}

///|
/// Return the centroid parent of node `u` in the centroid tree, or `-1` if
/// `u` is the centroid root.
fn CentroidTree::get_parent(self : CentroidTree, u : Int) -> Int {
  self.centroid_parent[u]
}

///|
/// Return the depth of node `u` in the centroid tree (root has depth 0).
fn CentroidTree::get_depth(self : CentroidTree, u : Int) -> Int {
  self.centroid_depth[u]
}

///|
/// The result of a centroid decomposition.
///
/// `parent[v]` and `depth[v]` describe the position of each node in the
/// centroid tree. Use the `parent` and `depth` methods instead of accessing
/// the arrays directly so that out-of-range indices are handled safely.
pub struct CentroidDecomp {
  parent : Array[Int]
  depth : Array[Int]
}

///|
/// Build the centroid decomposition of an undirected tree with `n` nodes
/// (labelled `0..n-1`) and the given edge list.
///
/// Each element of `edges` is a pair `(u, v)` representing an undirected
/// edge. Edges whose endpoints are out of range are silently ignored.
///
/// Returns a `CentroidDecomp` whose `parent` and `depth` methods can be used
/// to query the centroid tree.
///
/// Time complexity: O(n log n).
/// Space complexity: O(n).
pub fn build_centroid(n : Int, edges : ArrayView[(Int, Int)]) -> CentroidDecomp {
  let tree = CentroidTree::new(n)
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      tree.add_edge(u, v)
    }
  }
  tree.build()
  { parent: tree.centroid_parent, depth: tree.centroid_depth }
}

///|
/// Return the centroid parent of node `v`, or `-1` if `v` is the centroid
/// root or if `v` is out of range.
///
/// ```moonbit nocheck
/// let cd = @centroid.build_centroid(3, [(0,1),(1,2)][:])
/// assert_eq!(cd.parent(1), -1)  // node 1 is the centroid root of a 3-path
/// assert_eq!(cd.parent(0), 1)
/// assert_eq!(cd.parent(-1), -1) // out of range -> -1
/// ```
pub fn CentroidDecomp::parent(self : CentroidDecomp, v : Int) -> Int {
  if v < 0 || v >= self.parent.length() {
    -1
  } else {
    self.parent[v]
  }
}

///|
/// Return the centroid tree depth of node `v`, or `-1` if `v` is out of
/// range. The centroid root has depth 0.
///
/// ```moonbit nocheck
/// let cd = @centroid.build_centroid(3, [(0,1),(1,2)][:])
/// assert_eq!(cd.depth(1), 0)   // centroid root
/// assert_eq!(cd.depth(0), 1)
/// assert_eq!(cd.depth(10), -1) // out of range -> -1
/// ```
pub fn CentroidDecomp::depth(self : CentroidDecomp, v : Int) -> Int {
  if v < 0 || v >= self.depth.length() {
    -1
  } else {
    self.depth[v]
  }
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

  // Check all depths are reasonable (<= log2(7) ~= 3)
  let max_depth = [|
      for i in 0..<7 => ct.get_depth(i)
    |]
    .iter()
    .maximum()
    .unwrap_or(0)
  inspect(max_depth <= 3, content="true")
}
