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
/// A single node in the Link-Cut Tree data structure.
///
/// Each node participates in two overlapping tree structures simultaneously:
///
/// 1. **Auxiliary splay tree** — the BST that stores one preferred path.
///    The fields `parent`, `left`, and `right` describe this structure.
///    In-order traversal of the splay tree gives the path nodes ordered
///    from shallowest (root side) to deepest.
///
/// 2. **Represented tree** — the actual forest the caller cares about.
///    When a node is the root of its splay tree (no `parent` inside the splay),
///    `path_parent` points to the node in the *next* splay tree that sits
///    immediately above the top of this preferred path in the represented tree.
///
/// Layout for a preferred path [1 - 2 - 4] with 2 as the splay root:
///
/// ```
///         2  (splay root, path_parent -> nil or upper splay tree)
///        / \
///       1   4
/// ```
///
/// Fields:
/// - `parent` — parent in the splay tree; -1 if this node is the splay root
/// - `left` — left child in the splay tree (shallower nodes in represented tree)
/// - `right` — right child in the splay tree (deeper nodes in represented tree)
/// - `path_parent` — the represented-tree parent of the *top* of this splay
///   tree; only meaningful when `parent == -1` (i.e., this node is splay root)
/// - `flip` — lazy reversal flag; when `true`, the left/right children of this
///   node (and their subtrees) must be swapped before being read
/// - `value` — caller-supplied value stored at this node
/// - `path_sum` — sum of `value` for all nodes in this node's splay subtree;
///   maintained by `update` after every structural change
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
/// A Link-Cut Tree that maintains a dynamic forest of up to `n` nodes.
///
/// The nodes are numbered 0 to n-1. Initially every node is an isolated tree
/// (no edges). Edges can be added with `link` and removed with `cut`.
///
/// All operations run in **O(log n) amortized** time via the access lemma:
/// the total number of preferred-path changes over any m operations on an
/// n-node forest is O((m + n) log n).
///
/// This type is `priv`; it is used internally by other packages that expose
/// higher-level graph algorithms.
priv struct LinkCutTree {
  nodes : Array[LCTNode]
}

///|
/// Create a new Link-Cut Tree with `n` isolated nodes (0 to n-1).
///
/// Each node starts with `value = 0`, no edges, and no preferred paths.
///
/// Parameters:
/// - `n` — the number of nodes; must be >= 0
///
/// Returns a `LinkCutTree` with `n` nodes all disconnected from each other.
fn LinkCutTree::LinkCutTree(n : Int) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for _ in 0..<n {
    nodes.push({
      parent: -1,
      left: -1,
      right: -1,
      path_parent: -1,
      flip: false,
      value: 0L,
      path_sum: 0L,
    })
  }
  { nodes, }
}

///|
/// Return `true` when `v` is the root of its auxiliary splay tree.
///
/// A node is the splay root when it has no `parent` pointer inside the splay
/// tree. Note that `parent == -1` alone is sufficient, but a node can also be
/// a splay root when its parent exists yet does not recognise `v` as either
/// child — that happens when the parent is in a *different* splay tree (i.e.,
/// the `parent` field is actually carrying a path-parent relationship encoded
/// via the splay structure).
///
/// Specifically, `v` is the splay root iff:
/// - `parent < 0`, OR
/// - `nodes[parent].left != v` AND `nodes[parent].right != v`
fn LinkCutTree::is_splay_root(self : LinkCutTree, v : Int) -> Bool {
  let node = self.nodes[v]
  if node.parent < 0 {
    return true
  }
  let parent = self.nodes[node.parent]
  parent.left != v && parent.right != v
}

///|
/// Push the lazy `flip` flag of `v` one level down to its children.
///
/// The `flip` flag means "the left and right subtrees of `v` have been
/// reversed but the swap has not been applied yet". Before reading either
/// child of `v`, call `push_down(v)` to materialise the reversal.
///
/// After `push_down(v)`:
/// - `nodes[v].flip` is `false`
/// - If `v` had a left child, that child's `flip` flag is toggled
/// - If `v` had a right child, that child's `flip` flag is toggled
/// - `v`'s `left` and `right` pointers are physically swapped
///
/// This is the standard lazy-propagation mechanism used by `make_root`.
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
      self.nodes[node.left].flip = !self.nodes[node.left].flip
    }
    if node.right >= 0 {
      self.nodes[node.right].flip = !self.nodes[node.right].flip
    }
    self.nodes[v].flip = false
  }
}

