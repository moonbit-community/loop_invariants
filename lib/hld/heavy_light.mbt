// ============================================================================
// HEAVY-LIGHT DECOMPOSITION - Efficient Tree Path Queries
// ============================================================================
//
// Heavy-Light Decomposition (HLD) is a technique that decomposes a tree into
// disjoint paths (chains) such that any root-to-leaf path crosses at most
// O(log n) chains. This enables efficient path queries and updates.
//
// KEY INSIGHT: For each node, we identify its "heavy child" - the child with
// the largest subtree. By always following heavy edges when building chains,
// we ensure that moving to a light edge at least halves the subtree size,
// giving O(log n) chain crossings on any path.
//
// DEFINITIONS:
// - Heavy edge: Edge to the child with largest subtree size
// - Light edge: All other edges
// - Heavy path/chain: Maximal path of heavy edges
//
// STRUCTURE:
// Each node stores:
// - parent: Parent in tree
// - depth: Distance from root
// - subtree_size: Size of subtree rooted here
// - chain_head: Head of the chain this node belongs to
// - chain_pos: Position within the chain (for segment tree)
//
// OPERATIONS:
// - path_query(u, v): Query aggregate on path from u to v - O(log^2 n)
// - path_update(u, v, val): Update all edges/nodes on path - O(log^2 n)
// - lca(u, v): Find lowest common ancestor - O(log n)
// - subtree_query(u): Query aggregate on subtree of u - O(log n)
//
// SPACE: O(n)
// TIME: O(n) preprocessing, O(log^2 n) queries with segment tree

///|
/// Heavy-Light Decomposition data structure
priv struct HLD {
  n : Int
  adj : Array[Array[Int]] // Adjacency list
  parent : Array[Int]
  depth : Array[Int]
  subtree_size : Array[Int]
  chain_head : Array[Int] // Head of chain containing this node
  chain_pos : Array[Int] // Position in linearized array
  chain_arr : Array[Int] // Linearized array (node at position i)
  // Segment tree for path queries
  seg_tree : Array[Int64]
  node_val : Array[Int64] // Value at each node
}

///|
fn HLD::new(n : Int) -> HLD {
  {
    n,
    adj: Array::make(n, []),
    parent: Array::make(n, -1),
    depth: Array::make(n, 0),
    subtree_size: Array::make(n, 0),
    chain_head: Array::make(n, 0),
    chain_pos: Array::make(n, 0),
    chain_arr: Array::make(n, 0),
    seg_tree: Array::make(4 * n, 0L),
    node_val: Array::make(n, 0L),
  }
}

///|
fn HLD::add_edge(self : HLD, u : Int, v : Int) -> Unit {
  // Make copies to modify
  let adj_u = self.adj[u].copy()
  adj_u.push(v)
  self.adj[u] = adj_u
  let adj_v = self.adj[v].copy()
  adj_v.push(u)
  self.adj[v] = adj_v
}

