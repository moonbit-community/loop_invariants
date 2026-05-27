// ============================================================================
// SHOELACE FORMULA  -  signed area, perimeter, centroid for a polygon
// ============================================================================
//
// THE FORMULA  (Meister 1769; "shoelace" / Gauss's area formula)
//
// For a polygon with vertices `(x_0, y_0), ..., (x_{n-1}, y_{n-1})`
// listed in order around the boundary,
//
//   2 * signed_area = sum_{i=0..n-1} (x_i * y_{i+1} - x_{i+1} * y_i)
//
// (indices modulo n). The sign is **positive** for counter-clockwise
// orientation and **negative** for clockwise. Absolute value gives the
// geometric area. The same sum gives the polygon's orientation
// without needing trigonometry.
//
// POLYGON CENTROID
//
// For a non-self-intersecting polygon with signed area `A`:
//
//   Cx = 1/(6A) * sum (x_i + x_{i+1}) * (x_i*y_{i+1} - x_{i+1}*y_i)
//   Cy = 1/(6A) * sum (y_i + y_{i+1}) * (x_i*y_{i+1} - x_{i+1}*y_i)
//
// COMPLEXITY
//
//   O(n) time, O(1) extra space.
//
// THE INVARIANT
//
// After processing the i-th edge:
//
//   "running_sum  =  sum_{k=0..i} (x_k * y_{k+1} - x_{k+1} * y_k)
//                =  twice the signed area of the (open) polygonal chain
//                   v_0, v_1, ..., v_{i+1} closed back to v_0."

///|
/// Signed area of a polygon. Positive for CCW orientation, negative for
/// CW. Returns `0.0` for polygons with fewer than 3 vertices.
pub fn signed_area(vertices : Array[(Double, Double)]) -> Double {
  let n = vertices.length()
  if n < 3 {
    return 0.0
  }
  let mut s = 0.0
  for i in 0..<n {
    let j = if i + 1 == n { 0 } else { i + 1 }
    let (xi, yi) = vertices[i]
    let (xj, yj) = vertices[j]
    s = s + xi * yj - xj * yi
  }
  s * 0.5
}

///|
/// Unsigned (geometric) area; always non-negative.
pub fn area(vertices : Array[(Double, Double)]) -> Double {
  let s = signed_area(vertices)
  if s < 0.0 {
    -s
  } else {
    s
  }
}

///|
/// `+1` for CCW, `-1` for CW, `0` for degenerate (collinear or empty).
pub fn orientation(vertices : Array[(Double, Double)]) -> Int {
  let s = signed_area(vertices)
  if s > 0.0 {
    1
  } else if s < 0.0 {
    -1
  } else {
    0
  }
}

///|
/// Perimeter of the (closed) polygon: sum of Euclidean edge lengths.
pub fn perimeter(vertices : Array[(Double, Double)]) -> Double {
  let n = vertices.length()
  if n < 2 {
    return 0.0
  }
  let mut total = 0.0
  for i in 0..<n {
    let j = if i + 1 == n { 0 } else { i + 1 }
    let (xi, yi) = vertices[i]
    let (xj, yj) = vertices[j]
    let dx = xj - xi
    let dy = yj - yi
    total = total + sqrt(dx * dx + dy * dy)
  }
  total
}

///|
fn sqrt(x : Double) -> Double {
  // Newton's iteration; good to many digits for non-negative x.
  if x <= 0.0 {
    return 0.0
  }
  let mut g = x
  let mut i = 0
  while i < 50 {
    let next = 0.5 * (g + x / g)
    if next == g {
      break
    }
    g = next
    i = i + 1
  }
  g
}

///|
/// Centroid of a (non-self-intersecting) polygon. Returns `None` when
/// the polygon has fewer than 3 vertices or zero area.
pub fn centroid(vertices : Array[(Double, Double)]) -> (Double, Double)? {
  let n = vertices.length()
  if n < 3 {
    return None
  }
  let a = signed_area(vertices)
  if a == 0.0 {
    return None
  }
  let mut cx = 0.0
  let mut cy = 0.0
  for i in 0..<n {
    let j = if i + 1 == n { 0 } else { i + 1 }
    let (xi, yi) = vertices[i]
    let (xj, yj) = vertices[j]
    let cross = xi * yj - xj * yi
    cx = cx + (xi + xj) * cross
    cy = cy + (yi + yj) * cross
  }
  let factor = 1.0 / (6.0 * a)
  Some((cx * factor, cy * factor))
}

