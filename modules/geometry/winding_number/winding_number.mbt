// ============================================================================
// WINDING-NUMBER POINT-IN-POLYGON
// ============================================================================
//
// PROBLEM
//
// Decide whether a point `q` lies inside an arbitrary (possibly
// self-intersecting) polygon `P` given as a vertex list.
//
// The repository already has `geometry/point_in_polygon` (Jordan
// curve / ray-cast) and `geometry/point_in_convex_polygon`
// (specialised O(log n) binary search). This package implements the
// **winding number** algorithm, which is
//
//   - Correct for **self-intersecting** polygons (the ray-cast
//     interpretation is ambiguous in that case).
//   - Reports the actual winding number, which is useful for
//     non-zero / even-odd fill-rule classification.
//
// THE ALGORITHM (Dan Sunday's version)
//
// Walk each polygon edge `v_i v_{i+1}`. Whenever the edge crosses the
// horizontal ray from `q` toward `+infinity`:
//
//   - Upward crossing (v_i below or on horizontal, v_{i+1} strictly above)
//     contributes `+1` iff `q` is strictly left of the edge.
//   - Downward crossing (v_i above, v_{i+1} strictly below) contributes
//     `-1` iff `q` is strictly right of the edge.
//
// Sum is the winding number `w(q, P)`. Point is inside under the
// non-zero fill rule iff `w != 0`; under the even-odd rule iff `w`
// is odd.
//
// COMPLEXITY
//
//   O(n) per query.
//
// THE INVARIANT
//
//   "After processing edge i, the accumulator equals the signed
//    number of times the polygonal chain v_0 v_1 ... v_{i+1} winds
//    around q."

///|
fn is_left(
  a : (Double, Double),
  b : (Double, Double),
  p : (Double, Double),
) -> Double {
  // Positive if p is left of line AB, negative if right, zero if on line.
  (b.0 - a.0) * (p.1 - a.1) - (b.1 - a.1) * (p.0 - a.0)
}

///|
/// Compute the winding number of point `q` around polygon `poly`.
/// Positive = counter-clockwise turns; negative = clockwise.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Unit square CCW; centre has winding number 1.
///   let p = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
///   @debug.assert_eq(@winding_number.winding_number(p, (0.5, 0.5)), 1)
/// }
/// ```
pub fn winding_number(
  poly : Array[(Double, Double)],
  q : (Double, Double),
) -> Int {
  let n = poly.length()
  if n < 3 {
    return 0
  }
  let mut w = 0
  for i in 0..<n {
    let a = poly[i]
    let b = poly[if i + 1 == n { 0 } else { i + 1 }]
    if a.1 <= q.1 {
      // Upward edge?
      if b.1 > q.1 && is_left(a, b, q) > 0.0 {
        w = w + 1
      }
      // a.1 > q.1; downward edge?
    } else if b.1 <= q.1 && is_left(a, b, q) < 0.0 {
      w = w - 1
    }
  }
  w
}

///|
/// Non-zero fill rule: `true` iff the winding number is non-zero.
pub fn inside_nonzero(
  poly : Array[(Double, Double)],
  q : (Double, Double),
) -> Bool {
  winding_number(poly, q) != 0
}

///|
/// Even-odd fill rule: `true` iff the winding number is odd.
pub fn inside_evenodd(
  poly : Array[(Double, Double)],
  q : (Double, Double),
) -> Bool {
  winding_number(poly, q) % 2 != 0
}

///|
test "wn unit square ccw" {
  let p : Array[(Double, Double)] = [
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ]
  @debug.assert_eq(winding_number(p, (0.5, 0.5)), 1)
  @debug.assert_eq(winding_number(p, (2.0, 2.0)), 0)
  @debug.assert_eq(inside_nonzero(p, (0.5, 0.5)), true)
  @debug.assert_eq(inside_nonzero(p, (2.0, 2.0)), false)
}

///|
test "wn unit square cw" {
  let p : Array[(Double, Double)] = [
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
  ]
  @debug.assert_eq(winding_number(p, (0.5, 0.5)), -1)
  @debug.assert_eq(inside_nonzero(p, (0.5, 0.5)), true)
}

///|
test "wn self-intersecting" {
  // A figure-eight polygon: vertices form two crossed loops.
  // Lower loop (CCW), upper loop (CW), they share crossing point.
  let p : Array[(Double, Double)] = [
    (0.0, 0.0),
    (4.0, 0.0),
    (0.0, 4.0),
    (4.0, 4.0),
  ]
  // The two triangles wrap around their interiors with opposite winding.
  // Centre of lower triangle (1.0, 1.0): should have winding +1 (lower CCW).
  let w_low = winding_number(p, (1.0, 1.0))
  let w_high = winding_number(p, (1.0, 3.0))
  @debug.assert_eq(w_low + w_high, 0) // signs cancel
}

///|
test "wn triangle interior" {
  let p : Array[(Double, Double)] = [(0.0, 0.0), (4.0, 0.0), (2.0, 3.0)]
  @debug.assert_eq(winding_number(p, (2.0, 1.0)), 1)
  @debug.assert_eq(winding_number(p, (10.0, 10.0)), 0)
}

///|
test "wn degenerate polygons" {
  @debug.assert_eq(winding_number([], (0.0, 0.0)), 0)
  let single : Array[(Double, Double)] = [(0.0, 0.0)]
  @debug.assert_eq(winding_number(single, (0.0, 0.0)), 0)
  let two : Array[(Double, Double)] = [(0.0, 0.0), (1.0, 0.0)]
  @debug.assert_eq(winding_number(two, (0.5, 0.5)), 0)
}

///|
test "wn even-odd vs non-zero" {
  // Star-shaped polygon traced twice would have winding 2 everywhere
  // inside; non-zero rule says inside, even-odd says outside.
  // Approximate by a hexagon (winding 1) -- both rules agree.
  let hex : Array[(Double, Double)] = [
    (2.0, 0.0),
    (1.0, 1.732),
    (-1.0, 1.732),
    (-2.0, 0.0),
    (-1.0, -1.732),
    (1.0, -1.732),
  ]
  @debug.assert_eq(inside_nonzero(hex, (0.0, 0.0)), true)
  @debug.assert_eq(inside_evenodd(hex, (0.0, 0.0)), true)
  @debug.assert_eq(inside_nonzero(hex, (10.0, 10.0)), false)
  @debug.assert_eq(inside_evenodd(hex, (10.0, 10.0)), false)
}
