// ============================================================================
// LINE SEGMENT INTERSECTION - Orientation Tests
// ============================================================================
//
// Two segments (a,b) and (c,d) intersect if and only if their orientations
// differ, with careful handling of collinear cases.
//
// ALGORITHM OVERVIEW:
//   1. Compute four orientation values (cross products).
//   2. If signs of (o1,o2) differ AND signs of (o3,o4) differ: proper crossing.
//   3. If any cross product is zero: check whether the collinear point lies on
//      the other segment using an axis-aligned bounding-box test.
//
// LOOP INVARIANT (collinear check):
//   on_segment(a,b,p) holds iff p is collinear with a,b and lies within the
//   rectangle [min(a.x,b.x), max(a.x,b.x)] x [min(a.y,b.y), max(a.y,b.y)].
//
// TIME COMPLEXITY: O(1)
// SPACE COMPLEXITY: O(1)

///|
/// A point in two-dimensional integer space.
///
/// Both coordinates are `Int64` to prevent overflow when computing cross
/// products of large coordinate values (the product of two `Int64` differences
/// fits in `Int64` as long as individual coordinates are at most ~3e9).
///
/// # Fields
///
/// - `x` : horizontal coordinate
/// - `y` : vertical coordinate
///
/// # Example
///
/// ```moonbit nocheck
/// let p : Point = { x: 3L, y: 4L }
/// ```
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Debug, Eq)

///|
/// Compute the signed area (times two) of the triangle formed by `a`, `b`, `c`.
///
/// The value equals `(b - a) x (c - a)` where `x` is the 2-D cross product:
///
/// ```text
/// cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
/// ```
///
/// - Positive: `c` is to the left  of the directed line `a -> b` (CCW turn).
/// - Negative: `c` is to the right of the directed line `a -> b` (CW  turn).
/// - Zero    : `a`, `b`, `c` are collinear.
fn cross(a : Point, b : Point, c : Point) -> Int64 {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
/// Test whether point `p` lies on the closed segment `a`–`b`.
///
/// Assumes `a`, `b`, and `p` are already known to be collinear (cross product
/// is zero). The test reduces to an axis-aligned bounding-box inclusion check:
///
/// ```text
/// min(a.x, b.x) <= p.x <= max(a.x, b.x)   AND
/// min(a.y, b.y) <= p.y <= max(a.y, b.y)
/// ```
///
/// The bounds are **inclusive** so that endpoints count as being on the segment.
fn on_segment(a : Point, b : Point, p : Point) -> Bool {
  let min_x = if a.x < b.x { a.x } else { b.x }
  let max_x = if a.x > b.x { a.x } else { b.x }
  let min_y = if a.y < b.y { a.y } else { b.y }
  let max_y = if a.y > b.y { a.y } else { b.y }
  p.x >= min_x && p.x <= max_x && p.y >= min_y && p.y <= max_y
}

///|
/// Return `true` if the closed line segments `(a, b)` and `(c, d)` intersect.
///
/// "Intersect" includes all of the following cases:
///
/// - Proper crossing: the interior of one segment crosses the interior of the
///   other.
/// - Endpoint touch: an endpoint of one segment lies on the other segment.
/// - Collinear overlap: the segments are collinear and share at least one point.
///
/// Collinear disjoint segments (same line but no shared point) return `false`.
///
/// # Algorithm
///
/// Four orientation values are computed:
///
/// ```text
/// o1 = cross(a, b, c)   -- which side of ab is c on?
/// o2 = cross(a, b, d)   -- which side of ab is d on?
/// o3 = cross(c, d, a)   -- which side of cd is a on?
/// o4 = cross(c, d, b)   -- which side of cd is b on?
/// ```
///
/// General case (proper crossing): `o1` and `o2` have opposite signs AND `o3`
/// and `o4` have opposite signs.
///
/// Collinear case: if any `oN == 0` the corresponding point is on the
/// infinite line of the other segment; `on_segment` then tests whether it lies
/// within the finite bounds.
///
/// # Parameters
///
/// - `a`, `b` : endpoints of the first segment
/// - `c`, `d` : endpoints of the second segment
///
/// # Examples
///
/// Crossing diagonals of a unit square:
///
/// ```moonbit nocheck
/// let a = Point::{ x: 0L, y: 0L }
/// let b = Point::{ x: 4L, y: 4L }
/// let c = Point::{ x: 0L, y: 4L }
/// let d = Point::{ x: 4L, y: 0L }
/// @debug.assert_eq(segments_intersect(a, b, c, d), true)
/// ```
///
/// Parallel horizontal segments with a gap:
///
/// ```moonbit nocheck
/// let a = Point::{ x: 0L, y: 0L }
/// let b = Point::{ x: 1L, y: 0L }
/// let c = Point::{ x: 2L, y: 0L }
/// let d = Point::{ x: 3L, y: 0L }
/// @debug.assert_eq(segments_intersect(a, b, c, d), false)
/// ```
pub fn segments_intersect(a : Point, b : Point, c : Point, d : Point) -> Bool {
  let o1 = cross(a, b, c)
  let o2 = cross(a, b, d)
  let o3 = cross(c, d, a)
  let o4 = cross(c, d, b)
  if o1 == 0 && on_segment(a, b, c) {
    return true
  }
  if o2 == 0 && on_segment(a, b, d) {
    return true
  }
  if o3 == 0 && on_segment(c, d, a) {
    return true
  }
  if o4 == 0 && on_segment(c, d, b) {
    return true
  }
  ((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) &&
  ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0))
}
