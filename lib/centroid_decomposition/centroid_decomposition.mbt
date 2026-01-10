// ============================================================================
// CENTROID DECOMPOSITION - Tree Divide and Conquer
// ============================================================================
//
// Decomposes a tree by repeatedly finding and removing centroids.
// Enables efficient path queries and updates on trees.
//
// CENTROID: A node whose removal splits the tree into components
// each with at most n/2 nodes.
//
// KEY INSIGHT: The centroid tree has O(log n) depth, so any
// path query can be answered by checking O(log n) ancestors.
//
// INVARIANTS:
// 1. Every tree has at least one centroid
// 2. Removing centroid splits into components of size <= n/2
// 3. Centroid tree depth is O(log n)
//
// TIME COMPLEXITY: O(n log n) construction
// SPACE COMPLEXITY: O(n)

///|
priv struct TreeNode {
  neighbors : Array[Int]
}

///|
priv struct CentroidTree {
  n : Int
  adj : Array[Array[Int]]
  removed : Array[Bool]
  subtree_size : Array[Int]
  centroid_parent : Array[Int]
  centroid_depth : Array[Int]
}

///|
fn CentroidTree::new(n : Int) -> CentroidTree {
  let adj = Array::makei(n, fn(_) { [] })
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
/// Compute subtree sizes using functional for-loop style DFS
fn compute_subtree_size(
  ct : CentroidTree,
  node : Int,
  parent : Int
) -> Int {
  let children_size = for i = 0, total = 0; i < ct.adj[node].length(); {
    let neighbor = ct.adj[node][i]
    if neighbor != parent && not(ct.removed[neighbor]) {
      let child_size = compute_subtree_size(ct, neighbor, node)
      continue i + 1, total + child_size
    } else {
      continue i + 1, total
    }
  } else {
    total
  }
  ct.subtree_size[node] = 1 + children_size
  ct.subtree_size[node]
}

///|
/// Find centroid of subtree rooted at node
fn find_centroid(
  ct : CentroidTree,
  node : Int,
  parent : Int,
  tree_size : Int
) -> Int {
  for i = 0; i < ct.adj[node].length(); {
    let neighbor = ct.adj[node][i]
    if neighbor != parent && not(ct.removed[neighbor]) &&
       ct.subtree_size[neighbor] > tree_size / 2 {
      break find_centroid(ct, neighbor, node, tree_size)
    }
    continue i + 1
  } else {
    node
  }
}

///|
/// Build centroid decomposition recursively
fn build_centroid_tree(
  ct : CentroidTree,
  node : Int,
  parent_centroid : Int,
  depth : Int
) -> Int {
  // Compute subtree sizes
  let tree_size = compute_subtree_size(ct, node, -1)

  // Find centroid
  let centroid = find_centroid(ct, node, -1, tree_size)

  // Mark centroid as removed and set its parent
  ct.removed[centroid] = true
  ct.centroid_parent[centroid] = parent_centroid
  ct.centroid_depth[centroid] = depth

  // Recursively decompose each subtree
  for i = 0; i < ct.adj[centroid].length(); i = i + 1 {
    let neighbor = ct.adj[centroid][i]
    if not(ct.removed[neighbor]) {
      let _ = build_centroid_tree(ct, neighbor, centroid, depth + 1)

    }
  }

  centroid
}

///|
fn CentroidTree::build(self : CentroidTree) -> Int {
  build_centroid_tree(self, 0, -1, 0)
}

///|
/// Get ancestors in centroid tree (including self)
fn CentroidTree::get_centroid_ancestors(self : CentroidTree, node : Int) -> Array[Int] {
  let ancestors : Array[Int] = []
  for curr = node; curr >= 0; {
    ancestors.push(curr)
    continue self.centroid_parent[curr]
  }
  ancestors
}

///|
/// Get depth in centroid tree
fn CentroidTree::get_centroid_depth(self : CentroidTree, node : Int) -> Int {
  self.centroid_depth[node]
}

///|
/// Distance between two nodes using BFS (for testing)
fn CentroidTree::distance(self : CentroidTree, u : Int, v : Int) -> Int {
  if u == v {
    return 0
  }

  let visited = Array::make(self.n, false)
  let queue : Array[(Int, Int)] = [(u, 0)]
  visited[u] = true

  for i = 0; i < queue.length(); {
    let (node, dist) = queue[i]
    if node == v {
      break dist
    }

    for j = 0; j < self.adj[node].length(); j = j + 1 {
      let neighbor = self.adj[node][j]
      if not(visited[neighbor]) {
        visited[neighbor] = true
        queue.push((neighbor, dist + 1))
      }
    }
    continue i + 1
  } else {
    -1
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "centroid decomposition simple" {
  // Linear tree: 0 - 1 - 2 - 3 - 4
  let ct = CentroidTree::new(5)
  ct.add_edge(0, 1)
  ct.add_edge(1, 2)
  ct.add_edge(2, 3)
  ct.add_edge(3, 4)

  let root = ct.build()

  // Root should be the centroid (middle node)
  inspect(root, content="2")

  // All nodes should have depth <= log(n)
  for i = 0; i < 5; i = i + 1 {
    inspect(ct.centroid_depth[i] <= 3, content="true")
  }
}

///|
test "centroid decomposition star" {
  // Star tree: 0 is center, connected to 1, 2, 3, 4
  let ct = CentroidTree::new(5)
  ct.add_edge(0, 1)
  ct.add_edge(0, 2)
  ct.add_edge(0, 3)
  ct.add_edge(0, 4)

  let root = ct.build()

  // Root should be center
  inspect(root, content="0")
  inspect(ct.centroid_depth[0], content="0")
}

///|
test "centroid ancestors" {
  let ct = CentroidTree::new(7)
  // Binary tree structure
  ct.add_edge(0, 1)
  ct.add_edge(0, 2)
  ct.add_edge(1, 3)
  ct.add_edge(1, 4)
  ct.add_edge(2, 5)
  ct.add_edge(2, 6)

  let _ = ct.build()

  // Check that every node has O(log n) ancestors
  for i = 0; i < 7; i = i + 1 {
    let ancestors = ct.get_centroid_ancestors(i)
    inspect(ancestors.length() <= 4, content="true")
  }
}

///|
test "centroid distance" {
  let ct = CentroidTree::new(5)
  ct.add_edge(0, 1)
  ct.add_edge(1, 2)
  ct.add_edge(2, 3)
  ct.add_edge(3, 4)

  inspect(ct.distance(0, 4), content="4")
  inspect(ct.distance(1, 3), content="2")
  inspect(ct.distance(2, 2), content="0")
}

///|
test "centroid single node" {
  let ct = CentroidTree::new(1)
  let root = ct.build()

  inspect(root, content="0")
  inspect(ct.centroid_depth[0], content="0")
}

///|
test "centroid two nodes" {
  let ct = CentroidTree::new(2)
  ct.add_edge(0, 1)

  let root = ct.build()

  // Either node can be centroid
  inspect(root == 0 || root == 1, content="true")
}
