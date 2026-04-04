// ============================================================================
// LI CHAO TREE - Maximum Queries
// ============================================================================
//
// This file implements LiChaoTree, which maintains a set of lines y = m*x + b
// and answers "what is the maximum y at x?" queries in O(log C) time, where
// C = hi - lo is the x-coordinate range.
//
// TIME COMPLEXITY:
// ```
//   Insert line : O(log C)   -- one path from root to leaf
//   Query at x  : O(log C)   -- one path from root to leaf
//   Space       : O(L log C) -- each of the L inserted lines creates at
//                               most O(log C) new nodes (lazy allocation)
// ```
//
// CORRECTNESS ARGUMENT (sketch):
// ```
//   Claim: query(x) returns the maximum over all inserted lines at x.
//
//   Proof by induction on tree height:
//
//   Base case (leaf node [lo, lo]):
//     At most one line can be dominant (earlier losers were pushed away).
//     The dominant is the best line at lo, so query is correct.
//
//   Inductive step (internal node covering [lo, hi]):
//     Let L* be the line achieving the true maximum at x.
//     Case 1: L* is the dominant at this node.
//       query evaluates it and takes the max -> correct.
//     Case 2: L* lost to some other line D at some ancestor node A.
//       L* was pushed to the child of A containing x.
//       By induction on that subtree, L* is found.
//     Case 3: L* is dominant at some ancestor.
//       query already evaluated it on the way down -> correct.
//
//   In all cases the maximum is found along the root-to-leaf path for x.
// ```

///|
/// Li Chao Tree for maximum-value queries.
///
/// Maintains a dynamic set of lines `y = m * x + b` and answers queries of
/// the form "what is the maximum y at x = k?" in O(log C) time, where
/// C = `hi - lo` is the x-coordinate range.
///
/// Usage pattern:
/// ```
/// let tree = LiChaoTree::new(lo, hi)
/// tree.insert(slope, intercept)   // add a line y = slope * x + intercept
/// let max_y = tree.query(x)       // maximum y over all inserted lines at x
/// ```
///
/// Notes:
/// - All coordinates (`lo`, `hi`, slope, intercept, query x) are `Int64`.
/// - Querying an empty tree returns a large negative sentinel value.
/// - The tree covers the closed integer interval `[lo, hi]`; querying
///   outside this range gives undefined results.
pub(all) struct LiChaoTree {
  nodes : Array[LCNode]
  lo : Int64 // Minimum x-coordinate of the covered range
  hi : Int64 // Maximum x-coordinate of the covered range
}

///|
/// Create a new `LiChaoTree` for maximum queries over the integer interval
/// `[lo, hi]`.
///
/// A single root node (with the sentinel "no line") is allocated immediately.
/// All other nodes are created lazily as lines are inserted.
///
/// Parameters:
/// - `lo`: smallest x value that will ever be queried.
/// - `hi`: largest x value that will ever be queried.
///
/// Panics (index out of bounds) if `lo > hi`.
pub fn LiChaoTree::new(lo : Int64, hi : Int64) -> LiChaoTree {
  let nodes : Array[LCNode] = []
  // Create root node with undefined line
  nodes.push({ line: undefined_line(), left: -1, right: -1 })
  { nodes, lo, hi }
}

///|
/// Allocate a fresh node initialised with the sentinel "no line" and return
/// its index in `self.nodes`.
///
/// Called internally whenever a loser line needs to be pushed into a child
/// that does not yet exist.
fn LiChaoTree::new_node(self : LiChaoTree) -> Int {
  let idx = self.nodes.length()
  self.nodes.push({ line: undefined_line(), left: -1, right: -1 })
  idx
}

///|
/// Insert the line `y = m * x + b` into the tree.
///
/// After this call, all future `query` calls will consider this line when
/// computing the maximum.
///
/// Algorithm overview (see `insert_line_max` for the full recursive logic):
/// ```
/// At each node covering [lo, hi] with mid = (lo + hi) / 2:
///   1. Compare the new line against the node's dominant at mid.
///   2. The better-at-mid line stays as the new dominant (winner).
///   3. The worse-at-mid line (loser) is pushed to the child half where
///      it could still beat the winner.
///   4. Stop at a leaf or when no child is needed.
/// ```
///
/// Time complexity: O(log(hi - lo)).
pub fn LiChaoTree::insert(self : LiChaoTree, m : Int64, b : Int64) -> Unit {
  let line : Line = { m, b }
  insert_line_max(self, 0, self.lo, self.hi, line)
}

