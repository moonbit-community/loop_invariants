// ============================================================================
// CENTROID DECOMPOSITION - Divide and Conquer on Trees
// ============================================================================
//
// Centroid Decomposition is a technique that recursively decomposes a tree
// by finding and removing centroids, creating a "centroid tree" of O(log n) depth.
//
// KEY CONCEPTS:
//
// 1. CENTROID: A node whose removal splits the tree such that no remaining
//    component has more than n/2 nodes. Every tree has at least one centroid.
//
// 2. CENTROID TREE: A tree built by:
//    - Find centroid c of current tree
//    - Make c the root of this subtree in centroid tree
//    - Recursively process each component after removing c
//
// 3. DEPTH PROPERTY: The centroid tree has O(log n) depth because each
//    component has at most n/2 nodes after removing the centroid.
//
// APPLICATIONS:
// - Count paths of length k in O(n log n)
// - Find closest marked node in O(log n) per query
// - Tree distance queries
// - Path counting with specific properties
//
// COMPLEXITY:
// - Build centroid tree: O(n log n)
// - Each node appears on O(log n) centroid paths
// - Query time depends on application, typically O(log n) or O(log^2 n)

///|
/// Adjacency list representation of tree
struct TreeGraph {
  adj : Array[Array[Int]] // adj[u] = list of neighbors
  n : Int
}

///|
fn TreeGraph::new(n : Int) -> TreeGraph {
  let adj : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    let _ = i // suppress unused warning
    adj.push([])
  }
  { adj, n }
}

