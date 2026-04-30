// ============================================================================
// LINK-CUT TREES - Type Definitions
// ============================================================================
//
// Link-Cut Trees (Sleator & Tarjan, 1983) maintain a forest of rooted trees
// supporting dynamic connectivity operations in O(log n) amortized time.
//
// KEY INSIGHT:
// ```
//   Represent each tree as a collection of "preferred paths".
//   Each preferred path is stored in a splay tree, ordered by depth.
//
//   The preferred path from a node v is determined by the most recent
//   access pattern - it's the path taken when we last traversed through v.
// ```
//
// STRUCTURE OVERVIEW:
// ```
//   Original Tree:          Preferred Paths:       Splay Trees:
//
//        0                    0---1---2            [splay tree A]
//       /|\                   |                         |
//      1 2 3                  3---4               path-parent
//     /|   |                  |                         |
//    4 5   6                  6                   [splay tree B]
//                                                       |
//   Each preferred path      Paths connected       path-parent
//   forms a contiguous       by path-parent             |
//   chain in original        pointers            [splay tree C]
//   tree.
// ```
//
// POINTER TYPES:
// ```
//   parent:      Within splay tree (splay parent)
//   left/right:  Within splay tree (splay children)
//   path_parent: Between splay trees (to ancestor in original tree)
// ```
//
// KEY INVARIANTS:
// ```
//   1. SPLAY ORDER: In each splay tree, nodes are ordered by depth in
//      the original tree (shallower nodes = smaller = left side)
//
//   2. PREFERRED PATH: Each splay tree represents a contiguous path
//      from some ancestor to some descendant in the original tree
//
//   3. PATH PARENT: The root of a splay tree has a path_parent pointer
//      to the node directly above it in the original tree (or -1 if
//      it's the tree root)
//
//   4. COVERAGE: Every node is in exactly one splay tree at any time
// ```
//
// APPLICATIONS:
//   - Dynamic connectivity in trees
//   - Lowest Common Ancestor queries
//   - Path aggregation (sum, max, min)
//   - Re-rooting trees
//   - Network flow algorithms

///|
/// A single node in the Link-Cut Tree auxiliary structure.
///
/// Each node occupies exactly one splay tree at any moment. Splay trees
/// represent preferred paths — contiguous chains in the original tree ordered
/// by depth (shallower nodes on the left, deeper nodes on the right).
///
/// POINTER SEMANTICS:
/// ```
///   Three distinct cases for the (parent, path_parent) pair:
///
///   Splay-internal node:
///     parent >= 0  AND  nodes[parent].left == self OR nodes[parent].right == self
///
///   Splay root with an upward link (not tree root):
///     parent < 0  AND  path_parent >= 0
///     path_parent points to the topmost node of the next splay tree above.
///
///   Tree root (topmost node in the entire represented tree):
///     parent < 0  AND  path_parent < 0
/// ```
///
/// AGGREGATE MAINTENANCE:
/// ```
///   subtree_sum is kept in sync via push_up after every rotation or
///   structural change:
///     subtree_sum = value + left.subtree_sum + right.subtree_sum
///
///   It represents the sum of all node values on the portion of the
///   preferred path covered by this node's splay subtree.
/// ```
///
/// LAZY REVERSAL:
/// ```
///   The reversed flag is a lazy propagation marker set by make_root.
///   When true, the node's left and right children should be considered
///   swapped (and the flag should be forwarded to them before any
///   structural access). push_down applies the reversal and clears the flag.
/// ```
pub(all) struct LCTNode {
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
/// Create a new LCTNode with the given value.
///
/// The node starts as an isolated tree: no splay-tree edges (`parent`,
/// `left`, `right` all -1), no upward connection (`path_parent` = -1),
/// and no pending reversal (`reversed` = false).
/// `subtree_sum` is initialised to `value` because a lone node's path
/// aggregate is just its own value.
pub fn LCTNode::LCTNode(value : Int) -> LCTNode {
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
/// Link-Cut Tree data structure for dynamic forests.
///
/// Maintains a forest of rooted trees under a sequence of link and cut
/// operations, with O(log n) amortized time per operation.
///
/// REPRESENTATION:
/// ```
///   nodes[i] is vertex i in the forest.  All vertices are indexed 0..n-1.
///
///   Internally each tree is decomposed into preferred paths (see module
///   header).  Each preferred path is stored as a splay tree ordered by
///   depth:
///
///     Left in splay  <->  shallower in original tree
///     Right in splay <->  deeper in original tree
///
///   Splay trees belonging to the same original tree are chained via
///   path_parent pointers.  A node with path_parent == -1 and parent == -1
///   is the root of the entire original tree.
/// ```
///
/// INITIAL STATE:
/// ```
///   LinkCutTree(n) creates n isolated nodes.  Each node is its own
///   splay tree (trivially a single-node tree) and its own original tree
///   root.  No edges exist.
/// ```
///
/// THREAD SAFETY:
///   Not thread-safe. All operations mutate internal state.
pub(all) struct LinkCutTree {
  nodes : Array[LCTNode]
}

///|
/// Create a new Link-Cut Tree with `n` nodes, all with value 0.
///
/// Produces `n` isolated nodes (no edges). Each node is simultaneously its
/// own splay-tree root and its own original-tree root.
///
/// Time: O(n).
pub fn LinkCutTree::LinkCutTree(n : Int) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for i in 0..<n {
    nodes.push(LCTNode(0))
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (init nodes):
      #|  nodes[0..i) are initialized as isolated tree roots.
      #|
      #|INITIAL STATE:
      #|  Each node has parent = left = right = path_parent = -1
      #|  meaning each node is its own tree and splay tree root.
      #|
      #|MAINTENANCE:
      #|  Push a freshly initialized node for index i.
      #|
      #|TERMINATION:
      #|  At i = n, all n nodes are initialized.
    ),
  }
  { nodes, }
}

///|
/// Create a Link-Cut Tree with given initial node values.
///
/// Equivalent to `LinkCutTree(values.length())` followed by setting
/// each node's value from the array. Useful when path-sum queries are
/// planned from the start.
///
/// Time: O(n).
pub fn LinkCutTree::with_values(values : Array[Int]) -> LinkCutTree {
  let nodes : Array[LCTNode] = [ for value in values => LCTNode(value) ]
  { nodes, }
}
