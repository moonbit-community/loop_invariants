// ============================================================================
// POINT-SEGMENT AND SEGMENT-SEGMENT DISTANCE
// ============================================================================
//
// PROBLEM
//
// Three primitives in computational geometry, all returning `Double`:
//
//   - **point_to_segment**: shortest distance from a point P to segment AB.
//   - **segment_to_segment**: shortest distance between two segments
//     in 2-D (may or may not intersect).
//   - **closest_point_on_segment**: the foot of the perpendicular if it
//     lies inside the segment, else the nearer endpoint.
//
// THE MATH
//
// Parameterise AB as `A + t (B - A)` for `t in [0, 1]`. The
// orthogonal projection of P onto line AB has
//
//   t* = dot(AP, AB) / dot(AB, AB)
//
// Clip to `[0, 1]` to get the closest segment parameter, then
// distance is `|P - (A + t (B - A))|`.
//
// For segment-segment we use the case analysis: if the segments
// intersect, the distance is 0; otherwise it equals the minimum of
// the four point-to-segment distances (each endpoint of one segment
// to the other segment).
//
// COMPLEXITY
//
//   O(1) arithmetic.
//
// THE INVARIANT
//
//   "After clipping `t` to `[0, 1]`, the parameter t' yields the point
//    A + t' * (B - A) which is the closest point of AB to P."

///|
fn cross_d(ax : Double, ay : Double, bx : Double, by : Double) -> Double {
  ax * by - ay * bx
}

///|
fn sqrt(x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  let mut g = x
  let mut i = 0
  while i < 60 {
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
/// Closest point on segment `AB` to point `P`.
pub fn closest_point_on_segment(
  a : (Double, Double),
  b : (Double, Double),
  p : (Double, Double),
) -> (Double, Double) {
  let abx = b.0 - a.0
  let aby = b.1 - a.1
  let len_sq = abx * abx + aby * aby
  if len_sq <= 0.0 {
    return a
  }
  let apx = p.0 - a.0
  let apy = p.1 - a.1
  let mut t = (apx * abx + apy * aby) / len_sq
  if t < 0.0 {
    t = 0.0
  } else if t > 1.0 {
    t = 1.0
  }
  (a.0 + t * abx, a.1 + t * aby)
}

///|
/// Distance from point `P` to segment `AB`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Distance from (1, 1) to segment from (0,0) to (4,0) is 1.
///   @debug.assert_eq(
///     @segment_distance.point_to_segment((0.0, 0.0), (4.0, 0.0), (1.0, 1.0)),
///     1.0,
///   )
/// }
/// ```
pub fn point_to_segment(
  a : (Double, Double),
  b : (Double, Double),
  p : (Double, Double),
) -> Double {
  let c = closest_point_on_segment(a, b, p)
  let dx = p.0 - c.0
  let dy = p.1 - c.1
  sqrt(dx * dx + dy * dy)
}

///|
fn on_segment(
  a : (Double, Double),
  b : (Double, Double),
  p : (Double, Double),
) -> Bool {
  // Assumes p is colinear with a-b.
  let lo_x = if a.0 < b.0 { a.0 } else { b.0 }
  let hi_x = if a.0 > b.0 { a.0 } else { b.0 }
  let lo_y = if a.1 < b.1 { a.1 } else { b.1 }
  let hi_y = if a.1 > b.1 { a.1 } else { b.1 }
  p.0 >= lo_x && p.0 <= hi_x && p.1 >= lo_y && p.1 <= hi_y
}

///|
/// `true` iff segments `AB` and `CD` properly or improperly intersect.
pub fn segments_intersect(
  a : (Double, Double),
  b : (Double, Double),
  c : (Double, Double),
  d : (Double, Double),
) -> Bool {
  let d1 = cross_d(d.0 - c.0, d.1 - c.1, a.0 - c.0, a.1 - c.1)
  let d2 = cross_d(d.0 - c.0, d.1 - c.1, b.0 - c.0, b.1 - c.1)
  let d3 = cross_d(b.0 - a.0, b.1 - a.1, c.0 - a.0, c.1 - a.1)
  let d4 = cross_d(b.0 - a.0, b.1 - a.1, d.0 - a.0, d.1 - a.1)
  if ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0)) &&
    ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0)) {
    return true
  }
  // Collinear / endpoint touching: check if any endpoint lies on the other segment.
  if d1 == 0.0 && on_segment(c, d, a) {
    return true
  }
  if d2 == 0.0 && on_segment(c, d, b) {
    return true
  }
  if d3 == 0.0 && on_segment(a, b, c) {
    return true
  }
  if d4 == 0.0 && on_segment(a, b, d) {
    return true
  }
  false
}

