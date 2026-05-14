// ============================================================================
// QUICKHULL  -  Eddy 1977, Bykat 1978
// ============================================================================
//
// PROBLEM
//
// Given `n` points in the plane, compute the **convex hull**: the
// smallest convex polygon containing every point, returned as the
// counter-clockwise sequence of its vertices.
//
// THE IDEA
//
// Quickhull is the geometric analogue of Quicksort:
//
//   1. Pick the leftmost and rightmost points, P_min and P_max.
//      They are definitely on the hull. The line P_min - P_max
//      splits the remaining points into "above" and "below" sets.
//
//   2. For each side, find the point P_far that is **farthest** from
//      the line. P_far is on the hull (a basic fact about convex hulls).
//      Drop every point inside triangle P_min - P_far - P_max -- those
//      cannot be on the hull. Recurse on the points "outside" the two
//      new edges P_min - P_far and P_far - P_max.
//
//   3. Concatenate the upper and lower hulls.
//
// COMPLEXITY
//
//   Expected `O(n log n)` for points in general position, like
//   Quicksort. Worst case `O(n^2)` for adversarial inputs (e.g. all
//   points on a circle and a bad farthest-point pick), but in
//   practice extremely fast and constant-factor competitive with
//   Graham scan and Andrew's monotone chain.
//
// THE INVARIANT
//
//   "At every recursive call, the candidate set contains only points
//    strictly outside the current partial hull edge -- so any point
//    on the final hull that lies in the half-plane bounded by this
//    edge is still in the candidate set."
//
//   This is what guarantees correctness: a hull vertex never gets
//   discarded by accident, because it cannot be inside the triangle
//   formed by an edge and the farthest point.

///|
/// A 2D point with Double coordinates.
pub struct Point {
  x : Double
  y : Double
} derive(Eq)

///|
/// Construct a point.
pub fn point(x : Double, y : Double) -> Point {
  { x, y }
}

