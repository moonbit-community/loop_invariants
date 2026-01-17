// ============================================================================
// LCT - Splay Tree Operations
// ============================================================================
//
// Link-Cut Trees use splay trees as the auxiliary data structure for
// representing preferred paths. This module contains the splay tree
// operations that maintain the internal structure.
//
// SPLAY TREE OVERVIEW:
// ```
//   A splay tree is a self-adjusting BST where recently accessed
//   elements move to the root via rotations ("splaying").
//
//   Key property: O(log n) amortized time per operation.
//
//   In LCT context:
//   - Splay trees are keyed by DEPTH in original tree
//   - Leftmost node = shallowest = closer to tree root
//   - Rightmost node = deepest = further from tree root
// ```
//
// SPLAY CASES:
// ```
//   Let x be the node being splayed, y its parent, z its grandparent.
//
//   Case 1 - ZIG (y is root):
//       y              x
//      / \            / \
//     x   C   →      A   y
//    / \                / \
//   A   B              B   C
//
//   Case 2 - ZIG-ZIG (x and y are same-side children):
//         z                x
//        / \              / \
//       y   D            A   y
//      / \        →         / \
//     x   C                B   z
//    / \                      / \
//   A   B                    C   D
//
//   Case 3 - ZIG-ZAG (x and y are opposite-side children):
//       z                  x
//      / \                / \
//     y   D              y   z
//    / \        →       / \ / \
//   A   x              A  B C  D
//      / \
//     B   C
// ```
//
// WHY SPLAY?
// ```
//   1. Moves frequently accessed nodes to root (cache-friendly)
//   2. Provides amortized O(log n) guarantee via potential function
//   3. No balance information needed (unlike AVL/Red-Black)
//   4. Naturally adapts to access patterns
// ```

///|
/// Check if node is root of its splay tree.
///
/// A node is a splay root if:
///   1. It has no parent (parent == -1), OR
///   2. Its parent doesn't claim it as a child (path-parent relationship)
///
/// INSIGHT:
/// ```
///   The second condition distinguishes splay-parent from path-parent.
///   If parent >= 0 but neither left nor right child of parent is x,
///   then x is actually connected via path_parent, not splay tree edge.
/// ```
fn LinkCutTree::is_splay_root(self : LinkCutTree, x : Int) -> Bool {
  let p = self.nodes[x].parent
  if p < 0 {
    true
  } else {
    self.nodes[p].left != x && self.nodes[p].right != x
  }
}

///|
/// Push down lazy reversal flag.
///
/// REVERSAL OPERATION:
/// ```
///   The reversed flag indicates that the entire subtree should have
///   its left/right children swapped. This is used for re-rooting.
///
///   When we push down:
///   1. Swap our left and right children
///   2. Toggle the reversed flag on both children
///   3. Clear our own reversed flag
///
///   This implements lazy propagation - we only apply the reversal
///   when we actually need to traverse through a node.
/// ```
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
/// Update aggregate values from children.
///
/// AGGREGATION:
/// ```
///   subtree_sum = value + left.subtree_sum + right.subtree_sum
///
///   This represents the sum of all node values on the path
///   represented by this splay tree subtree.
///
///   Called after any structural change (rotation, link, cut).
/// ```
fn LinkCutTree::push_up(self : LinkCutTree, x : Int) -> Unit {
  let l = self.nodes[x].left
  let r = self.nodes[x].right
  let l_sum = if l >= 0 { self.nodes[l].subtree_sum } else { 0 }
  let r_sum = if r >= 0 { self.nodes[r].subtree_sum } else { 0 }
  self.nodes[x].subtree_sum = self.nodes[x].value + l_sum + r_sum
}

