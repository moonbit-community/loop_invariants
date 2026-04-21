// ============================================================================
// LI CHAO TREE - Minimum Queries
// ============================================================================
//
// This file implements LiChaoTreeMin, which maintains a set of lines y = m*x + b
// and answers "what is the minimum y at x?" queries in O(log C) time, where
// C = hi - lo is the x-coordinate range.
//
// The algorithm is the mirror image of the maximum version (lichao_max.mbt):
//   - "winner" at a midpoint = the line with the SMALLER value there.
//   - "loser" is pushed to the child half where its value might be smaller
//     than the winner's.
//   - query returns the MINIMUM of all dominant evaluations along the path.
//
// TYPICAL USE CASES:
// ```
//   1. DP optimisation (convex hull trick for minimisation):
//        dp[i] = min over j of  ( a[j] * x[i] + b[j] )
//      Insert line (slope=a[j], intercept=b[j]) for each j.
//      Query at x = x[i] to evaluate dp[i].
//      Works for arbitrary j and i order.
//
//   2. Shortest path in a DAG where edge cost from u to v is linear in
//      some parameter of u:  cost(u, v) = rate[u] * dist[v] + fixed[u].
//      Insert one line per source node, query at each destination value.
//
//   3. Lower envelope of lines:
//      Maintain the minimum over a growing set of lines at any x.
// ```

///|
/// Li Chao Tree for minimum-value queries.
///
/// Maintains a dynamic set of lines `y = m * x + b` and answers queries of
/// the form "what is the minimum y at x = k?" in O(log C) time, where
/// C = `hi - lo` is the x-coordinate range.
///
/// This is the dual of `LiChaoTree`: every comparison is reversed so that
/// the line with the **smaller** value at a node's midpoint becomes dominant.
///
/// Usage pattern:
/// ```
/// let tree = LiChaoTreeMin(lo, hi)
/// tree.insert(slope, intercept)   // add a line y = slope * x + intercept
/// let min_y = tree.query(x)       // minimum y over all inserted lines at x
/// ```
///
/// Notes:
/// - All coordinates (`lo`, `hi`, slope, intercept, query x) are `Int64`.
/// - Querying an empty tree returns a large positive sentinel value.
/// - The tree covers the closed integer interval `[lo, hi]`; querying
///   outside this range gives undefined results.
pub(all) struct LiChaoTreeMin {
  nodes : Array[LCNode]
  lo : Int64 // Minimum x-coordinate of the covered range
  hi : Int64 // Maximum x-coordinate of the covered range
}

///|
/// Create a new `LiChaoTreeMin` for minimum queries over the integer interval
/// `[lo, hi]`.
///
/// A single root node (with the sentinel "no line") is allocated immediately.
/// All other nodes are created lazily as lines are inserted.
///
/// Parameters:
/// - `lo`: smallest x value that will ever be queried.
/// - `hi`: largest x value that will ever be queried.
pub fn LiChaoTreeMin::LiChaoTreeMin(lo : Int64, hi : Int64) -> LiChaoTreeMin {
  let nodes : Array[LCNode] = []
  nodes.push({ line: undefined_line_min(), left: -1, right: -1 })
  { nodes, lo, hi }
}

///|
/// Allocate a fresh node initialised with the sentinel "no line" (min version)
/// and return its index in `self.nodes`.
///
/// Called internally whenever a loser line must be pushed into a child that
/// has not yet been allocated.
fn LiChaoTreeMin::new_node(self : LiChaoTreeMin) -> Int {
  let idx = self.nodes.length()
  self.nodes.push({ line: undefined_line_min(), left: -1, right: -1 })
  idx
}

///|
/// Insert the line `y = m * x + b` into the tree.
///
/// After this call, all future `query` calls will consider this line when
/// computing the minimum.
///
/// Algorithm overview (see `insert_line_min` for the full recursive logic):
/// ```
/// At each node covering [lo, hi] with mid = (lo + hi) / 2:
///   1. Compare the new line against the node's dominant at mid.
///   2. The line with the SMALLER value at mid stays as the new dominant.
///   3. The larger-at-mid line (loser) is pushed to the child half where
///      it could still be smaller than the winner.
/// ```
///
/// Time complexity: O(log(hi - lo)).
pub fn LiChaoTreeMin::insert(
  self : LiChaoTreeMin,
  m : Int64,
  b : Int64,
) -> Unit {
  let line : Line = { m, b }
  insert_line_min(self, 0, self.lo, self.hi, line)
}

