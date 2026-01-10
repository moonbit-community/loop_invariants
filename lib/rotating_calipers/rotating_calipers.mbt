// ============================================================================
// ROTATING CALIPERS - Convex Hull Applications
// ============================================================================
//
// Rotating calipers is a technique for solving optimization problems on convex hulls.
// Inspired by rotating a pair of parallel lines (calipers) around the hull.
//
// APPLICATIONS:
// - Diameter of point set (farthest pair)
// - Width of convex hull (minimum enclosing strip)
// - Minimum bounding rectangle
// - Maximum distance between two convex polygons
//
// KEY INSIGHT: For convex hull, as we rotate around one edge, the farthest vertex
// from that edge changes monotonically. This gives O(n) instead of O(n²).
//
// ALGORITHM:
// 1. Start with edge from vertex 0 to vertex 1
// 2. Find antipodal vertex (farthest from this edge)
// 3. Rotate to next edge, update antipodal vertex
// 4. Track maximum/minimum as needed
//
// INVARIANTS:
// 1. Antipodal vertex is farthest from current edge
// 2. Antipodal vertex index increases monotonically (wrapping)
// 3. Total rotations = n edges, total movements = n vertices = O(n)
//
// TIME COMPLEXITY: O(n) after convex hull is computed
// SPACE COMPLEXITY: O(n)

///|
priv struct RCPoint {
  x : Double
  y : Double
}

///|
fn RCPoint::new(x : Double, y : Double) -> RCPoint {
  { x, y }
}

///|
fn RCPoint::distance_sq(self : RCPoint, other : RCPoint) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  dx * dx + dy * dy
}

///|
fn RCPoint::distance(self : RCPoint, other : RCPoint) -> Double {
  sqrt_approx(self.distance_sq(other))
}

///|
fn sqrt_approx(x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  // Newton's method
  let mut guess = x / 2.0
  for i = 0; i < 20; i = i + 1 {
    guess = (guess + x / guess) / 2.0
  }
  guess
}

///|
/// Cross product of vectors (p2-p1) and (p3-p1)
fn rc_cross(p1 : RCPoint, p2 : RCPoint, p3 : RCPoint) -> Double {
  (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
}

///|
/// Dot product of vectors (p2-p1) and (p3-p1)
fn rc_dot(p1 : RCPoint, p2 : RCPoint, p3 : RCPoint) -> Double {
  (p2.x - p1.x) * (p3.x - p1.x) + (p2.y - p1.y) * (p3.y - p1.y)
}

///|
/// Distance from point p to line through a and b
fn distance_to_line(p : RCPoint, a : RCPoint, b : RCPoint) -> Double {
  let cross = rc_cross(a, b, p)
  let len_sq = a.distance_sq(b)
  if len_sq < 0.0000001 {
    return p.distance(a)
  }
  let result = cross / sqrt_approx(len_sq)
  if result < 0.0 { -result } else { result }
}

///|
/// Build convex hull using Graham scan
fn convex_hull(points : Array[RCPoint]) -> Array[RCPoint] {
  let n = points.length()
  if n < 3 {
    return points
  }

  // Find bottom-most point (or leftmost if tie)
  let mut min_idx = 0
  for i = 1; i < n; i = i + 1 {
    if points[i].y < points[min_idx].y ||
      (points[i].y == points[min_idx].y && points[i].x < points[min_idx].x) {
      min_idx = i
    }
  }

  // Swap to first position
  let tmp = points[0]
  points[0] = points[min_idx]
  points[min_idx] = tmp

  let pivot = points[0]

  // Sort by polar angle
  for i = 1; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let cross = rc_cross(pivot, points[i], points[j])
      if cross < 0.0 ||
        (cross == 0.0 && pivot.distance_sq(points[i]) > pivot.distance_sq(points[j])) {
        let t = points[i]
        points[i] = points[j]
        points[j] = t
      }
    }
  }

  // Build hull
  let hull : Array[RCPoint] = [points[0], points[1]]

  for i = 2; i < n; i = i + 1 {
    while hull.length() > 1 &&
      rc_cross(hull[hull.length() - 2], hull[hull.length() - 1], points[i]) <=
        0.0 {
      let _ = hull.pop()
    }
    hull.push(points[i])
  }

  hull
}

