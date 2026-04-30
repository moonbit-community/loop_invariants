// ============================================================================
// SUFFIX TREE - Type Definitions
// ============================================================================
//
// Core data structures for the suffix tree. The tree is stored as a flat array
// of nodes, where each node holds outgoing edges. Edges carry substring labels
// as (start, end) index pairs into the original text, enabling O(1) edge
// creation without copying characters.
//
// MEMORY LAYOUT:
//   - Node 0 is always the root.
//   - Leaf nodes have no outgoing edges.
//   - Each suffix ends at a unique leaf (guaranteed by the sentinel character).

///|
/// Sentinel character appended to the input string during construction.
///
/// Using the NUL character ensures no suffix is a prefix of another, so every
/// suffix ends at a leaf and leaf counts are unambiguous. The sentinel will
/// never appear in ordinary text.
pub const SENTINEL : Char = '\u0000'

///|
/// A single directed edge in the suffix tree, labelled by a substring of the
/// original text.
///
/// The label is stored implicitly as the half-open index range `[start, end)`
/// into the text array. This reduces per-edge storage from O(label_length) to
/// O(1) regardless of how long the substring is.
///
/// Fields:
/// - `start` - Inclusive start index of the edge label in `text`.
/// - `end`   - Exclusive end index of the edge label in `text`.
/// - `child` - Index of the child `Node` that this edge leads to.
pub(all) struct Edge {
  start : Int
  end : Int
  child : Int
}

///|
/// A node in the suffix tree.
///
/// Each node stores its outgoing edges and a precomputed leaf count used to
/// answer occurrence queries in O(1) after construction.
///
/// Fields:
/// - `edges`      - Outgoing edges, each labelled with a distinct first character.
/// - `leaf_count` - Number of leaves in this subtree. Valid only after
///                  `compute_leaf_counts` has been called. For a leaf node
///                  (no outgoing edges) this value is 1; for an internal node
///                  it equals the number of suffixes passing through it, which
///                  is the number of times the path label from the root to this
///                  node occurs as a substring of the text.
///
/// Invariants:
/// - No two edges from the same node share the same first character.
/// - `leaf_count` equals the number of leaf descendants once construction is
///   complete.
pub(all) struct Node {
  edges : Array[Edge]
  mut leaf_count : Int
}

///|
/// The suffix tree data structure built over a single text string.
///
/// After construction every suffix of the original string corresponds to a
/// unique root-to-leaf path, and every root-to-leaf path spells a suffix.
/// Any substring of the text is a prefix of at least one suffix, so substring
/// queries reduce to a single downward walk from the root.
///
/// Fields:
/// - `text`  - The original string as a character array with `SENTINEL` appended.
/// - `nodes` - All nodes stored in a flat array; node 0 is always the root.
///
/// Properties:
/// - Build time: O(n²) using naive one-suffix-at-a-time insertion.
/// - `contains` query: O(m) where m is the pattern length.
/// - `count_occurrences` query: O(m).
pub struct SuffixTree {
  text : Array[Char]
  nodes : Array[Node]
}

///|
/// Create a new, empty node with no outgoing edges and a leaf count of zero.
///
/// Used internally during tree construction whenever a new node (either a
/// split node or a new leaf) must be allocated.
pub fn Node::Node() -> Node {
  { edges: [], leaf_count: 0 }
}