///|
/// Distance between two segments `AB` and `CD` in the plane. Returns
/// `0.0` if they intersect.
pub fn segment_to_segment(
  a : (Double, Double),
  b : (Double, Double),
  c : (Double, Double),
  d : (Double, Double),
) -> Double {
  if segments_intersect(a, b, c, d) {
    return 0.0
  }
  let mut best = point_to_segment(a, b, c)
  let cand1 = point_to_segment(a, b, d)
  if cand1 < best {
    best = cand1
  }
  let cand2 = point_to_segment(c, d, a)
  if cand2 < best {
    best = cand2
  }
  let cand3 = point_to_segment(c, d, b)
  if cand3 < best {
    best = cand3
  }
  best
}

///|
fn abs_d(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
test "point on segment line" {
  // Point above middle of segment.
  let d = point_to_segment((0.0, 0.0), (4.0, 0.0), (1.0, 1.0))
  @debug.assert_eq(d, 1.0)
}

///|
test "point past endpoint" {
  // Past endpoint -> distance to endpoint.
  let d = point_to_segment((0.0, 0.0), (4.0, 0.0), (5.0, 3.0))
  let expected = sqrt(1.0 * 1.0 + 3.0 * 3.0)
  @debug.assert_eq(abs_d(d - expected) < 1.0e-12, true)
}

///|
test "point on degenerate segment" {
  // A == B: distance from P to A.
  let d = point_to_segment((3.0, 4.0), (3.0, 4.0), (0.0, 0.0))
  @debug.assert_eq(d, 5.0)
}

///|
test "segments intersect distance zero" {
  // Cross at (1, 1).
  let d = segment_to_segment((0.0, 0.0), (2.0, 2.0), (0.0, 2.0), (2.0, 0.0))
  @debug.assert_eq(d, 0.0)
}

///|
test "parallel segments" {
  // Parallel horizontal segments distance 1 apart.
  let d = segment_to_segment((0.0, 0.0), (5.0, 0.0), (0.0, 1.0), (5.0, 1.0))
  @debug.assert_eq(d, 1.0)
}

///|
test "skew segments" {
  let d = segment_to_segment((0.0, 0.0), (1.0, 0.0), (2.0, 1.0), (3.0, 1.0))
  let expected = sqrt(1.0 * 1.0 + 1.0 * 1.0)
  @debug.assert_eq(abs_d(d - expected) < 1.0e-12, true)
}

///|
test "closest point clipping" {
  // Foot inside.
  let c = closest_point_on_segment((0.0, 0.0), (4.0, 0.0), (1.0, 2.0))
  @debug.assert_eq(c, (1.0, 0.0))
  // Foot before A.
  let c2 = closest_point_on_segment((0.0, 0.0), (4.0, 0.0), (-1.0, 1.0))
  @debug.assert_eq(c2, (0.0, 0.0))
  // Foot after B.
  let c3 = closest_point_on_segment((0.0, 0.0), (4.0, 0.0), (5.0, 1.0))
  @debug.assert_eq(c3, (4.0, 0.0))
}

///|
test "segments share endpoint distance zero" {
  let d = segment_to_segment((0.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 1.0))
  @debug.assert_eq(d, 0.0)
}
