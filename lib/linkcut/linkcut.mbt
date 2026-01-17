// ============================================================================
// LINK-CUT TREE - Dynamic Tree Connectivity with Path Queries
// ============================================================================
//
// Link-Cut Tree is a data structure for maintaining a forest of trees that
// supports dynamic linking/cutting of edges and path queries/updates.
//
// KEY INSIGHT: Decompose tree into "preferred paths" - vertical chains where
// each node prefers one child. These paths are stored in auxiliary splay trees.
// Non-preferred edges are represented by "path-parent" pointers.
//
// STRUCTURE:
// - Each node belongs to exactly one auxiliary splay tree (representing preferred path)
// - Splay tree keys: depth in represented tree (deeper = larger)
// - Left child in splay = nodes higher on preferred path
// - Right child in splay = nodes lower on preferred path
// - Path-parent: points to top of preferred path above this one
//
// EXAMPLE:
// Represented tree:     After access(F):
//       A                 Preferred path: A-B-D-F
//      / \                Splay tree: A <- B <- D <- F
//     B   C                          (where <- means "right child")
//    /|\
//   D E F              C and E become separate splay trees with path-parent
//                      pointing to B
//
// OPERATIONS:
// - access(v): Make v-to-root path preferred, O(log n) amortized
// - link(u, v): Make u child of v (u must be tree root), O(log n) amortized
// - cut(v): Remove edge from v to its parent, O(log n) amortized
// - find_root(v): Find root of v's tree, O(log n) amortized
// - lca(u, v): Lowest common ancestor, O(log n) amortized
//
// INVARIANTS:
// 1. In-order traversal of splay tree gives path top-to-bottom
// 2. Each splay tree represents a maximal preferred path
// 3. Path-parent pointers connect splay trees along represented tree edges
// 4. Splay operations maintain BST property on depth

///|
/// Link-Cut Tree node
priv struct LCTNode {
  mut parent : Int // Parent in splay tree (-1 if root of splay tree)
  mut left : Int // Left child in splay tree
  mut right : Int // Right child in splay tree
  mut path_parent : Int // Parent of this splay tree's root in represented tree
  mut flip : Bool // Lazy flip flag for makeroot operation
  mut value : Int64 // Node value
  mut path_sum : Int64 // Sum of values on path (in this splay subtree)
}

///|
/// Link-Cut Tree forest
priv struct LinkCutTree {
  nodes : Array[LCTNode]
}

///|
fn LinkCutTree::new(n : Int) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for i = 0; i < n; i = i + 1 {
    nodes.push({
      parent: -1,
      left: -1,
      right: -1,
      path_parent: -1,
      flip: false,
      value: 0L,
      path_sum: 0L,
    })
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init nodes):
      #|nodes[0..i) are initialized with default values.
      #|MAINTENANCE:
      #|Push a node initialized with zero value and empty pointers.
      #|TERMINATION:
      #|At i = n, all nodes are initialized.
    ),
  }
  { nodes, }
}

///|
/// Check if node is root of its splay tree
fn LinkCutTree::is_splay_root(self : LinkCutTree, v : Int) -> Bool {
  let node = self.nodes[v]
  if node.parent < 0 {
    return true
  }
  let parent = self.nodes[node.parent]
  parent.left != v && parent.right != v
}

///|
/// Push down lazy flip flag
fn LinkCutTree::push_down(self : LinkCutTree, v : Int) -> Unit {
  if v < 0 {
    return
  }
  let node = self.nodes[v]
  if node.flip {
    // Swap children
    let tmp = node.left
    self.nodes[v].left = node.right
    self.nodes[v].right = tmp

    // Propagate flip to children
    if node.left >= 0 {
      self.nodes[node.left].flip = not(self.nodes[node.left].flip)
    }
    if node.right >= 0 {
      self.nodes[node.right].flip = not(self.nodes[node.right].flip)
    }
    self.nodes[v].flip = false
  }
}

///|
/// Update node's path_sum from children
fn LinkCutTree::update(self : LinkCutTree, v : Int) -> Unit {
  if v < 0 {
    return
  }
  let node = self.nodes[v]
  let mut sum = node.value
  if node.left >= 0 {
    sum = sum + self.nodes[node.left].path_sum
  }
  if node.right >= 0 {
    sum = sum + self.nodes[node.right].path_sum
  }
  self.nodes[v].path_sum = sum
}

