// ============================================================================
// LINK-CUT TREES - Dynamic Tree Operations with O(log n) Amortized Time
// ============================================================================
//
// Link-Cut Trees (Sleator & Tarjan, 1983) maintain a forest of rooted trees
// supporting dynamic connectivity operations:
//
// KEY OPERATIONS:
// - link(u, v): Make u a child of v (trees must be in different components)
// - cut(u): Remove the edge from u to its parent
// - find_root(u): Find the root of u's tree
// - path_query(u): Query aggregate value on path from u to root
// - lca(u, v): Find lowest common ancestor
//
// CORE IDEA: Represent each tree as a set of "preferred paths" (heavy paths).
// Each preferred path is stored in a splay tree ordered by depth.
//
// STRUCTURE:
// 1. Each node has at most one "preferred child" (forming preferred paths)
// 2. Preferred paths are stored in auxiliary splay trees (keyed by depth)
// 3. Splay trees are connected by "path-parent" pointers
//
// TIME COMPLEXITY: O(log n) amortized per operation
//
// INVARIANTS:
// 1. Preferred Path: Each preferred path is a contiguous path in original tree
// 2. Splay Order: Nodes in splay tree are ordered by depth (ancestors left)
// 3. Path Parent: Root of splay tree has path-parent to node above it
// 4. Access Property: After access(v), path from v to root is one preferred path

///|
/// Node in the Link-Cut Tree
/// Uses splay tree for preferred path representation
priv struct LCTNode {
  mut parent : Int // Parent in splay tree (-1 if root of splay tree)
  mut left : Int // Left child in splay tree (-1 if none)
  mut right : Int // Right child in splay tree (-1 if none)
  mut path_parent : Int // Path-parent pointer (-1 if none)
  mut reversed : Bool // Lazy propagation flag for subtree reversal
  // Data fields
  mut value : Int // Node value
  mut subtree_sum : Int // Aggregate for path queries
}

///|
fn LCTNode::new(value : Int) -> LCTNode {
  {
    parent: -1,
    left: -1,
    right: -1,
    path_parent: -1,
    reversed: false,
    value,
    subtree_sum: value,
  }
}

///|
/// Link-Cut Tree data structure
priv struct LinkCutTree {
  nodes : Array[LCTNode]
}

///|
fn LinkCutTree::new(n : Int) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for i = 0; i < n; i = i + 1 {
    nodes.push(LCTNode::new(0))
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init nodes):
      #|nodes[0..i) are initialized with default values.
      #|MAINTENANCE:
      #|Push a freshly initialized node for index i.
      #|TERMINATION:
      #|At i = n, all nodes are initialized.
    ),
  }
  { nodes, }
}

///|
/// Create Link-Cut Tree with initial values
fn LinkCutTree::with_values(values : Array[Int]) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for i = 0; i < values.length(); i = i + 1 {
    nodes.push(LCTNode::new(values[i]))
  } where {
    invariant: i >= 0 && i <= values.length(),
    reasoning: (
      #|INVARIANT (init values):
      #|nodes[0..i) reflect values[0..i) in node.value.
      #|MAINTENANCE:
      #|Push a node initialized with values[i].
      #|TERMINATION:
      #|At i = values.length(), all values are loaded.
    ),
  }
  { nodes, }
}

// ============================================================================
// SPLAY TREE OPERATIONS (Auxiliary structure for preferred paths)
// ============================================================================

///|
/// Check if node is root of its splay tree
/// A node is splay root if parent is -1 OR parent's children don't include it
fn LinkCutTree::is_splay_root(self : LinkCutTree, x : Int) -> Bool {
  let p = self.nodes[x].parent
  if p < 0 {
    true
  } else {
    self.nodes[p].left != x && self.nodes[p].right != x
  }
}

///|
/// Push down lazy reversal flag
fn LinkCutTree::push_down(self : LinkCutTree, x : Int) -> Unit {
  if self.nodes[x].reversed {
    // Swap children
    let tmp = self.nodes[x].left
    self.nodes[x].left = self.nodes[x].right
    self.nodes[x].right = tmp

    // Propagate to children
    let l = self.nodes[x].left
    let r = self.nodes[x].right
    if l >= 0 {
      self.nodes[l].reversed = not(self.nodes[l].reversed)
    }
    if r >= 0 {
      self.nodes[r].reversed = not(self.nodes[r].reversed)
    }
    self.nodes[x].reversed = false
  }
}