///|
/// Build HLD from tree rooted at node 0
fn HLD::build(self : HLD, root : Int) -> Unit {
  // DFS 1: Compute parent, depth, subtree_size
  // Also reorder children so heavy child is first
  fn dfs1(
    hld : HLD,
    u : Int,
    p : Int,
    d : Int
  ) -> Int {
    hld.parent[u] = p
    hld.depth[u] = d
    hld.subtree_size[u] = 1
    let mut max_child_size = 0
    let mut heavy_idx = -1
    let adj_u = hld.adj[u]
    
    // First pass: compute subtree sizes
    for i = 0; i < adj_u.length(); i = i + 1 {
      let v = adj_u[i]
      if v != p {
        let child_size = dfs1(hld, v, u, d + 1)
        hld.subtree_size[u] = hld.subtree_size[u] + child_size
        if child_size > max_child_size {
          max_child_size = child_size
          heavy_idx = i
        }
      }
    }
    
    // Move heavy child to front of adjacency list
    if heavy_idx > 0 {
      let new_adj = hld.adj[u].copy()
      let tmp = new_adj[0]
      new_adj[0] = new_adj[heavy_idx]
      new_adj[heavy_idx] = tmp
      hld.adj[u] = new_adj
    }
    
    hld.subtree_size[u]
  }
  
  let _ = dfs1(self, root, -1, 0)
  
  // DFS 2: Decompose into chains
  // Assign chain_head and chain_pos
  fn dfs2(
    hld : HLD,
    u : Int,
    p : Int,
    head : Int,
    pos : Ref[Int]
  ) -> Unit {
    hld.chain_head[u] = head
    hld.chain_pos[u] = pos.val
    hld.chain_arr[pos.val] = u
    pos.val = pos.val + 1
    
    let adj_u = hld.adj[u]
    let mut first_child = true
    
    // Process children - heavy child first (it's at index 0 after reordering)
    for i = 0; i < adj_u.length(); i = i + 1 {
      let v = adj_u[i]
      if v != p {
        if first_child {
          // Heavy child: continue same chain
          dfs2(hld, v, u, head, pos)
          first_child = false
        } else {
          // Light child: start new chain
          dfs2(hld, v, u, v, pos)
        }
      }
    }
  }
  
  let pos_ref : Ref[Int] = { val: 0 }
  dfs2(self, root, -1, root, pos_ref)
}

// ============================================================================
// SEGMENT TREE FOR PATH QUERIES
// ============================================================================

///|
/// Build segment tree from node values
fn HLD::build_segtree(self : HLD) -> Unit {
  fn build_rec(hld : HLD, node : Int, start : Int, end : Int) -> Unit {
    if start == end {
      let u = hld.chain_arr[start]
      hld.seg_tree[node] = hld.node_val[u]
      return
    }
    let mid = (start + end) / 2
    build_rec(hld, 2 * node, start, mid)
    build_rec(hld, 2 * node + 1, mid + 1, end)
    hld.seg_tree[node] = hld.seg_tree[2 * node] + hld.seg_tree[2 * node + 1]
  }
  
  if self.n > 0 {
    build_rec(self, 1, 0, self.n - 1)
  }
}

///|
/// Point update: set value of node u
fn HLD::update_node(self : HLD, u : Int, val : Int64) -> Unit {
  self.node_val[u] = val
  let pos = self.chain_pos[u]
  
  fn update_rec(hld : HLD, node : Int, start : Int, end : Int, pos : Int, val : Int64) -> Unit {
    if start == end {
      hld.seg_tree[node] = val
      return
    }
    let mid = (start + end) / 2
    if pos <= mid {
      update_rec(hld, 2 * node, start, mid, pos, val)
    } else {
      update_rec(hld, 2 * node + 1, mid + 1, end, pos, val)
    }
    hld.seg_tree[node] = hld.seg_tree[2 * node] + hld.seg_tree[2 * node + 1]
  }
  
  if self.n > 0 {
    update_rec(self, 1, 0, self.n - 1, pos, val)
  }
}

///|
/// Range query on segment tree [l, r]
fn HLD::query_range(self : HLD, l : Int, r : Int) -> Int64 {
  fn query_rec(hld : HLD, node : Int, start : Int, end : Int, l : Int, r : Int) -> Int64 {
    if r < start || end < l {
      return 0L
    }
    if l <= start && end <= r {
      return hld.seg_tree[node]
    }
    let mid = (start + end) / 2
    query_rec(hld, 2 * node, start, mid, l, r) +
      query_rec(hld, 2 * node + 1, mid + 1, end, l, r)
  }
  
  if self.n == 0 || l > r {
    return 0L
  }
  query_rec(self, 1, 0, self.n - 1, l, r)
}

// ============================================================================
// PATH QUERIES
// ============================================================================

