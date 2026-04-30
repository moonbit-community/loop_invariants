// ============================================================================
// LI CHAO TREE - Type Definitions
// ============================================================================
//
// A Li Chao Tree is a segment-tree variant that maintains a set of linear
// functions f(x) = m*x + b and answers maximum (or minimum) queries at
// arbitrary x in O(log C) time, where C = hi - lo is the coordinate range.
//
// KEY INSIGHT - THE WINNER / LOSER MECHANISM:
// ```
//   Each segment-tree node stores one "dominant" line for its interval.
//
//   When inserting a new line into a node covering [lo, hi]:
//     mid = (lo + hi) / 2
//     1. Compare new line vs current dominant at mid.
//     2. The line with the better value at mid becomes the new dominant
//        (the "winner"). The other is the "loser".
//     3. The loser may still beat the winner somewhere in [lo, hi], but
//        only in ONE of the two halves [lo, mid] or [mid+1, hi]:
//          - if loser beats winner at lo  -> recurse LEFT
//          - otherwise                   -> recurse RIGHT
//
//   Two linear functions cross at most once, so the loser can only be
//   better than the winner on one contiguous sub-interval.
// ```
//
// VISUAL - WINNER / LOSER SPLIT:
// ```
//   Interval [0, 8], mid = 4
//
//   y
//   |
// 8 |W                 W = winner at lo (negative slope)
// 6 |  W               L = loser  at lo (positive slope)
// 4 |    W=L           they tie at mid
// 2 |       L
// 0 |__________W___ x
//   0    4         8
//
//   Loser L beats winner W only in the right half [5, 8].
//   We recurse right and leave the left half to the winner.
// ```
//
// QUERY MECHANISM:
// ```
//   To answer query(x):
//     1. Start at root, evaluate dominant line at x.
//     2. Descend to the child that contains x (left if x <= mid, else right).
//     3. Accumulate max (or min) of all dominant evaluations along the path.
//
//   Correctness: the true best line for x must be the dominant at SOME node
//   on the root-to-leaf path containing x, because every line that was ever
//   pushed past a node without becoming dominant was sent to the child that
//   could contain x only if it beats the dominant there - and so on by
//   induction down the tree.
// ```

///|
/// A linear function `y = m * x + b`.
///
/// Parameters:
/// - `m`: slope (coefficient of x).
/// - `b`: y-intercept (constant term).
///
/// Evaluation: `eval(x) = m * x + b`.
///
/// Both `m` and `b` are `Int64` to avoid overflow when multiplying large
/// slopes by large x values.  Callers should still guard against overflow
/// when slopes and x values are both close to `Int64` limits.
pub(all) struct Line {
  m : Int64 // Slope
  b : Int64 // Y-intercept
}

///|
/// Evaluate the line at `x`.
///
/// Returns `m * x + b` using `Int64` arithmetic.
pub fn Line::eval(self : Line, x : Int64) -> Int64 {
  self.m * x + self.b
}

///|
/// Return the sentinel "no line" value used by `LiChaoTree` (maximum queries).
///
/// The sentinel has slope 0 and intercept `Int64::min_value + 1`, so it
/// evaluates to a value smaller than any real line at every x.  Any real line
/// inserted into the tree will beat it at the midpoint comparison and replace
/// it as the dominant.
///
/// Use `Line::is_undefined` to test whether a line is this sentinel.
pub fn undefined_line() -> Line {
  { m: 0L, b: -9223372036854775807L } // MIN_INT64 + 1
}

///|
/// Return `true` if `self` is the sentinel produced by `undefined_line`.
///
/// This is used internally to detect nodes that have not yet received any
/// real line.  A node holding the sentinel always loses at the midpoint
/// comparison and is replaced by the first real line inserted into it.
pub fn Line::is_undefined(self : Line) -> Bool {
  self.b == -9223372036854775807L && self.m == 0L
}

///|
/// Return the sentinel "no line" value used by `LiChaoTreeMin` (minimum queries).
///
/// The sentinel has slope 0 and intercept `Int64::max_value - 1`, so it
/// evaluates to a value larger than any real line at every x.  Any real line
/// inserted into the tree will beat it at the midpoint comparison and replace
/// it as the dominant.
///
/// Use `Line::is_undefined_min` to test whether a line is this sentinel.
pub fn undefined_line_min() -> Line {
  { m: 0L, b: 9223372036854775806L } // MAX_INT64 - 1
}

///|
/// Return `true` if `self` is the sentinel produced by `undefined_line_min`.
///
/// Symmetric to `Line::is_undefined` but for minimum-query trees.
pub fn Line::is_undefined_min(self : Line) -> Bool {
  self.b == 9223372036854775806L && self.m == 0L
}

///|
/// A single node in the Li Chao segment tree.
///
/// Each node covers a contiguous integer interval `[lo, hi]` (tracked by the
/// traversal, not stored in the node itself) and holds:
///
/// - `line`: the dominant line for this node's interval.  Initially a
///   sentinel (`undefined_line` or `undefined_line_min`).  After the first
///   insertion into this node it becomes a real line, and subsequent
///   insertions may replace it if a better line arrives at the midpoint.
///
/// - `left`:  index into the owning tree's `nodes` array for the child that
///   covers `[lo, mid]`.  `-1` means the child has not been allocated yet
///   (lazy allocation).
///
/// - `right`: index into the owning tree's `nodes` array for the child that
///   covers `[mid+1, hi]`.  `-1` means not yet allocated.
///
/// Children are allocated on demand: a child node is only created when a
/// loser line is pushed to that half during an insertion.  This keeps space
/// usage at O(L * log C) for L inserted lines.
pub(all) struct LCNode {
  mut line : Line
  mut left : Int // index of left child, -1 if absent
  mut right : Int // index of right child, -1 if absent
}
