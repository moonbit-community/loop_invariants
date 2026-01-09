// ============================================================================
// CENTROID DECOMPOSITION - Divide and Conquer on Trees
// ============================================================================
//
// Centroid Decomposition is a technique for decomposing a tree into a hierarchy
// of centroids, enabling efficient path queries and tree divide-and-conquer.
//
// KEY INSIGHT: A centroid of a tree is a node whose removal splits the tree
// into subtrees, each with at most n/2 nodes. Every tree has a centroid.
// By recursively finding centroids, we build a "centroid tree" of depth O(log n).
//
// STRUCTURE:
// - Original tree: arbitrary structure with n nodes
// - Centroid tree: root is centroid of whole tree
//   - Children are centroids of remaining subtrees after removal
//   - Depth is O(log n) because each subtree is at most half the size
//
// EXAMPLE:
// Original tree:
//       1
//      /|\
//     2 3 4
//    /|   |
//   5 6   7
//
// If centroid is 1, we remove it and recurse on subtrees {2,5,6}, {3}, {4,7}
// The centroid tree might look like:
//       1
//      /|\
//     2 3 4
//    /|   |
//   5 6   7
//
// INVARIANTS:
// 1. Centroid of subtree S has at most |S|/2 nodes in any child subtree
// 2. Centroid tree has depth O(log n)
// 3. Any path in original tree passes through O(log n) centroid ancestors
//
// TIME COMPLEXITY:
// - Build centroid decomposition: O(n log n)
// - Query path through centroid tree: O(log n) centroids visited
//
// APPLICATIONS:
// - Count paths with property P (sum, length, etc.)
// - Answer distance queries efficiently
// - Tree pattern matching

///|
/// Tree represented as adjacency list
priv struct Tree {
  adj : Array[Array[Int]] // adj[v] = list of neighbors
  n : Int
}

///|
fn Tree::new(n : Int) -> Tree {
  let adj : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    adj.push([])
  }
  { adj, n }
}

