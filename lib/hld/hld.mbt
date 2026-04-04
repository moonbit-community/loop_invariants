// ============================================================================
// HEAVY-LIGHT DECOMPOSITION - Tree Path Queries in O(log² n)
// ============================================================================
//
// HLD decomposes a tree into heavy and light edges, enabling efficient
// path queries by ensuring any root-to-leaf path crosses O(log n) light edges.
//
// DEFINITIONS:
// - Heavy child: child with largest subtree
// - Heavy edge: edge to heavy child
// - Light edge: edge to non-heavy child
// - Heavy path: maximal path of heavy edges
//
// KEY INSIGHT: Any path from root to leaf crosses at most O(log n) light edges,
// because crossing a light edge means going to a subtree of size ≤ n/2.
//
// ALGORITHM:
// 1. DFS to compute subtree sizes and identify heavy children
// 2. DFS to assign positions and chain heads
// 3. For path queries: walk up chains, query segment tree on each chain
//
// INVARIANTS:
// 1. Each node has exactly one heavy child (or none if leaf)
// 2. Heavy paths are contiguous in position array
// 3. Light edge crossings ≤ log n on any root-to-leaf path
//
// TIME COMPLEXITY: O(log² n) per path query, O(n) preprocessing
// SPACE COMPLEXITY: O(n)

///|
/// Heavy-Light Decomposition data structure.
///
/// Decomposes a static unrooted tree into heavy and light edges so that any
/// root-to-leaf path crosses at most O(log n) light edges.  Each heavy chain
/// receives a contiguous block of positions, allowing an external segment tree
/// or Fenwick tree to answer path queries in O(log² n) and subtree queries in
/// O(log n).
///
/// Fields (all 0-indexed, length `n`):
/// - `n`            : number of nodes
/// - `adj`          : adjacency list
/// - `parent`       : parent of each node (-1 for root)
/// - `depth`        : depth of each node (root = 0)
/// - `subtree_size` : size of the subtree rooted at each node
/// - `heavy_child`  : the heavy child of each node (-1 if leaf)
/// - `chain_head`   : the topmost node of the heavy chain that contains each node
/// - `position`     : DFS timestamp used as the index into an external array structure
/// - `timer`        : internal counter incremented during `dfs_hld`
///
/// After `build(root)` you can call:
/// - `lca(u, v)`            - lowest common ancestor
/// - `path_length(u, v)`    - number of edges on the path
/// - `count_chains(u, v)`   - number of chain segments the path crosses
/// - `get_position(u)`      - position index for node `u`
/// - `get_chain_head(u)`    - head of the chain that contains node `u`
priv struct HLD {
  n : Int
  adj : Array[Array[Int]]
  parent : Array[Int]
  depth : Array[Int]
  subtree_size : Array[Int]
  heavy_child : Array[Int]
  chain_head : Array[Int]
  position : Array[Int] // Position in segment tree
  mut timer : Int
}

///|
/// Create a new HLD instance for a tree with `n` nodes (0-indexed).
///
/// All internal arrays are zeroed/reset; no edges have been added yet.
/// Call `add_edge` to build the tree topology, then `build` to run both
/// DFS passes.
///
/// # Example
/// ```mbt check
/// test {
///   let hld = HLD::new(5)
///   hld.add_edge(0, 1)
///   hld.add_edge(1, 2)
///   hld.add_edge(2, 3)
///   hld.add_edge(3, 4)
///   hld.build(0)
///   inspect(hld.path_length(0, 4), content="4")
/// }
/// ```
fn HLD::new(n : Int) -> HLD {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  {
    n,
    adj,
    parent: Array::make(n, -1),
    depth: Array::make(n, 0),
    subtree_size: Array::make(n, 0),
    heavy_child: Array::make(n, -1),
    chain_head: Array::make(n, 0),
    position: Array::make(n, 0),
    timer: 0,
  }
}