///|
fn TreeGraph::add_edge(self : TreeGraph, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Centroid Decomposition data structure
struct CentroidDecomp {
  tree : TreeGraph
  // Centroid tree structure
  centroid_parent : Array[Int] // Parent in centroid tree (-1 for root)
  centroid_depth : Array[Int] // Depth in centroid tree
  removed : Array[Bool] // Whether node has been removed (used during build)
  subtree_size : Array[Int] // Subtree sizes (used during build)
  // Root of centroid tree
  mut centroid_root : Int
}

///|
/// Build centroid decomposition of a tree
fn CentroidDecomp::build(tree : TreeGraph) -> CentroidDecomp {
  let n = tree.n
  let centroid_parent : Array[Int] = Array::make(n, -1)
  let centroid_depth : Array[Int] = Array::make(n, 0)
  let removed : Array[Bool] = Array::make(n, false)
  let subtree_size : Array[Int] = Array::make(n, 0)
  let cd = CentroidDecomp::{
    tree,
    centroid_parent,
    centroid_depth,
    removed,
    subtree_size,
    centroid_root: -1,
  }
  if n > 0 {
    cd.centroid_root = cd.decompose(0, -1, 0)
  }
  cd
}

///|
/// Compute subtree sizes rooted at node, ignoring removed nodes
fn CentroidDecomp::compute_sizes(
  self : CentroidDecomp,
  node : Int,
  parent : Int,
) -> Int {
  self.subtree_size[node] = 1
  for i = 0; i < self.tree.adj[node].length(); i = i + 1 {
    let child = self.tree.adj[node][i]
    if child != parent && not(self.removed[child]) {
      self.subtree_size[node] = self.subtree_size[node] +
        self.compute_sizes(child, node)
    }
  }
  self.subtree_size[node]
}

///|
/// Find centroid of subtree containing start_node
/// A centroid is a node where all subtrees have size <= n/2
fn CentroidDecomp::find_centroid(
  self : CentroidDecomp,
  start_node : Int,
  tree_size : Int,
) -> Int {
  let half = tree_size / 2

  // DFS to find centroid
  for node = start_node, parent = -1 {
    // Check if current node is centroid
    let mut max_subtree = tree_size - self.subtree_size[node]
    let mut next_node = -1
    for i = 0; i < self.tree.adj[node].length(); i = i + 1 {
      let child = self.tree.adj[node][i]
      if child != parent && not(self.removed[child]) {
        if self.subtree_size[child] > max_subtree {
          max_subtree = self.subtree_size[child]
          next_node = child
        }
      }
    }
    if max_subtree <= half {
      // Current node is centroid
      break node
    } else {
      // Move toward larger subtree
      continue next_node, node
    }
  } where {
    invariant: node >= 0 && not(self.removed[node]),
    reasoning: (
      #|CENTROID FINDING INVARIANT:
      #|
      #|1. At each step, node is in the subtree containing the centroid
      #|   - We move toward the subtree with size > n/2
      #|   - The centroid must be in that direction
      #|
      #|2. Termination: max_subtree decreases as we move toward centroid
      #|   - Eventually max_subtree <= n/2, making current node the centroid
      #|
      #|3. Correctness: When max_subtree <= n/2:
      #|   - All children's subtrees have size <= n/2 (by max_subtree)
      #|   - Parent's side has size = tree_size - subtree_size[node] <= n/2
      #|   - This satisfies centroid definition
    ),
  }
}

///|
/// Decompose subtree containing node, returning centroid of this subtree
fn CentroidDecomp::decompose(
  self : CentroidDecomp,
  node : Int,
  parent_centroid : Int,
  depth : Int,
) -> Int {
  // Compute subtree sizes
  let tree_size = self.compute_sizes(node, -1)

  // Find centroid
  let centroid = self.find_centroid(node, tree_size)

  // Set centroid properties
  self.centroid_parent[centroid] = parent_centroid
  self.centroid_depth[centroid] = depth
  self.removed[centroid] = true

  // Recursively decompose each subtree
  for i = 0; i < self.tree.adj[centroid].length(); i = i + 1 {
    let child = self.tree.adj[centroid][i]
    if not(self.removed[child]) {
      let _ = self.decompose(child, centroid, depth + 1)

    }
  }
  centroid
}

// ============================================================================
// PATH COUNTING - Count paths of exactly length k
// ============================================================================

///|
/// Count all pairs of nodes at distance exactly k
/// Uses centroid decomposition for O(n log n) time
fn CentroidDecomp::count_paths_of_length(
  self : CentroidDecomp,
  k : Int,
) -> Int64 {
  // Reset removed array for fresh traversal
  for i = 0; i < self.tree.n; i = i + 1 {
    self.removed[i] = false
  }
  self.count_paths_rec(self.centroid_root, k)
}

///|
/// Recursive path counting through centroid
fn CentroidDecomp::count_paths_rec(
  self : CentroidDecomp,
  centroid : Int,
  k : Int,
) -> Int64 {
  if centroid < 0 {
    return 0L
  }

  // Mark centroid as processed
  self.removed[centroid] = true

  // Count paths passing through centroid
  let mut total : Int64 = 0L

  // Collect distances from centroid to all nodes in subtree
  let all_distances : Array[Int] = []
  for i = 0; i < self.tree.adj[centroid].length(); i = i + 1 {
    let child = self.tree.adj[centroid][i]
    if not(self.removed[child]) {
      // Get distances from this child's subtree
      let child_distances = self.collect_distances(child, centroid, 1)

      // Count paths that combine with previously seen distances
      for j = 0; j < child_distances.length(); j = j + 1 {
        let d = child_distances[j]
        if d <= k {
          // Count how many nodes we've seen at distance k - d
          let need = k - d
          for m = 0; m < all_distances.length(); m = m + 1 {
            if all_distances[m] == need {
              total = total + 1L
            }
          }
          // Also count paths that end at centroid (d == k)
          if d == k {
            total = total + 1L
          }
        }
      }

      // Add child distances to all_distances
      for j = 0; j < child_distances.length(); j = j + 1 {
        all_distances.push(child_distances[j])
      }
    }
  }

  // Recursively count in child centroids
  for i = 0; i < self.tree.adj[centroid].length(); i = i + 1 {
    let child = self.tree.adj[centroid][i]
    if not(self.removed[child]) {
      // Find the centroid of child's subtree
      let _ = self.compute_sizes(child, -1)
      let child_centroid = self.find_centroid(child, self.subtree_size[child])
      total = total + self.count_paths_rec(child_centroid, k)
    }
  }
  total
}

///|
/// Collect distances from all nodes in subtree to the centroid
fn CentroidDecomp::collect_distances(
  self : CentroidDecomp,
  node : Int,
  parent : Int,
  dist : Int,
) -> Array[Int] {
  let result : Array[Int] = [dist]
  for i = 0; i < self.tree.adj[node].length(); i = i + 1 {
    let child = self.tree.adj[node][i]
    if child != parent && not(self.removed[child]) {
      let child_dists = self.collect_distances(child, node, dist + 1)
      for j = 0; j < child_dists.length(); j = j + 1 {
        result.push(child_dists[j])
      }
    }
  }
  result
}

// ============================================================================
// CLOSEST MARKED NODE QUERIES
// ============================================================================

///|
/// Structure for closest marked node queries
struct ClosestMarked {
  cd : CentroidDecomp
  dist_to_centroid : Array[Array[Int]] // dist_to_centroid[v][i] = dist from v to its i-th centroid ancestor
  marked : Array[Bool] // Which nodes are marked
  closest : Array[Int] // closest[c] = min distance from centroid c to any marked node in its decomposition subtree
}

///|
fn ClosestMarked::new(tree : TreeGraph) -> ClosestMarked {
  let cd = CentroidDecomp::build(tree)
  let n = tree.n

  // Compute distances from each node to all its centroid ancestors
  let dist_to_centroid : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    let _ = i
    dist_to_centroid.push([])
  }

  // For each node, walk up centroid tree and compute distances
  for v = 0; v < n; v = v + 1 {
    for c = v, d = 0; c >= 0; {
      dist_to_centroid[v].push(d)
      let parent = cd.centroid_parent[c]
      if parent >= 0 {
        // Compute distance from v to parent centroid
        let new_d = compute_tree_dist(tree, v, parent)
        continue parent, new_d
      } else {
        break
      }
    }
  }
  let marked : Array[Bool] = Array::make(n, false)
  let closest : Array[Int] = Array::make(n, 1000000000) // infinity
  { cd, dist_to_centroid, marked, closest }
}

