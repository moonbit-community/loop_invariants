// ============================================================================
// CONVEX HULL - Computational Geometry
// ============================================================================
//
// The convex hull of a set of points is the smallest convex polygon that
// contains all the points. Think of it as stretching a rubber band around
// all the points.
//
// KEY INSIGHT: A point P is on the convex hull if and only if it cannot be
// expressed as a convex combination of other points.
//
// ALGORITHMS IMPLEMENTED:
// 1. Monotone Chain (Andrew's Algorithm) - O(n log n)
// 2. Graham Scan - O(n log n)
// 3. Jarvis March (Gift Wrapping) - O(nh) where h = hull size
//
// CROSS PRODUCT:
// For vectors OA and OB, cross product OA × OB tells us the orientation:
// - Positive: counterclockwise (left turn)
// - Zero: collinear
// - Negative: clockwise (right turn)
//
// cross(O, A, B) = (A.x - O.x) * (B.y - O.y) - (A.y - O.y) * (B.x - O.x)
//
// MONOTONE CHAIN ALGORITHM:
// 1. Sort points by x-coordinate (then y for ties)
// 2. Build lower hull: left to right, keeping only right turns
// 3. Build upper hull: right to left, keeping only right turns
// 4. Concatenate lower and upper hulls
//
// INVARIANTS:
// 1. At each step, the hull array forms a convex chain
// 2. New points only extend or replace tail of chain
// 3. Cross product test ensures convexity
//
// TIME COMPLEXITY: O(n log n) for sorting, O(n) for hull construction
// SPACE COMPLEXITY: O(n)

///|
/// A 2D point with 64-bit integer coordinates.
///
/// Using `Int64` avoids overflow in cross-product computations for coordinate
/// values up to about 3 billion. All convex-hull functions in this package
/// accept and return `Array[Point]`.
///
/// Example:
/// ```
/// let p : Point = { x: 3L, y: 4L }
/// ```
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Debug, Eq)

