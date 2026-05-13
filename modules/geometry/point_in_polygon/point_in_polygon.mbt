// ============================================================================
// POINT IN POLYGON - Ray Casting with Boundary Detection
// ============================================================================
//
// We cast a horizontal ray to the right and count edge crossings. An odd number
// of crossings means the point is inside. Collinear points on edges are treated
// as boundary.
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(1)

///|
/// A 2-D point with 64-bit integer coordinates.
///
/// Integer coordinates are required so that all arithmetic (cross products,
/// bounding-box checks) is exact with no floating-point rounding error.
///
/// # Example
///
/// ```moonbit nocheck
/// let p : @point_in_polygon.Point = { x: 3L, y: 7L }
/// ```
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Debug, Eq)

///|
/// The result of a point-in-polygon query.
///
/// - `Inside`   -- the point is strictly inside the polygon.
/// - `Outside`  -- the point is strictly outside the polygon.
/// - `Boundary` -- the point lies exactly on an edge or vertex.
pub enum Location {
  Inside
  Outside
  Boundary
} derive(Debug, Eq)

///|
/// Renders a `Location` value as a human-readable string.
///
/// Produces `"Inside"`, `"Outside"`, or `"Boundary"`.
pub impl Show for Location with output(self, logger) {
  match self {
    Inside => logger.write_string("Inside")
    Outside => logger.write_string("Outside")
    Boundary => logger.write_string("Boundary")
  }
}

// ----------------------------------------------------------------------------
// Internal helpers
// ----------------------------------------------------------------------------

///|
/// Signed 2-D cross product of vectors AB and AC.
///
/// Returns `(b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)`.
///
/// - Zero  => A, B, C are collinear.
/// - Positive => C is to the left of directed segment A->B.
/// - Negative => C is to the right.
fn cross(a : Point, b : Point, c : Point) -> Int64 {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
/// Returns true when point `p` lies inside the axis-aligned bounding box of
/// segment AB (inclusive on all sides).
///
/// This is used together with `cross == 0` to test whether a collinear point
/// actually falls on the segment rather than on its infinite extension.
fn on_segment(a : Point, b : Point, p : Point) -> Bool {
  let min_x = if a.x < b.x { a.x } else { b.x }
  let max_x = if a.x > b.x { a.x } else { b.x }
  let min_y = if a.y < b.y { a.y } else { b.y }
  let max_y = if a.y > b.y { a.y } else { b.y }
  p.x >= min_x && p.x <= max_x && p.y >= min_y && p.y <= max_y
}

// ----------------------------------------------------------------------------
// Public API
// ----------------------------------------------------------------------------

///|
/// Determine whether point `p` lies inside, outside, or on the boundary of
/// `poly`.
///
/// ## Algorithm
///
/// The function uses the **ray casting** method:
///
/// 1. For each directed edge A->B of the polygon, first check whether `p` is
///    collinear with A and B and falls on the segment.  If so, return
///    `Boundary` immediately.
/// 2. Check whether the horizontal ray extending to the right from `p` crosses
///    edge A->B.  The **half-open y-interval** rule `[min_y, max_y)` ensures
///    that a ray passing through a vertex is counted exactly once.
/// 3. After all edges: an **odd** crossing count means `Inside`; **even** means
///    `Outside`.
///
/// ## Complexity
///
/// - Time:  O(n) -- one pass over the n edges.
/// - Space: O(1) -- no auxiliary storage.
///
/// ## Preconditions
///
/// - The polygon must be **simple** (no self-intersections).
/// - Vertices may be given in either clockwise or counter-clockwise order.
/// - A polygon with fewer than 3 vertices always returns `Outside`.
///
/// ## Example
///
/// ```moonbit nocheck
/// let square : Array[@point_in_polygon.Point] = [
///   { x: 0L, y: 0L },
///   { x: 4L, y: 0L },
///   { x: 4L, y: 4L },
///   { x: 0L, y: 4L },
/// ]
///
/// let r1 = @point_in_polygon.point_in_polygon(square, { x: 2L, y: 2L })
/// // r1 is Inside
///
/// let r2 = @point_in_polygon.point_in_polygon(square, { x: 5L, y: 2L })
/// // r2 is Outside
///
/// let r3 = @point_in_polygon.point_in_polygon(square, { x: 4L, y: 2L })
/// // r3 is Boundary
/// ```
pub fn point_in_polygon(poly : Array[Point], p : Point) -> Location {
  let n = poly.length()
  if n < 3 {
    return Outside
  }
  let inside = for b in poly; a = poly[n - 1], inside = false {
    let c = cross(a, b, p)
    if c == 0 && on_segment(a, b, p) {
      return Boundary
    }
    let above_a = a.y > p.y
    let above_b = b.y > p.y
    if above_a != above_b {
      let lhs = (b.x - a.x) * (p.y - a.y)
      let rhs = (p.x - a.x) * (b.y - a.y)
      let intersects = if b.y > a.y { lhs > rhs } else { lhs < rhs }
      if intersects {
        continue b, !inside
      } else {
        continue b, inside
      }
    } else {
      continue b, inside
    }
  } nobreak {
    inside
  }
  if inside {
    Inside
  } else {
    Outside
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "point in polygon square" {
  let poly : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]
  debug_inspect(point_in_polygon(poly, { x: 2L, y: 2L }), content="Inside")
  debug_inspect(point_in_polygon(poly, { x: 5L, y: 2L }), content="Outside")
  debug_inspect(point_in_polygon(poly, { x: 4L, y: 2L }), content="Boundary")
}