///|
fn Tree::add_edge(self : Tree, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// Centroid Decomposition structure
priv struct CentroidDecomp {
  tree : Tree // Original tree
  centroid_parent : Array[Int] // Parent in centroid tree (-1 for root)
  centroid_depth : Array[Int] // Depth in centroid tree
  removed : Array[Bool] // Whether node is "removed" in current recursion
  subtree_size : Array[Int] // Subtree sizes (recomputed during decomposition)
}

///|
fn CentroidDecomp::new(tree : Tree) -> CentroidDecomp {
  let n = tree.n
  {
    tree,
    centroid_parent: Array::make(n, -1),
    centroid_depth: Array::make(n, 0),
    removed: Array::make(n, false),
    subtree_size: Array::make(n, 0),
  }
}

///|
/// Compute subtree sizes rooted at node
/// REASONING: DFS to count nodes, excluding "removed" nodes
fn CentroidDecomp::compute_sizes(self : CentroidDecomp, node : Int, parent : Int) -> Int {
  self.subtree_size[node] = 1

  // INVARIANT: Sum sizes of children not yet removed
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
/// Find centroid of subtree rooted at node with given total size
/// REASONING: Centroid is node where all subtrees have <= total/2 nodes
fn CentroidDecomp::find_centroid(
  self : CentroidDecomp,
  node : Int,
  parent : Int,
  total : Int
) -> Int {
  // INVARIANT: We're looking for node where max child subtree <= total/2
  for i = 0; i < self.tree.adj[node].length(); i = i + 1 {
    let child = self.tree.adj[node][i]
    if child != parent && not(self.removed[child]) {
      // Check if child subtree is too large
      if self.subtree_size[child] > total / 2 {
        // Centroid must be in this child's subtree
        return self.find_centroid(child, node, total)
      }
    }
  }

  // No child subtree is too large, this node is the centroid
  // Also need to check "parent" direction: total - subtree_size[node] <= total/2
  // This is equivalent to subtree_size[node] >= total/2, which is true since
  // we reached here without finding a larger child
  node
}

///|
/// Build centroid decomposition recursively
/// REASONING: Find centroid, mark as removed, recurse on subtrees
fn CentroidDecomp::decompose(
  self : CentroidDecomp,
  node : Int,
  cent_parent : Int,
  depth : Int
) -> Int {
  // Compute sizes for this subtree
  let total = self.compute_sizes(node, -1)

  // Find centroid
  let centroid = self.find_centroid(node, -1, total)

  // Record centroid tree structure
  self.centroid_parent[centroid] = cent_parent
  self.centroid_depth[centroid] = depth

  // Mark centroid as removed for recursive calls
  self.removed[centroid] = true

  // Recurse on each remaining subtree
  // INVARIANT: Each child subtree has at most total/2 nodes
  for i = 0; i < self.tree.adj[centroid].length(); i = i + 1 {
    let child = self.tree.adj[centroid][i]
    if not(self.removed[child]) {
      let _ = self.decompose(child, centroid, depth + 1)

    }
  }

  centroid
}

///|
/// Build the decomposition starting from node 0
fn CentroidDecomp::build(self : CentroidDecomp) -> Int {
  if self.tree.n == 0 {
    return -1
  }
  self.decompose(0, -1, 0)
}

///|
/// Get the centroid tree root
fn CentroidDecomp::root(self : CentroidDecomp) -> Int {
  // Root is the node with centroid_parent = -1
  for i = 0; i < self.tree.n; i = i + 1 {
    if self.centroid_parent[i] == -1 {
      return i
    }
  }
  -1
}

///|
/// Get path from node to centroid root in centroid tree
fn CentroidDecomp::path_to_root(self : CentroidDecomp, node : Int) -> Array[Int] {
  let path : Array[Int] = []

  // INVARIANT: curr moves up centroid tree until root
  for curr = node; curr >= 0; {
    path.push(curr)
    continue self.centroid_parent[curr]
  }

  path
}

///|
/// Get depth in centroid tree
fn CentroidDecomp::get_depth(self : CentroidDecomp, node : Int) -> Int {
  self.centroid_depth[node]
}

///|
/// Get parent in centroid tree
fn CentroidDecomp::get_parent(self : CentroidDecomp, node : Int) -> Int {
  self.centroid_parent[node]
}

// ============================================================================
// DISTANCE QUERIES using Centroid Decomposition
// ============================================================================
//
// We can answer distance queries by precomputing distances from each node
// to all its centroid ancestors. Then dist(u, v) can be found by checking
// their lowest common centroid ancestor.

///|
/// Distance oracle using centroid decomposition
priv struct DistanceOracle {
  decomp : CentroidDecomp
  dist_to_ancestor : Array[Array[Int]] // dist_to_ancestor[v][d] = dist from v to its depth-d centroid ancestor
}

///|
fn DistanceOracle::new(tree : Tree) -> DistanceOracle {
  let n = tree.n
  let decomp = CentroidDecomp::new(tree)
  let _ = decomp.build()

  // Reset removed flags for distance computation
  for i = 0; i < n; i = i + 1 {
    decomp.removed[i] = false
  }

  // Compute distances from each node to its centroid ancestors
  let max_depth = for i = 0, max_d = 0; i < n; i = i + 1 {
    if decomp.centroid_depth[i] > max_d {
      continue i + 1, decomp.centroid_depth[i]
    } else {
      continue i + 1, max_d
    }
  } else {
    max_d
  }

  let dist_to_ancestor : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    dist_to_ancestor.push(Array::make(max_depth + 1, -1))
  }

  // For each centroid, compute distances to all nodes in its subtree
  compute_all_distances(decomp, dist_to_ancestor)

  { decomp, dist_to_ancestor }
}

///|
/// Compute distances from each centroid to nodes in its subtree
fn compute_all_distances(
  decomp : CentroidDecomp,
  dist_to_ancestor : Array[Array[Int]]
) -> Unit {
  let n = decomp.tree.n

  // Process each node as a potential centroid
  for cent = 0; cent < n; cent = cent + 1 {
    let depth = decomp.centroid_depth[cent]

    // BFS from centroid to compute distances
    let visited = Array::make(n, false)
    let queue : Array[(Int, Int)] = [] // (node, distance)
    queue.push((cent, 0))
    visited[cent] = true

    // INVARIANT: BFS explores nodes by distance from centroid
    for head = 0; head < queue.length(); {
      let (node, dist) = queue[head]

      // Record distance from node to this centroid ancestor
      dist_to_ancestor[node][depth] = dist

      // Explore neighbors
      for i = 0; i < decomp.tree.adj[node].length(); i = i + 1 {
        let neighbor = decomp.tree.adj[node][i]
        if not(visited[neighbor]) {
          // Only visit if this centroid is an ancestor in centroid tree
          let path = decomp.path_to_root(neighbor)
          let is_in_subtree = for j = 0; j < path.length(); j = j + 1 {
            if path[j] == cent {
              break true
            }
          } else {
            false
          }

          if is_in_subtree {
            visited[neighbor] = true
            queue.push((neighbor, dist + 1))
          }
        }
      }

      continue head + 1
    }
  }
}

///|
/// Query distance between two nodes
/// REASONING: Find lowest common centroid ancestor and use triangle inequality
fn DistanceOracle::query(self : DistanceOracle, u : Int, v : Int) -> Int {
  if u == v {
    return 0
  }

  let path_u = self.decomp.path_to_root(u)
  let path_v = self.decomp.path_to_root(v)

  // Find lowest common centroid ancestor
  // INVARIANT: Check all pairs of ancestors
  let mut min_dist = 2147483647

  for i = 0; i < path_u.length(); i = i + 1 {
    let cent_u = path_u[i]
    for j = 0; j < path_v.length(); j = j + 1 {
      let cent_v = path_v[j]
      if cent_u == cent_v {
        // Common ancestor found
        let depth = self.decomp.centroid_depth[cent_u]
        let dist_u = self.dist_to_ancestor[u][depth]
        let dist_v = self.dist_to_ancestor[v][depth]
        if dist_u >= 0 && dist_v >= 0 {
          let total = dist_u + dist_v
          if total < min_dist {
            min_dist = total
          }
        }
      }
    }
  }

  min_dist
}

///|
fn DistanceOracle::max_centroid_depth(self : DistanceOracle) -> Int {
  for i = 0, max_d = 0; i < self.decomp.tree.n; i = i + 1 {
    if self.decomp.centroid_depth[i] > max_d {
      continue i + 1, self.decomp.centroid_depth[i]
    } else {
      continue i + 1, max_d
    }
  } else {
    max_d
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "centroid basic" {
  let tree = Tree::new(7)
  // Build tree:
  //       0
  //      /|\
  //     1 2 3
  //    /|   |
  //   4 5   6
  tree.add_edge(0, 1)
  tree.add_edge(0, 2)
  tree.add_edge(0, 3)
  tree.add_edge(1, 4)
  tree.add_edge(1, 5)
  tree.add_edge(3, 6)

  let decomp = CentroidDecomp::new(tree)
  let root = decomp.build()

  // Root should be a valid node
  inspect(root >= 0 && root < 7, content="true")

  // All nodes should be in centroid tree
  for i = 0; i < 7; i = i + 1 {
    inspect(decomp.centroid_depth[i] >= 0, content="true")
  }
}

///|
test "centroid path" {
  let tree = Tree::new(5)
  // Path: 0 - 1 - 2 - 3 - 4
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)

  let decomp = CentroidDecomp::new(tree)
  let root = decomp.build()

  // Centroid of path should be middle node (2)
  inspect(root, content="2")

  // Depth should be O(log n)
  let max_depth = for i = 0, max_d = 0; i < 5; i = i + 1 {
    if decomp.centroid_depth[i] > max_d {
      continue i + 1, decomp.centroid_depth[i]
    } else {
      continue i + 1, max_d
    }
  } else {
    max_d
  }

  inspect(max_depth <= 3, content="true") // log2(5) ~ 2.3
}

///|
test "centroid star" {
  let tree = Tree::new(6)
  // Star: center 0, leaves 1-5
  for i = 1; i < 6; i = i + 1 {
    tree.add_edge(0, i)
  }

  let decomp = CentroidDecomp::new(tree)
  let root = decomp.build()

  // Centroid should be center (0)
  inspect(root, content="0")

  // All other nodes should have depth 1
  for i = 1; i < 6; i = i + 1 {
    inspect(decomp.centroid_depth[i], content="1")
  }
}

///|
test "centroid path to root" {
  let tree = Tree::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)

  let decomp = CentroidDecomp::new(tree)
  let _ = decomp.build()

  // Path from leaf to centroid root
  let path = decomp.path_to_root(0)

  // Path should end at root (centroid_parent = -1)
  let last = path[path.length() - 1]
  inspect(decomp.centroid_parent[last], content="-1")
}

///|
test "centroid single node" {
  let tree = Tree::new(1)

  let decomp = CentroidDecomp::new(tree)
  let root = decomp.build()

  inspect(root, content="0")
  inspect(decomp.centroid_depth[0], content="0")
  inspect(decomp.centroid_parent[0], content="-1")
}

///|
test "distance oracle basic" {
  let tree = Tree::new(5)
  // Path: 0 - 1 - 2 - 3 - 4
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)

  let oracle = DistanceOracle::new(tree)

  // Adjacent nodes
  inspect(oracle.query(0, 1), content="1")
  inspect(oracle.query(1, 2), content="1")

  // Endpoints
  inspect(oracle.query(0, 4), content="4")

  // Same node
  inspect(oracle.query(2, 2), content="0")
}

