// ============================================================================
// POINT IN POLYGON - Geometric Containment Test
// ============================================================================
//
// Determines if a point lies inside, outside, or on the boundary of a polygon.
// Uses ray casting algorithm (odd-even rule).
//
// RAY CASTING: Cast a horizontal ray from point to infinity.
// Count intersections with polygon edges.
// - Odd count: inside
// - Even count: outside
//
// WINDING NUMBER: Alternative method counts how many times the polygon
// winds around the point. Non-zero means inside.
//
// EDGE CASES:
// - Point on vertex or edge (boundary case)
// - Ray passing through vertex
// - Horizontal edges
//
// INVARIANTS:
// 1. Ray intersects edge if: min(y1, y2) < py <= max(y1, y2)
// 2. Winding number is ±1 for each edge crossed
// 3. Sum of winding contributions = 0 for outside points
//
// TIME COMPLEXITY: O(n) where n is number of vertices
// SPACE COMPLEXITY: O(1)

///|
priv struct Point2D {
  x : Double
  y : Double
}

///|
fn Point2D::new(x : Double, y : Double) -> Point2D {
  { x, y }
}

///|
priv enum PointLocation {
  Inside
  Outside
  OnBoundary
}

///|
const PIP_EPS : Double = 0.0000000001

///|
fn abs_double(x : Double) -> Double {
  if x < 0.0 { -x } else { x }
}

///|
/// Check if point is on line segment between p1 and p2
fn on_segment(p : Point2D, p1 : Point2D, p2 : Point2D) -> Bool {
  // Check if p is between p1 and p2 (assuming collinearity)
  let min_x = if p1.x < p2.x { p1.x } else { p2.x }
  let max_x = if p1.x > p2.x { p1.x } else { p2.x }
  let min_y = if p1.y < p2.y { p1.y } else { p2.y }
  let max_y = if p1.y > p2.y { p1.y } else { p2.y }

  p.x >= min_x - PIP_EPS &&
    p.x <= max_x + PIP_EPS &&
    p.y >= min_y - PIP_EPS &&
    p.y <= max_y + PIP_EPS
}

///|
/// Cross product of vectors (p2-p1) and (p3-p1)
fn cross_product(p1 : Point2D, p2 : Point2D, p3 : Point2D) -> Double {
  (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
}

///|
/// Ray casting algorithm for point in polygon
fn point_in_polygon_ray(point : Point2D, polygon : Array[Point2D]) -> PointLocation {
  let n = polygon.length()
  if n < 3 {
    return PointLocation::Outside
  }

  let mut intersections = 0

  for i = 0; i < n; i = i + 1 {
    let p1 = polygon[i]
    let p2 = polygon[(i + 1) % n]

    // Check if point is on edge
    let cross = cross_product(p1, p2, point)
    if abs_double(cross) < PIP_EPS && on_segment(point, p1, p2) {
      return PointLocation::OnBoundary
    }

    // Ray casting: horizontal ray to the right
    let min_y = if p1.y < p2.y { p1.y } else { p2.y }
    let max_y = if p1.y > p2.y { p1.y } else { p2.y }

    // Check if ray can intersect this edge
    if point.y > min_y && point.y <= max_y {
      // Calculate x coordinate of intersection
      let x_intersect = p1.x + (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
      if x_intersect > point.x {
        intersections = intersections + 1
      }
    }
  }

  if intersections % 2 == 1 {
    PointLocation::Inside
  } else {
    PointLocation::Outside
  }
}

///|
/// Winding number algorithm for point in polygon
fn point_in_polygon_winding(
  point : Point2D,
  polygon : Array[Point2D]
) -> PointLocation {
  let n = polygon.length()
  if n < 3 {
    return PointLocation::Outside
  }

  let mut winding = 0

  for i = 0; i < n; i = i + 1 {
    let p1 = polygon[i]
    let p2 = polygon[(i + 1) % n]

    // Check if point is on edge
    let cross = cross_product(p1, p2, point)
    if abs_double(cross) < PIP_EPS && on_segment(point, p1, p2) {
      return PointLocation::OnBoundary
    }

    if p1.y <= point.y {
      if p2.y > point.y {
        // Upward crossing
        if cross > 0.0 {
          winding = winding + 1
        }
      }
    } else {
      if p2.y <= point.y {
        // Downward crossing
        if cross < 0.0 {
          winding = winding - 1
        }
      }
    }
  }

  if winding != 0 {
    PointLocation::Inside
  } else {
    PointLocation::Outside
  }
}

///|
/// Simple check: is point inside polygon? (true/false)
fn is_inside(point : Point2D, polygon : Array[Point2D]) -> Bool {
  match point_in_polygon_ray(point, polygon) {
    PointLocation::Inside => true
    _ => false
  }
}

///|
/// Check if point is on boundary
fn is_on_boundary(point : Point2D, polygon : Array[Point2D]) -> Bool {
  match point_in_polygon_ray(point, polygon) {
    PointLocation::OnBoundary => true
    _ => false
  }
}

// ============================================================================
// POLYGON AREA
// ============================================================================

///|
/// Calculate signed area of polygon using shoelace formula
fn polygon_area_signed(polygon : Array[Point2D]) -> Double {
  let n = polygon.length()
  if n < 3 {
    return 0.0
  }

  let mut area = 0.0
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    area = area + polygon[i].x * polygon[j].y
    area = area - polygon[j].x * polygon[i].y
  }

  area / 2.0
}

///|
/// Calculate area of polygon (absolute value)
fn polygon_area(polygon : Array[Point2D]) -> Double {
  let signed = polygon_area_signed(polygon)
  if signed < 0.0 { -signed } else { signed }
}

///|
/// Check if polygon is convex
fn is_convex(polygon : Array[Point2D]) -> Bool {
  let n = polygon.length()
  if n < 3 {
    return false
  }

  let mut sign = 0

  for i = 0; i < n; i = i + 1 {
    let p1 = polygon[i]
    let p2 = polygon[(i + 1) % n]
    let p3 = polygon[(i + 2) % n]

    let cross = cross_product(p1, p2, p3)

    if abs_double(cross) > PIP_EPS {
      let current_sign = if cross > 0.0 { 1 } else { -1 }
      if sign == 0 {
        sign = current_sign
      } else if sign != current_sign {
        return false
      }
    }
  }

  true
}

// ============================================================================
// POINT IN CONVEX POLYGON (O(log n))
// ============================================================================

///|
/// Fast point in convex polygon test using binary search
fn point_in_convex_polygon(
  point : Point2D,
  polygon : Array[Point2D]
) -> PointLocation {
  let n = polygon.length()
  if n < 3 {
    return PointLocation::Outside
  }

  // Check if point is on correct side of first and last edges
  let p0 = polygon[0]

  // Cross product with first edge
  let cross1 = cross_product(p0, polygon[1], point)
  if cross1 < -PIP_EPS {
    return PointLocation::Outside
  }

  // Cross product with last edge
  let cross2 = cross_product(p0, polygon[n - 1], point)
  if cross2 > PIP_EPS {
    return PointLocation::Outside
  }

  // Binary search for the right triangle
  let mut lo = 1
  let mut hi = n - 1

  while hi - lo > 1 {
    let mid = (lo + hi) / 2
    let cross = cross_product(p0, polygon[mid], point)
    if cross >= 0.0 {
      lo = mid
    } else {
      hi = mid
    }
  }

  // Check if inside triangle (p0, polygon[lo], polygon[lo+1])
  let cross = cross_product(polygon[lo], polygon[lo + 1], point)

  if abs_double(cross) < PIP_EPS {
    if on_segment(point, polygon[lo], polygon[lo + 1]) {
      return PointLocation::OnBoundary
    }
  }

  if cross < -PIP_EPS {
    return PointLocation::Outside
  }

  // Check boundary with first and last edges
  if abs_double(cross1) < PIP_EPS && on_segment(point, p0, polygon[1]) {
    return PointLocation::OnBoundary
  }
  if abs_double(cross2) < PIP_EPS && on_segment(point, p0, polygon[n - 1]) {
    return PointLocation::OnBoundary
  }

  PointLocation::Inside
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "point_in_polygon inside" {
  let polygon : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(4.0, 4.0),
    Point2D::new(0.0, 4.0),
  ]

  let point = Point2D::new(2.0, 2.0)
  inspect(is_inside(point, polygon), content="true")
}

///|
test "point_in_polygon outside" {
  let polygon : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(4.0, 4.0),
    Point2D::new(0.0, 4.0),
  ]

  let point = Point2D::new(5.0, 5.0)
  inspect(is_inside(point, polygon), content="false")
}