///|
/// Signed twice the area of the triangle (a, b, c). Positive iff
/// c is to the **left** of the directed line a -> b.
fn cross(a : Point, b : Point, c : Point) -> Double {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
/// Compute the convex hull of `points` and return the hull vertices
/// in counter-clockwise order, starting with the leftmost point.
/// Duplicate input points are tolerated; collinear interior points
/// on a hull edge are *omitted* from the result.
///
/// ## Example
///
/// ```moonbit nocheck
/// let pts = [
///   @quickhull.point(0.0, 0.0),
///   @quickhull.point(1.0, 0.0),
///   @quickhull.point(1.0, 1.0),
///   @quickhull.point(0.0, 1.0),
///   @quickhull.point(0.5, 0.5),
/// ]
///
/// let h = @quickhull.convex_hull(pts)
/// // h has length 4 -- the four corners of the unit square.
/// ```
pub fn convex_hull(points : Array[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 1 {
    return points.copy()
  }
  if n == 2 {
    if points[0] == points[1] {
      return [points[0]]
    } else {
      return [points[0], points[1]]
    }
  }
  // Find leftmost and rightmost points (ties broken by y).
  let mut lo = 0
  let mut hi = 0
  for i in 1..<n {
    if points[i].x < points[lo].x ||
      (points[i].x == points[lo].x && points[i].y < points[lo].y) {
      lo = i
    }
    if points[i].x > points[hi].x ||
      (points[i].x == points[hi].x && points[i].y > points[hi].y) {
      hi = i
    }
  }
  if lo == hi {
    // All points are coincident.
    return [points[lo]]
  }
  let p_lo = points[lo]
  let p_hi = points[hi]
  // Partition into "above" (left of lo -> hi) and "below" (right of lo -> hi).
  let above : Array[Point] = []
  let below : Array[Point] = []
  for i in 0..<n {
    if i == lo || i == hi {
      continue
    }
    let c = cross(p_lo, p_hi, points[i])
    if c > 0.0 {
      above.push(points[i])
    } else if c < 0.0 {
      below.push(points[i])
    }
  }
  // Recurse on each side.
  let upper = qh_find_hull(above, p_lo, p_hi)
  let lower = qh_find_hull(below, p_hi, p_lo)
  // Stitch CCW: start at p_lo, go below to p_hi (right-then-up sweep),
  // then above back to p_lo (left-then-down sweep). With math y-up,
  // this is counter-clockwise.
  let result : Array[Point] = []
  result.push(p_lo)
  for v in lower {
    result.push(v)
  }
  result.push(p_hi)
  for v in upper {
    result.push(v)
  }
  result
}

///|
/// Recursive sub-routine: given a list of points all strictly to the
/// left of the directed line `a -> b`, return the points that lie on
/// the hull, ordered along the boundary from `a` to `b`.
fn qh_find_hull(points : Array[Point], a : Point, b : Point) -> Array[Point] {
  if points.length() == 0 {
    return []
  }
  // Find the point farthest from line a -> b.
  let mut best_idx = 0
  let mut best_dist = 0.0
  for i in 0..<points.length() {
    let d = cross(a, b, points[i])
    if d > best_dist {
      best_dist = d
      best_idx = i
    }
  }
  let p_far = points[best_idx]
  // Split remaining points: those left of a -> p_far go to one set,
  // those left of p_far -> b go to the other. Points inside the
  // triangle (or on the new edges) are discarded.
  let left_set : Array[Point] = []
  let right_set : Array[Point] = []
  for i in 0..<points.length() {
    if i == best_idx {
      continue
    }
    let c_ap = cross(a, p_far, points[i])
    if c_ap > 0.0 {
      left_set.push(points[i])
      continue
    }
    let c_pb = cross(p_far, b, points[i])
    if c_pb > 0.0 {
      right_set.push(points[i])
    }
  }
  let left_hull = qh_find_hull(left_set, a, p_far)
  let right_hull = qh_find_hull(right_set, p_far, b)
  let result : Array[Point] = []
  for v in left_hull {
    result.push(v)
  }
  result.push(p_far)
  for v in right_hull {
    result.push(v)
  }
  result
}

///|
test "quickhull empty" {
  let h = convex_hull([])
  @debug.assert_eq(h.length(), 0)
}

///|
test "quickhull single point" {
  let h = convex_hull([point(1.0, 2.0)])
  @debug.assert_eq(h.length(), 1)
  @debug.assert_eq(h[0].x, 1.0)
  @debug.assert_eq(h[0].y, 2.0)
}

///|
test "quickhull two points" {
  let h = convex_hull([point(0.0, 0.0), point(1.0, 1.0)])
  @debug.assert_eq(h.length(), 2)
}

///|
test "quickhull duplicated points" {
  let h = convex_hull([point(1.0, 1.0), point(1.0, 1.0), point(1.0, 1.0)])
  @debug.assert_eq(h.length(), 1)
}

///|
test "quickhull square with interior" {
  let pts = [
    point(0.0, 0.0),
    point(1.0, 0.0),
    point(1.0, 1.0),
    point(0.0, 1.0),
    point(0.5, 0.5),
    point(0.3, 0.7),
    point(0.7, 0.3),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 4)
}

///|
test "quickhull triangle" {
  let pts = [point(0.0, 0.0), point(2.0, 0.0), point(1.0, 2.0)]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 3)
}

///|
test "quickhull collinear edge" {
  // 3 points on a line plus one above -- hull should be triangle
  // (interior collinear point dropped).
  let pts = [point(0.0, 0.0), point(1.0, 0.0), point(2.0, 0.0), point(1.0, 1.0)]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 3)
}

///|
test "quickhull all collinear" {
  let pts = [point(0.0, 0.0), point(1.0, 0.0), point(2.0, 0.0), point(3.0, 0.0)]
  let h = convex_hull(pts)
  // Just two endpoints when all points are collinear.
  @debug.assert_eq(h.length(), 2)
}

///|
test "quickhull ccw orientation" {
  let pts = [point(0.0, 0.0), point(2.0, 0.0), point(2.0, 2.0), point(0.0, 2.0)]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 4)
  // Signed area > 0 iff CCW.
  let mut area2 = 0.0
  for i in 0..<h.length() {
    let j = (i + 1) % h.length()
    area2 = area2 + h[i].x * h[j].y - h[j].x * h[i].y
  }
  @debug.assert_eq(area2 > 0.0, true)
}

///|
test "quickhull pentagon plus interior" {
  // Regular pentagon vertices plus several interior points.
  let pts = [
    point(1.0, 0.0),
    point(0.309, 0.951),
    point(-0.809, 0.588),
    point(-0.809, -0.588),
    point(0.309, -0.951),
    point(0.0, 0.0),
    point(0.1, 0.1),
    point(-0.1, -0.1),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 5)
}
