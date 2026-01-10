// ============================================================================
// HEAVY-LIGHT DECOMPOSITION - Tree Path Queries
// ============================================================================
//
// Decomposes a tree into heavy and light edges to enable
// O(log n) path queries using segment trees.
//
// HEAVY EDGE: Edge to child with largest subtree
// LIGHT EDGE: All other edges
//
// KEY INSIGHT: Any path from root to leaf crosses at most O(log n)
// light edges, so any path is covered by O(log n) heavy chains.
//
// INVARIANTS:
// 1. Each node has exactly one heavy child (or none if leaf)
// 2. Heavy chains form contiguous ranges in DFS order
// 3. At most O(log n) chains on any root-to-leaf path
//
// TIME COMPLEXITY: O(log² n) per query with segment tree
// SPACE COMPLEXITY: O(n)

///|
priv struct HLD {
  n : Int
  adj : Array[Array[Int]]
  parent : Array[Int]
  depth : Array[Int]
  subtree_size : Array[Int]
  chain_head : Array[Int]    // Head of heavy chain containing this node
  chain_pos : Array[Int]     // Position in linearized array
  chain_arr : Array[Int]     // Linearized array for segment tree
}

///|
fn HLD::new(n : Int) -> HLD {
  let adj = Array::makei(n, fn(_) { [] })
  {
    n,
    adj,
    parent: Array::make(n, -1),
    depth: Array::make(n, 0),
    subtree_size: Array::make(n, 1),
    chain_head: Array::makei(n, fn(i) { i }),
    chain_pos: Array::make(n, 0),
    chain_arr: Array::make(n, 0),
  }
}

///|
fn HLD::add_edge(self : HLD, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
  self.adj[v].push(u)
}

///|
/// First DFS: compute parent, depth, subtree sizes
fn hld_dfs1(hld : HLD, node : Int, par : Int, d : Int) -> Int {
  hld.parent[node] = par
  hld.depth[node] = d

  // Compute subtree size
  let size = for i = 0, total = 1; i < hld.adj[node].length(); {
    let child = hld.adj[node][i]
    if child != par {
      let child_size = hld_dfs1(hld, child, node, d + 1)
      continue i + 1, total + child_size
    } else {
      continue i + 1, total
    }
  } else {
    total
  }

  hld.subtree_size[node] = size
  size
}

///|
/// Reorder adjacency list to put heavy child first
fn hld_reorder(hld : HLD, node : Int, par : Int) -> Unit {
  let mut heavy_idx = -1
  let mut max_size = 0

  for i = 0; i < hld.adj[node].length(); i = i + 1 {
    let child = hld.adj[node][i]
    if child != par && hld.subtree_size[child] > max_size {
      max_size = hld.subtree_size[child]
      heavy_idx = i
    }
  }

  // Swap heavy child to front
  if heavy_idx > 0 {
    let tmp = hld.adj[node][0]
    hld.adj[node][0] = hld.adj[node][heavy_idx]
    hld.adj[node][heavy_idx] = tmp
  }

  // Recurse
  for i = 0; i < hld.adj[node].length(); i = i + 1 {
    let child = hld.adj[node][i]
    if child != par {
      hld_reorder(hld, child, node)
    }
  }
}

///|
/// Second DFS: decompose into heavy chains
fn hld_dfs2(hld : HLD, node : Int, par : Int, pos : Int) -> Int {
  hld.chain_pos[node] = pos
  hld.chain_arr[pos] = node

  // Process heavy child first (stays in same chain)
  let next_pos = for i = 0, curr_pos = pos + 1; i < hld.adj[node].length(); {
    let child = hld.adj[node][i]
    if child != par {
      if i == 0 {
        // Heavy child: same chain
        hld.chain_head[child] = hld.chain_head[node]
        let new_pos = hld_dfs2(hld, child, node, curr_pos)
        continue i + 1, new_pos
      } else {
        // Light child: new chain
        hld.chain_head[child] = child
        let new_pos = hld_dfs2(hld, child, node, curr_pos)
        continue i + 1, new_pos
      }
    } else {
      continue i + 1, curr_pos
    }
  } else {
    curr_pos
  }

  next_pos
}