///|
test "shoelace unit square ccw" {
  // (0,0) (1,0) (1,1) (0,1) -> area 1, ccw.
  let v = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
  @debug.assert_eq(signed_area(v), 1.0)
  @debug.assert_eq(area(v), 1.0)
  @debug.assert_eq(orientation(v), 1)
}

///|
test "shoelace unit square cw" {
  let v = [(0.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 0.0)]
  @debug.assert_eq(signed_area(v), -1.0)
  @debug.assert_eq(area(v), 1.0)
  @debug.assert_eq(orientation(v), -1)
}

///|
test "shoelace triangle 3-4-5" {
  // Right triangle legs 3, 4; area = 6.
  let v = [(0.0, 0.0), (3.0, 0.0), (0.0, 4.0)]
  @debug.assert_eq(area(v), 6.0)
}

///|
test "shoelace degenerate" {
  let empty : Array[(Double, Double)] = []
  @debug.assert_eq(signed_area(empty), 0.0)
  @debug.assert_eq(area(empty), 0.0)
  @debug.assert_eq(orientation(empty), 0)
  let two = [(0.0, 0.0), (1.0, 1.0)]
  @debug.assert_eq(signed_area(two), 0.0)
  // Collinear: 0 area
  let col = [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)]
  @debug.assert_eq(area(col), 0.0)
}

///|
test "shoelace perimeter square" {
  let v = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
  let p = perimeter(v)
  let diff = if p - 4.0 < 0.0 { 4.0 - p } else { p - 4.0 }
  @debug.assert_eq(diff < 1.0e-9, true)
}

///|
test "shoelace centroid square" {
  let v = [(0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0)]
  match centroid(v) {
    Some((cx, cy)) => {
      let dx = if cx - 1.0 < 0.0 { 1.0 - cx } else { cx - 1.0 }
      let dy = if cy - 1.0 < 0.0 { 1.0 - cy } else { cy - 1.0 }
      @debug.assert_eq(dx < 1.0e-9, true)
      @debug.assert_eq(dy < 1.0e-9, true)
    }
    None => @debug.assert_eq(true, false)
  }
}

///|
test "shoelace centroid triangle" {
  // Centroid of triangle is mean of vertices.
  let v = [(0.0, 0.0), (6.0, 0.0), (0.0, 9.0)]
  match centroid(v) {
    Some((cx, cy)) => {
      let dx = if cx - 2.0 < 0.0 { 2.0 - cx } else { cx - 2.0 }
      let dy = if cy - 3.0 < 0.0 { 3.0 - cy } else { cy - 3.0 }
      @debug.assert_eq(dx < 1.0e-9, true)
      @debug.assert_eq(dy < 1.0e-9, true)
    }
    None => @debug.assert_eq(true, false)
  }
}

///|
test "shoelace centroid degenerate" {
  @debug.assert_eq(centroid([(0.0, 0.0), (1.0, 0.0)]), None)
  @debug.assert_eq(centroid([(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)]), None) // 0 area
}

///|
test "shoelace pentagon" {
  // Regular pentagon with vertices at (cos(2*pi*k/5), sin(2*pi*k/5)).
  // Use a hand-listed approximation.
  let v = [
    (1.0, 0.0),
    (0.30901699437494745, 0.9510565162951535),
    (-0.8090169943749475, 0.5877852522924731),
    (-0.8090169943749473, -0.5877852522924732),
    (0.30901699437494723, -0.9510565162951536),
  ]
  // Known area of regular unit-circumradius pentagon: (5/4)*tan(pi/5) ~ 0.9081...
  let a = area(v)
  let known = 2.377641290737884 // 5/2 * sin(2*pi/5) ~ pentagon area inscribed in unit circle
  // Use 5/2 * sin(2*pi/5) = 5/2 * 0.951... = 2.377...
  let diff = if a - known < 0.0 { known - a } else { a - known }
  @debug.assert_eq(diff < 1.0e-3, true)
}
