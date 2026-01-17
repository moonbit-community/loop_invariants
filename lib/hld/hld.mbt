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
fn HLD::add_edge(self : HLD, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// First DFS: compute parent, depth, subtree size, heavy child
fn HLD::dfs_size(self : HLD, u : Int, p : Int, d : Int) -> Unit {
  self.parent[u] = p
  self.depth[u] = d
  self.subtree_size[u] = 1
  let mut max_child_size = 0
  for v in self.adj[u] {
    if v != p {
      self.dfs_size(v, u, d + 1)
      self.subtree_size[u] = self.subtree_size[u] + self.subtree_size[v]
      if self.subtree_size[v] > max_child_size {
        max_child_size = self.subtree_size[v]
        self.heavy_child[u] = v
      }
    }
  }
}

///|
/// Second DFS: assign positions and chain heads
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
fn HLD::build(self : HLD, root : Int) -> Unit {
  if self.n > 0 {
    self.dfs_size(root, -1, 0)
    self.dfs_hld(root, root)
  }
}

///|
/// Find LCA using HLD
fn HLD::lca(self : HLD, u : Int, v : Int) -> Int {
  loop (u, v) {
    (a, b) =>
      if self.chain_head[a] == self.chain_head[b] {
        if self.depth[a] < self.depth[b] {
          break a
        } else {
          break b
        }
      } else if self.depth[self.chain_head[a]] < self.depth[self.chain_head[b]] {
        continue (a, self.parent[self.chain_head[b]])
      } else {
        continue (self.parent[self.chain_head[a]], b)
      }
  }
}

///|
/// Get path length between two nodes
fn HLD::path_length(self : HLD, u : Int, v : Int) -> Int {
  let l = self.lca(u, v)
  self.depth[u] + self.depth[v] - 2 * self.depth[l]
}

///|
/// Count number of chain switches on path (for complexity analysis)
fn HLD::count_chains(self : HLD, u : Int, v : Int) -> Int {
  loop (u, v, 0) {
    (a, b, count) =>
      if self.chain_head[a] == self.chain_head[b] {
        break count + 1 // Include final chain
      } else if self.depth[self.chain_head[a]] < self.depth[self.chain_head[b]] {
        continue (a, self.parent[self.chain_head[b]], count + 1)
      } else {
        continue (self.parent[self.chain_head[a]], b, count + 1)
      }
  }
}

///|
fn HLD::get_position(self : HLD, u : Int) -> Int {
  self.position[u]
}

///|
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
