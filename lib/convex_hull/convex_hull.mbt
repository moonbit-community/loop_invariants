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
/// 2D Point with integer coordinates
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Show, Eq)

///|
/// Cross product of vectors OA and OB
/// Positive = counterclockwise, Zero = collinear, Negative = clockwise
fn cross(o : Point, a : Point, b : Point) -> Int64 {
  (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
}

///|
/// Compare points for sorting: by x first, then by y
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
/// Compute convex hull using Monotone Chain algorithm
/// Returns points in counterclockwise order starting from leftmost point
///
/// ALGORITHM:
/// 1. Sort points lexicographically (by x, then y)
/// 2. Build lower hull: process points left-to-right
/// 3. Build upper hull: process points right-to-left
/// 4. Concatenate (removing duplicate endpoints)
///
/// INVARIANT: At each step, hull[] forms a convex chain with right turns only
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
  for i = 0; i < n; i = i + 1 {
    // While last two points and sorted[i] don't make a right turn, remove last
    while hull.length() >= 2 {
      let top = hull[hull.length() - 1]
      let second = hull[hull.length() - 2]
      if cross(second, top, sorted[i]) <= 0L {
        let _ = hull.pop()

      } else {
        break
      }
    }
    hull.push(sorted[i])
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (lower hull):
      #|hull contains the lower hull for points in sorted[0..i).
      #|MAINTENANCE:
      #|Pop while the last three points make a non-right turn, then push sorted[i].
      #|Removed points are interior or collinear and cannot be on the lower hull.
      #|TERMINATION:
      #|At i = n, hull is the full lower hull in left-to-right order.
    ),
  }

  // Build upper hull
  let lower_len = hull.length()
  // INVARIANT: hull[lower_len:] contains upper hull in right-to-left order
  for i = n - 2; i >= 0; i = i - 1 {
    while hull.length() > lower_len {
      let top = hull[hull.length() - 1]
      let second = hull[hull.length() - 2]
      if cross(second, top, sorted[i]) <= 0L {
        let _ = hull.pop()

      } else {
        break
      }
    }
    hull.push(sorted[i])
  } where {
    invariant: i >= -1 && i <= n - 2,
    reasoning: (
      #|INVARIANT (upper hull):
      #|hull[0..lower_len] is the completed lower hull; hull[lower_len..] is the
      #|partial upper hull built from sorted points in (i, n).
      #|MAINTENANCE:
      #|Process points right-to-left, popping while convexity is violated, then
      #|push sorted[i] to extend the upper hull.
      #|TERMINATION:
      #|At i = -1, the upper hull is complete; combined with lower hull, the
      #|polygon is closed (duplicate endpoint removed).
    ),
  }

  // Remove last point (duplicate of first)
  let _ = hull.pop()
  hull
}

// ============================================================================
// GRAHAM SCAN
// ============================================================================