///|
/// Rotate node v up (zig operation in splay tree)
/// REASONING: Standard tree rotation preserving BST property
fn LinkCutTree::rotate(self : LinkCutTree, v : Int) -> Unit {
  let p = self.nodes[v].parent
  if p < 0 {
    return
  }
  let g = self.nodes[p].parent
  let p_is_left = g >= 0 && self.nodes[g].left == p

  // Push down from grandparent to ensure consistency
  if g >= 0 {
    self.push_down(g)
  }
  self.push_down(p)
  self.push_down(v)

  // Determine if v is left or right child of p
  if self.nodes[p].left == v {
    // v is left child - right rotation
    let vr = self.nodes[v].right
    self.nodes[p].left = vr
    if vr >= 0 {
      self.nodes[vr].parent = p
    }
    self.nodes[v].right = p
  } else {
    // v is right child - left rotation
    let vl = self.nodes[v].left
    self.nodes[p].right = vl
    if vl >= 0 {
      self.nodes[vl].parent = p
    }
    self.nodes[v].left = p
  }
  self.nodes[p].parent = v
  self.nodes[v].parent = g

  // Update grandparent's child pointer
  if g >= 0 {
    if p_is_left {
      self.nodes[g].left = v
    } else {
      self.nodes[g].right = v
    }
  }

  // Inherit path-parent from p
  self.nodes[v].path_parent = self.nodes[p].path_parent
  self.nodes[p].path_parent = -1

  // Update aggregates
  self.update(p)
  self.update(v)
}

///|
/// Splay node v to the root of its splay tree
/// REASONING: Standard splay operation with zig, zig-zig, zig-zag cases
fn LinkCutTree::splay(self : LinkCutTree, v : Int) -> Unit {
  // First push down from root to v
  let path : Array[Int] = []
  let mut curr = v
  while not(self.is_splay_root(curr)) {
    path.push(curr)
    curr = self.nodes[curr].parent
  }
  path.push(curr)

  // Push down along path from root to v
  for i in path.length() >.. 0 {
    self.push_down(path[i])
  }

  // Splay v to root
  // INVARIANT: Each iteration moves v closer to root
  while not(self.is_splay_root(v)) {
    let p = self.nodes[v].parent
    if not(self.is_splay_root(p)) {
      let g = self.nodes[p].parent
      let v_is_left = self.nodes[p].left == v
      let p_is_left = self.nodes[g].left == p
      if v_is_left == p_is_left {
        // Zig-zig: rotate parent first
        self.rotate(p)
        self.rotate(v)
      } else {
        // Zig-zag: rotate v twice
        self.rotate(v)
        self.rotate(v)
      }
    } else {
      // Zig: single rotation
      self.rotate(v)
    }
  }
}

///|
/// Access operation: make path from v to root a preferred path
/// Returns the last node accessed (useful for LCA)
/// REASONING: We splay v, then walk up path-parent pointers,
/// at each step making the upward edge preferred
fn LinkCutTree::access(self : LinkCutTree, v : Int) -> Int {
  self.splay(v)

  // Cut right child (make v the bottom of its preferred path)
  if self.nodes[v].right >= 0 {
    self.nodes[self.nodes[v].right].path_parent = v
    self.nodes[self.nodes[v].right].parent = -1
    self.nodes[v].right = -1
    self.update(v)
  }
  let mut last = v

  // Walk up path-parents and merge splay trees
  // INVARIANT: v is root of its splay tree
  while self.nodes[v].path_parent >= 0 {
    let w = self.nodes[v].path_parent
    last = w
    self.splay(w)

    // Cut w's right child (old preferred path below w)
    if self.nodes[w].right >= 0 {
      self.nodes[self.nodes[w].right].path_parent = w
      self.nodes[self.nodes[w].right].parent = -1
    }

    // Make v the new right child of w (new preferred path)
    self.nodes[w].right = v
    self.nodes[v].parent = w
    self.nodes[v].path_parent = -1
    self.update(w)
    self.splay(v)
  }
  last
}

///|
/// Find root of the tree containing v
fn LinkCutTree::find_root(self : LinkCutTree, v : Int) -> Int {
  let _ = self.access(v)

  // Root is leftmost node in splay tree
  // INVARIANT: Left child is higher in represented tree
  let mut root = v
  self.push_down(root)
  while self.nodes[root].left >= 0 {
    root = self.nodes[root].left
    self.push_down(root)
  }
  self.splay(root)
  root
}