///|
/// Compute distance between two nodes in tree (BFS)
fn compute_tree_dist(tree : TreeGraph, u : Int, v : Int) -> Int {
  if u == v {
    return 0
  }
  let visited : Array[Bool] = Array::make(tree.n, false)
  let queue : Array[(Int, Int)] = [(u, 0)]
  visited[u] = true
  for front = 0; front < queue.length(); {
    let (node, dist) = queue[front]
    if node == v {
      break dist
    }
    for i = 0; i < tree.adj[node].length(); i = i + 1 {
      let next = tree.adj[node][i]
      if not(visited[next]) {
        visited[next] = true
        queue.push((next, dist + 1))
      }
    }
    continue front + 1
  } else { // Should not happen in connected tree
    -1
  } where {
    invariant: front >= 0,
    reasoning: (
      #|BFS DISTANCE INVARIANT:
      #|
      #|1. Queue contains nodes in order of increasing distance from u
      #|2. Each node is visited exactly once
      #|3. When we reach v, dist is the shortest path length
    ),
  }
}

///|
/// Mark node v
fn ClosestMarked::mark(self : ClosestMarked, v : Int) -> Unit {
  if self.marked[v] {
    return
  }
  self.marked[v] = true

  // Update closest[] for all centroid ancestors
  for i = 0, c = v; c >= 0; {
    let dist = self.dist_to_centroid[v][i]
    if dist < self.closest[c] {
      self.closest[c] = dist
    }
    continue i + 1, self.cd.centroid_parent[c]
  } where {
    invariant: i >= 0,
    reasoning: (
      #|MARK UPDATE INVARIANT:
      #|
      #|1. Walk up centroid tree from v
      #|2. For each centroid ancestor c, update closest[c] if v is closer
      #|3. This maintains: closest[c] = min distance from c to any marked node
      #|   in c's centroid decomposition subtree
    ),
  }
}