///|
/// Update aggregate values from children
fn LinkCutTree::push_up(self : LinkCutTree, x : Int) -> Unit {
  let l = self.nodes[x].left
  let r = self.nodes[x].right
  let mut sum = self.nodes[x].value
  if l >= 0 {
    sum = sum + self.nodes[l].subtree_sum
  }
  if r >= 0 {
    sum = sum + self.nodes[r].subtree_sum
  }
  self.nodes[x].subtree_sum = sum
}

///|
/// Rotate node x up (zig or zag)
/// Maintains splay tree structure and updates aggregates
fn LinkCutTree::rotate(self : LinkCutTree, x : Int) -> Unit {
  let y = self.nodes[x].parent
  let z = self.nodes[y].parent
  let is_left = self.nodes[y].left == x

  // x takes y's place
  if z >= 0 {
    if self.nodes[z].left == y {
      self.nodes[z].left = x
    } else if self.nodes[z].right == y {
      self.nodes[z].right = x
    }
    // else z is path-parent, handled separately
  }

  // Move appropriate child of x to y
  if is_left {
    self.nodes[y].left = self.nodes[x].right
    if self.nodes[x].right >= 0 {
      self.nodes[self.nodes[x].right].parent = y
    }
    self.nodes[x].right = y
  } else {
    self.nodes[y].right = self.nodes[x].left
    if self.nodes[x].left >= 0 {
      self.nodes[self.nodes[x].left].parent = y
    }
    self.nodes[x].left = y
  }
  self.nodes[y].parent = x
  self.nodes[x].parent = z

  // Transfer path-parent from y to x
  self.nodes[x].path_parent = self.nodes[y].path_parent
  self.nodes[y].path_parent = -1

  // Update aggregates (y first, then x since x is now y's parent)
  self.push_up(y)
  self.push_up(x)
}

///|
/// Splay node x to root of its splay tree
/// This is the key operation for amortized O(log n) guarantee
fn LinkCutTree::splay(self : LinkCutTree, x : Int) -> Unit {
  // First, push down all lazy values on path from splay root to x
  self.push_down_path(x)

  // Splay until x is root of its splay tree
  for ; not(self.is_splay_root(x)); {
    let y = self.nodes[x].parent
    if self.is_splay_root(y) {
      // Zig: y is splay root, one rotation
      self.rotate(x)
    } else {
      let z = self.nodes[y].parent
      let x_is_left = self.nodes[y].left == x
      let y_is_left = self.nodes[z].left == y
      if x_is_left == y_is_left {
        // Zig-zig: same direction, rotate y first
        self.rotate(y)
        self.rotate(x)
      } else {
        // Zig-zag: different directions, rotate x twice
        self.rotate(x)
        self.rotate(x)
      }
    }
  } where {
    invariant: x >= 0,
    reasoning: (
      #|SPLAY INVARIANT:
      #|
      #|1. Each iteration moves x closer to splay root
      #|   - Zig: x becomes root
      #|   - Zig-zig/zig-zag: x's depth decreases by 2
      #|
      #|2. Splay tree structure is maintained:
      #|   - In-order traversal unchanged (depth ordering preserved)
      #|   - Parent/child pointers consistent
      #|
      #|3. Amortized O(log n): Sleator-Tarjan potential function analysis
      #|   Potential = sum of log(size of subtree) for all nodes
      #|   Each splay pays O(3 * (new_potential - old_potential) + 1)
      #|MAINTENANCE:
      #|Each rotation preserves in-order structure while moving x upward.
      #|TERMINATION:
      #|x's depth strictly decreases until it becomes splay root.
    ),
  }
}

///|
/// Push down lazy values on path from splay root to x
fn LinkCutTree::push_down_path(self : LinkCutTree, x : Int) -> Unit {
  // Collect ancestors first (need to push from top down)
  let path : Array[Int] = []
  for node = x; not(self.is_splay_root(node)); {
    path.push(node)
    continue self.nodes[node].parent
  } else {
    path.push(node)
  } where {
    invariant: node >= 0 && node < self.nodes.length(),
    reasoning: (
      #|INVARIANT (collect path):
      #|node is a valid ancestor on the path from x to the splay root.
      #|MAINTENANCE:
      #|Move to the parent until the splay root is reached.
      #|TERMINATION:
      #|At the root, the full path is collected.
    ),
  }

  // Push down from root to x
  for i = path.length() - 1; i >= 0; i = i - 1 {
    self.push_down(path[i])
  } where {
    invariant: i >= -1 && i < path.length(),
    reasoning: (
      #|INVARIANT (push down path):
      #|Lazy flags are pushed for nodes above index i in path.
      #|MAINTENANCE:
      #|Push down at path[i] to propagate reversals to its children.
      #|TERMINATION:
      #|At i = -1, all nodes on the path are pushed down.
    ),
  }
}