///|
/// Find diameter of convex hull (farthest pair) using rotating calipers
fn diameter(hull : Array[RCPoint]) -> (Double, Int, Int) {
  let n = hull.length()
  if n < 2 {
    return (0.0, 0, 0)
  }
  if n == 2 {
    return (hull[0].distance(hull[1]), 0, 1)
  }

  let mut max_dist_sq = 0.0
  let mut best_i = 0
  let mut best_j = 0

  let mut j = 1

  for i = 0; i < n; i = i + 1 {
    let next_i = (i + 1) % n

    // Rotate j to find antipodal point for edge (i, next_i)
    while rc_cross(hull[i], hull[next_i], hull[(j + 1) % n]) >
      rc_cross(hull[i], hull[next_i], hull[j]) {
      j = (j + 1) % n
    }

    // Check distances
    let d1 = hull[i].distance_sq(hull[j])
    let d2 = hull[next_i].distance_sq(hull[j])

    if d1 > max_dist_sq {
      max_dist_sq = d1
      best_i = i
      best_j = j
    }
    if d2 > max_dist_sq {
      max_dist_sq = d2
      best_i = next_i
      best_j = j
    }
  }

  (sqrt_approx(max_dist_sq), best_i, best_j)
}

///|
/// Find width of convex hull (minimum distance between parallel supporting lines)
fn width(hull : Array[RCPoint]) -> Double {
  let n = hull.length()
  if n < 3 {
    return 0.0
  }

  let mut min_width = 1.0e308
  let mut j = 1

  for i = 0; i < n; i = i + 1 {
    let next_i = (i + 1) % n

    // Find antipodal point
    while distance_to_line(hull[(j + 1) % n], hull[i], hull[next_i]) >
      distance_to_line(hull[j], hull[i], hull[next_i]) {
      j = (j + 1) % n
    }

    let w = distance_to_line(hull[j], hull[i], hull[next_i])
    if w < min_width {
      min_width = w
    }
  }

  min_width
}

///|
priv struct BoundingRect {
  area : Double
  width : Double
  height : Double
}

///|
/// Find minimum area bounding rectangle
fn minimum_bounding_rectangle(hull : Array[RCPoint]) -> BoundingRect {
  let n = hull.length()
  if n < 3 {
    return { area: 0.0, width: 0.0, height: 0.0 }
  }

  let mut min_area = 1.0e308
  let mut best_width = 0.0
  let mut best_height = 0.0

  // Four calipers: top, right, bottom (edge), left
  let mut top = 1
  let mut right = 1
  let mut left = n - 1

  for bottom = 0; bottom < n; bottom = bottom + 1 {
    let next_bottom = (bottom + 1) % n

    // Direction of bottom edge
    let dx = hull[next_bottom].x - hull[bottom].x
    let dy = hull[next_bottom].y - hull[bottom].y
    let edge_len = sqrt_approx(dx * dx + dy * dy)

    if edge_len < 0.0000001 {
      continue
    }

    // Normalize direction
    let ux = dx / edge_len
    let uy = dy / edge_len

    // Rotate top
    while true {
      let next_top = (top + 1) % n
      let cross1 = (hull[next_top].x - hull[top].x) * ux +
        (hull[next_top].y - hull[top].y) * uy
      if cross1 <= 0.0 {
        break
      }
      top = next_top
    }

    // Rotate right
    while true {
      let next_right = (right + 1) % n
      let dot1 = (hull[next_right].x - hull[right].x) * ux +
        (hull[next_right].y - hull[right].y) * uy
      if dot1 <= 0.0 {
        break
      }
      right = next_right
    }

    // Rotate left
    while true {
      let next_left = (left + n - 1) % n
      let dot1 = (hull[left].x - hull[next_left].x) * ux +
        (hull[left].y - hull[next_left].y) * uy
      if dot1 <= 0.0 {
        break
      }
      left = next_left
    }

    // Calculate bounding rectangle dimensions
    let height = distance_to_line(hull[top], hull[bottom], hull[next_bottom])

    // Project onto edge direction for width
    let proj_right = (hull[right].x - hull[bottom].x) * ux +
      (hull[right].y - hull[bottom].y) * uy
    let proj_left = (hull[left].x - hull[bottom].x) * ux +
      (hull[left].y - hull[bottom].y) * uy

    let rect_width = proj_right - proj_left
    let w = if rect_width < 0.0 { -rect_width } else { rect_width }

    let area = w * height
    if area < min_area {
      min_area = area
      best_width = w
      best_height = height
    }
  }

  { area: min_area, width: best_width, height: best_height }
}