///|
/// Compute the 2D cross product of vectors OA and OB.
///
/// Returns a positive value when the turn O -> A -> B is counterclockwise
/// (left turn), zero when the three points are collinear, and a negative value
/// when the turn is clockwise (right turn).
///
/// Formula: `(A.x - O.x) * (B.y - O.y) - (A.y - O.y) * (B.x - O.x)`
fn cross(o : Point, a : Point, b : Point) -> Int64 {
  (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
}

///|
/// Lexicographic comparator for `Point`: sorts by x first, then by y.
///
/// Returns -1, 0, or 1 in the style expected by `Array::sort_by`.
fn point_compare(a : Point, b : Point) -> Int {
  if a.x != b.x {
    if a.x < b.x {
      -1
    } else {
      1
    }
  } else if a.y != b.y {
    if a.y < b.y {
      -1
    } else {
      1
    }
  } else {
    0
  }
}

// ============================================================================
// MONOTONE CHAIN (ANDREW'S ALGORITHM)
// ============================================================================

///|
/// Compute the convex hull using Andrew's monotone chain algorithm.
///
/// Returns the hull vertices in counterclockwise order, starting from the
/// lexicographically smallest point (bottom-left). The last point is NOT
/// repeated; the closing edge is implicit from last back to first.
///
/// Time: O(n log n). Space: O(n).
///
/// Steps:
/// 1. Sort points lexicographically (by x, then by y for ties).
/// 2. Build the lower hull left-to-right, discarding any non-right-turn.
/// 3. Build the upper hull right-to-left with the same rule.
/// 4. Concatenate, dropping the shared endpoints.
///
/// Invariant maintained during both passes: every consecutive triple in the
/// growing chain makes a strict right turn, guaranteeing convexity.
pub fn convex_hull_monotone(points : Array[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 2 {
    return points.copy()
  }

  // Sort points lexicographically
  let sorted = points.copy()
  sorted.sort_by(point_compare)
  let hull : Array[Point] = []

  // Build lower hull
  // INVARIANT: hull contains lower hull points in left-to-right order
  // Each consecutive triple makes a right turn (or is collinear)
  for i in 0..<n {
    // While last two points and sorted[i] don't make a right turn, remove last
    for pop_next = hull.length() >= 2; pop_next; {
      let top = hull[hull.length() - 1]
      let second = hull[hull.length() - 2]
      if cross(second, top, sorted[i]) <= 0L {
        let _ = hull.pop()
        continue hull.length() >= 2
      } else {
        break
      }
    }
    hull.push(sorted[i])
  }

  // Build upper hull
  let lower_len = hull.length()
  // INVARIANT: hull[lower_len:] contains upper hull in right-to-left order
  let start_exclusive = n - 1
  for i in start_exclusive>..0 {
    for pop_next = hull.length() > lower_len; pop_next; {
      let top = hull[hull.length() - 1]
      let second = hull[hull.length() - 2]
      if cross(second, top, sorted[i]) <= 0L {
        let _ = hull.pop()
        continue hull.length() > lower_len
      } else {
        break
      }
    }
    hull.push(sorted[i])
  }

  // Remove last point (duplicate of first)
  let _ = hull.pop()
  hull
}

///|
/// Compute the convex hull from an `ArrayView[Point]`.
///
/// This is a convenience wrapper around `convex_hull_monotone` that accepts a
/// slice of an array without requiring an explicit copy at the call site. The
/// returned array follows the same counterclockwise ordering.
///
/// Example:
/// ```
/// let pts : Array[@convex_hull.Point] = [
///   { x: 0L, y: 0L }, { x: 4L, y: 0L },
///   { x: 4L, y: 4L }, { x: 0L, y: 4L },
///   { x: 2L, y: 2L },
/// ]
/// let hull = @convex_hull.convex_hull(pts[:])
/// // hull.length() == 4
/// ```
pub fn convex_hull(points : ArrayView[Point]) -> Array[Point] {
  convex_hull_monotone(points.to_owned())
}

// ============================================================================
// GRAHAM SCAN
// ============================================================================

///|
/// Compute the convex hull using the Graham scan algorithm.
///
/// Returns hull vertices in counterclockwise order, starting from the
/// bottom-most (then leftmost) point.
///
/// Time: O(n log n). Space: O(n).
///
/// Steps:
/// 1. Pick the pivot: the point with the lowest y-coordinate (leftmost on tie).
/// 2. Sort the remaining points by polar angle relative to the pivot;
///    for collinear points, place the farthest one first.
/// 3. Maintain a stack of hull candidates: pop the top whenever adding the next
///    point would create a clockwise (or collinear) turn.
///
/// Invariant: the stack always contains a strictly convex chain in
/// counterclockwise order around the pivot.
pub fn convex_hull_graham(points : Array[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 2 {
    return points.copy()
  }

  // Find bottom-most point (and leftmost if tied)
  let pts = points.copy()
  let pivot_idx = for i = 1, pivot_idx = 0; i < n; {
    let pivot_idx = if pts[i].y < pts[pivot_idx].y ||
      (pts[i].y == pts[pivot_idx].y && pts[i].x < pts[pivot_idx].x) {
      i
    } else {
      pivot_idx
    }
    continue i + 1, pivot_idx
  } nobreak {
    pivot_idx
  }

  // Swap pivot to first position
  let temp = pts[0]
  pts[0] = pts[pivot_idx]
  pts[pivot_idx] = temp
  let pivot = pts[0]

  // Sort by polar angle with pivot
  // For points with same angle, keep the farthest one
  let rest = pts[1:].to_owned()
  rest.sort_by((a, b) => {
    let cp = cross(pivot, a, b)
    if cp > 0L {
      -1 // a comes before b (counterclockwise)
    } else if cp < 0L {
      1 // b comes before a
    } else {
      // Collinear: keep the one farther from pivot first
      let dist_a = (a.x - pivot.x) * (a.x - pivot.x) +
        (a.y - pivot.y) * (a.y - pivot.y)
      let dist_b = (b.x - pivot.x) * (b.x - pivot.x) +
        (b.y - pivot.y) * (b.y - pivot.y)
      if dist_a > dist_b {
        -1
      } else {
        1
      }
    }
  })

  // Graham scan
  let hull : Array[Point] = [pivot]

  // INVARIANT: hull forms a convex polygon with counterclockwise orientation
  for point in rest {
    // Remove points that would make a right turn
    for pop_next = hull.length() >= 2; pop_next; {
      let top = hull[hull.length() - 1]
      let second = hull[hull.length() - 2]
      if cross(second, top, point) <= 0L {
        let _ = hull.pop()
        continue hull.length() >= 2
      } else {
        break
      }
    }
    hull.push(point)
  }
  hull
}

// ============================================================================
// JARVIS MARCH (GIFT WRAPPING)
// ============================================================================

///|
/// Compute the convex hull using the Jarvis march (gift-wrapping) algorithm.
///
/// Returns hull vertices in counterclockwise order, starting from the
/// leftmost (then bottom-most) point.
///
/// Time: O(n * h), where h is the number of hull vertices. This is
/// output-sensitive: when h is small (e.g. h = O(log n)) it can be faster
/// than the O(n log n) sorting-based algorithms. In the worst case (all points
/// on the hull) it degrades to O(n^2).
///
/// Steps:
/// 1. Start from the leftmost point (guaranteed to be on the hull).
/// 2. At each step, scan all remaining points and select the one that is most
///    counterclockwise relative to the current point.
/// 3. Stop when the selection returns to the starting point.
///
/// Invariant: every point in `hull` so far is a true hull vertex visited in
/// counterclockwise order; the current point is always a valid hull vertex.
pub fn convex_hull_jarvis(points : Array[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 2 {
    return points.copy()
  }

  // Find leftmost point
  let leftmost = for i = 1, leftmost = 0; i < n; {
    let leftmost = if points[i].x < points[leftmost].x ||
      (points[i].x == points[leftmost].x && points[i].y < points[leftmost].y) {
      i
    } else {
      leftmost
    }
    continue i + 1, leftmost
  } nobreak {
    leftmost
  }
  let hull : Array[Point] = []

  // INVARIANT: hull contains points on the convex hull in CCW order
  // current is the index of the most recently added hull point
  for current = leftmost {
    hull.push(points[current])

    // Find the point that is most counterclockwise from current
    let next = for i = 0, next = (if current == 0 { 1 } else { 0 }); i < n; {
      if i == current {
        continue i + 1, next
      }
      let cp = cross(points[current], points[next], points[i])
      let next = if cp < 0L {
        i
      } else if cp == 0L {
        // Collinear: choose the farther point
        let dist_next = (points[next].x - points[current].x) *
          (points[next].x - points[current].x) +
          (points[next].y - points[current].y) *
          (points[next].y - points[current].y)
        let dist_i = (points[i].x - points[current].x) *
          (points[i].x - points[current].x) +
          (points[i].y - points[current].y) * (points[i].y - points[current].y)
        if dist_i > dist_next {
          i
        } else {
          next
        }
      } else {
        next
      }
      continue i + 1, next
    } nobreak {
      next
    }

    // Stop when we return to the starting point
    if next == leftmost {
      break
    }
    continue next
  } where {
    proof_invariant: current >= 0 && current < n && hull.length() <= n,
    proof_reasoning: (
      #|INVARIANT (Jarvis march):
      #|current is a valid point index on the hull; hull stores the path so far.
      #|MAINTENANCE:
      #|Select the most counterclockwise next point and append it to hull.
      #|TERMINATION:
      #|When current returns to leftmost, the hull is closed within n steps.
    ),
  }
  hull
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

///|
/// Compute twice the signed area of a polygon using the shoelace formula.
///
/// Returns a non-negative `Int64` equal to `2 * area`. Returning twice the
/// area keeps the result as an exact integer (no floating-point rounding) for
/// integer-coordinate polygons.
///
/// The input array is treated as an ordered list of vertices (the closing edge
/// from the last vertex back to the first is implicit). Works for any simple
/// polygon; typically applied to the output of one of the hull functions.
///
/// Example: a unit square with vertices `(0,0), (1,0), (1,1), (0,1)` has area
/// 1, so this function returns 2.
pub fn polygon_area_2x(hull : Array[Point]) -> Int64 {
  let n = hull.length()
  if n < 3 {
    return 0L
  }

  // Shoelace formula: sum cross products of adjacent edges
  let area = hull[:].foldi(init=0L, (i, acc, point) => {
    let next = hull[(i + 1) % n]
    acc + point.x * next.y - next.x * point.y
  })
  if area < 0L {
    -area
  } else {
    area
  }
}

///|
/// Test whether a point lies inside, on the boundary of, or outside a convex
/// polygon.
///
/// The `hull` array must list the polygon's vertices in counterclockwise order
/// (as produced by the hull functions in this package).
///
/// Return values:
/// - `1`  -- the point is strictly inside the polygon.
/// - `0`  -- the point is on an edge or at a vertex.
/// - `-1` -- the point is strictly outside the polygon.
///
/// The algorithm checks the sign of the cross product for every directed edge.
/// A point outside will produce a negative cross product for at least one edge.
/// Time: O(n).
pub fn point_in_hull(hull : Array[Point], p : Point) -> Int {
  let n = hull.length()
  if n < 3 {
    return -1
  }

  // Check if point is on the same side of all edges
  let on_boundary = for i = 0, on_boundary = false; i < n; {
    let j = (i + 1) % n
    let cp = cross(hull[i], hull[j], p)
    if cp < 0L {
      return -1 // Outside
    }
    let on_boundary = if cp == 0L {
      // Check if point is on the edge segment
      let min_x = if hull[i].x < hull[j].x { hull[i].x } else { hull[j].x }
      let max_x = if hull[i].x > hull[j].x { hull[i].x } else { hull[j].x }
      let min_y = if hull[i].y < hull[j].y { hull[i].y } else { hull[j].y }
      let max_y = if hull[i].y > hull[j].y { hull[i].y } else { hull[j].y }
      if p.x >= min_x && p.x <= max_x && p.y >= min_y && p.y <= max_y {
        true
      } else {
        on_boundary
      }
    } else {
      on_boundary
    }
    continue i + 1, on_boundary
  } nobreak {
    on_boundary
  }
  if on_boundary {
    0
  } else {
    1
  }
}

///|
/// Find the squared diameter of a convex polygon (the farthest pair of vertices).
///
/// Uses the rotating calipers technique, which runs in O(n) time given a convex
/// polygon already in counterclockwise order. The result is the maximum squared
/// Euclidean distance over all pairs of hull vertices.
///
/// Returning the squared distance avoids floating-point arithmetic and is exact
/// for integer coordinates.
///
/// For a square with side length `s`, the diameter is the diagonal, so this
/// function returns `2 * s^2`. For a segment of length `d`, it returns `d^2`.
///
/// Time: O(n). Requires the hull to be convex and in counterclockwise order.
pub fn hull_diameter_squared(hull : Array[Point]) -> Int64 {
  let n = hull.length()
  if n < 2 {
    return 0L
  }
  if n == 2 {
    let dx = hull[1].x - hull[0].x
    let dy = hull[1].y - hull[0].y
    return dx * dx + dy * dy
  }

  // Rotating calipers algorithm
  // INVARIANT: For edge (i, i+1), j is the antipodal vertex
  let max_dist = for i = 0, j = 1, max_dist = 0L; i < n; {
    // Find the farthest point from edge (i, i+1)
    let i_next = (i + 1) % n

    // Advance j while it increases distance
    let j = for j = j {
      let j_next = (j + 1) % n
      let area_curr = cross(hull[i], hull[i_next], hull[j])
      let area_next = cross(hull[i], hull[i_next], hull[j_next])
      if area_next > area_curr {
        continue j_next
      } else {
        break j
      }
    } where {
      proof_invariant: j >= 0 && j < n,
      proof_reasoning: (
        #|INVARIANT (advance antipodal):
        #|j stays a valid hull index; it is the best antipodal candidate so far.
        #|MAINTENANCE:
        #|Advance to j_next only when the area (distance proxy) increases.
        #|TERMINATION:
        #|Stop when further rotation does not improve the area.
      ),
    }

    // Check distances from both endpoints of edge to antipodal point
    let dx1 = hull[j].x - hull[i].x
    let dy1 = hull[j].y - hull[i].y
    let dist1 = dx1 * dx1 + dy1 * dy1
    let dx2 = hull[j].x - hull[i_next].x
    let dy2 = hull[j].y - hull[i_next].y
    let dist2 = dx2 * dx2 + dy2 * dy2
    let edge_max = if dist1 > dist2 { dist1 } else { dist2 }
    let max_dist = if edge_max > max_dist { edge_max } else { max_dist }
    continue i + 1, j, max_dist
  } nobreak {
    max_dist
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (rotating calipers):
      #|j is the current antipodal candidate for edge (i, i+1), and max_dist
      #|tracks the best diameter so far.
      #|MAINTENANCE:
      #|Advance j while area increases, then update distances for edge endpoints.
      #|Convexity ensures j only moves forward.
      #|TERMINATION:
      #|After all edges, max_dist is the squared diameter; total time is O(n).
    ),
  }
  max_dist
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "monotone chain basic" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
    { x: 2L, y: 2L }, // Interior point
  ]
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="4")
}

///|
test "monotone chain triangle" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 2L, y: 3L },
  ]
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="3")
}

