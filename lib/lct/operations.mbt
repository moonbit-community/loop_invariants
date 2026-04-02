// ============================================================================
// LCT - Tree Operations
// ============================================================================
//
// This module contains the main Link-Cut Tree operations built on access:
//   - find_root: Find the root of a node's tree
//   - cut: Remove edge from node to its parent
//   - link: Add edge making one node child of another
//   - connected: Check if two nodes are in same tree
//   - lca: Find lowest common ancestor
//   - make_root: Re-root a tree at a given node
//   - path_sum: Query aggregate on path to root
//
// All operations are O(log n) amortized.

///|
/// Find root of the tree containing v.
///
/// ALGORITHM:
/// ```
///   1. access(v): Path from v to root becomes one splay tree
///   2. Find leftmost node in splay tree (minimum depth = root)
///   3. Splay the root for good amortization
/// ```
///
/// WHY LEFTMOST = ROOT:
/// ```
///   In LCT splay trees, nodes are ordered by depth:
///     - Left = shallower (closer to tree root)
///     - Right = deeper (further from tree root)
///
///   After access(v), the splay tree contains the path from v to root.
///   The tree root has minimum depth, so it's the leftmost node.
/// ```
pub fn LinkCutTree::find_root(self : LinkCutTree, v : Int) -> Int {
  self.access(v)

  // Find leftmost node (minimum depth = tree root)
  let root = for node = v {
    self.push_down(node)
    if self.nodes[node].left < 0 {
      break node
    } else {
      continue self.nodes[node].left
    }
  } where {
    invariant: node >= 0,
    reasoning: (
      #|FIND ROOT INVARIANT:
      #|
      #|  node is on the path from v toward the tree root.
      #|  We traverse left children to find the shallowest node.
      #|
      #|WHY PUSH_DOWN:
      #|  Reversal flags might swap left/right children.
      #|  Must push before accessing left child.
      #|
      #|MAINTENANCE:
      #|  Move to left child if it exists.
      #|
      #|TERMINATION:
      #|  When left is -1, node is the leftmost = tree root.
    ),
  }

  // Splay the root for amortized efficiency
  self.splay(root)
  root
}

///|
/// Cut v from its parent in the original tree.
///
/// ALGORITHM:
/// ```
///   1. access(v): Path from v to root is one splay tree, v is root
///   2. Detach v's left subtree (contains all ancestors)
///   3. v is now root of its own tree
/// ```
///
/// PRECONDITION: v has a parent (is not already a tree root)
pub fn LinkCutTree::cut(self : LinkCutTree, v : Int) -> Unit {
  self.access(v)

  // After access, v's ancestors are in left subtree
  // Detach them to separate v from its parent
  if self.nodes[v].left >= 0 {
    self.nodes[self.nodes[v].left].parent = -1
    self.nodes[v].left = -1
    self.push_up(v)
  }
}

///|
/// Link v as a child of w (v must be a tree root).
///
/// ALGORITHM:
/// ```
///   1. access(v): v becomes splay root
///   2. access(w): w becomes splay root
///   3. Make w the left child of v
///      (w is now "shallower" = parent in original tree)
/// ```
///
/// PRECONDITION: v is root of its tree (no parent)
/// PRECONDITION: v and w are in different trees
pub fn LinkCutTree::link(self : LinkCutTree, v : Int, w : Int) -> Unit {
  self.access(v)
  self.access(w)

  // Make w the left child of v
  // In splay tree order: w (parent, shallower) is left of v (child, deeper)
  self.nodes[v].left = w
  self.nodes[w].parent = v
  self.push_up(v)
}

///|
/// Check if u and v are in the same tree.
///
/// ALGORITHM:
/// ```
///   1. access(u): u becomes splay root of path to root
///   2. access(v): v becomes splay root of path to root
///   3. If u now has parent or path_parent, they share a root
/// ```
///
/// WHY THIS WORKS:
/// ```
///   After access(u), u is root of its path's splay tree.
///   After access(v), v is root of its path's splay tree.
///
///   If u and v are in same tree:
///   - v's access will extend the preferred path through u
///   - u will now have a parent (part of v's splay tree)
///   - OR u will have path_parent (connected to v's path)
///
///   If u and v are in different trees:
///   - v's access doesn't affect u's tree
///   - u remains isolated (parent = path_parent = -1)
/// ```
pub fn LinkCutTree::connected(self : LinkCutTree, u : Int, v : Int) -> Bool {
  if u == v {
    return true
  }
  self.access(u)
  self.access(v)
  // If u has any upward connection, they share a tree
  self.nodes[u].parent >= 0 || self.nodes[u].path_parent >= 0
}