///|
fn HLD::build(self : HLD, root : Int) -> Unit {
  let _ = hld_dfs1(self, root, -1, 0)
  hld_reorder(self, root, -1)
  self.chain_head[root] = root
  let _ = hld_dfs2(self, root, -1, 0)

}

///|
/// Find LCA using HLD
fn HLD::lca(self : HLD, u : Int, v : Int) -> Int {
  for a = u, b = v; ; {
    // Move the deeper chain head up
    if self.depth[self.chain_head[a]] > self.depth[self.chain_head[b]] {
      continue self.parent[self.chain_head[a]], b
    } else if self.depth[self.chain_head[a]] < self.depth[self.chain_head[b]] {
      continue a, self.parent[self.chain_head[b]]
    } else {
      // Same chain head
      if self.chain_head[a] == self.chain_head[b] {
        // Same chain, return shallower node
        break if self.depth[a] < self.depth[b] { a } else { b }
      } else {
        // Different chains at same depth, move both up
        continue self.parent[self.chain_head[a]], self.parent[self.chain_head[b]]
      }
    }
  }
}

///|
/// Get distance between two nodes
fn HLD::distance(self : HLD, u : Int, v : Int) -> Int {
  let l = self.lca(u, v)
  self.depth[u] + self.depth[v] - 2 * self.depth[l]
}

///|
/// Get path from u to v as array of nodes
fn HLD::get_path(self : HLD, u : Int, v : Int) -> Array[Int] {
  let l = self.lca(u, v)
  let path : Array[Int] = []

  // u to lca
  for curr = u; curr != l; {
    path.push(curr)
    continue self.parent[curr]
  }
  path.push(l)

  // lca to v (reversed)
  let v_to_lca : Array[Int] = []
  for curr = v; curr != l; {
    v_to_lca.push(curr)
    continue self.parent[curr]
  }

  // Append in reverse
  for i = v_to_lca.length() - 1; i >= 0; {
    path.push(v_to_lca[i])
    continue i - 1
  }

  path
}

///|
/// Check if node a is ancestor of node b
fn HLD::is_ancestor(self : HLD, a : Int, b : Int) -> Bool {
  self.lca(a, b) == a
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "hld build and lca" {
  let hld = HLD::new(7)
  // Tree:
  //       0
  //      / \
  //     1   2
  //    /|   |\
  //   3 4  5 6
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
}

///|
test "hld distance" {
  let hld = HLD::new(7)
  hld.add_edge(0, 1)
  hld.add_edge(0, 2)
  hld.add_edge(1, 3)
  hld.add_edge(1, 4)
  hld.add_edge(2, 5)
  hld.add_edge(2, 6)

  hld.build(0)

  inspect(hld.distance(3, 4), content="2")
  inspect(hld.distance(3, 5), content="4")
  inspect(hld.distance(0, 6), content="2")
}

///|
test "hld path" {
  let hld = HLD::new(5)
  // Linear: 0 - 1 - 2 - 3 - 4
  hld.add_edge(0, 1)
  hld.add_edge(1, 2)
  hld.add_edge(2, 3)
  hld.add_edge(3, 4)

  hld.build(0)

  let path = hld.get_path(0, 4)
  inspect(path.length(), content="5")
  inspect(path[0], content="0")
  inspect(path[4], content="4")
}

///|
test "hld is ancestor" {
  let hld = HLD::new(4)
  hld.add_edge(0, 1)
  hld.add_edge(1, 2)
  hld.add_edge(1, 3)

  hld.build(0)

  inspect(hld.is_ancestor(0, 2), content="true")
  inspect(hld.is_ancestor(1, 3), content="true")
  inspect(hld.is_ancestor(2, 3), content="false")
}

///|
test "hld single node" {
  let hld = HLD::new(1)
  hld.build(0)

  inspect(hld.lca(0, 0), content="0")
  inspect(hld.distance(0, 0), content="0")
}

///|
test "hld chain positions" {
  let hld = HLD::new(5)
  hld.add_edge(0, 1)
  hld.add_edge(1, 2)
  hld.add_edge(2, 3)
  hld.add_edge(3, 4)

  hld.build(0)

  // In a linear tree, should form one heavy chain
  // All nodes should have same chain head (0)
  for i = 0; i < 5; i = i + 1 {
    inspect(hld.chain_head[i], content="0")
  }
}