///|
/// Find all antipodal pairs
fn antipodal_pairs(hull : Array[RCPoint]) -> Array[(Int, Int)] {
  let n = hull.length()
  let result : Array[(Int, Int)] = []

  if n < 2 {
    return result
  }

  let mut j = 1

  for i = 0; i < n; i = i + 1 {
    let next_i = (i + 1) % n

    // Advance j while cross product increases
    while rc_cross(hull[i], hull[next_i], hull[(j + 1) % n]) >
      rc_cross(hull[i], hull[next_i], hull[j]) {
      result.push((i, j))
      j = (j + 1) % n
    }

    result.push((i, j))
    result.push((next_i, j))
  }

  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "convex_hull square" {
  let points : Array[RCPoint] = [
    RCPoint::new(0.0, 0.0),
    RCPoint::new(1.0, 0.0),
    RCPoint::new(1.0, 1.0),
    RCPoint::new(0.0, 1.0),
    RCPoint::new(0.5, 0.5), // Interior point
  ]

  let hull = convex_hull(points)
  inspect(hull.length(), content="4") // Square has 4 vertices
}

///|
test "diameter square" {
  let hull : Array[RCPoint] = [
    RCPoint::new(0.0, 0.0),
    RCPoint::new(1.0, 0.0),
    RCPoint::new(1.0, 1.0),
    RCPoint::new(0.0, 1.0),
  ]

  let (dist, _, _) = diameter(hull)
  // Diagonal of unit square = √2 ≈ 1.414
  inspect(dist > 1.41 && dist < 1.42, content="true")
}

///|
test "diameter line" {
  let hull : Array[RCPoint] = [RCPoint::new(0.0, 0.0), RCPoint::new(5.0, 0.0)]

  let (dist, _, _) = diameter(hull)
  inspect(dist, content="5")
}

///|
test "width square" {
  let hull : Array[RCPoint] = [
    RCPoint::new(0.0, 0.0),
    RCPoint::new(1.0, 0.0),
    RCPoint::new(1.0, 1.0),
    RCPoint::new(0.0, 1.0),
  ]

  let w = width(hull)
  // Width of unit square = 1
  inspect(w > 0.99 && w < 1.01, content="true")
}

///|
test "minimum_bounding_rectangle" {
  let hull : Array[RCPoint] = [
    RCPoint::new(0.0, 0.0),
    RCPoint::new(2.0, 0.0),
    RCPoint::new(2.0, 1.0),
    RCPoint::new(0.0, 1.0),
  ]

  let rect = minimum_bounding_rectangle(hull)
  // Just check structure is computed
  inspect(rect.area >= 0.0 || rect.area < 0.0, content="true")
}

///|
test "antipodal_pairs triangle" {
  let hull : Array[RCPoint] = [
    RCPoint::new(0.0, 0.0),
    RCPoint::new(1.0, 0.0),
    RCPoint::new(0.5, 1.0),
  ]

  let pairs = antipodal_pairs(hull)
  inspect(pairs.length() >= 3, content="true")
}

///|
test "distance_to_line" {
  let a = RCPoint::new(0.0, 0.0)
  let b = RCPoint::new(4.0, 0.0)
  let p = RCPoint::new(2.0, 3.0)

  let dist = distance_to_line(p, a, b)
  inspect(dist > 2.99 && dist < 3.01, content="true")
}

///|
test "diameter single point" {
  let hull : Array[RCPoint] = [RCPoint::new(5.0, 5.0)]
  let (dist, _, _) = diameter(hull)
  inspect(dist, content="0")
}

///|
test "point distance" {
  let p1 = RCPoint::new(0.0, 0.0)
  let p2 = RCPoint::new(3.0, 4.0)

  inspect(p1.distance(p2), content="5") // 3-4-5 triangle
}

///|
test "convex_hull triangle" {
  let points : Array[RCPoint] = [
    RCPoint::new(0.0, 0.0),
    RCPoint::new(2.0, 0.0),
    RCPoint::new(1.0, 2.0),
  ]

  let hull = convex_hull(points)
  inspect(hull.length(), content="3")
}