///|
/// Query minimum distance from v to any marked node
fn ClosestMarked::query(self : ClosestMarked, v : Int) -> Int {
  let mut min_dist = 1000000000

  // Check all centroid ancestors of v
  for i = 0, c = v; c >= 0; {
    let dist_to_c = self.dist_to_centroid[v][i]
    let closest_from_c = self.closest[c]
    let total = dist_to_c + closest_from_c
    if total < min_dist {
      min_dist = total
    }
    continue i + 1, self.cd.centroid_parent[c]
  } else {
    min_dist
  } where {
    invariant: i >= 0,
    reasoning: (
      #|QUERY INVARIANT:
      #|
      #|1. For each centroid ancestor c of v:
      #|   - dist_to_c = distance from v to c
      #|   - closest[c] = min distance from c to any marked node in c's subtree
      #|   - total = shortest path from v through c to closest marked node
      #|
      #|2. The actual closest marked node's path must pass through some
      #|   common centroid ancestor of v and the marked node
      #|
      #|3. By checking all centroid ancestors, we find the minimum
      #|
      #|CORRECTNESS: O(log n) ancestors due to centroid tree depth
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "centroid decomposition build" {
  // Build a simple tree: 0 - 1 - 2 - 3 - 4
  let tree = TreeGraph::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)
  let cd = CentroidDecomp::build(tree)

  // Centroid of path should be middle node (2)
  inspect(cd.centroid_root, content="2")

  // Centroid tree depth should be O(log n)
  for i = 0; i < 5; i = i + 1 {
    guard cd.centroid_depth[i] <= 3 else { fail("Depth too large") }
  }
}

///|
test "centroid decomposition star tree" {
  // Star tree: 0 connected to 1, 2, 3, 4
  let tree = TreeGraph::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(0, 2)
  tree.add_edge(0, 3)
  tree.add_edge(0, 4)
  let cd = CentroidDecomp::build(tree)

  // Centroid should be the center (0)
  inspect(cd.centroid_root, content="0")
}

///|
test "centroid path counting" {
  // Path: 0 - 1 - 2 - 3 - 4
  let tree = TreeGraph::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)
  let cd = CentroidDecomp::build(tree)

  // Pairs at distance 1: (0,1), (1,2), (2,3), (3,4) = 4
  inspect(cd.count_paths_of_length(1), content="4")

  // Pairs at distance 2: (0,2), (1,3), (2,4) = 3
  inspect(cd.count_paths_of_length(2), content="3")
}

///|
test "closest marked queries" {
  // Tree: 0 - 1 - 2 - 3 - 4
  let tree = TreeGraph::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)
  let cm = ClosestMarked::new(tree)

  // No marked nodes yet
  inspect(cm.query(0), content="1000000000") // infinity

  // Mark node 2
  cm.mark(2)

  // Distance from each node to closest marked (node 2)
  inspect(cm.query(0), content="2") // 0 -> 1 -> 2
  inspect(cm.query(1), content="1") // 1 -> 2
  inspect(cm.query(2), content="0") // 2 itself
  inspect(cm.query(3), content="1") // 3 -> 2
  inspect(cm.query(4), content="2") // 4 -> 3 -> 2

  // Mark node 4
  cm.mark(4)

  // Now node 4 is closer to nodes 3, 4
  inspect(cm.query(3), content="1") // 3 -> 4 (distance 1) vs 3 -> 2 (distance 1)
  inspect(cm.query(4), content="0") // 4 itself
}

///|
test "closest marked star" {
  // Star: 0 connected to 1, 2, 3, 4
  let tree = TreeGraph::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(0, 2)
  tree.add_edge(0, 3)
  tree.add_edge(0, 4)
  let cm = ClosestMarked::new(tree)
  cm.mark(1)
  inspect(cm.query(0), content="1") // 0 -> 1
  inspect(cm.query(2), content="2") // 2 -> 0 -> 1
  cm.mark(3)
  inspect(cm.query(2), content="2") // 2 -> 0 -> 1 or 2 -> 0 -> 3
  inspect(cm.query(0), content="1") // 0 -> 1 or 0 -> 3
}

// ============================================================================
// CENTROID TREE TRAVERSAL
// ============================================================================

///|
/// Get all nodes in the subtree of centroid c in the centroid tree
fn CentroidDecomp::get_centroid_subtree(
  self : CentroidDecomp,
  c : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  fn dfs(cd : CentroidDecomp, node : Int, result : Array[Int]) -> Unit {
    result.push(node)
    // Find children in centroid tree
    for i = 0; i < cd.tree.n; i = i + 1 {
      if cd.centroid_parent[i] == node {
        dfs(cd, i, result)
      }
    }
  }

  dfs(self, c, result)
  result
}

///|
test "centroid subtree" {
  // Path: 0 - 1 - 2 - 3 - 4
  let tree = TreeGraph::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)
  let cd = CentroidDecomp::build(tree)

  // All nodes should be in root's subtree
  let subtree = cd.get_centroid_subtree(cd.centroid_root)
  inspect(subtree.length(), content="5")
}