// ============================================================================
// ACCESS OPERATION - The Core of Link-Cut Trees
// ============================================================================

///|
/// Access operation: Make path from v to root a single preferred path
/// After access(v), v is the splay root of the preferred path containing root
///
/// This is THE fundamental operation - all others build on this
fn LinkCutTree::access(self : LinkCutTree, v : Int) -> Unit {
  // Splay v in its current splay tree
  self.splay(v)

  // Detach v's right subtree (these are descendants in current preferred path)
  // They become non-preferred children
  if self.nodes[v].right >= 0 {
    self.nodes[self.nodes[v].right].path_parent = v
    self.nodes[self.nodes[v].right].parent = -1
    self.nodes[v].right = -1
    self.push_up(v)
  }

  // Walk up through path-parent pointers, splicing v's path into each tree
  for ; self.nodes[v].path_parent >= 0; {
    let w = self.nodes[v].path_parent
    self.splay(w)

    // Detach w's current right subtree
    if self.nodes[w].right >= 0 {
      self.nodes[self.nodes[w].right].path_parent = w
      self.nodes[self.nodes[w].right].parent = -1
    }

    // Attach v's tree as w's right subtree
    self.nodes[w].right = v
    self.nodes[v].parent = w
    self.nodes[v].path_parent = -1
    self.push_up(w)

    // Now splay v again (it's in a larger splay tree now)
    self.splay(v)
  } where {
    invariant: v >= 0,
    reasoning: (
      #|ACCESS INVARIANT:
      #|
      #|1. Loop processes path-parent chain from v to original tree root
      #|   - path_parent points to node directly above in original tree
      #|   - Each iteration "splices" one path-parent link
      #|
      #|2. After each iteration:
      #|   - v is in a splay tree containing more of the path to root
      #|   - v's path_parent points to next node up (or -1 if done)
      #|
      #|3. After access completes:
      #|   - Path from v to tree root is one continuous preferred path
      #|   - v is at the root of this path's splay tree
      #|   - v has no right child (it's the deepest node on preferred path)
      #|
      #|4. Time: O(log n) amortized
      #|   - Each splay is O(log n) amortized
      #|   - Number of splays = number of preferred child changes on path
      #|   - Amortized O(1) preferred child changes per access
      #|MAINTENANCE:
      #|Each splice replaces w's right subtree with v, extending the preferred
      #|path by one ancestor step.
      #|TERMINATION:
      #|path_parent moves upward and becomes -1 at the tree root.
    ),
  }
}

// ============================================================================
// LINK-CUT TREE OPERATIONS
// ============================================================================

///|
/// Find root of the tree containing v
/// Returns the root node index
fn LinkCutTree::find_root(self : LinkCutTree, v : Int) -> Int {
  self.access(v)

  // After access, root is leftmost node in v's splay tree
  // (splay trees ordered by depth, root has minimum depth)
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
      #|1. After access(v), the splay tree contains path from v to tree root
      #|2. Splay trees are ordered by depth (shallower = left)
      #|3. Tree root has minimum depth → it's the leftmost node
      #|4. We traverse left children until we reach leftmost node
      #|MAINTENANCE:
      #|Moving to the left child keeps us on the shallowest path.
      #|TERMINATION:
      #|When no left child exists, we are at the leftmost (tree root) node.
    ),
  }

  // Splay root to maintain good structure
  self.splay(root)
  root
}

///|
/// Cut v from its parent in the original tree
/// After cut, v is the root of its own tree
fn LinkCutTree::cut(self : LinkCutTree, v : Int) -> Unit {
  self.access(v)

  // After access, v's parent in original tree is the rightmost node
  // in v's left subtree (if it exists)
  if self.nodes[v].left >= 0 {
    self.nodes[self.nodes[v].left].parent = -1
    self.nodes[v].left = -1
    self.push_up(v)
  }
}

///|
/// Link v as a child of w (v must be a tree root)
fn LinkCutTree::link(self : LinkCutTree, v : Int, w : Int) -> Unit {
  self.access(v)
  self.access(w)

  // After access(v), v should have no left child (it's tree root)
  // We make w the left child of v (w becomes v's parent in original tree)
  self.nodes[v].left = w
  self.nodes[w].parent = v
  self.push_up(v)
}

