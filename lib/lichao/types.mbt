// ============================================================================
// LI CHAO TREE - Type Definitions
// ============================================================================
//
// Li Chao Tree is a segment tree variant for efficiently maintaining a set of
// linear functions f(x) = mx + b and answering maximum/minimum queries at any x.
//
// KEY INSIGHT - THE WINNER/LOSER MECHANISM:
// ```
//   At each segment tree node, we store a "dominant" line for that interval.
//
//   When inserting a new line:
//   1. Compare new line with current dominant at interval's MIDPOINT
//   2. The line winning at midpoint becomes the new dominant
//   3. The loser might still win at other points in the interval
//   4. We only need to recurse in ONE direction (where the loser might win)
//
//   The key observation: if we know which line wins at midpoint, and which
//   wins at an endpoint, we can determine which half the loser might win in.
// ```
//
// VISUAL EXAMPLE:
// ```
//   Insert lines y = 2x + 1 (steep) and y = -x + 7 (negative slope)
//
//   On interval [0, 10], midpoint = 5:
//     Line 1 at x=5: 2(5)+1 = 11
//     Line 2 at x=5: -5+7 = 2
//     Winner at midpoint: Line 1
//
//   But Line 2 might win in left half (at x=0: Line 1=1, Line 2=7)
//   So we recurse into left child with Line 2
//
//       y
//       |     /
//       |    / Line 1 (steep)
//       |   /
//       |  / _____Line 2 (negative)
//       | /\/
//       |/_/______ x
//       0   5   10
// ```
//
// WHY ONLY ONE RECURSION:
// ```
//   If the loser wins at the left endpoint → it might win in left half
//   If the loser wins at the right endpoint → it might win in right half
//   But it can't win in BOTH halves (since winner dominates at midpoint)
// ```
//
// QUERY MECHANISM:
// ```
//   To query at x:
//   1. Start at root, evaluate dominant line at x
//   2. Recurse to child containing x
//   3. Take max of all evaluations along the path
//
//   This works because the true maximum must be the dominant line
//   at some node along the root-to-leaf path containing x.
// ```
//
// APPLICATIONS:
//   - DP optimization (convex hull trick, divide and conquer)
//   - Maintaining upper/lower envelope of lines
//   - Shortest path in DAG with linear cost functions

///|
/// A linear function y = mx + b.
///
/// REPRESENTATION:
/// ```
///   m: slope (coefficient of x)
///   b: y-intercept (constant term)
///
///   eval(x) = m * x + b
/// ```
pub(all) struct Line {
  m : Int64 // Slope
  b : Int64 // Y-intercept
}

///|
/// Evaluate line at x.
pub fn Line::eval(self : Line, x : Int64) -> Int64 {
  self.m * x + self.b
}

///|
/// Special "undefined" line that always loses in maximum queries.
///
/// Uses a very negative b value so that any real line will dominate.
pub fn undefined_line() -> Line {
  { m: 0L, b: -9223372036854775807L } // MIN_INT64 + 1
}

///|
/// Check if line is the undefined sentinel for max queries.
pub fn Line::is_undefined(self : Line) -> Bool {
  self.b == -9223372036854775807L && self.m == 0L
}

///|
/// Special "undefined" line that always loses in minimum queries.
///
/// Uses a very positive b value so that any real line will dominate.
pub fn undefined_line_min() -> Line {
  { m: 0L, b: 9223372036854775806L } // MAX_INT64 - 1
}

///|
/// Check if line is the undefined sentinel for min queries.
pub fn Line::is_undefined_min(self : Line) -> Bool {
  self.b == 9223372036854775806L && self.m == 0L
}

///|
/// Li Chao Tree node.
///
/// STRUCTURE:
/// ```
///   line:  The dominant line for this node's interval
///   left:  Index of left child (-1 if none)
///   right: Index of right child (-1 if none)
///
///   Left child covers [lo, mid]
///   Right child covers [mid+1, hi]
/// ```
pub(all) struct LCNode {
  mut line : Line
  mut left : Int // Child indices (-1 for none)
  mut right : Int
}