///|
/// Make v the root of its tree (path reversal)
fn LinkCutTree::make_root(self : LinkCutTree, v : Int) -> Unit {
  let _ = self.access(v)
  // Flip the path (reverse it)
  self.nodes[v].flip = not(self.nodes[v].flip)
  self.push_down(v)
}

///|
/// Link: make v a child of w in the forest
/// Precondition: v and w are in different trees, v is root of its tree
fn LinkCutTree::link(self : LinkCutTree, v : Int, w : Int) -> Bool {
  // Make v root of its tree
  self.make_root(v)

  // Check if they're already in same tree
  if self.find_root(w) == v {
    return false // Already connected
  }

  // Make path from w to root preferred
  let _ = self.access(w)

  // v becomes right child of w
  self.nodes[w].right = v
  self.nodes[v].parent = w
  self.update(w)
  true
}

///|
/// Cut: remove edge between v and its parent in represented tree
fn LinkCutTree::cut_parent(self : LinkCutTree, v : Int) -> Unit {
  let _ = self.access(v)

  // v's left subtree contains its ancestors
  if self.nodes[v].left >= 0 {
    self.nodes[self.nodes[v].left].parent = -1
    self.nodes[v].left = -1
    self.update(v)
  }
}

///|
/// Cut edge between v and w (if exists)
fn LinkCutTree::cut(self : LinkCutTree, v : Int, w : Int) -> Bool {
  self.make_root(v)
  let _ = self.access(w)

  // Check if v and w are connected by an edge
  if self.nodes[w].left != v || self.nodes[v].right >= 0 {
    return false // No direct edge
  }
  self.nodes[v].parent = -1
  self.nodes[w].left = -1
  self.update(w)
  true
}

///|
/// Check if v and w are in the same tree
fn LinkCutTree::connected(self : LinkCutTree, v : Int, w : Int) -> Bool {
  if v == w {
    return true
  }
  let _ = self.access(v)
  let _ = self.access(w)
  // After access(w), v's path_parent or splay ancestor should be set if connected
  self.nodes[v].path_parent >= 0 || self.nodes[v].parent >= 0
}

///|
/// Find LCA of v and w in represented tree
/// Returns -1 if they're in different trees
fn LinkCutTree::lca(self : LinkCutTree, v : Int, w : Int) -> Int {
  if v == w {
    return v
  }
  let _ = self.access(v)
  let result = self.access(w)

  // Check if v is now in the path from w to root
  if self.nodes[v].path_parent >= 0 || self.nodes[v].parent >= 0 {
    result
  } else {
    -1
  }
}

///|
/// Set value at node v
fn LinkCutTree::set_value(self : LinkCutTree, v : Int, value : Int64) -> Unit {
  let _ = self.access(v)
  self.nodes[v].value = value
  self.update(v)
}

///|
/// Get value at node v
fn LinkCutTree::get_value(self : LinkCutTree, v : Int) -> Int64 {
  self.nodes[v].value
}

///|
/// Query path sum from v to root of its tree
fn LinkCutTree::path_sum_to_root(self : LinkCutTree, v : Int) -> Int64 {
  let _ = self.access(v)
  self.nodes[v].path_sum
}

///|
fn LinkCutTree::size(self : LinkCutTree) -> Int {
  self.nodes.length()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "linkcut basic" {
  let lct = LinkCutTree::new(5)

  // Initially all nodes are separate trees
  inspect(lct.find_root(0), content="0")
  inspect(lct.find_root(4), content="4")
}

///|
test "linkcut link and find_root" {
  let lct = LinkCutTree::new(5)

  // Build tree: 0 - 1 - 2, 3 - 4
  inspect(lct.link(1, 0), content="true")
  inspect(lct.link(2, 1), content="true")
  inspect(lct.link(4, 3), content="true")

  // All of 0, 1, 2 should have same root
  let root012 = lct.find_root(2)
  inspect(lct.find_root(0) == root012, content="true")
  inspect(lct.find_root(1) == root012, content="true")

  // 3, 4 have different root
  let root34 = lct.find_root(4)
  inspect(lct.find_root(3) == root34, content="true")
  inspect(root012 != root34, content="true")
}

///|
test "linkcut connected" {
  let lct = LinkCutTree::new(5)

  // Build tree: 0 - 1 - 2
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 1)
  inspect(lct.connected(0, 2), content="true")
  inspect(lct.connected(1, 2), content="true")
  inspect(lct.connected(0, 3), content="false")
}