///|
/// Query sum on path from v to root.
///
/// ALGORITHM:
/// ```
///   1. access(v): Path from v to root is one splay tree
///   2. Return v's subtree_sum (includes entire path)
/// ```
pub fn LinkCutTree::path_sum(self : LinkCutTree, v : Int) -> Int {
  self.access(v)
  self.nodes[v].subtree_sum
}

///|
/// Update value at node v.
pub fn LinkCutTree::update_value(
  self : LinkCutTree,
  v : Int,
  value : Int,
) -> Unit {
  self.access(v)
  self.nodes[v].value = value
  self.push_up(v)
}

///|
/// Find LCA of u and v in the represented forest.
///
/// ALGORITHM:
/// ```
///   1. access(u): Path from u to root is preferred
///   2. access(v): Path from v to root is preferred
///   3. If u and v are in different trees, return -1
///   4. Splay u: u moves to where its path meets v's path
///   5. If u has path_parent, that's the LCA; otherwise u is LCA
/// ```
///
/// WHY THIS WORKS:
/// ```
///   After access(u), the path u→root is one splay tree.
///   After access(v), the path v→root is one splay tree.
///
///   If paths share vertices (common ancestors):
///   - v's access may have changed u's splay tree
///   - u might now have a path_parent (the LCA split the path)
///   - Or u is on v's path (u is an ancestor of v)
///
///   Splaying u positions it correctly:
///   - If u.path_parent exists: that node is where paths diverged = LCA
///   - If u.path_parent == -1: u itself is the LCA (u is ancestor of v)
/// ```
///
/// RETURNS: LCA node index, or -1 if u and v are in different trees
pub fn LinkCutTree::lca(self : LinkCutTree, u : Int, v : Int) -> Int {
  if u == v {
    return u
  }
  self.access(u)
  self.access(v)

  // Check if u is still connected to tree (same tree as v)
  if self.nodes[u].parent < 0 && self.nodes[u].path_parent < 0 {
    return -1 // Different trees
  }

  // Splay u to find where it meets v's path
  self.splay(u)

  // If u has path_parent, that's the LCA
  // Otherwise u itself is the LCA
  if self.nodes[u].path_parent >= 0 {
    self.nodes[u].path_parent
  } else {
    u
  }
}

///|
/// Make v the root of its tree.
///
/// ALGORITHM:
/// ```
///   1. access(v): Path from v to root is one splay tree
///   2. Reverse the splay tree (flips parent-child relationships)
///   3. v is now the shallowest node = new tree root
/// ```
///
/// HOW REVERSAL WORKS:
/// ```
///   Splay tree is ordered by depth (left = shallow, right = deep).
///   Reversing the tree inverts this ordering.
///
///   Before: root ← ... ← v  (root is leftmost, v is rightmost)
///   After:  v ← ... ← root  (v is leftmost, root is rightmost)
///
///   In original tree terms:
///   - Old parent-child edges on path are reversed
///   - v becomes new root, old root becomes descendant
/// ```
pub fn LinkCutTree::make_root(self : LinkCutTree, v : Int) -> Unit {
  self.access(v)
  // Toggle reversal flag (will flip the path orientation)
  self.nodes[v].reversed = !self.nodes[v].reversed
  self.push_down(v) // Apply immediately to maintain invariants
}

///|
/// Link v to w, making v a child of w.
/// Unlike basic link, this handles arbitrary trees by re-rooting first.
///
/// ALGORITHM:
/// ```
///   1. make_root(v): v becomes root of its tree
///   2. access(w): w is on preferred path
///   3. link v under w
/// ```
fn LinkCutTree::link_as_root(self : LinkCutTree, v : Int, w : Int) -> Unit {
  self.make_root(v)
  self.access(w)
  self.nodes[v].left = w
  self.nodes[w].parent = v
  self.push_up(v)
}

///|
/// Cut edge between u and v (when edge direction is unknown).
///
/// ALGORITHM:
/// ```
///   1. make_root(u): u becomes root, so if u-v edge exists, v is child
///   2. access(v): v is on path from v to u (which is now root)
///   3. If v.left == u, there was an edge; cut it
/// ```
fn LinkCutTree::cut_edge(self : LinkCutTree, u : Int, v : Int) -> Unit {
  self.make_root(u)
  self.access(v)
  if self.nodes[v].left == u {
    self.nodes[v].left = -1
    self.nodes[u].parent = -1
    self.push_up(v)
  }
}
