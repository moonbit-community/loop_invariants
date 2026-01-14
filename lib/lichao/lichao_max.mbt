// ============================================================================
// LI CHAO TREE - Maximum Queries
// ============================================================================
//
// Li Chao Tree for answering "what is the maximum y value at x?"
// given a set of lines y = mx + b.
//
// TIME COMPLEXITY:
// ```
//   Insert line: O(log N) where N = hi - lo (coordinate range)
//   Query at x:  O(log N)
//   Space:       O(L log N) where L = number of lines inserted
//                (each line creates at most O(log N) nodes)
// ```
//
// CORRECTNESS PROOF SKETCH:
// ```
//   Claim: For any x in [lo, hi], query(x) returns max over all lines.
//
//   Proof:
//   1. Consider the path from root to leaf containing x
//   2. At each node, the dominant line was chosen to beat all other
//      lines that were inserted to that node, at the midpoint
//   3. The true maximum line for x either:
//      - Is the dominant line at some node on the path, OR
//      - Was pushed to a child that contains x
//   4. By induction, we eventually find it along the path
// ```

///|
/// Li Chao Tree for maximum queries.
///
/// STRUCTURE:
/// ```
///   nodes: Array of tree nodes (index 0 is root)
///   lo:    Minimum x-coordinate in range
///   hi:    Maximum x-coordinate in range
///
///   The tree covers discrete x-values in [lo, hi].
///   Each internal node covers [lo, mid] and [mid+1, hi].
/// ```
pub(all) struct LiChaoTree {
  nodes : Array[LCNode]
  lo : Int64 // Coordinate range
  hi : Int64
}

///|
/// Create a new Li Chao Tree for maximum queries over [lo, hi].
pub fn LiChaoTree::new(lo : Int64, hi : Int64) -> LiChaoTree {
  let nodes : Array[LCNode] = []
  // Create root node with undefined line
  nodes.push({ line: undefined_line(), left: -1, right: -1 })
  { nodes, lo, hi }
}

///|
/// Create a new node and return its index.
fn LiChaoTree::new_node(self : LiChaoTree) -> Int {
  let idx = self.nodes.length()
  self.nodes.push({ line: undefined_line(), left: -1, right: -1 })
  idx
}

///|
/// Insert a line y = mx + b.
///
/// ALGORITHM:
/// ```
///   Starting from root, at each node:
///   1. Compare new line with current dominant at midpoint
///   2. Winner becomes new dominant
///   3. Loser recurses to child where it might win
/// ```
pub fn LiChaoTree::insert(self : LiChaoTree, m : Int64, b : Int64) -> Unit {
  let line : Line = { m, b }
  insert_line_max(self, 0, self.lo, self.hi, line)
}

///|
/// Internal: Insert line into subtree.
///
/// INVARIANT:
/// ```
///   After insertion, for any x in [lo, hi], the maximum over all
///   inserted lines is found by taking max of dominant lines on
///   the path from root to leaf containing x.
/// ```
fn insert_line_max(
  tree : LiChaoTree,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  new_line : Line,
) -> Unit {
  let node = tree.nodes[node_idx]

  // If node's line is undefined, just set it
  if node.line.is_undefined() {
    tree.nodes[node_idx].line = new_line
    return
  }
  let mid = (lo + hi) / 2L

  // Compare at midpoint to determine winner/loser
  let curr_at_mid = node.line.eval(mid)
  let new_at_mid = new_line.eval(mid)

  // Winner dominates at midpoint, loser might dominate elsewhere
  let mut winner = node.line
  let mut loser = new_line
  if new_at_mid > curr_at_mid {
    winner = new_line
    loser = node.line
  }
  tree.nodes[node_idx].line = winner

  // Leaf node: nowhere to push loser
  if lo == hi {
    return
  }

  // Determine which side loser might win
  let winner_at_lo = winner.eval(lo)
  let loser_at_lo = loser.eval(lo)

  // INSIGHT:
  // ```
  //   If loser wins at lo (left endpoint):
  //     loser might dominate in left half [lo, mid]
  //   Else (loser wins at hi):
  //     loser might dominate in right half [mid+1, hi]
  // ```
  if loser_at_lo > winner_at_lo {
    // Loser might win in left half
    if tree.nodes[node_idx].left < 0 {
      tree.nodes[node_idx].left = tree.new_node()
    }
    insert_line_max(tree, tree.nodes[node_idx].left, lo, mid, loser)
  } else {
    // Loser might win in right half
    if tree.nodes[node_idx].right < 0 {
      tree.nodes[node_idx].right = tree.new_node()
    }
    insert_line_max(tree, tree.nodes[node_idx].right, mid + 1L, hi, loser)
  }
}

///|
/// Query maximum y-value at x.
///
/// ALGORITHM:
/// ```
///   1. Start at root
///   2. Evaluate dominant line at current node
///   3. Recurse to child containing x
///   4. Return max of all evaluations along path
/// ```
pub fn LiChaoTree::query(self : LiChaoTree, x : Int64) -> Int64 {
  query_max_impl(self, 0, self.lo, self.hi, x)
}

///|
/// Internal: Query maximum from subtree.
fn query_max_impl(
  tree : LiChaoTree,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  x : Int64,
) -> Int64 {
  if node_idx < 0 {
    return -9223372036854775807L // Return minimum for undefined
  }
  let node = tree.nodes[node_idx]
  let curr_val = if node.line.is_undefined() {
    -9223372036854775807L
  } else {
    node.line.eval(x)
  }

  // Leaf node: return current value
  if lo == hi {
    return curr_val
  }
  let mid = (lo + hi) / 2L

  // Recurse to child containing x, take max
  if x <= mid {
    let child_val = query_max_impl(tree, node.left, lo, mid, x)
    if child_val > curr_val {
      child_val
    } else {
      curr_val
    }
  } else {
    let child_val = query_max_impl(tree, node.right, mid + 1L, hi, x)
    if child_val > curr_val {
      child_val
    } else {
      curr_val
    }
  }
}

///|
/// Get number of nodes in tree (for efficiency analysis).
pub fn LiChaoTree::node_count(self : LiChaoTree) -> Int {
  self.nodes.length()
}