///|
/// Compute convex hull using Graham Scan algorithm
/// Returns points in counterclockwise order
///
/// ALGORITHM:
/// 1. Find the bottom-most point (pivot)
/// 2. Sort other points by polar angle with pivot
/// 3. Process points, maintaining convex hull invariant
pub fn convex_hull_graham(points : Array[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 2 {
    return points.copy()
  }

  // Find bottom-most point (and leftmost if tied)
  let pts = points.copy()
  let mut pivot_idx = 0
  for i = 1; i < n; i = i + 1 {
    if pts[i].y < pts[pivot_idx].y ||
      (pts[i].y == pts[pivot_idx].y && pts[i].x < pts[pivot_idx].x) {
      pivot_idx = i
    }
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|INVARIANT (pivot scan):
      #|pivot_idx is the lowest (then leftmost) point among pts[0..i).
      #|MAINTENANCE:
      #|Compare pts[i] to the current pivot and update if it is lower/leftmost.
      #|TERMINATION:
      #|At i = n, pivot_idx is the lowest-leftmost point.
    ),
  }

  // Swap pivot to first position
  let temp = pts[0]
  pts[0] = pts[pivot_idx]
  pts[pivot_idx] = temp
  let pivot = pts[0]

  // Sort by polar angle with pivot
  // For points with same angle, keep the farthest one
  let rest : Array[Point] = []
  for i = 1; i < n; i = i + 1 {
    rest.push(pts[i])
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|INVARIANT (rest points):
      #|rest contains pts[1..i) (all points except the pivot).
      #|MAINTENANCE:
      #|Append pts[i] to rest.
      #|TERMINATION:
      #|At i = n, rest contains all non-pivot points.
    ),
  }
  rest.sort_by(fn(a, b) {
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
  for i = 0; i < rest.length(); i = i + 1 {
    // Remove points that would make a right turn
    while hull.length() >= 2 {
      let top = hull[hull.length() - 1]
      let second = hull[hull.length() - 2]
      if cross(second, top, rest[i]) <= 0L {
        let _ = hull.pop()

      } else {
        break
      }
    }
    hull.push(rest[i])
  } where {
    invariant: i >= 0 && i <= rest.length(),
    reasoning: (
      #|INVARIANT (Graham scan):
      #|hull is the convex hull of the processed points in rest[0..i), in CCW
      #|order, starting at pivot.
      #|MAINTENANCE:
      #|Pop while the last three points make a non-left turn, then push rest[i].
      #|TERMINATION:
      #|At i = rest.length(), hull is the convex hull in CCW order.
    ),
  }
  hull
}

// ============================================================================
// JARVIS MARCH (GIFT WRAPPING)
// ============================================================================

///|
/// Compute convex hull using Jarvis March (Gift Wrapping) algorithm
/// Returns points in counterclockwise order
///
/// TIME: O(nh) where h is the number of hull points
/// Best when h is small (output-sensitive)
///
/// ALGORITHM:
/// 1. Start from the leftmost point
/// 2. Find the point that makes the smallest counterclockwise angle
/// 3. Repeat until we return to the start
///
/// INVARIANT: At each iteration, current point is on the hull
pub fn convex_hull_jarvis(points : Array[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 2 {
    return points.copy()
  }

  // Find leftmost point
  let mut leftmost = 0
  for i = 1; i < n; i = i + 1 {
    if points[i].x < points[leftmost].x ||
      (points[i].x == points[leftmost].x && points[i].y < points[leftmost].y) {
      leftmost = i
    }
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|INVARIANT (leftmost scan):
      #|leftmost is the leftmost point among points[0..i).
      #|MAINTENANCE:
      #|Compare points[i] to the current leftmost and update if needed.
      #|TERMINATION:
      #|At i = n, leftmost is the leftmost (then lowest) point.
    ),
  }
  let hull : Array[Point] = []
  let mut current = leftmost

  // INVARIANT: hull contains points on the convex hull in CCW order
  // current is the index of the most recently added hull point
  for {
    hull.push(points[current])

    // Find the point that is most counterclockwise from current
    let mut next = 0
    if current == 0 {
      next = 1
    }
    for i = 0; i < n; i = i + 1 {
      if i == current {
        continue
      }
      let cp = cross(points[current], points[next], points[i])
      if cp < 0L {
        // points[i] is more counterclockwise
        next = i
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
          next = i
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (next candidate):
        #|next is the best candidate among points[0..i) for the next hull point.
        #|MAINTENANCE:
        #|Compare points[i] to next using orientation and distance for collinear.
        #|TERMINATION:
        #|At i = n, next is the most counterclockwise choice.
      ),
    }
    current = next

    // Stop when we return to the starting point
    if current == leftmost {
      break
    }
  } where {
    invariant: current >= 0 && current < n && hull.length() <= n,
    reasoning: (
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
/// Calculate the area of a polygon (can be used on convex hull)
/// Returns twice the area (to avoid floating point)
pub fn polygon_area_2x(hull : Array[Point]) -> Int64 {
  let n = hull.length()
  if n < 3 {
    return 0L
  }

  // Shoelace formula
  // INVARIANT: area accumulates signed areas of triangles from origin
  // Shoelace formula sums cross products of adjacent edges; total equals 2x signed area
  let mut area = 0L
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    let delta = hull[i].x * hull[j].y - hull[j].x * hull[i].y
    area = area + delta
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (shoelace):
      #|area accumulates cross terms for edges in [0, i).
      #|MAINTENANCE:
      #|Add the cross term for edge (i, i+1).
      #|TERMINATION:
      #|At i = n, area is the full shoelace sum.
    ),
  }
  if area < 0L {
    -area
  } else {
    area
  }
}

///|
/// Check if a point is inside or on the convex hull
/// Returns: 1 = inside, 0 = on boundary, -1 = outside
pub fn point_in_hull(hull : Array[Point], p : Point) -> Int {
  let n = hull.length()
  if n < 3 {
    return -1
  }

  // Check if point is on the same side of all edges
  let mut on_boundary = false
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    let cp = cross(hull[i], hull[j], p)
    if cp < 0L {
      return -1 // Outside
    } else if cp == 0L {
      // Check if point is on the edge segment
      let min_x = if hull[i].x < hull[j].x { hull[i].x } else { hull[j].x }
      let max_x = if hull[i].x > hull[j].x { hull[i].x } else { hull[j].x }
      let min_y = if hull[i].y < hull[j].y { hull[i].y } else { hull[j].y }
      let max_y = if hull[i].y > hull[j].y { hull[i].y } else { hull[j].y }
      if p.x >= min_x && p.x <= max_x && p.y >= min_y && p.y <= max_y {
        on_boundary = true
      }
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (point-in-hull):
      #|p has been checked against edges in [0, i) and is on the left side.
      #|MAINTENANCE:
      #|Check edge (i, i+1); if p is to the right, return outside.
      #|TERMINATION:
      #|At i = n, p lies inside or on all hull edges.
    ),
  }
  if on_boundary {
    0
  } else {
    1
  }
}

///|
/// Find the diameter of a convex hull (farthest pair of points)
/// Uses rotating calipers - O(n)
/// Returns twice the squared distance
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
  let mut max_dist = 0L
  for i = 0, j = 1; i < n; {
    // Find the farthest point from edge (i, i+1)
    let i_next = (i + 1) % n
    let mut curr_j = j

    // Advance j while it increases distance
    for {
      let j_next = (curr_j + 1) % n
      let area_curr = cross(hull[i], hull[i_next], hull[curr_j])
      let area_next = cross(hull[i], hull[i_next], hull[j_next])
      if area_next > area_curr {
        curr_j = j_next
      } else {
        break
      }
    } where {
      invariant: curr_j >= 0 && curr_j < n,
      reasoning: (
        #|INVARIANT (advance antipodal):
        #|curr_j stays a valid hull index; it is the best antipodal candidate so far.
        #|MAINTENANCE:
        #|Advance to j_next only when the area (distance proxy) increases.
        #|TERMINATION:
        #|Stop when further rotation does not improve the area.
      ),
    }

    // Check distances from both endpoints of edge to antipodal point
    let dx1 = hull[curr_j].x - hull[i].x
    let dy1 = hull[curr_j].y - hull[i].y
    let dist1 = dx1 * dx1 + dy1 * dy1
    let dx2 = hull[curr_j].x - hull[i_next].x
    let dy2 = hull[curr_j].y - hull[i_next].y
    let dist2 = dx2 * dx2 + dy2 * dy2
    if dist1 > max_dist {
      max_dist = dist1
    }
    if dist2 > max_dist {
      max_dist = dist2
    }
    continue i + 1, curr_j
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