///|
/// Query sum on path from u to v
/// REASONING: We climb from the deeper node toward LCA, processing one chain
/// at a time. When nodes are in different chains, we process the chain of the
/// node with deeper chain_head and move to its parent. This ensures we cross
/// O(log n) chains total.
fn HLD::path_query(self : HLD, u : Int, v : Int) -> Int64 {
  // LOOP INVARIANT:
  // - We want sum on path from current a to current b
  // - result accumulates partial sums from chains we've fully processed
  // - When a and b are in same chain, we can directly query [min_pos, max_pos]
  for a = u, b = v, result = 0L; ; {
    // If in same chain, query directly and return
    if self.chain_head[a] == self.chain_head[b] {
      let pos_a = self.chain_pos[a]
      let pos_b = self.chain_pos[b]
      let l = if pos_a < pos_b { pos_a } else { pos_b }
      let r = if pos_a > pos_b { pos_a } else { pos_b }
      break result + self.query_range(l, r)
    }
    
    // Move the node with deeper chain head upward
    let head_a = self.chain_head[a]
    let head_b = self.chain_head[b]
    
    if self.depth[head_a] >= self.depth[head_b] {
      // Process chain of a from a to head_a
      let new_result = result + self.query_range(self.chain_pos[head_a], self.chain_pos[a])
      // Move a to parent of head_a
      let new_a = self.parent[head_a]
      continue new_a, b, new_result
    } else {
      // Process chain of b from b to head_b
      let new_result = result + self.query_range(self.chain_pos[head_b], self.chain_pos[b])
      // Move b to parent of head_b
      let new_b = self.parent[head_b]
      continue a, new_b, new_result
    }
  } where {
    invariant: a >= 0 && a < self.n && b >= 0 && b < self.n,
    reasoning: "Each iteration moves one node up a chain; process terminates when same chain",
  }
}

///|
/// Path update: add val to all nodes on path from u to v
fn HLD::path_update(self : HLD, u : Int, v : Int, val : Int64) -> Unit {
  // Similar structure to path_query but updates instead
  for a = u, b = v; ; {
    if self.chain_head[a] == self.chain_head[b] {
      let pos_a = self.chain_pos[a]
      let pos_b = self.chain_pos[b]
      let l = if pos_a < pos_b { pos_a } else { pos_b }
      let r = if pos_a > pos_b { pos_a } else { pos_b }
      // Update each node in range
      for i = l; i <= r; i = i + 1 {
        let node = self.chain_arr[i]
        self.update_node(node, self.node_val[node] + val)
      }
      break
    }
    
    let head_a = self.chain_head[a]
    let head_b = self.chain_head[b]
    
    if self.depth[head_a] >= self.depth[head_b] {
      // Update chain of a
      for i = self.chain_pos[head_a]; i <= self.chain_pos[a]; i = i + 1 {
        let node = self.chain_arr[i]
        self.update_node(node, self.node_val[node] + val)
      }
      continue self.parent[head_a], b
    } else {
      // Update chain of b
      for i = self.chain_pos[head_b]; i <= self.chain_pos[b]; i = i + 1 {
        let node = self.chain_arr[i]
        self.update_node(node, self.node_val[node] + val)
      }
      continue a, self.parent[head_b]
    }
  } where {
    invariant: a >= 0 && b >= 0,
    reasoning: "Each iteration processes one chain and moves up; terminates when same chain",
  }
}

///|
/// Find Lowest Common Ancestor of u and v
/// REASONING: Same climbing technique as path query, but we just find where paths meet
fn HLD::lca(self : HLD, u : Int, v : Int) -> Int {
  for a = u, b = v; ; {
    if self.chain_head[a] == self.chain_head[b] {
      // Same chain: LCA is the shallower node
      break if self.depth[a] < self.depth[b] { a } else { b }
    }
    
    let head_a = self.chain_head[a]
    let head_b = self.chain_head[b]
    
    if self.depth[head_a] >= self.depth[head_b] {
      continue self.parent[head_a], b
    } else {
      continue a, self.parent[head_b]
    }
  } where {
    invariant: a >= 0 && b >= 0,
    reasoning: "Climbing toward root; chains converge to common ancestor",
  }
}

///|
/// Get distance (number of edges) between u and v
fn HLD::distance(self : HLD, u : Int, v : Int) -> Int {
  let l = self.lca(u, v)
  self.depth[u] + self.depth[v] - 2 * self.depth[l]
}