///|
/// Recursive helper: insert `new_line` into the subtree rooted at `node_idx`,
/// which covers the interval `[lo, hi]`.
///
/// Invariant maintained after every call:
/// ```
///   For any x in [lo, hi], the maximum over all lines ever inserted into
///   this subtree equals the maximum of the dominant lines on the path from
///   node_idx down to the leaf containing x.
/// ```
///
/// The function runs in O(log(hi - lo)) time because the loser is pushed to
/// at most one child (two linear functions cross at most once, so the loser
/// can only beat the winner on one side of mid).
fn insert_line_max(
  tree : LiChaoTree,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  new_line : Line,
) -> Unit {
  let node = tree.nodes[node_idx]

  // If the node's dominant is the sentinel, set it directly and return.
  // No comparison needed: any real line beats the sentinel everywhere.
  if node.line.is_undefined() {
    tree.nodes[node_idx].line = new_line
    return
  }
  let mid = (lo + hi) / 2L

  // Evaluate both lines at the midpoint to determine winner and loser.
  let curr_at_mid = node.line.eval(mid)
  let new_at_mid = new_line.eval(mid)

  // Winner: better (larger) value at mid -> becomes the new dominant.
  // Loser:  worse at mid -> may still win somewhere in [lo, hi].
  let (winner, loser) = if new_at_mid > curr_at_mid {
    (new_line, node.line)
  } else {
    (node.line, new_line)
  }
  tree.nodes[node_idx].line = winner

  // Leaf node: the loser has nowhere to go.
  if lo == hi {
    return
  }

  // Decide which half the loser might win in.
  //
  // Key observation: two lines cross at most once.  The winner dominates at
  // mid, so the loser can only beat the winner on one side of mid.  We find
  // which side by checking the left endpoint (lo):
  //
  //   loser(lo) > winner(lo)  =>  loser wins on the LEFT  half [lo,   mid]
  //   otherwise               =>  loser wins on the RIGHT half [mid+1, hi]
  let winner_at_lo = winner.eval(lo)
  let loser_at_lo = loser.eval(lo)
  if loser_at_lo > winner_at_lo {
    // Loser might win somewhere in [lo, mid]; recurse left.
    if tree.nodes[node_idx].left < 0 {
      tree.nodes[node_idx].left = tree.new_node()
    }
    insert_line_max(tree, tree.nodes[node_idx].left, lo, mid, loser)
  } else {
    // Loser might win somewhere in [mid+1, hi]; recurse right.
    if tree.nodes[node_idx].right < 0 {
      tree.nodes[node_idx].right = tree.new_node()
    }
    insert_line_max(tree, tree.nodes[node_idx].right, mid + 1L, hi, loser)
  }
}

///|
/// Return the maximum value of any inserted line at `x`.
///
/// Walks the root-to-leaf path for `x`, evaluates the dominant line at each
/// node, and returns the maximum of those evaluations.
///
/// If no lines have been inserted, returns a large negative sentinel value
/// (just above `Int64::min_value`).
///
/// Time complexity: O(log(hi - lo)).
///
/// Precondition: `lo <= x <= hi` (the range used at construction).
pub fn LiChaoTree::query(self : LiChaoTree, x : Int64) -> Int64 {
  query_max_impl(self, 0, self.lo, self.hi, x)
}

///|
/// Recursive helper: return the maximum dominant-line evaluation at `x`
/// within the subtree rooted at `node_idx` covering `[lo, hi]`.
///
/// Returns the sentinel minimum (`-9223372036854775807`) when `node_idx < 0`
/// (absent child), so that a missing child never contributes to the maximum.
fn query_max_impl(
  tree : LiChaoTree,
  node_idx : Int,
  lo : Int64,
  hi : Int64,
  x : Int64,
) -> Int64 {
  if node_idx < 0 {
    // Absent child: contribute the smallest possible value so it never wins.
    return -9223372036854775807L
  }
  let node = tree.nodes[node_idx]
  let curr_val = if node.line.is_undefined() {
    -9223372036854775807L
  } else {
    node.line.eval(x)
  }

  // Leaf node: no children to visit.
  if lo == hi {
    return curr_val
  }
  let mid = (lo + hi) / 2L

  // Descend to the child whose interval contains x, then take the max.
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
/// Return the total number of nodes currently allocated in the tree.
///
/// Useful for benchmarking and verifying the O(L log C) space bound: after
/// inserting L lines over a range of size C the node count should be at most
/// `1 + L * ceil(log2(C + 1))`.
pub fn LiChaoTree::node_count(self : LiChaoTree) -> Int {
  self.nodes.length()
}