///|
test "distance oracle tree" {
  let tree = Tree::new(7)
  //       0
  //      /|\
  //     1 2 3
  //    /|   |
  //   4 5   6
  tree.add_edge(0, 1)
  tree.add_edge(0, 2)
  tree.add_edge(0, 3)
  tree.add_edge(1, 4)
  tree.add_edge(1, 5)
  tree.add_edge(3, 6)

  let oracle = DistanceOracle::new(tree)

  // Distance from 4 to 6: 4-1-0-3-6 = 4
  inspect(oracle.query(4, 6), content="4")

  // Distance from 4 to 5: 4-1-5 = 2
  inspect(oracle.query(4, 5), content="2")

  // Distance from 2 to 6: 2-0-3-6 = 3
  inspect(oracle.query(2, 6), content="3")
}

///|
test "distance oracle depth bound" {
  // Build a balanced binary tree to test depth
  let tree = Tree::new(15)
  // Level 0: 0
  // Level 1: 1, 2
  // Level 2: 3, 4, 5, 6
  // Level 3: 7, 8, 9, 10, 11, 12, 13, 14
  tree.add_edge(0, 1)
  tree.add_edge(0, 2)
  tree.add_edge(1, 3)
  tree.add_edge(1, 4)
  tree.add_edge(2, 5)
  tree.add_edge(2, 6)
  tree.add_edge(3, 7)
  tree.add_edge(3, 8)
  tree.add_edge(4, 9)
  tree.add_edge(4, 10)
  tree.add_edge(5, 11)
  tree.add_edge(5, 12)
  tree.add_edge(6, 13)
  tree.add_edge(6, 14)

  let oracle = DistanceOracle::new(tree)

  // Max depth should be O(log n) = O(log 15) ~ 4
  let max_depth = oracle.max_centroid_depth()
  inspect(max_depth <= 5, content="true")
}