///|
/// Check if u and v are in the same tree
fn LinkCutTree::connected(self : LinkCutTree, u : Int, v : Int) -> Bool {
  if u == v {
    return true
  }
  self.access(u)
  self.access(v)
  // After both accesses, check if they share a root
  // u has a path-parent or is in same splay tree as v
  self.nodes[u].parent >= 0 || self.nodes[u].path_parent >= 0
}

///|
/// Query sum on path from v to root
fn LinkCutTree::path_sum(self : LinkCutTree, v : Int) -> Int {
  self.access(v)
  self.nodes[v].subtree_sum
}

///|
/// Update value at node v
fn LinkCutTree::update_value(self : LinkCutTree, v : Int, value : Int) -> Unit {
  self.access(v)
  self.nodes[v].value = value
  self.push_up(v)
}

// ============================================================================
// LOWEST COMMON ANCESTOR
// ============================================================================

///|
/// Find LCA of u and v in the represented forest
/// Returns -1 if u and v are in different trees
fn LinkCutTree::lca(self : LinkCutTree, u : Int, v : Int) -> Int {
  if u == v {
    return u
  }
  self.access(u)
  self.access(v)

  // After access(v), check if u is still connected
  if self.nodes[u].parent < 0 && self.nodes[u].path_parent < 0 {
    return -1 // Different trees
  }

  // Splay u - the LCA will be where u's path meets v's path
  self.splay(u)

  // If u has a path-parent, that's the LCA
  // Otherwise, u itself is the LCA (u is an ancestor of v)
  if self.nodes[u].path_parent >= 0 {
    self.nodes[u].path_parent
  } else {
    u
  }
}

// ============================================================================
// MAKE ROOT (Re-rooting operation)
// ============================================================================

///|
/// Make v the root of its tree
/// Uses path reversal to flip the path from v to current root
fn LinkCutTree::make_root(self : LinkCutTree, v : Int) -> Unit {
  self.access(v)
  // Reverse the splay tree (flips parent-child relationships on path)
  self.nodes[v].reversed = not(self.nodes[v].reversed)
  self.push_down(v) // Immediately apply to maintain invariants
}

///|
/// Link v to w with v as child, using make_root to handle arbitrary trees
fn LinkCutTree::link_as_root(self : LinkCutTree, v : Int, w : Int) -> Unit {
  self.make_root(v)
  self.access(w)
  self.nodes[v].left = w
  self.nodes[w].parent = v
  self.push_up(v)
}

