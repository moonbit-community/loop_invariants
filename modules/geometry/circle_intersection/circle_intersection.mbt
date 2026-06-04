// ============================================================================
// CIRCLE / LINE INTERSECTION
// ============================================================================
//
// PROBLEM
//
// Two basic geometric primitives:
//
//   - circle_circle_intersection(c1, r1, c2, r2)
//   - line_circle_intersection((p1, p2), centre, radius)
//
// Each returns the intersection points (0, 1, or 2 of them).
//
// CIRCLE-CIRCLE
//
// Given two circles `(x_i, y_i, r_i)`, distance `d` between centres:
//
//   if d > r1 + r2 or d + min(r1, r2) < max(r1, r2): no intersection
//   if d == 0 and r1 == r2: infinitely many; return None
//   else:
//     a = (r1^2 - r2^2 + d^2) / (2 d)
//     h = sqrt(r1^2 - a^2)
//     px = x1 + a (x2 - x1) / d   plus perpendicular component +- h * (y2 - y1) / d
//
// LINE-CIRCLE
//
// Parametrise the line as `p1 + t (p2 - p1)`; solve a quadratic in `t`.
//
// COMPLEXITY
//
//   O(1) arithmetic, plus one sqrt.
//
// THE INVARIANT
//
//   "When two distinct intersection points are returned, each lies on
//    both circles within numerical tolerance."

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
/// Result of intersecting two geometric objects: 0, 1, or 2 points.
pub(all) enum Intersection {
  Empty
  Single((Double, Double))
  Pair((Double, Double), (Double, Double))
  Infinite
}

///|
/// Intersect two circles `(c1, r1)` and `(c2, r2)`. Returns
/// `Infinite` for identical circles.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Two unit circles centred at (0,0) and (1,0) intersect at
///   // (0.5, +-sqrt(3)/2).
///   match @circle_intersection.circle_circle((0.0, 0.0), 1.0, (1.0, 0.0), 1.0) {
///     Pair(_, _) => @debug.assert_eq(true, true)
///     _ => @debug.assert_eq(true, false)
///   }
/// }
/// ```
pub fn circle_circle(
  c1 : (Double, Double),
  r1 : Double,
  c2 : (Double, Double),
  r2 : Double,
) -> Intersection {
  let dx = c2.0 - c1.0
  let dy = c2.1 - c1.1
  let d2 = dx * dx + dy * dy
  let d = sqrt(d2)
  if d == 0.0 {
    if r1 == r2 {
      return Infinite
    } else {
      return Empty
    }
  }
  let rr = r1 + r2
  let rd = if r1 > r2 { r1 - r2 } else { r2 - r1 }
  if d > rr || d < rd {
    return Empty
  }
  let a = (r1 * r1 - r2 * r2 + d2) / (2.0 * d)
  let h2 = r1 * r1 - a * a
  let h = if h2 < 0.0 { 0.0 } else { sqrt(h2) }
  let xm = c1.0 + a * dx / d
  let ym = c1.1 + a * dy / d
  if h == 0.0 {
    Single((xm, ym))
  } else {
    let px = xm + h * dy / d
    let py = ym - h * dx / d
    let qx = xm - h * dy / d
    let qy = ym + h * dx / d
    Pair((px, py), (qx, qy))
  }
}

///|
/// Intersect line through `p1` and `p2` with the circle centred at
/// `centre` with radius `r`. `p1 == p2` returns `Empty`.
pub fn line_circle(
  p1 : (Double, Double),
  p2 : (Double, Double),
  centre : (Double, Double),
  r : Double,
) -> Intersection {
  let dx = p2.0 - p1.0
  let dy = p2.1 - p1.1
  let a = dx * dx + dy * dy
  if a == 0.0 {
    return Empty
  }
  let fx = p1.0 - centre.0
  let fy = p1.1 - centre.1
  let b = 2.0 * (fx * dx + fy * dy)
  let c = fx * fx + fy * fy - r * r
  let disc = b * b - 4.0 * a * c
  if disc < 0.0 {
    return Empty
  }
  if disc == 0.0 {
    let t = -b / (2.0 * a)
    Single((p1.0 + t * dx, p1.1 + t * dy))
  } else {
    let sd = sqrt(disc)
    let t1 = (-b + sd) / (2.0 * a)
    let t2 = (-b - sd) / (2.0 * a)
    Pair((p1.0 + t1 * dx, p1.1 + t1 * dy), (p1.0 + t2 * dx, p1.1 + t2 * dy))
  }
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
fn close(a : Double, b : Double) -> Bool {
  abs_d(a - b) < 1.0e-9
}

///|
test "two unit circles" {
  match circle_circle((0.0, 0.0), 1.0, (1.0, 0.0), 1.0) {
    Pair((x1, y1), (x2, y2)) => {
      @debug.assert_eq(close(x1, 0.5), true)
      @debug.assert_eq(close(x2, 0.5), true)
      let expected = sqrt(0.75)
      @debug.assert_eq(close(abs_d(y1), expected), true)
      @debug.assert_eq(close(abs_d(y2), expected), true)
    }
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "disjoint circles" {
  match circle_circle((0.0, 0.0), 1.0, (10.0, 0.0), 1.0) {
    Empty => ()
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "concentric circles" {
  match circle_circle((1.0, 1.0), 2.0, (1.0, 1.0), 3.0) {
    Empty => ()
    _ => @debug.assert_eq(true, false)
  }
  // Same circle.
  match circle_circle((1.0, 1.0), 2.0, (1.0, 1.0), 2.0) {
    Infinite => ()
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "tangent circles" {
  // Internally tangent.
  match circle_circle((0.0, 0.0), 3.0, (1.0, 0.0), 2.0) {
    Single((x, y)) => {
      @debug.assert_eq(close(x, 3.0), true)
      @debug.assert_eq(close(y, 0.0), true)
    }
    _ => @debug.assert_eq(true, false)
  }
  // Externally tangent.
  match circle_circle((0.0, 0.0), 1.0, (2.0, 0.0), 1.0) {
    Single((x, y)) => {
      @debug.assert_eq(close(x, 1.0), true)
      @debug.assert_eq(close(y, 0.0), true)
    }
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "line_circle through centre" {
  // Horizontal line through (0, 0) with circle r=1.
  match line_circle((-2.0, 0.0), (2.0, 0.0), (0.0, 0.0), 1.0) {
    Pair((x1, _), (x2, _)) =>
      @debug.assert_eq(close(abs_d(x1), 1.0) && close(abs_d(x2), 1.0), true)
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "line_circle tangent" {
  // Tangent line y=1 with unit circle.
  match line_circle((-1.0, 1.0), (1.0, 1.0), (0.0, 0.0), 1.0) {
    Single((x, y)) => {
      @debug.assert_eq(close(x, 0.0), true)
      @debug.assert_eq(close(y, 1.0), true)
    }
    _ => @debug.assert_eq(true, false)
  }
}

///|
test "line_circle miss" {
  match line_circle((-1.0, 2.0), (1.0, 2.0), (0.0, 0.0), 1.0) {
    Empty => ()
    _ => @debug.assert_eq(true, false)
  }
}