///|
/// Recursive helper: insert `new_line` into the subtree rooted at `node_idx`,
/// which covers the interval `[lo, hi]`, for minimum queries.
///
/// Invariant maintained after every call:
/// ```
///   For any x in [lo, hi], the minimum over all lines ever inserted into
///   this subtree equals the minimum of the dominant lines on the path from
///   node_idx down to the leaf containing x.
/// ```
///
/// Symmetric to `insert_line_max`: every `>` comparison is replaced by `<`
/// so that the line with the smaller value at mid wins.
fn insert_line_min(
  tree : LiChaoTreeMin,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  new_line : Line,
) -> Unit {
  let node = tree.nodes[node_idx]

  // If the node's dominant is the sentinel, set it directly and return.
  // Any real line has a smaller value than the sentinel everywhere.
  if node.line.is_undefined_min() {
    tree.nodes[node_idx].line = new_line
    return
  }
  let mid = (lo + hi) / 2L
  let curr_at_mid = node.line.eval(mid)
  let new_at_mid = new_line.eval(mid)

  // For minimum queries, the winner has the SMALLER value at mid.
  let (winner, loser) = if new_at_mid < curr_at_mid {
    (new_line, node.line)
  } else {
    (node.line, new_line)
  }
  tree.nodes[node_idx].line = winner

  // Leaf node: the loser has nowhere to go.
  if lo == hi {
    return
  }

  // Determine which half the loser might be smaller in.
  //
  // Two lines cross at most once.  The winner is smaller at mid, so the loser
  // can only be smaller than the winner on at most one side of mid.  We
  // determine which side by checking the left endpoint (lo):
  //
  //   loser(lo) < winner(lo)  =>  loser is smaller on LEFT  half [lo,   mid]
  //   otherwise               =>  loser is smaller on RIGHT half [mid+1, hi]
  let winner_at_lo = winner.eval(lo)
  let loser_at_lo = loser.eval(lo)
  if loser_at_lo < winner_at_lo {
    // Loser might be smaller in [lo, mid]; recurse left.
    if tree.nodes[node_idx].left < 0 {
      tree.nodes[node_idx].left = tree.new_node()
    }
    insert_line_min(tree, tree.nodes[node_idx].left, lo, mid, loser)
  } else {
    // Loser might be smaller in [mid+1, hi]; recurse right.
    if tree.nodes[node_idx].right < 0 {
      tree.nodes[node_idx].right = tree.new_node()
    }
    insert_line_min(tree, tree.nodes[node_idx].right, mid + 1L, hi, loser)
  }
}

///|
/// Return the minimum value of any inserted line at `x`.
///
/// Walks the root-to-leaf path for `x`, evaluates the dominant line at each
/// node, and returns the minimum of those evaluations.
///
/// If no lines have been inserted, returns a large positive sentinel value
/// (just below `Int64::max_value`).
///
/// Time complexity: O(log(hi - lo)).
///
/// Precondition: `lo <= x <= hi` (the range used at construction).
pub fn LiChaoTreeMin::query(self : LiChaoTreeMin, x : Int64) -> Int64 {
  query_min_impl(self, 0, self.lo, self.hi, x)
}

///|
/// Recursive helper: return the minimum dominant-line evaluation at `x`
/// within the subtree rooted at `node_idx` covering `[lo, hi]`.
///
/// Returns the sentinel maximum (`9223372036854775806`) when `node_idx < 0`
/// (absent child), so that a missing child never contributes to the minimum.
fn query_min_impl(
  tree : LiChaoTreeMin,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  x : Int64,
) -> Int64 {
  if node_idx < 0 {
    // Absent child: contribute the largest possible value so it never wins.
    return 9223372036854775806L
  }
  let node = tree.nodes[node_idx]
  let curr_val = if node.line.is_undefined_min() {
    9223372036854775806L
  } else {
    node.line.eval(x)
  }

  // Leaf node: no children to visit.
  if lo == hi {
    return curr_val
  }
  let mid = (lo + hi) / 2L

  // Descend to the child whose interval contains x, then take the min.
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
/// Return the total number of nodes currently allocated in the tree.
///
/// Useful for benchmarking and verifying the O(L log C) space bound: after
/// inserting L lines over a range of size C the node count should be at most
/// `1 + L * ceil(log2(C + 1))`.
pub fn LiChaoTreeMin::node_count(self : LiChaoTreeMin) -> Int {
  self.nodes.length()
}