///|
test "graham scan basic" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
    { x: 2L, y: 2L },
  ]
  let hull = convex_hull_graham(points)
  inspect(hull.length(), content="4")
}

///|
test "jarvis march basic" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
    { x: 2L, y: 2L },
  ]
  let hull = convex_hull_jarvis(points)
  inspect(hull.length(), content="4")
}

///|
test "convex hull collinear points" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 1L, y: 0L },
    { x: 2L, y: 0L },
    { x: 3L, y: 0L },
  ]

  // Collinear points form a degenerate hull (line segment)
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="2")
}

///|
test "convex hull alias" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 2L, y: 0L },
    { x: 2L, y: 2L },
    { x: 0L, y: 2L },
    { x: 1L, y: 1L },
  ]
  let hull = convex_hull(points)
  inspect(hull.length(), content="4")
}

///|
test "convex hull single point" {
  let points : Array[Point] = [{ x: 5L, y: 5L }]
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="1")
}

///|
test "convex hull two points" {
  let points : Array[Point] = [{ x: 0L, y: 0L }, { x: 5L, y: 5L }]
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="2")
}

///|
test "polygon area" {
  // Square with side 4
  let square : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]
  // Area = 16, so 2x = 32
  inspect(polygon_area_2x(square), content="32")

  // Triangle with base 4, height 3
  let triangle : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 2L, y: 3L },
  ]
  // Area = 6, so 2x = 12
  inspect(polygon_area_2x(triangle), content="12")
}