///|
/// Cut edge between u and v (when edge direction is unknown)
fn LinkCutTree::cut_edge(self : LinkCutTree, u : Int, v : Int) -> Unit {
  self.make_root(u)
  self.access(v)
  if self.nodes[v].left == u {
    self.nodes[v].left = -1
    self.nodes[u].parent = -1
    self.push_up(v)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "lct basic operations" {
  // Create a forest of 5 isolated nodes
  let lct = LinkCutTree::new(5)

  // Initially, each node is its own root
  inspect(lct.find_root(0), content="0")
  inspect(lct.find_root(1), content="1")
  inspect(lct.find_root(2), content="2")

  // Link: 1 -> 0 (1 becomes child of 0)
  lct.link(1, 0)
  inspect(lct.find_root(1), content="0")
  inspect(lct.connected(0, 1), content="true")

  // Link: 2 -> 1 (2 becomes child of 1)
  lct.link(2, 1)
  inspect(lct.find_root(2), content="0")
  inspect(lct.connected(0, 2), content="true")
}

///|
test "lct cut operation" {
  let lct = LinkCutTree::new(4)

  // Build tree: 0 <- 1 <- 2 <- 3
  lct.link(1, 0)
  lct.link(2, 1)
  lct.link(3, 2)
  inspect(lct.find_root(3), content="0")

  // Cut 2 from 1
  lct.cut(2)

  // Now 2 and 3 are in separate tree from 0 and 1
  inspect(lct.find_root(3), content="2")
  inspect(lct.find_root(1), content="0")
  inspect(lct.connected(1, 3), content="false")
}

///|
test "lct path sum" {
  let values = [10, 20, 30, 40, 50]
  let lct = LinkCutTree::with_values(values)

  // Build tree: 0 <- 1 <- 2 <- 3 <- 4
  lct.link(1, 0)
  lct.link(2, 1)
  lct.link(3, 2)
  lct.link(4, 3)

  // Path sum from 4 to root (0): 10 + 20 + 30 + 40 + 50 = 150
  inspect(lct.path_sum(4), content="150")

  // Path sum from 2 to root (0): 10 + 20 + 30 = 60
  inspect(lct.path_sum(2), content="60")

  // Path sum from 0 to root (0): just 10
  inspect(lct.path_sum(0), content="10")
  lct.update_value(2, 100)
  inspect(lct.path_sum(4), content="220")
}

///|
test "lct lca" {
  let lct = LinkCutTree::new(7)

  // Build tree:
  //       0
  //      / \
  //     1   2
  //    / \   \
  //   3   4   5
  //       |
  //       6
  lct.link(1, 0)
  lct.link(2, 0)
  lct.link(3, 1)
  lct.link(4, 1)
  lct.link(5, 2)
  lct.link(6, 4)

  // LCA of 3 and 4 is 1
  inspect(lct.lca(3, 4), content="1")

  // LCA of 3 and 5 is 0
  inspect(lct.lca(3, 5), content="0")

  // LCA of 6 and 3 is 1
  inspect(lct.lca(6, 3), content="1")
}

///|
test "lct make root" {
  let lct = LinkCutTree::new(4)

  // Build tree: 0 <- 1 <- 2 <- 3
  lct.link(1, 0)
  lct.link(2, 1)
  lct.link(3, 2)
  inspect(lct.find_root(3), content="0")

  // Make 2 the new root
  lct.make_root(2)
  inspect(lct.find_root(3), content="2")
  inspect(lct.find_root(0), content="2")
}

///|
test "lct stress test" {
  let n = 50
  let lct = LinkCutTree::new(n)

  // Build a path: 0 <- 1 <- 2 <- ... <- 49
  for i = 1; i < n; i = i + 1 {
    lct.link(i, i - 1)
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|INVARIANT (build chain):
      #|Nodes [0..i) form a single chain rooted at 0.
      #|MAINTENANCE:
      #|Link node i to i-1 to extend the chain by one.
      #|TERMINATION:
      #|At i = n, the full chain is built.
    ),
  }

  // All should have root 0
  for i = 0; i < n; i = i + 1 {
    guard lct.find_root(i) == 0 else { fail("Wrong root") }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (verify roots):
      #|Nodes [0..i) have been verified to share root 0.
      #|MAINTENANCE:
      #|Check node i and advance.
      #|TERMINATION:
      #|At i = n, all nodes are verified in the same tree.
    ),
  }

  // Cut in the middle
  lct.cut(25)

  // Nodes 0-24 have root 0, nodes 25-49 have root 25
  inspect(lct.find_root(24), content="0")
  inspect(lct.find_root(25), content="25")
  inspect(lct.find_root(49), content="25")
  inspect(lct.connected(24, 25), content="false")
}

// ============================================================================
// DYNAMIC CONNECTIVITY WITH LINK-CUT TREES
// ============================================================================

///|
/// Dynamic forest supporting link/cut/connected queries
priv struct DynamicForest {
  lct : LinkCutTree
}

///|
fn DynamicForest::new(n : Int) -> DynamicForest {
  { lct: LinkCutTree::new(n) }
}

///|
fn DynamicForest::link(self : DynamicForest, u : Int, v : Int) -> Bool {
  // Check if already connected
  if self.lct.connected(u, v) {
    return false // Would create a cycle
  }
  self.lct.link_as_root(u, v)
  true
}

///|
fn DynamicForest::cut(self : DynamicForest, u : Int, v : Int) -> Bool {
  // Check if edge exists
  if not(self.lct.connected(u, v)) {
    return false
  }
  self.lct.cut_edge(u, v)
  true
}

///|
fn DynamicForest::connected(self : DynamicForest, u : Int, v : Int) -> Bool {
  self.lct.connected(u, v)
}

///|
test "dynamic forest" {
  let forest = DynamicForest::new(5)

  // Initially disconnected
  inspect(forest.connected(0, 1), content="false")

  // Link 0-1
  inspect(forest.link(0, 1), content="true")
  inspect(forest.connected(0, 1), content="true")

  // Link 1-2, 2-3, 3-4
  let _ = forest.link(1, 2)
  let _ = forest.link(2, 3)
  let _ = forest.link(3, 4)
  inspect(forest.connected(0, 4), content="true")

  // Cut 2-3
  inspect(forest.cut(2, 3), content="true")
  inspect(forest.connected(0, 2), content="true")
  inspect(forest.connected(3, 4), content="true")
  inspect(forest.connected(0, 4), content="false")
}