///|
test "linkcut cut" {
  let lct = LinkCutTree::new(5)

  // Build tree: 0 - 1 - 2 - 3
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 1)
  let _ = lct.link(3, 2)
  inspect(lct.connected(0, 3), content="true")

  // Cut edge 1-2
  inspect(lct.cut(1, 2), content="true")

  // Now 0-1 and 2-3 are separate trees
  inspect(lct.connected(0, 1), content="true")
  inspect(lct.connected(2, 3), content="true")
  inspect(lct.connected(0, 2), content="false")
}

///|
test "linkcut lca" {
  let lct = LinkCutTree::new(7)

  // Build tree:
  //       0
  //      / \
  //     1   2
  //    / \
  //   3   4
  //  /
  // 5
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 0)
  let _ = lct.link(3, 1)
  let _ = lct.link(4, 1)
  let _ = lct.link(5, 3)

  // LCA of 5 and 4 should be 1
  // First make 0 the root
  lct.make_root(0)
  inspect(lct.lca(5, 4), content="1")

  // LCA of 3 and 4 should be 1
  lct.make_root(0)
  inspect(lct.lca(3, 4), content="1")

  // LCA of 5 and 2 should be 0
  lct.make_root(0)
  inspect(lct.lca(5, 2), content="0")
}

///|
test "linkcut path sum" {
  let lct = LinkCutTree::new(5)

  // Set values
  for i in 0..<5 {
    lct.set_value(i, (i + 1).to_int64())
  }

  // Build path: 0 - 1 - 2 - 3 - 4
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 1)
  let _ = lct.link(3, 2)
  let _ = lct.link(4, 3)

  // Make 0 the root
  lct.make_root(0)

  // Path sum from 4 to root: 1 + 2 + 3 + 4 + 5 = 15
  inspect(lct.path_sum_to_root(4), content="15")
}

///|
test "linkcut double link fails" {
  let lct = LinkCutTree::new(3)

  // First link succeeds
  inspect(lct.link(1, 0), content="true")

  // Trying to link already connected nodes fails
  inspect(lct.link(0, 1), content="false")
}

///|
test "linkcut size" {
  let lct = LinkCutTree::new(10)
  inspect(lct.size(), content="10")
}

///|
test "linkcut get value" {
  let lct = LinkCutTree::new(3)
  lct.set_value(1, 42L)
  inspect(lct.get_value(1), content="42")
}

///|
test "linkcut make root" {
  let lct = LinkCutTree::new(5)

  // Build path: 0 - 1 - 2 - 3 - 4
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 1)
  let _ = lct.link(3, 2)
  let _ = lct.link(4, 3)

  // Initially root should be 0
  lct.make_root(0)
  inspect(lct.find_root(4) == 0, content="true")

  // Make 2 the root
  lct.make_root(2)
  inspect(lct.find_root(0) == 2, content="true")
  inspect(lct.find_root(4) == 2, content="true")
}

///|
test "linkcut star topology" {
  let lct = LinkCutTree::new(6)

  // Build star: 0 is center, 1-5 are leaves
  for i = 1; i < 6; i = i + 1 {
    let _ = lct.link(i, 0)

  } where {
    invariant: i >= 1 && i <= 6,
    reasoning: (
      #|INVARIANT (build star):
      #|Leaves [1..i) are linked to the center 0.
      #|MAINTENANCE:
      #|Link leaf i to the center.
      #|TERMINATION:
      #|At i = 6, the star is fully built.
    ),
  }

  // All nodes should be in same tree
  for i = 1; i < 6; i = i + 1 {
    inspect(lct.connected(0, i), content="true")
  } where {
    invariant: i >= 1 && i <= 6,
    reasoning: (
      #|INVARIANT (verify star):
      #|Leaves [1..i) have been verified connected to the center.
      #|MAINTENANCE:
      #|Check connectivity for leaf i.
      #|TERMINATION:
      #|At i = 6, all leaves are verified connected.
    ),
  }

  // All pairs of leaves should be connected
  inspect(lct.connected(1, 5), content="true")
  inspect(lct.connected(2, 4), content="true")
}

///|
test "linkcut cut_parent" {
  let lct = LinkCutTree::new(4)

  // Build path: 0 - 1 - 2 - 3
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 1)
  let _ = lct.link(3, 2)
  inspect(lct.connected(0, 3), content="true")

  // Cut 2 from its parent (1)
  lct.make_root(0)
  lct.cut_parent(2)

  // Now 0-1 and 2-3 should be separate
  inspect(lct.connected(0, 1), content="true")
  inspect(lct.connected(2, 3), content="true")
}