///|
test "point in hull" {
  let square : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]

  // Inside
  inspect(point_in_hull(square, { x: 2L, y: 2L }), content="1")

  // On boundary
  inspect(point_in_hull(square, { x: 2L, y: 0L }), content="0")

  // On corner
  inspect(point_in_hull(square, { x: 0L, y: 0L }), content="0")

  // Outside
  inspect(point_in_hull(square, { x: 5L, y: 5L }), content="-1")
}

///|
test "hull diameter" {
  // Square with side 4, diameter is diagonal = sqrt(32)
  let square : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 4L, y: 4L },
    { x: 0L, y: 4L },
  ]
  // Diameter squared = 32
  inspect(hull_diameter_squared(square), content="32")
}

///|
test "convex hull complex" {
  // More complex shape with many interior points
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 10L, y: 0L },
    { x: 10L, y: 10L },
    { x: 0L, y: 10L },
    { x: 5L, y: 5L },
    { x: 3L, y: 3L },
    { x: 7L, y: 7L },
    { x: 2L, y: 8L },
    { x: 8L, y: 2L },
  ]
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="4")

  // Area should be 100, so 2x = 200
  inspect(polygon_area_2x(hull), content="200")
}

///|
test "all algorithms agree" {
  let points : Array[Point] = [
    { x: 1L, y: 2L },
    { x: 5L, y: 1L },
    { x: 8L, y: 4L },
    { x: 6L, y: 8L },
    { x: 2L, y: 7L },
    { x: 4L, y: 4L },
  ]
  let hull1 = convex_hull_monotone(points)
  let hull2 = convex_hull_graham(points)
  let hull3 = convex_hull_jarvis(points)

  // All should have the same size
  inspect(
    hull1.length() == hull2.length() && hull2.length() == hull3.length(),
    content="true",
  )
  inspect(hull1.length(), content="5")
}

