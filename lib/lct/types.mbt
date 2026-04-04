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
/// Node in the Link-Cut Tree
///
/// STRUCTURE:
/// ```
///   Each node maintains:
///   - Splay tree pointers (parent, left, right)
///   - Path-parent pointer (connection to ancestor splay tree)
///   - Lazy reversal flag (for re-rooting)
///   - Data fields (value, aggregate)
///
///   Pointer semantics:
///   - parent >= 0: splay tree parent
///   - parent < 0 AND path_parent >= 0: root of splay tree with connection above
///   - parent < 0 AND path_parent < 0: root of entire tree
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
/// Create a new LCT node with given value.
pub fn LCTNode::new(value : Int) -> LCTNode {
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
///
/// REPRESENTATION:
/// ```
///   A forest of rooted trees where each tree is decomposed into
///   preferred paths stored in splay trees.
///
///   nodes[i] represents vertex i in the forest.
///
///   Initial state: n isolated nodes, each its own tree root.
/// ```
pub(all) struct LinkCutTree {
  nodes : Array[LCTNode]
}

///|
/// Create a new Link-Cut Tree with n nodes, all with value 0.
pub fn LinkCutTree::new(n : Int) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for i in 0..<n {
    nodes.push(LCTNode::new(0))
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
/// Create Link-Cut Tree with initial values.
pub fn LinkCutTree::with_values(values : Array[Int]) -> LinkCutTree {
  let nodes : Array[LCTNode] = []
  for value in values {
    nodes.push(LCTNode::new(value))
  }
  { nodes, }
}