///|
/// Query sum on subtree rooted at u
/// REASONING: Due to DFS order in chain assignment, subtree of u occupies
/// contiguous positions [chain_pos[u], chain_pos[u] + subtree_size[u] - 1]
fn HLD::subtree_query(self : HLD, u : Int) -> Int64 {
  let start = self.chain_pos[u]
  let end = start + self.subtree_size[u] - 1
  self.query_range(start, end)
}

///|
/// Subtree update: add val to all nodes in subtree of u
fn HLD::subtree_update(self : HLD, u : Int, val : Int64) -> Unit {
  let start = self.chain_pos[u]
  let end = start + self.subtree_size[u] - 1
  for i = start; i <= end; i = i + 1 {
    let node = self.chain_arr[i]
    self.update_node(node, self.node_val[node] + val)
  }
}

///|
fn HLD::get_node_value(self : HLD, u : Int) -> Int64 {
  self.node_val[u]
}

///|
fn HLD::set_node_value(self : HLD, u : Int, val : Int64) -> Unit {
  self.update_node(u, val)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "hld basic tree" {
  // Build tree:
  //        0
  //       /|\
  //      1 2 3
  //     /|   |
  //    4 5   6
  let hld = HLD::new(7)
  hld.add_edge(0, 1)
  hld.add_edge(0, 2)
  hld.add_edge(0, 3)
  hld.add_edge(1, 4)
  hld.add_edge(1, 5)
  hld.add_edge(3, 6)
  hld.build(0)
  
  // Set values: node i has value i+1
  for i = 0; i < 7; i = i + 1 {
    hld.node_val[i] = (i + 1).to_int64()
  }
  hld.build_segtree()
  
  // Test depth
  inspect(hld.depth[0], content="0")
  inspect(hld.depth[1], content="1")
  inspect(hld.depth[4], content="2")
  
  // Test LCA
  inspect(hld.lca(4, 5), content="1")
  inspect(hld.lca(4, 6), content="0")
  inspect(hld.lca(4, 2), content="0")
  inspect(hld.lca(0, 6), content="0")
  
  // Test distance
  inspect(hld.distance(4, 5), content="2")
  inspect(hld.distance(4, 6), content="4")
}

///|
test "hld path query" {
  // Linear tree: 0 - 1 - 2 - 3 - 4
  let hld = HLD::new(5)
  hld.add_edge(0, 1)
  hld.add_edge(1, 2)
  hld.add_edge(2, 3)
  hld.add_edge(3, 4)
  hld.build(0)
  
  // Set values: node i has value i+1
  for i = 0; i < 5; i = i + 1 {
    hld.node_val[i] = (i + 1).to_int64()
  }
  hld.build_segtree()
  
  // Path query 0 to 4: sum of 1+2+3+4+5 = 15
  inspect(hld.path_query(0, 4), content="15")
  
  // Path query 1 to 3: sum of 2+3+4 = 9
  inspect(hld.path_query(1, 3), content="9")
  
  // Path query single node
  inspect(hld.path_query(2, 2), content="3")
}

///|
test "hld subtree query" {
  // Tree:     0
  //          /|\
  //         1 2 3
  //        /|
  //       4 5
  let hld = HLD::new(6)
  hld.add_edge(0, 1)
  hld.add_edge(0, 2)
  hld.add_edge(0, 3)
  hld.add_edge(1, 4)
  hld.add_edge(1, 5)
  hld.build(0)
  
  // Set all values to 1
  for i = 0; i < 6; i = i + 1 {
    hld.node_val[i] = 1L
  }
  hld.build_segtree()
  
  // Subtree of 1: nodes 1, 4, 5 -> sum = 3
  inspect(hld.subtree_query(1), content="3")
  
  // Subtree of 0: all nodes -> sum = 6
  inspect(hld.subtree_query(0), content="6")
  
  // Subtree of leaf 4: just node 4 -> sum = 1
  inspect(hld.subtree_query(4), content="1")

  // Test subtree update: add 10 to subtree of 1
  hld.subtree_update(1, 10L)
  // Now: 0=1, 1=11, 2=1, 3=1, 4=11, 5=11
  inspect(hld.subtree_query(1), content="33") // 11+11+11
  inspect(hld.subtree_query(0), content="36") // 1+11+1+1+11+11
}

///|
test "hld updates" {
  // Linear tree: 0 - 1 - 2
  let hld = HLD::new(3)
  hld.add_edge(0, 1)
  hld.add_edge(1, 2)
  hld.build(0)
  
  // Initialize all to 0
  hld.build_segtree()
  
  inspect(hld.path_query(0, 2), content="0")
  
  // Update node 1 to value 10
  hld.set_node_value(1, 10L)
  inspect(hld.path_query(0, 2), content="10")
  inspect(hld.get_node_value(1), content="10")
  
  // Path update: add 5 to path 0-2
  hld.path_update(0, 2, 5L)
  // Now: 0=5, 1=15, 2=5
  inspect(hld.path_query(0, 2), content="25")
}

///|
test "hld binary tree" {
  // Complete binary tree of depth 2
  //         0
  //        / \
  //       1   2
  //      / \ / \
  //     3  4 5  6
  let hld = HLD::new(7)
  hld.add_edge(0, 1)
  hld.add_edge(0, 2)
  hld.add_edge(1, 3)
  hld.add_edge(1, 4)
  hld.add_edge(2, 5)
  hld.add_edge(2, 6)
  hld.build(0)
  
  // Set values to powers of 2
  hld.node_val[0] = 1L
  hld.node_val[1] = 2L
  hld.node_val[2] = 4L
  hld.node_val[3] = 8L
  hld.node_val[4] = 16L
  hld.node_val[5] = 32L
  hld.node_val[6] = 64L
  hld.build_segtree()
  
  // Path 3 to 6: 3-1-0-2-6 = 8+2+1+4+64 = 79
  inspect(hld.path_query(3, 6), content="79")
  
  // Path 3 to 4: 3-1-4 = 8+2+16 = 26
  inspect(hld.path_query(3, 4), content="26")
  
  // LCA of 3 and 6 is 0
  inspect(hld.lca(3, 6), content="0")
  
  // LCA of 3 and 4 is 1
  inspect(hld.lca(3, 4), content="1")
  
  // Distance 3 to 6 = 4
  inspect(hld.distance(3, 6), content="4")
}

///|
test "hld chain structure" {
  // Bamboo tree (worst case for naive): 0-1-2-3-4-5-6-7
  // HLD should create a single chain
  let hld = HLD::new(8)
  for i = 0; i < 7; i = i + 1 {
    hld.add_edge(i, i + 1)
  }
  hld.build(0)
  
  // All nodes should be in same chain
  let head = hld.chain_head[0]
  for i = 0; i < 8; i = i + 1 {
    guard hld.chain_head[i] == head else {
      fail("Node \{i} not in expected chain")
    }
  }
  
  // Chain positions should be consecutive from root
  for i = 0; i < 8; i = i + 1 {
    guard hld.chain_pos[i] == i else {
      fail("Node \{i} has wrong chain position")
    }
  }
}

///|
test "hld star tree" {
  // Star tree: 0 connected to 1,2,3,4,5
  // Each leaf starts its own chain (all are light children except one)
  let hld = HLD::new(6)
  for i = 1; i <= 5; i = i + 1 {
    hld.add_edge(0, i)
  }
  hld.build(0)
  
  // Root is at depth 0
  inspect(hld.depth[0], content="0")
  
  // All leaves at depth 1
  for i = 1; i <= 5; i = i + 1 {
    guard hld.depth[i] == 1 else {
      fail("Leaf \{i} should be at depth 1")
    }
  }
  
  // Set values and test
  for i = 0; i < 6; i = i + 1 {
    hld.node_val[i] = (i * 10).to_int64()
  }
  hld.build_segtree()
  
  // Path from leaf 1 to leaf 5 goes through root
  // Values: 10 + 0 + 50 = 60
  inspect(hld.path_query(1, 5), content="60")
}