///|
test "cross product" {
  let o = { x: 0L, y: 0L }
  let a = { x: 1L, y: 0L }
  let b = { x: 0L, y: 1L }

  // Counterclockwise
  inspect(cross(o, a, b) > 0L, content="true")

  // Clockwise
  inspect(cross(o, b, a) < 0L, content="true")

  // Collinear
  let c = { x: 2L, y: 0L }
  inspect(cross(o, a, c), content="0")
}

///|
test "convex hull empty" {
  let points : Array[Point] = []
  let hull = convex_hull_monotone(points)
  inspect(hull.length(), content="0")
}

///|
test "convex hull all same point" {
  let points : Array[Point] = [
    { x: 5L, y: 5L },
    { x: 5L, y: 5L },
    { x: 5L, y: 5L },
  ]
  let hull = convex_hull_monotone(points)
  // After sorting and processing, should have 1 unique point
  inspect(hull.length() >= 1, content="true")
}

///|
test "hull diameter line" {
  let points : Array[Point] = [{ x: 0L, y: 0L }, { x: 10L, y: 0L }]
  // Diameter = 10, squared = 100
  inspect(hull_diameter_squared(points), content="100")
}

///|
test "point in hull triangle" {
  let triangle : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 6L, y: 0L },
    { x: 3L, y: 6L },
  ]

  // Center of triangle (centroid)
  inspect(point_in_hull(triangle, { x: 3L, y: 2L }), content="1")

  // Outside
  inspect(point_in_hull(triangle, { x: 0L, y: 6L }), content="-1")
}