///|
test "point_in_polygon on_edge" {
  let polygon : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(4.0, 4.0),
    Point2D::new(0.0, 4.0),
  ]

  let point = Point2D::new(2.0, 0.0) // On bottom edge
  inspect(is_on_boundary(point, polygon), content="true")
}

///|
test "point_in_polygon on_vertex" {
  let polygon : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(4.0, 4.0),
    Point2D::new(0.0, 4.0),
  ]

  let point = Point2D::new(0.0, 0.0) // On vertex
  inspect(is_on_boundary(point, polygon), content="true")
}

///|
test "point_in_polygon triangle" {
  let triangle : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(2.0, 3.0),
  ]

  inspect(is_inside(Point2D::new(2.0, 1.0), triangle), content="true")
  inspect(is_inside(Point2D::new(0.0, 3.0), triangle), content="false")
}

///|
test "polygon_area square" {
  let square : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(2.0, 0.0),
    Point2D::new(2.0, 2.0),
    Point2D::new(0.0, 2.0),
  ]

  inspect(polygon_area(square), content="4") // 2 * 2 = 4
}

///|
test "polygon_area triangle" {
  let triangle : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(2.0, 3.0),
  ]

  inspect(polygon_area(triangle), content="6") // (4 * 3) / 2 = 6
}

///|
test "is_convex square" {
  let square : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(2.0, 0.0),
    Point2D::new(2.0, 2.0),
    Point2D::new(0.0, 2.0),
  ]

  inspect(is_convex(square), content="true")
}

///|
test "is_convex concave" {
  // L-shaped polygon (concave)
  let l_shape : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(2.0, 0.0),
    Point2D::new(2.0, 1.0),
    Point2D::new(1.0, 1.0),
    Point2D::new(1.0, 2.0),
    Point2D::new(0.0, 2.0),
  ]

  inspect(is_convex(l_shape), content="false")
}

///|
test "winding_number inside" {
  let polygon : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(4.0, 4.0),
    Point2D::new(0.0, 4.0),
  ]

  match point_in_polygon_winding(Point2D::new(2.0, 2.0), polygon) {
    PointLocation::Inside => ()
    _ => fail("Expected inside")
  }
}

///|
test "point_in_convex_polygon" {
  let polygon : Array[Point2D] = [
    Point2D::new(0.0, 0.0),
    Point2D::new(4.0, 0.0),
    Point2D::new(4.0, 4.0),
    Point2D::new(0.0, 4.0),
  ]

  match point_in_convex_polygon(Point2D::new(2.0, 2.0), polygon) {
    PointLocation::Inside => ()
    _ => fail("Expected inside")
  }
}