///|
test "centroid chain" {
  // Long chain to test depth bound
  let n = 16
  let tree = Tree::new(n)
  for i = 0; i < n - 1; i = i + 1 {
    tree.add_edge(i, i + 1)
  }

  let decomp = CentroidDecomp::new(tree)
  let _ = decomp.build()

  // Max depth should be O(log n) = O(log 16) = 4
  let max_depth = for i = 0, max_d = 0; i < n; i = i + 1 {
    if decomp.centroid_depth[i] > max_d {
      continue i + 1, decomp.centroid_depth[i]
    } else {
      continue i + 1, max_d
    }
  } else {
    max_d
  }

  inspect(max_depth <= 5, content="true")
}

///|
test "distance oracle single" {
  let tree = Tree::new(1)
  let oracle = DistanceOracle::new(tree)

  inspect(oracle.query(0, 0), content="0")
}

///|
test "distance oracle two nodes" {
  let tree = Tree::new(2)
  tree.add_edge(0, 1)

  let oracle = DistanceOracle::new(tree)

  inspect(oracle.query(0, 1), content="1")
  inspect(oracle.query(1, 0), content="1")
}

///|
test "centroid accessors" {
  let tree = Tree::new(5)
  tree.add_edge(0, 1)
  tree.add_edge(1, 2)
  tree.add_edge(2, 3)
  tree.add_edge(3, 4)

  let decomp = CentroidDecomp::new(tree)
  let _ = decomp.build()

  // Test root function
  let root = decomp.root()
  inspect(root >= 0 && root < 5, content="true")

  // Test get_depth
  inspect(decomp.get_depth(root), content="0")

  // Test get_parent of root
  inspect(decomp.get_parent(root), content="-1")
}