///|
/// Rotate node x up (zig or zag).
///
/// ROTATION MECHANICS:
/// ```
///   LEFT ROTATION (x is right child of y):
///       y                x
///      / \              / \
///     A   x     →      y   C
///        / \          / \
///       B   C        A   B
///
///   RIGHT ROTATION (x is left child of y):
///       y              x
///      / \            / \
///     x   C    →     A   y
///    / \                / \
///   A   B              B   C
///
///   Key operations:
///   1. x takes y's position (in z's children or as root)
///   2. The "inner" subtree of x (B) becomes child of y
///   3. y becomes child of x
///   4. Path-parent transfers from y to x
/// ```
fn LinkCutTree::rotate(self : LinkCutTree, x : Int) -> Unit {
  let y = self.nodes[x].parent
  let z = self.nodes[y].parent
  let is_left = self.nodes[y].left == x

  // x takes y's place in z
  if z >= 0 {
    if self.nodes[z].left == y {
      self.nodes[z].left = x
    } else if self.nodes[z].right == y {
      self.nodes[z].right = x
    }
    // else z is path-parent, no splay tree link to update
  }

  // Move inner subtree of x to y
  if is_left {
    // Right rotation: x's right child goes to y's left
    self.nodes[y].left = self.nodes[x].right
    if self.nodes[x].right >= 0 {
      self.nodes[self.nodes[x].right].parent = y
    }
    self.nodes[x].right = y
  } else {
    // Left rotation: x's left child goes to y's right
    self.nodes[y].right = self.nodes[x].left
    if self.nodes[x].left >= 0 {
      self.nodes[self.nodes[x].left].parent = y
    }
    self.nodes[x].left = y
  }

  // Update parent pointers
  self.nodes[y].parent = x
  self.nodes[x].parent = z

  // Transfer path-parent from y to x (x is now splay root of what y was)
  self.nodes[x].path_parent = self.nodes[y].path_parent
  self.nodes[y].path_parent = -1

  // Update aggregates (y first, then x since x is now above y)
  self.push_up(y)
  self.push_up(x)
}

///|
/// Push down lazy values on path from splay root to x.
///
/// WHY TOP-DOWN:
/// ```
///   Reversal flags must be pushed from ancestors to descendants.
///   If we rotate before pushing, we might access children that
///   should have been swapped.
///
///   Algorithm:
///   1. Collect path from x to splay root
///   2. Push down from root to x (reverse order)
/// ```
fn LinkCutTree::push_down_path(self : LinkCutTree, x : Int) -> Unit {
  // Collect ancestors (need to push from top down)
  let path : Array[Int] = []
  for node = x; not(self.is_splay_root(node)); {
    path.push(node)
    continue self.nodes[node].parent
  } else {
    path.push(node) // Include the splay root
  } where {
    invariant: node >= 0 && node < self.nodes.length(),
    reasoning: (
      #|INVARIANT (collect path):
      #|  path contains nodes from x toward splay root.
      #|  node is the current ancestor being added.
      #|
      #|MAINTENANCE:
      #|  Add node to path, move to parent.
      #|
      #|TERMINATION:
      #|  Stops at splay root (is_splay_root returns true).
    ),
  }

  // Push down from root to x (reverse order)
  for i in path.length() >.. 0 {
    self.push_down(path[i])
  }
}

///|
/// Splay node x to root of its splay tree.
///
/// ALGORITHM:
/// ```
///   1. First push down all lazy values on path to x
///   2. While x is not splay root:
///      - If parent is splay root: single rotation (zig)
///      - Else if zig-zig (same direction): rotate parent, then x
///      - Else (zig-zag): rotate x twice
/// ```
///
/// AMORTIZED ANALYSIS:
/// ```
///   Potential function: Φ = Σ log(size(subtree(v)))
///
///   Each splay operation pays:
///     - Actual cost: O(rotations)
///     - Potential change: O(log n) decrease
///
///   Amortized cost = actual + ΔΦ = O(log n)
///
///   The zig-zig case is crucial: rotating parent first creates
///   a more balanced structure, leading to better amortization.
/// ```
fn LinkCutTree::splay(self : LinkCutTree, x : Int) -> Unit {
  // Push down lazy values first
  self.push_down_path(x)

  // Splay until x is root of its splay tree
  for ; not(self.is_splay_root(x)); {
    let y = self.nodes[x].parent
    if self.is_splay_root(y) {
      // Zig: y is splay root, single rotation
      self.rotate(x)
    } else {
      let z = self.nodes[y].parent
      let x_is_left = self.nodes[y].left == x
      let y_is_left = self.nodes[z].left == y
      if x_is_left == y_is_left {
        // Zig-zig: same direction, rotate parent first
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
      #|   - Zig: x becomes splay root (1 rotation)
      #|   - Zig-zig/zig-zag: x moves up by 2 levels (2 rotations)
      #|
      #|2. Splay tree structure preserved:
      #|   - In-order traversal unchanged (depth ordering preserved)
      #|   - All parent/child pointers remain consistent
      #|
      #|3. Path-parent correctly transferred:
      #|   - Only the splay root holds the path-parent pointer
      #|   - Rotations move this pointer to the new root
      #|
      #|MAINTENANCE:
      #|  Each rotation sequence moves x up while preserving order.
      #|
      #|TERMINATION:
      #|  x's depth decreases each iteration; stops at splay root.
    ),
  }
}