///|
/// Recompute `v.path_sum` from `v.value` and its children's `path_sum`.
///
/// Must be called on `v` after any structural change to `v`'s splay subtree
/// (rotations, child pointer updates). Children must be up-to-date before
/// calling `update(v)`.
///
/// Invariant maintained: for every node v,
///   `nodes[v].path_sum == sum of nodes[x].value for all x in v's splay subtree`
fn LinkCutTree::update(self : LinkCutTree, v : Int) -> Unit {
  if v < 0 {
    return
  }
  let node = self.nodes[v]
  let sum = node.value +
    (if node.left >= 0 { self.nodes[node.left].path_sum } else { 0L }) +
    (if node.right >= 0 { self.nodes[node.right].path_sum } else { 0L })
  self.nodes[v].path_sum = sum
}

///|
/// Perform a single splay-tree rotation that moves `v` one level up toward
/// the splay root (the "zig" step).
///
/// Let p = parent of v, g = parent of p.
///
/// If v is the left child of p (right rotation around p):
/// ```
///       p              v
///      / \            / \
///     v   R    -->   L   p
///    / \                / \
///   L   M              M   R
/// ```
/// If v is the right child of p (left rotation around p):
/// ```
///     p                  v
///    / \                / \
///   L   v      -->     p   R
///      / \            / \
///     M   R          L   M
/// ```
///
/// After the rotation:
/// - v takes p's position in the tree
/// - `path_parent` is transferred from p to v (v inherits the connection to
///   the represented tree segment above p's old splay tree)
/// - `update` is called on p first, then v, to keep `path_sum` correct
///
/// Precondition: `v` must not be a splay-tree root (i.e., it has a parent).
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
/// Splay `v` to the root of its auxiliary splay tree.
///
/// Uses the standard three-case splay strategy to achieve amortized O(log n):
///
/// - **Zig** — v's parent p is the splay root: single rotation of v.
/// - **Zig-zig** — v and p are both left children (or both right): rotate p
///   first, then rotate v. This "straightens" the path and pays for future
///   operations.
/// - **Zig-zag** — v and p are on opposite sides: rotate v twice.
///
/// Before splaying, the entire ancestor path from the splay root down to v is
/// traversed and `push_down` is called top-to-bottom so that lazy `flip` flags
/// are materialised before any rotation reads child pointers.
///
/// After `splay(v)`:
/// - `v` is the root of its splay tree (`is_splay_root(v)` returns `true`)
/// - The BST property (depth order) is preserved
/// - `path_sum` is correct for every node on the path that was rotated
fn LinkCutTree::splay(self : LinkCutTree, v : Int) -> Unit {
  // First push down from root to v
  let path : Array[Int] = []
  let curr = for curr = v; !self.is_splay_root(curr); {
    path.push(curr)
    continue self.nodes[curr].parent
  } nobreak {
    curr
  }
  path.push(curr)

  // Push down along path from root to v
  for i in path.length()>..0 {
    self.push_down(path[i])
  }

  // Splay v to root
  // INVARIANT: Each iteration moves v closer to root
  for keep_splaying = !self.is_splay_root(v); keep_splaying; {
    let p = self.nodes[v].parent
    if !self.is_splay_root(p) {
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
    continue !self.is_splay_root(v)
  }
}

///|
/// Make the path from `v` to the root of its represented tree the preferred
/// path, and splay `v` to the root of the resulting auxiliary splay tree.
///
/// Returns the last node that was splayed during the walk up through
/// path-parent pointers. This return value is the **LCA** of `v` and whatever
/// node was accessed most recently before this call (used by `lca`).
///
/// Algorithm:
/// 1. Splay `v` within its current splay tree and cut its right child
///    (detaching any preferred path that continues below `v`).
/// 2. Walk up via `path_parent` pointers. At each step:
///    a. Splay the node `w` pointed to by `path_parent`.
///    b. Cut `w`'s old right child (the previously preferred segment below w).
///    c. Attach v's splay tree as `w`'s right child (new preferred edge).
///    d. Splay `v` again to collect the extended path into one splay tree.
/// 3. Stop when `path_parent` is -1 (we have reached the root's splay tree).
///
/// Each call to `access` does O(number of preferred-path changes) rotations.
/// The amortized cost is O(log n) by the access lemma.
fn LinkCutTree::access(self : LinkCutTree, v : Int) -> Int {
  self.splay(v)

  // Cut right child (make v the bottom of its preferred path)
  if self.nodes[v].right >= 0 {
    self.nodes[self.nodes[v].right].path_parent = v
    self.nodes[self.nodes[v].right].parent = -1
    self.nodes[v].right = -1
    self.update(v)
  }
  let last = for last = v; self.nodes[v].path_parent >= 0; {
    let w = self.nodes[v].path_parent
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
    continue w
  } nobreak {
    last
  }
  last
}

///|
/// Find and return the root of the represented tree that contains node `v`.
///
/// After `access(v)`, the splay tree holds exactly the path from the
/// represented root down to `v`. The represented root is the shallowest node
/// on that path, which is the **leftmost** node in the splay tree (smallest
/// depth key). We walk left until no left child exists, then splay that node
/// to the splay-tree root for amortized efficiency.
///
/// This operation has amortized O(log n) time.
fn LinkCutTree::find_root(self : LinkCutTree, v : Int) -> Int {
  let _ = self.access(v)

  // Root is leftmost node in splay tree
  // INVARIANT: Left child is higher in represented tree
  self.push_down(v)
  let root = for root = v; self.nodes[root].left >= 0; {
    let root = self.nodes[root].left
    self.push_down(root)
    continue root
  } nobreak {
    root
  }
  self.splay(root)
  root
}

///|
/// Reroot the represented tree at node `v`, making `v` the new tree root.
///
/// Internally, `access(v)` brings the path root-to-v into one splay tree.
/// Setting `flip = true` on `v` (the splay root) lazily reverses the
/// in-order sequence of that splay tree, which corresponds to reversing
/// the direction of the root-to-v path so that v becomes the root and the
/// old root becomes a leaf.
///
/// `push_down(v)` is called immediately to apply the flip to `v`'s direct
/// children before any other operation reads them.
///
/// After `make_root(v)`, `find_root(w)` returns `v` for every node `w` in
/// the same tree.
fn LinkCutTree::make_root(self : LinkCutTree, v : Int) -> Unit {
  let _ = self.access(v)
  // Flip the path (reverse it)
  self.nodes[v].flip = !self.nodes[v].flip
  self.push_down(v)
}

///|
/// Add an edge between nodes `v` and `w`, merging their trees.
///
/// Returns `true` if the edge was added successfully.
/// Returns `false` if `v` and `w` are already in the same tree (adding the
/// edge would create a cycle).
///
/// Steps:
/// 1. `make_root(v)` — make `v` the root of its tree.
/// 2. `find_root(w)` — if the result equals `v`, they are already connected.
/// 3. `access(w)` — bring `w` to the splay root of its path.
/// 4. Attach `v` as `w`'s right (deeper) child in the splay tree, creating
///    the represented-tree edge w -> v.
///
/// Precondition: both `v` and `w` must be valid node indices in `[0, n)`.
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
/// Remove the edge between `v` and the parent of `v` in the represented tree.
///
/// This is the "cut from parent" variant. It does not require knowing which
/// node is the parent: after `access(v)`, `v`'s left child in the splay tree
/// represents all ancestors of `v` on the root-to-v path. Detaching the left
/// subtree removes exactly the edge between `v` and its immediate parent in
/// the represented tree.
///
/// If `v` is already a tree root (no parent edge), this is a no-op.
///
/// Precondition: `v` must be a valid node index in `[0, n)`.
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
/// Remove the edge between nodes `v` and `w`.
///
/// Returns `true` if the edge existed and was removed.
/// Returns `false` if no direct edge exists between `v` and `w`.
///
/// Steps:
/// 1. `make_root(v)` — v becomes the root of its tree; the v-w edge now
///    points upward from w to v (i.e., w is a child of v in the rooted tree).
///    Wait — actually after make_root(v), w's parent chain goes up to v.
///    After `access(w)`, the splay tree is [v, ..., w] and v must be w's
///    immediate left child (adjacent in the represented tree) for the edge
///    to exist without any intermediate node between them.
/// 2. Verify: `nodes[w].left == v` and `nodes[v].right < 0` (no node between
///    v and w in the splay tree).
/// 3. Detach v from w's left pointer.
///
/// Precondition: both `v` and `w` must be valid node indices in `[0, n)`.
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
/// Return `true` when `v` and `w` are in the same represented tree.
///
/// Algorithm: `access(v)` brings v's path to the splay root. Then `access(w)`
/// walks up from w. If v and w are connected, the walk from w will eventually
/// encounter v's splay tree, leaving v with a non-negative `parent` or
/// `path_parent` after the second access.
///
/// The check `nodes[v].path_parent >= 0 || nodes[v].parent >= 0` is true
/// exactly when v ended up inside the splay tree that was built during
/// `access(w)`, meaning v and w share a common root.
///
/// Time: O(log n) amortized.
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
/// Find the lowest common ancestor (LCA) of `v` and `w` in the represented
/// tree with respect to a **fixed root**.
///
/// The caller must have established a fixed root via `make_root` before using
/// this function. The LCA result depends on which node is the current root.
///
/// Returns the LCA node index, or -1 if `v` and `w` are in different trees.
///
/// Algorithm:
/// 1. `access(v)` — the preferred path is now root-to-v.
/// 2. `access(w)` — as this walk proceeds up from w, at some point it will
///    enter the splay tree built in step 1. The **last node that was splayed**
///    in step 1's splay tree before the two paths merged is the LCA.
///    `access` returns exactly this node.
///
/// The "last node splayed" is the LCA because it is the deepest node that lies
/// on both the root-to-v path and the root-to-w path.
///
/// Time: O(log n) amortized.
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
/// Set the value stored at node `v` to `value` and update path aggregates.
///
/// After this call, `path_sum` on v and all ancestors in v's splay tree
/// reflects the new value. Any subsequent `path_sum_to_root` query that
/// includes `v` will see the updated value.
///
/// Parameters:
/// - `v` — node index in `[0, n)`
/// - `value` — new `Int64` value to store at node `v`
fn LinkCutTree::set_value(self : LinkCutTree, v : Int, value : Int64) -> Unit {
  let _ = self.access(v)
  self.nodes[v].value = value
  self.update(v)
}

///|
/// Return the value stored at node `v`.
///
/// This is a direct read of `nodes[v].value` and does not require any splay
/// operations.
///
/// Parameters:
/// - `v` — node index in `[0, n)`
fn LinkCutTree::get_value(self : LinkCutTree, v : Int) -> Int64 {
  self.nodes[v].value
}

///|
/// Return the sum of values on the path from node `v` to the root of its
/// represented tree (inclusive of both endpoints).
///
/// After `access(v)`, v is the splay root and the splay tree holds exactly
/// the root-to-v path. Therefore `nodes[v].path_sum` equals the desired sum.
///
/// To query the sum of values on a path between two arbitrary nodes u and w:
/// ```
/// make_root(u)
/// access(w)
/// answer = nodes[w].path_sum
/// ```
///
/// Parameters:
/// - `v` — node index in `[0, n)`
///
/// Returns: `Int64` sum of `value` fields along the path from v to the root.
fn LinkCutTree::path_sum_to_root(self : LinkCutTree, v : Int) -> Int64 {
  let _ = self.access(v)
  self.nodes[v].path_sum
}

///|
/// Return the number of nodes in this Link-Cut Tree.
fn LinkCutTree::size(self : LinkCutTree) -> Int {
  self.nodes.length()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "linkcut basic" {
  let lct = LinkCutTree(5)

  // Initially all nodes are separate trees
  inspect(lct.find_root(0), content="0")
  inspect(lct.find_root(4), content="4")
}

///|
test "linkcut link and find_root" {
  let lct = LinkCutTree(5)

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
  let lct = LinkCutTree(5)

  // Build tree: 0 - 1 - 2
  let _ = lct.link(1, 0)
  let _ = lct.link(2, 1)
  inspect(lct.connected(0, 2), content="true")
  inspect(lct.connected(1, 2), content="true")
  inspect(lct.connected(0, 3), content="false")
}

///|
test "linkcut cut" {
  let lct = LinkCutTree(5)

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
  let lct = LinkCutTree(7)

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
  let lct = LinkCutTree(5)

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
  let lct = LinkCutTree(3)

  // First link succeeds
  inspect(lct.link(1, 0), content="true")

  // Trying to link already connected nodes fails
  inspect(lct.link(0, 1), content="false")
}

///|
test "linkcut size" {
  let lct = LinkCutTree(10)
  inspect(lct.size(), content="10")
}

///|
test "linkcut get value" {
  let lct = LinkCutTree(3)
  lct.set_value(1, 42L)
  inspect(lct.get_value(1), content="42")
}

///|
test "linkcut make root" {
  let lct = LinkCutTree(5)

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
  let lct = LinkCutTree(6)

  // Build star: 0 is center, 1-5 are leaves
  for i in 1..<6 {
    let _ = lct.link(i, 0)
  }

  // All nodes should be in same tree
  for i in 1..<6 {
    inspect(lct.connected(0, i), content="true")
  }

  // All pairs of leaves should be connected
  inspect(lct.connected(1, 5), content="true")
  inspect(lct.connected(2, 4), content="true")
}

///|
test "linkcut cut_parent" {
  let lct = LinkCutTree(4)

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
