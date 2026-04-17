// ============================================================================
// POLYGON TRIANGULATION - Minimum Weight DP (Convex Polygon)
// ============================================================================
//
// We minimize the total weight of a triangulation for a convex polygon.
// Each triangle's weight is defined as the sum of squared edge lengths,
// keeping everything in integers (no sqrt).
//
// DP:
//   dp[i][j] = min over k in (i+1..j-1)
//              dp[i][k] + dp[k][j] + cost(i, k, j)
//
// TIME COMPLEXITY: O(n^3)
// SPACE COMPLEXITY: O(n^2)

///|
/// Sentinel value used to initialise dp cells before minimisation.
/// Equal to `Int64::max_value / 2` to prevent overflow when two sentinels are
/// added together during the recurrence evaluation.
const INF64 : Int64 = 4611686018427387903L

///|
/// A two-dimensional point with integer coordinates.
///
/// Coordinates are `Int64` so that squared distances
/// `(x1 - x2)^2 + (y1 - y2)^2` never overflow for inputs in the range
/// `-10^9 .. 10^9`.
///
/// # Example
///
/// ```mbt nocheck
/// let p : @polygon_triangulation.Point = { x: 3L, y: -4L }
/// assert_eq!(p.x, 3L)
/// ```
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Debug, Eq)

///|
/// Returns the squared Euclidean distance between two points.
///
/// Using squared distance avoids floating-point arithmetic and keeps all
/// intermediate values in `Int64`.
fn dist2(a : Point, b : Point) -> Int64 {
  let dx = a.x - b.x
  let dy = a.y - b.y
  dx * dx + dy * dy
}

///|
/// Returns the cost of triangle `(points[i], points[j], points[k])`, defined
/// as the sum of squared lengths of its three sides.
///
/// This is the local cost added to the DP when a triangulation splits interval
/// `[i, j]` at vertex `k`.
fn triangle_cost(points : Array[Point], i : Int, j : Int, k : Int) -> Int64 {
  dist2(points[i], points[j]) +
  dist2(points[j], points[k]) +
  dist2(points[k], points[i])
}

///|
/// Computes the minimum-weight triangulation of a **convex** polygon.
///
/// The polygon is given as an array of vertices in order (clockwise or
/// counter-clockwise). The weight of a triangulation is the sum of each
/// triangle's cost, where a triangle's cost is the sum of the squared lengths
/// of its three sides.
///
/// Returns `None` when the polygon has fewer than 3 vertices (a triangle or
/// polygon cannot be formed).
///
/// # Algorithm
///
/// Interval DP: `dp[i][j]` is the minimum cost to triangulate the sub-polygon
/// formed by the chain of vertices from index `i` to index `j`.
///
/// ```
/// dp[i][j] = min over k in (i+1 .. j-1):
///                dp[i][k] + dp[k][j] + cost(i, k, j)
/// ```
///
/// The table is filled bottom-up by increasing interval length, so every
/// sub-problem `dp[i][k]` and `dp[k][j]` is already optimal when `dp[i][j]`
/// is computed.
///
/// Time: O(n^3). Space: O(n^2).
///
/// # Example
///
/// ```mbt nocheck
/// let square : Array[@polygon_triangulation.Point] = [
///   { x: 0L, y: 0L },
///   { x: 1L, y: 0L },
///   { x: 1L, y: 1L },
///   { x: 0L, y: 1L },
/// ]
/// assert_eq!(@polygon_triangulation.min_weight_triangulation(square), Some(8L))
/// ```
pub fn min_weight_triangulation(points : Array[Point]) -> Int64? {
  let n = points.length()
  if n < 3 {
    return None
  }
  let dp : Array[Array[Int64]] = [ for _ in 0..<n => Array::make(n, 0L) ]
  for len in 2..<n {
    for i in 0..<(n - len) {
      let j = i + len
      dp[i][j] = INF64
      for k in (i + 1)..<j {
        let cost = dp[i][k] + dp[k][j] + triangle_cost(points, i, k, j)
        if cost < dp[i][j] {
          dp[i][j] = cost
        }
      } where {
        proof_invariant: k >= i + 1 && k <= j,
        proof_reasoning: (
          #|INVARIANT (split scan):
          #|dp[i][j] is the minimum cost among splits in [i+1..k). Each split
          #|forms triangle (i, k, j) plus optimal subproblems on both sides.
          #|MAINTENANCE:
          #|Evaluate split at k and update dp[i][j] if cost is lower.
          #|TERMINATION:
          #|At k = j, all splits are considered and dp[i][j] is optimal.
        ),
      }
    } where {
      proof_invariant: i >= 0 && i + len <= n,
      proof_reasoning: (
        #|INVARIANT (fixed length):
        #|For all indices i' in [0..i), dp[i'][i'+len] is finalized for the
        #|current length len.
        #|MAINTENANCE:
        #|Compute dp[i][j] by scanning all splits between i and j.
        #|TERMINATION:
        #|At i such that i+len = n, all intervals of this length are computed.
      ),
    }
  } where {
    proof_invariant: len >= 2 && len <= n,
    proof_reasoning: (
      #|INVARIANT (length expansion):
      #|All dp intervals with length < len are already optimal. This ensures
      #|subproblems dp[i][k] and dp[k][j] are solved before dp[i][j].
      #|MAINTENANCE:
      #|Increase len by 1 and compute all intervals of that length.
      #|TERMINATION:
      #|At len = n-1, dp[0][n-1] is the minimum triangulation cost.
    ),
  }
  Some(dp[0][n - 1])
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "triangulation triangle" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 1L, y: 0L },
    { x: 0L, y: 1L },
  ]
  inspect(min_weight_triangulation(points).unwrap(), content="4")
}

///|
test "triangulation square" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 1L, y: 0L },
    { x: 1L, y: 1L },
    { x: 0L, y: 1L },
  ]
  inspect(min_weight_triangulation(points).unwrap(), content="8")
}

///|
test "triangulation invalid" {
  let points : Array[Point] = [{ x: 0L, y: 0L }, { x: 1L, y: 0L }]
  guard min_weight_triangulation(points) is None else { fail("expected None") }
}
