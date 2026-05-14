// ============================================================================
// JARVIS MARCH (GIFT WRAPPING)  -  Jarvis 1973
// ============================================================================
//
// PROBLEM
//
// Given `n` points in the plane, compute the convex hull -- the
// smallest convex polygon containing every input point, returned
// counter-clockwise.
//
// THE IDEA
//
// "Wrap" the hull, one vertex at a time, like wrapping a gift. Start
// from the lowest-leftmost point (which must be on the hull). At each
// step, the next hull vertex is the point `q` that lies "most counter-
// clockwise" relative to the current direction -- equivalently, the
// point `q` such that every other remaining point is to the LEFT of
// the directed line `current -> q`. Repeat until we return to the
// starting point.
//
// COMPLEXITY
//
//   Time  : O(n * h) where h is the number of hull vertices.
//   Space : O(h)
//
// This is **output-sensitive**: when the hull has few vertices,
// Jarvis is much faster than `O(n log n)` algorithms like Graham scan
// or Andrew's monotone chain. For example, if only `O(log n)` hull
// points, Jarvis runs in `O(n log n)` total. The worst case (`h = n`,
// all points on the hull) is `O(n^2)`.
//
// THE INVARIANT
//
//   "After processing iteration k, the partial hull contains the
//    k-th counter-clockwise hull vertex, and every input point is
//    in the closed half-plane to the LEFT of the directed edge from
//    the previous vertex to the new one."
//
//   Equivalently: at every step, picking the "leftmost-relative"
//   candidate never excludes a true hull vertex, because that vertex
//   would also be a valid choice (the leftmost candidate is unique
//   only up to colinear ties).

///|
/// A 2D point with Double coordinates.
pub struct JmPoint {
  x : Double
  y : Double
} derive(Eq)

///|
/// Construct a point.
pub fn jm_point(x : Double, y : Double) -> JmPoint {
  { x, y }
}

///|
/// Signed twice the area of triangle (a, b, c). Positive iff c is
/// to the left of directed line a -> b.
fn jm_cross(a : JmPoint, b : JmPoint, c : JmPoint) -> Double {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
/// Squared distance between two points.
fn jm_dist_sq(a : JmPoint, b : JmPoint) -> Double {
  let dx = a.x - b.x
  let dy = a.y - b.y
  dx * dx + dy * dy
}

///|
/// Compute the convex hull of `points` by gift-wrapping. Returns the
/// hull vertices in counter-clockwise order, starting from the
/// lowest-leftmost point. Collinear points on a hull edge are dropped
/// (only the farthest extreme is kept), matching most hull libraries.
///
/// ## Example
///
/// ```moonbit nocheck
/// let pts = [
///   @jarvis_march.jm_point(0.0, 0.0),
///   @jarvis_march.jm_point(1.0, 0.0),
///   @jarvis_march.jm_point(1.0, 1.0),
///   @jarvis_march.jm_point(0.0, 1.0),
///   @jarvis_march.jm_point(0.5, 0.5),  // interior, dropped
/// ]
/// @jarvis_march.convex_hull(pts)
/// // [(0,0), (1,0), (1,1), (0,1)]
/// ```
pub fn convex_hull(points : Array[JmPoint]) -> Array[JmPoint] {
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
  // Find the starting vertex: lowest-y; ties broken by smallest-x.
  let mut start = 0
  for i in 1..<n {
    if points[i].y < points[start].y ||
      (points[i].y == points[start].y && points[i].x < points[start].x) {
      start = i
    }
  }
  let hull : Array[JmPoint] = []
  let mut current = start
  // Watchdog limit -- at most n iterations.
  for _ in 0..<n {
    hull.push(points[current])
    // Find the "most counter-clockwise" candidate.
    let mut next = (current + 1) % n
    for i in 0..<n {
      if i == current {
        continue
      }
      let c = jm_cross(points[current], points[next], points[i])
      // c < 0: i is to the right of current -> next; `next` is not the
      //         "rightmost" candidate -- update to i so all other points
      //         end up on the LEFT (the convex-hull-going-CCW invariant).
      // c > 0: i is to the left of current -> next; `next` is fine.
      // c == 0: collinear -- prefer the farther point so we skip interior
      //         collinears.
      if c < 0.0 {
        next = i
      } else if c == 0.0 &&
        jm_dist_sq(points[current], points[i]) >
        jm_dist_sq(points[current], points[next]) {
        next = i
      }
    }
    if next == start {
      break
    }
    current = next
  }
  hull
}

///|
test "jarvis empty" {
  @debug.assert_eq(convex_hull([]).length(), 0)
}

///|
test "jarvis single point" {
  let h = convex_hull([jm_point(1.0, 2.0)])
  @debug.assert_eq(h.length(), 1)
}

///|
test "jarvis two points" {
  let h = convex_hull([jm_point(0.0, 0.0), jm_point(3.0, 4.0)])
  @debug.assert_eq(h.length(), 2)
}

///|
test "jarvis square with interior" {
  let pts = [
    jm_point(0.0, 0.0),
    jm_point(1.0, 0.0),
    jm_point(1.0, 1.0),
    jm_point(0.0, 1.0),
    jm_point(0.5, 0.5),
    jm_point(0.25, 0.75),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 4)
}

///|
test "jarvis triangle" {
  let pts = [jm_point(0.0, 0.0), jm_point(2.0, 0.0), jm_point(1.0, 2.0)]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 3)
}

///|
test "jarvis collinear interior dropped" {
  // Three collinear points on x-axis + one above; hull is triangle.
  let pts = [
    jm_point(0.0, 0.0),
    jm_point(1.0, 0.0),
    jm_point(2.0, 0.0),
    jm_point(1.0, 1.0),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 3)
}

///|
test "jarvis all collinear" {
  let pts = [
    jm_point(0.0, 0.0),
    jm_point(1.0, 0.0),
    jm_point(2.0, 0.0),
    jm_point(3.0, 0.0),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 2)
}

///|
test "jarvis ccw orientation" {
  let pts = [
    jm_point(0.0, 0.0),
    jm_point(2.0, 0.0),
    jm_point(2.0, 2.0),
    jm_point(0.0, 2.0),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h.length(), 4)
  // CCW: signed area > 0.
  let mut area2 = 0.0
  for i in 0..<h.length() {
    let j = (i + 1) % h.length()
    area2 = area2 + h[i].x * h[j].y - h[j].x * h[i].y
  }
  @debug.assert_eq(area2 > 0.0, true)
}

///|
test "jarvis starts at lowest-leftmost" {
  // Lowest y is (0, 0). Hull starts there.
  let pts = [
    jm_point(2.0, 2.0),
    jm_point(0.0, 0.0),
    jm_point(2.0, 0.0),
    jm_point(0.0, 2.0),
  ]
  let h = convex_hull(pts)
  @debug.assert_eq(h[0].x, 0.0)
  @debug.assert_eq(h[0].y, 0.0)
}
