// ============================================================================
// LI CHAO TREE - Minimum Queries
// ============================================================================
//
// Li Chao Tree for answering "what is the minimum y value at x?"
// given a set of lines y = mx + b.
//
// The algorithm is symmetric to maximum queries, but:
// - Winner at midpoint is the line with SMALLER value
// - Loser might win in the half where it has smaller value than winner
// - Query returns minimum of all evaluations along path
//
// TYPICAL USE CASES:
// ```
//   1. Shortest path DP: dp[i] = min(dp[j] + cost(j, i))
//      where cost is linear in j
//
//   2. Convex hull trick for minimization:
//      Maintain lower envelope of lines
//
//   3. Divide and conquer DP optimization
// ```

///|
/// Li Chao Tree for minimum queries.
///
/// Symmetric to LiChaoTree but optimizes for minimum instead of maximum.
pub(all) struct LiChaoTreeMin {
  nodes : Array[LCNode]
  lo : Int64
  hi : Int64
}

///|
/// Create a new Li Chao Tree for minimum queries over [lo, hi].
pub fn LiChaoTreeMin::new(lo : Int64, hi : Int64) -> LiChaoTreeMin {
  let nodes : Array[LCNode] = []
  nodes.push({ line: undefined_line_min(), left: -1, right: -1 })
  { nodes, lo, hi }
}

///|
/// Create a new node and return its index.
fn LiChaoTreeMin::new_node(self : LiChaoTreeMin) -> Int {
  let idx = self.nodes.length()
  self.nodes.push({ line: undefined_line_min(), left: -1, right: -1 })
  idx
}

///|
/// Insert a line y = mx + b for minimum queries.
///
/// ALGORITHM:
/// ```
///   Same as max version, but:
///   - Winner has SMALLER value at midpoint
///   - Loser recurses where it might have smaller value
/// ```
pub fn LiChaoTreeMin::insert(
  self : LiChaoTreeMin,
  m : Int64,
  b : Int64,
) -> Unit {
  let line : Line = { m, b }
  insert_line_min(self, 0, self.lo, self.hi, line)
}

///|
/// Internal: Insert line into subtree for min queries.
fn insert_line_min(
  tree : LiChaoTreeMin,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  new_line : Line,
) -> Unit {
  let node = tree.nodes[node_idx]
  if node.line.is_undefined_min() {
    tree.nodes[node_idx].line = new_line
    return
  }
  let mid = (lo + hi) / 2L
  let curr_at_mid = node.line.eval(mid)
  let new_at_mid = new_line.eval(mid)

  // For minimum, winner has SMALLER value at midpoint
  let mut winner = node.line
  let mut loser = new_line
  if new_at_mid < curr_at_mid {
    winner = new_line
    loser = node.line
  }
  tree.nodes[node_idx].line = winner
  if lo == hi {
    return
  }
  let winner_at_lo = winner.eval(lo)
  let loser_at_lo = loser.eval(lo)

  // Loser might win (have smaller value) where it beats winner
  if loser_at_lo < winner_at_lo {
    if tree.nodes[node_idx].left < 0 {
      tree.nodes[node_idx].left = tree.new_node()
    }
    insert_line_min(tree, tree.nodes[node_idx].left, lo, mid, loser)
  } else {
    if tree.nodes[node_idx].right < 0 {
      tree.nodes[node_idx].right = tree.new_node()
    }
    insert_line_min(tree, tree.nodes[node_idx].right, mid + 1L, hi, loser)
  }
}

///|
/// Query minimum y-value at x.
pub fn LiChaoTreeMin::query(self : LiChaoTreeMin, x : Int64) -> Int64 {
  query_min_impl(self, 0, self.lo, self.hi, x)
}

///|
/// Internal: Query minimum from subtree.
fn query_min_impl(
  tree : LiChaoTreeMin,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  x : Int64,
) -> Int64 {
  if node_idx < 0 {
    return 9223372036854775806L // Return maximum for undefined
  }
  let node = tree.nodes[node_idx]
  let curr_val = if node.line.is_undefined_min() {
    9223372036854775806L
  } else {
    node.line.eval(x)
  }
  if lo == hi {
    return curr_val
  }
  let mid = (lo + hi) / 2L

  // Recurse to child containing x, take min
  if x <= mid {
    let child_val = query_min_impl(tree, node.left, lo, mid, x)
    if child_val < curr_val {
      child_val
    } else {
      curr_val
    }
  } else {
    let child_val = query_min_impl(tree, node.right, mid + 1L, hi, x)
    if child_val < curr_val {
      child_val
    } else {
      curr_val
    }
  }
}

///|
/// Get number of nodes in tree.
pub fn LiChaoTreeMin::node_count(self : LiChaoTreeMin) -> Int {
  self.nodes.length()
}