///|
/// Add an undirected edge between nodes `u` and `v`.
///
/// Must be called before `build`.  Edges may be added in any order.
/// The two endpoints are pushed into each other's adjacency list so that
/// the tree can be rooted at any node during `build`.
///
/// # Example
/// ```mbt check
/// test {
///   let hld = HLD::new(3)
///   hld.add_edge(0, 1)
///   hld.add_edge(1, 2)
///   hld.build(0)
///   inspect(hld.path_length(0, 2), content="2")
/// }
/// ```
fn HLD::add_edge(self : HLD, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// First DFS: compute parent, depth, subtree size, heavy child.
///
/// Visits every node exactly once in depth-first order starting from `u`
/// (with parent `p` at depth `d`).  At each node it:
/// 1. Records the parent and depth.
/// 2. Recursively processes all children (neighbours except the parent).
/// 3. Accumulates their subtree sizes into `subtree_size[u]`.
/// 4. Tracks the child with the largest subtree and stores it in
///    `heavy_child[u]`.  Ties are broken by iteration order.
///
/// This is the first of the two DFS passes that constitute `build`.
fn HLD::dfs_size(self : HLD, u : Int, p : Int, d : Int) -> Unit {
  self.parent[u] = p
  self.depth[u] = d
  self.subtree_size[u] = 1
  for i = 0, max_child_size = 0; i < self.adj[u].length(); {
    let v = self.adj[u][i]
    if v != p {
      self.dfs_size(v, u, d + 1)
      self.subtree_size[u] = self.subtree_size[u] + self.subtree_size[v]
      let max_child_size = if self.subtree_size[v] > max_child_size {
        self.heavy_child[u] = v
        self.subtree_size[v]
      } else {
        max_child_size
      }
      continue i + 1, max_child_size
    }
    continue i + 1, max_child_size
  }
}

///|
/// Second DFS: assign positions and chain heads.
///
/// Visits every node exactly once, but processes the heavy child before
/// all light children.  This ordering guarantees that all nodes on the
/// same heavy chain receive consecutive positions (`position` values),
/// which is the property that makes a chain a single range in the
/// external data structure.
///
/// - `u`    : current node being processed
/// - `head` : the topmost node of the heavy chain that `u` belongs to
///
/// At each node:
/// 1. `chain_head[u]` is set to `head`.
/// 2. `position[u]` is set to the current timer value; the timer is
///    then incremented.
/// 3. The heavy child (if any) continues the same chain, so it is
///    visited first with the same `head`.
/// 4. Each light child starts a new chain, so it is visited with itself
///    as the new `head`.
///
/// This is the second of the two DFS passes that constitute `build`.
fn HLD::dfs_hld(self : HLD, u : Int, head : Int) -> Unit {
  self.chain_head[u] = head
  self.position[u] = self.timer
  self.timer = self.timer + 1

  // Process heavy child first (keeps heavy path contiguous)
  if self.heavy_child[u] >= 0 {
    self.dfs_hld(self.heavy_child[u], head)
  }

  // Process light children (start new chains)
  for v in self.adj[u] {
    if v != self.parent[u] && v != self.heavy_child[u] {
      self.dfs_hld(v, v) // v becomes head of new chain
    }
  }
}

///|
/// Run both DFS passes and populate all HLD arrays.
///
/// Must be called exactly once after all edges have been added.
/// `root` can be any node (0-indexed); all subsequent queries assume
/// the tree is rooted at `root`.
///
/// Steps performed:
/// 1. `dfs_size(root, -1, 0)` - fills `parent`, `depth`, `subtree_size`,
///    and `heavy_child`.
/// 2. `dfs_hld(root, root)` - fills `chain_head` and `position`.
///
/// Does nothing when `n == 0`.
///
/// # Example
/// ```mbt check
/// test {
///   let hld = HLD::new(4)
///   hld.add_edge(0, 1)
///   hld.add_edge(0, 2)
///   hld.add_edge(0, 3)
///   hld.build(0)
///   inspect(hld.lca(1, 2), content="0")
///   inspect(hld.lca(2, 3), content="0")
/// }
/// ```
fn HLD::build(self : HLD, root : Int) -> Unit {
  if self.n > 0 {
    self.dfs_size(root, -1, 0)
    self.dfs_hld(root, root)
  }
}

///|
/// Find the Lowest Common Ancestor (LCA) of nodes `u` and `v`.
///
/// Uses the HLD chain structure: while `u` and `v` are on different chains,
/// climb the one whose chain head is deeper (higher depth value).  When
/// both nodes are on the same chain, the shallower of the two is the LCA.
///
/// Time complexity: O(log n) chain jumps.
///
/// # Example
/// ```mbt check
/// test {
///   //       0
///   //      / \
///   //     1   2
///   //    / \
///   //   3   4
///   let hld = HLD::new(5)
///   hld.add_edge(0, 1)
///   hld.add_edge(0, 2)
///   hld.add_edge(1, 3)
///   hld.add_edge(1, 4)
///   hld.build(0)
///   inspect(hld.lca(3, 4), content="1")
///   inspect(hld.lca(3, 2), content="0")
///   inspect(hld.lca(0, 4), content="0")
/// }
/// ```
fn HLD::lca(self : HLD, u : Int, v : Int) -> Int {
  for a = u, b = v {
    if self.chain_head[a] == self.chain_head[b] {
      if self.depth[a] < self.depth[b] {
        break a
      } else {
        break b
      }
    } else if self.depth[self.chain_head[a]] < self.depth[self.chain_head[b]] {
      continue a, self.parent[self.chain_head[b]]
    } else {
      continue self.parent[self.chain_head[a]], b
    }
  }
}

///|
/// Return the number of edges on the path between `u` and `v`.
///
/// Computed as `depth[u] + depth[v] - 2 * depth[lca(u, v)]`.
/// Returns 0 when `u == v`.
///
/// Time complexity: O(log n).
///
/// # Example
/// ```mbt check
/// test {
///   // Linear chain: 0 - 1 - 2 - 3 - 4
///   let hld = HLD::new(5)
///   hld.add_edge(0, 1)
///   hld.add_edge(1, 2)
///   hld.add_edge(2, 3)
///   hld.add_edge(3, 4)
///   hld.build(0)
///   inspect(hld.path_length(0, 4), content="4")
///   inspect(hld.path_length(1, 3), content="2")
///   inspect(hld.path_length(2, 2), content="0")
/// }
/// ```
fn HLD::path_length(self : HLD, u : Int, v : Int) -> Int {
  let l = self.lca(u, v)
  self.depth[u] + self.depth[v] - 2 * self.depth[l]
}

///|
/// Count the number of contiguous chain segments the path u -> v spans.
///
/// Each iteration of the loop contributes one segment: either the tail of a
/// chain (when the two nodes are on different chains) or the final shared
/// chain segment.  The result is always at least 1 (the final shared
/// segment) and is bounded by O(log n).
///
/// This function is primarily useful for verifying the logarithmic
/// complexity of the decomposition in tests and benchmarks.
///
/// Time complexity: O(log n).
///
/// # Example
/// ```mbt check
/// test {
///   // Linear chain 0-1-2-3-4-5-6-7 forms a single heavy chain.
///   let hld = HLD::new(8)
///   for i in 0..<7 {
///     hld.add_edge(i, i + 1)
///   }
///   hld.build(0)
///   inspect(hld.count_chains(0, 7), content="1")
/// }
/// ```
fn HLD::count_chains(self : HLD, u : Int, v : Int) -> Int {
  for a = u, b = v, count = 0 {
    if self.chain_head[a] == self.chain_head[b] {
      break count + 1 // Include final chain
    } else if self.depth[self.chain_head[a]] < self.depth[self.chain_head[b]] {
      continue a, self.parent[self.chain_head[b]], count + 1
    } else {
      continue self.parent[self.chain_head[a]], b, count + 1
    }
  }
}

///|
/// Return the position (DFS timestamp) assigned to node `u`.
///
/// This is the index you should use when reading or writing into an
/// external segment tree or Fenwick tree.  All nodes in the same heavy
/// chain have consecutive positions, so a chain maps to a contiguous
/// range `[position[head] .. position[tail]]`.
///
/// `build` must have been called before using this function.
///
/// # Example
/// ```mbt check
/// test {
///   // Linear chain 0-1-2: positions are 0, 1, 2 in order.
///   let hld = HLD::new(3)
///   hld.add_edge(0, 1)
///   hld.add_edge(1, 2)
///   hld.build(0)
///   inspect(hld.get_position(0), content="0")
///   inspect(hld.get_position(1), content="1")
///   inspect(hld.get_position(2), content="2")
/// }
/// ```
fn HLD::get_position(self : HLD, u : Int) -> Int {
  self.position[u]
}

///|
/// Return the head (topmost node) of the heavy chain that contains node `u`.
///
/// The chain head is the shallowest node on the heavy path through `u`.
/// Two nodes are on the same heavy chain if and only if their chain heads
/// are equal.
///
/// `build` must have been called before using this function.
///
/// # Example
/// ```mbt check
/// test {
///   // Linear chain 0-1-2: all nodes share chain head 0.
///   let hld = HLD::new(3)
///   hld.add_edge(0, 1)
///   hld.add_edge(1, 2)
///   hld.build(0)
///   inspect(hld.get_chain_head(0), content="0")
///   inspect(hld.get_chain_head(1), content="0")
///   inspect(hld.get_chain_head(2), content="0")
/// }
/// ```
fn HLD::get_chain_head(self : HLD, u : Int) -> Int {
  self.chain_head[u]
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "hld basic" {
  let hld = HLD::new(7)
  //       0
  //      / \
  //     1   2
  //    /|   |\
  //   3 4   5 6
  hld.add_edge(0, 1)
  hld.add_edge(0, 2)
  hld.add_edge(1, 3)
  hld.add_edge(1, 4)
  hld.add_edge(2, 5)
  hld.add_edge(2, 6)
  hld.build(0)
  inspect(hld.lca(3, 4), content="1")
  inspect(hld.lca(3, 5), content="0")
  inspect(hld.lca(5, 6), content="2")
  let pos3 = hld.get_position(3)
  let head3 = hld.get_chain_head(3)
  inspect(pos3 >= 0 && pos3 < 7, content="true")
  inspect(head3 >= 0 && head3 < 7, content="true")
}

///|
test "hld path length" {
  let hld = HLD::new(5)
  // 0 - 1 - 2 - 3 - 4
  hld.add_edge(0, 1)
  hld.add_edge(1, 2)
  hld.add_edge(2, 3)
  hld.add_edge(3, 4)
  hld.build(0)
  inspect(hld.path_length(0, 4), content="4")
  inspect(hld.path_length(1, 3), content="2")
  inspect(hld.path_length(2, 2), content="0")
}

///|
test "hld chain count" {
  let hld = HLD::new(7)
  hld.add_edge(0, 1)
  hld.add_edge(0, 2)
  hld.add_edge(1, 3)
  hld.add_edge(1, 4)
  hld.add_edge(2, 5)
  hld.add_edge(2, 6)
  hld.build(0)

  // Chain switches should be O(log n)
  let chains = hld.count_chains(3, 6)
  inspect(chains <= 4, content="true")
}

///|
test "hld single node" {
  let hld = HLD::new(1)
  hld.build(0)
  inspect(hld.lca(0, 0), content="0")
  inspect(hld.path_length(0, 0), content="0")
}

///|
test "hld linear" {
  let hld = HLD::new(8)
  for i in 0..<7 {
    hld.add_edge(i, i + 1)
  }
  hld.build(0)

  // Linear tree should be one heavy chain
  inspect(hld.count_chains(0, 7), content="1")
  inspect(hld.lca(0, 7), content="0")
}
