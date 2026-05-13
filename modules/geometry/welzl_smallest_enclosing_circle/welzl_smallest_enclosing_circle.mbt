// ============================================================================
// WELZL'S SMALLEST ENCLOSING CIRCLE - Minimum Bounding Disk
// ============================================================================
//
// Given a finite set of points in the plane, find the unique smallest circle
// that contains all of them. The minimum enclosing circle (MEC) always
// exists, is unique, and is determined by at most 3 of the input points
// lying exactly on its boundary.
//
// THE BOUNDARY STRUCTURE THEOREM (Welzl, 1991):
//   The MEC of P is either
//     (a) the circle through 2 antipodal points of P (the diameter case), or
//     (b) the unique circumscribed circle of 3 boundary points of P.
//   In other words, at most 3 input points sit on the optimal boundary.
//
// THE ITERATIVE WELZL ALGORITHM (the version implemented here):
//
//   circle = empty
//   for i in 0..n:
//     if points[i] not in circle:
//       # points[i] lies outside the MEC of points[0..i); it must be on the
//       # boundary of the new MEC.
//       circle = circle around points[i] alone
//       for j in 0..i:
//         if points[j] not in circle:
//           # Both points[i] and points[j] are boundary points.
//           circle = diameter circle of (points[i], points[j])
//           for k in 0..j:
//             if points[k] not in circle:
//               # 3 boundary points -> unique circumscribed circle.
//               circle = circumcircle(points[i], points[j], points[k])
//   return circle
//
// WHY THE TRIPLE NESTED LOOP IS LINEAR ON AVERAGE:
//   The outer loop misses with probability 3/i on a *random* permutation,
//   because at most 3 of the i points sit on the MEC boundary. Similar
//   backwards-analysis arguments give 2/i for the middle loop and 1/i for
//   the inner loop. Summing the work,
//
//     E[time]  =  sum_{i=1..n}  O(1) + (3/i) · O(i) + (2/i)·(1/i)·O(i^2)
//              =  O(n).
//
//   Without shuffling, the worst case is O(n^3). This package does NOT
//   shuffle internally; the caller is responsible for randomising input
//   order if the expected linear bound is desired.
//
// CORE GEOMETRIC PRIMITIVES:
//   - circle_from_two(p, q):    circle whose diameter is pq.
//   - circle_from_three(a,b,c): unique circumscribed circle of three points,
//                               falling back to a pairwise diameter circle
//                               when the three are nearly collinear.
//   - contains_point(c, p):     |p - center|^2 <= radius^2 + EPS, computed
//                               on squared distances to avoid a sqrt.
//
// TIME COMPLEXITY : O(n)   expected on a random permutation
//                   O(n^3) worst case on adversarial input
// SPACE COMPLEXITY: O(1)   (apart from the input itself)

///|
/// A 2D point with `Double` coordinates.
///
/// Mirrors the convention used by other floating-point geometry packages
/// (e.g. `closest_pair`). Coordinates are assumed to be reasonable in
/// magnitude (roughly `|x|, |y| <= 1e6`); much larger values may lose
/// precision in the circumcircle determinant.
pub(all) struct Point {
  x : Double
  y : Double
} derive(Debug, Eq)

///|
/// A 2D circle described by its center and (non-negative) radius.
///
/// A radius of exactly `0.0` represents a degenerate "point circle" --
/// the output for a single-point input or an empty input.
pub(all) struct Circle {
  center : Point
  radius : Double
} derive(Debug)

///|
/// Slack used by `contains_point`. Set to `1.0e-10`, which is comfortably
/// above the round-off of a single circumcircle computation for coordinates
/// in the `[-1e6, 1e6]` range.
const EPS : Double = 1.0e-10

///|
/// Squared Euclidean distance between two points. Returns a `Double` so
/// the result composes with the radius-squared comparison in
/// `contains_point` without converting.
fn dist_sq(p : Point, q : Point) -> Double {
  let dx = p.x - q.x
  let dy = p.y - q.y
  dx * dx + dy * dy
}

///|
/// Test whether `p` lies inside (or on the boundary of) `c`.
///
/// Uses squared distances throughout; the slack `EPS` is added to
/// `radius^2` so that floating-point round-off does not spuriously kick
/// a boundary point out of the circle.
fn contains_point(c : Circle, p : Point) -> Bool {
  dist_sq(c.center, p) <= c.radius * c.radius + EPS
}

///|
/// Build the smallest circle through two points: the circle whose diameter
/// is the segment `pq`. Its center is the midpoint of `pq` and its radius
/// is `|pq|/2`.
fn circle_from_two(p : Point, q : Point) -> Circle {
  let cx = (p.x + q.x) * 0.5
  let cy = (p.y + q.y) * 0.5
  let dx = p.x - q.x
  let dy = p.y - q.y
  let r = (dx * dx + dy * dy).sqrt() * 0.5
  { center: { x: cx, y: cy }, radius: r }
}

///|
/// Circumscribed circle of three points (the unique circle through `a`,
/// `b`, and `c`).
///
/// Derivation. The circumcenter is the intersection of the perpendicular
/// bisectors of `ab` and `ac`. Translate so that `a` becomes the origin:
/// let `B = b - a`, `C = c - a`. Then the circumcenter (also translated)
/// is
///
///   D     = 2 · (B.x · C.y  -  B.y · C.x)
///   u.x   = ( C.y · |B|^2  -  B.y · |C|^2 ) / D
///   u.y   = ( B.x · |C|^2  -  C.x · |B|^2 ) / D
///
/// and the actual center is `a + u`. The radius is `|u|`.
///
/// When `D` is near zero the three points are (nearly) collinear and no
/// finite circumcircle exists. In that situation we fall back to the
/// diameter circle of the farthest pair: the smallest enclosing circle of
/// three collinear points is the circle whose diameter is the two extreme
/// ones.
fn circle_from_three(a : Point, b : Point, c : Point) -> Circle {
  let bx = b.x - a.x
  let by = b.y - a.y
  let cx = c.x - a.x
  let cy = c.y - a.y
  let d = 2.0 * (bx * cy - by * cx)
  let abs_d = if d < 0.0 { -d } else { d }
  if abs_d < EPS {
    // Nearly collinear: pick the farthest pair as the diameter.
    let dab = dist_sq(a, b)
    let dac = dist_sq(a, c)
    let dbc = dist_sq(b, c)
    if dab >= dac && dab >= dbc {
      circle_from_two(a, b)
    } else if dac >= dbc {
      circle_from_two(a, c)
    } else {
      circle_from_two(b, c)
    }
  } else {
    let b2 = bx * bx + by * by
    let c2 = cx * cx + cy * cy
    let ux = (cy * b2 - by * c2) / d
    let uy = (bx * c2 - cx * b2) / d
    let center = { x: a.x + ux, y: a.y + uy }
    let r = (ux * ux + uy * uy).sqrt()
    { center, radius: r }
  }
}

///|
/// MEC of all points known so far that *also* lies on the boundary
/// through `p`. Inner two loops of Welzl's iterative variant.
///
/// On entry, `p = points[i]` is a fixed boundary point. We sweep `points[0..j_max)`
/// and grow a circle that always passes through `p`. When a new
/// point `q = points[j]` falls outside the current circle, both `p` and
/// `q` must be boundary points of the new candidate, so we restart from
/// the diameter circle on `(p, q)` and run the third loop in
/// `mec_with_two`.
fn mec_with_one(points : ArrayView[Point], j_max : Int, p : Point) -> Circle {
  let init : Circle = { center: p, radius: 0.0 }
  for j = 0, circle = init; j < j_max; {
    let q = points[j]
    let circle = if contains_point(circle, q) {
      circle
    } else {
      mec_with_two(points, j, p, q)
    }
    continue j + 1, circle
  } nobreak {
    circle
  } where {
    proof_invariant: j >= 0 && j <= j_max,
    proof_reasoning: (
      #|INVARIANT (Welzl middle loop):
      #|  `circle` is the smallest enclosing circle of `points[0..j)` subject
      #|  to the constraint that `p` lies on its boundary. Equivalently, it
      #|  is the MEC of `points[0..j) ∪ {p}` known to touch `p`.
      #|
      #|MAINTENANCE:
      #|  Take the next candidate q = points[j].
      #|    Case A — q is already inside `circle`. The constraint set does
      #|      not grow, so `circle` remains optimal for `points[0..j+1)`
      #|      with `p` on its boundary.
      #|    Case B — q is strictly outside `circle`. Adding q tightens the
      #|      constraint: every circle containing both `points[0..j+1)` and
      #|      passing through `p` must also pass through q (any strictly
      #|      smaller circle through p that contained q would have already
      #|      contained the current j-prefix and contradicted optimality).
      #|      Hence the new optimum passes through *both* p and q, and is
      #|      computed by the inner routine `mec_with_two`.
      #|
      #|TERMINATION:
      #|  `j` increments by one each iteration and is bounded above by
      #|  `j_max`. The inner call `mec_with_two` runs in O(j) and does not
      #|  re-enter this loop.
    ),
  }
}

///|
/// Innermost Welzl loop: fixed boundary points `p` and `q`, sweep
/// `points[0..k_max)`, rebuilding through the circumcircle whenever a new
/// point escapes.
fn mec_with_two(
  points : ArrayView[Point],
  k_max : Int,
  p : Point,
  q : Point,
) -> Circle {
  let init = circle_from_two(p, q)
  for k = 0, circle = init; k < k_max; {
    let r = points[k]
    let circle = if contains_point(circle, r) {
      circle
    } else {
      circle_from_three(p, q, r)
    }
    continue k + 1, circle
  } nobreak {
    circle
  } where {
    proof_invariant: k >= 0 && k <= k_max,
    proof_reasoning: (
      #|INVARIANT (Welzl inner loop):
      #|  `circle` is the smallest enclosing circle of `points[0..k)` subject
      #|  to the constraint that both `p` and `q` lie on its boundary. For
      #|  k > 0 the circle is uniquely determined by the three boundary
      #|  points (p, q, and the most recently `escaping` point).
      #|
      #|MAINTENANCE:
      #|  Consider the next candidate r = points[k].
      #|    Case A — r is inside `circle`. The MEC under the (p, q)
      #|      constraint is unchanged.
      #|    Case B — r is strictly outside `circle`. Among all circles
      #|      through p and q that contain `points[0..k)`, none contains r
      #|      (since `circle` is the smallest such circle and r is outside
      #|      it). Hence the new optimum must additionally pass through r.
      #|      Three boundary points uniquely determine a circle, namely
      #|      `circle_from_three(p, q, r)`.
      #|
      #|TERMINATION:
      #|  `k` increases by one each iteration and is bounded by `k_max`. No
      #|  further recursion happens beyond the circumcircle construction.
      #|
      #|EXPECTED-TIME REMARK:
      #|  Backwards analysis: on a random permutation of points, the
      #|  probability that `points[k]` is one of the three boundary points
      #|  of the optimum is at most 3/k. So the inner-loop body fires at
      #|  most O(1) times in expectation over the k_max iterations.
    ),
  }
}

///|
/// Smallest circle enclosing every point in `points`.
///
/// Returns a degenerate circle of radius `0.0` for an empty input or a
/// single point. For two points the result is the diameter circle on the
/// pair. For three or more points the result is determined by 2 or 3 of
/// the input points lying on the boundary.
///
/// ## Parameters
///
/// - `points` : a view of the input points. The order matters for
///   *complexity* but not for *correctness*; see the README for the
///   randomisation argument.
///
/// ## Complexity
///
/// Expected `O(n)` on a uniformly random permutation of the input, with a
/// worst case of `O(n^3)` on adversarial orderings. The algorithm does
/// not allocate beyond constant scratch.
///
/// ## Examples
///
/// ```moonbit nocheck
/// test {
///   let pts : Array[@welzl_smallest_enclosing_circle.Point] = [
///     { x: 0.0, y: 0.0 },
///     { x: 4.0, y: 0.0 },
///     { x: 2.0, y: 3.0 },
///   ]
///   let c = @welzl_smallest_enclosing_circle.smallest_enclosing_circle(pts[:])
///   // c.center is the circumcenter of the triangle.
/// }
/// ```
pub fn smallest_enclosing_circle(points : ArrayView[Point]) -> Circle {
  let n = points.length()
  if n == 0 {
    return { center: { x: 0.0, y: 0.0 }, radius: 0.0 }
  }
  let init : Circle = { center: points[0], radius: 0.0 }
  for i = 0, circle = init; i < n; {
    let p = points[i]
    let circle = if contains_point(circle, p) {
      circle
    } else {
      // `p` must be on the boundary of the new optimal circle.
      mec_with_one(points, i, p)
    }
    continue i + 1, circle
  } nobreak {
    circle
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_invariant: circle.radius >= 0.0,
    proof_reasoning: (
      #|INVARIANT (Welzl outer loop):
      #|  `circle` is the smallest enclosing circle of `points[0..i)`. At
      #|  the start of iteration i = 0 the prefix is empty, so the
      #|  degenerate "point circle" at points[0] (radius 0) trivially
      #|  encloses it.
      #|
      #|MAINTENANCE:
      #|  Consider points[i].
      #|    Case A — points[i] is inside `circle`. The MEC of the larger
      #|      prefix is unchanged because the constraint set has not grown
      #|      strictly.
      #|    Case B — points[i] is strictly outside `circle`. By the
      #|      Boundary Structure Theorem, any enclosing circle of the new
      #|      prefix that contains points[i] is no smaller than `circle`
      #|      unless it places points[i] on its boundary. So the new MEC
      #|      passes through points[i]; build it by the middle loop, which
      #|      computes the MEC of `points[0..i)` constrained to pass
      #|      through points[i] (recursively touching one more boundary
      #|      point per nesting level).
      #|
      #|TERMINATION:
      #|  `i` increments deterministically by 1 from 0 up to n.
      #|
      #|EXPECTED-TIME REMARK:
      #|  On a random permutation, points[i] is one of the at-most-3
      #|  boundary points of the i-prefix optimum with probability ≤ 3/i.
      #|  So the rebuilding branch (Case B) is rarely taken, and summing
      #|  the work across i gives an expected linear-time algorithm.
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
/// Absolute difference of two doubles; convenient for floating-point
/// closeness checks in tests.
fn abs_diff(a : Double, b : Double) -> Double {
  let d = a - b
  if d < 0.0 {
    -d
  } else {
    d
  }
}

///|
test "mec empty input" {
  let pts : Array[Point] = []
  let c = smallest_enclosing_circle(pts[:])
  @debug.assert_eq(c.radius, 0.0)
  @debug.assert_eq(c.center.x, 0.0)
  @debug.assert_eq(c.center.y, 0.0)
}

///|
test "mec single point" {
  let pts : Array[Point] = [{ x: 3.0, y: -2.0 }]
  let c = smallest_enclosing_circle(pts[:])
  @debug.assert_eq(c.radius, 0.0)
  @debug.assert_eq(c.center.x, 3.0)
  @debug.assert_eq(c.center.y, -2.0)
}

///|
test "mec two points yields diameter circle" {
  let pts : Array[Point] = [{ x: 0.0, y: 0.0 }, { x: 6.0, y: 8.0 }]
  let c = smallest_enclosing_circle(pts[:])
  // Diameter = 10, radius = 5, center = (3, 4).
  @debug.assert_eq(abs_diff(c.radius, 5.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 3.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.y, 4.0) < 1.0e-9, true)
}

///|
test "mec three points circumcircle" {
  // Right triangle with legs 3 and 4; hypotenuse is the diameter (5).
  let pts : Array[Point] = [
    { x: 0.0, y: 0.0 },
    { x: 3.0, y: 0.0 },
    { x: 0.0, y: 4.0 },
  ]
  let c = smallest_enclosing_circle(pts[:])
  // The MEC of a right triangle is the diameter on its hypotenuse:
  // center (1.5, 2), radius 2.5.
  @debug.assert_eq(abs_diff(c.radius, 2.5) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 1.5) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.y, 2.0) < 1.0e-9, true)
}

///|
test "mec equilateral triangle" {
  // Equilateral with side 2: vertices (0,0), (2,0), (1, sqrt(3)).
  // Circumradius is side / sqrt(3) = 2/sqrt(3) ≈ 1.1547005.
  let h = (3.0 : Double).sqrt()
  let pts : Array[Point] = [
    { x: 0.0, y: 0.0 },
    { x: 2.0, y: 0.0 },
    { x: 1.0, y: h },
  ]
  let c = smallest_enclosing_circle(pts[:])
  let expected_r = 2.0 / h
  @debug.assert_eq(abs_diff(c.radius, expected_r) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 1.0) < 1.0e-9, true)
  // Circumcenter y = h/3 for this triangle.
  @debug.assert_eq(abs_diff(c.center.y, h / 3.0) < 1.0e-9, true)
}

///|
test "mec square corners diagonal radius" {
  let pts : Array[Point] = [
    { x: 0.0, y: 0.0 },
    { x: 2.0, y: 0.0 },
    { x: 2.0, y: 2.0 },
    { x: 0.0, y: 2.0 },
  ]
  let c = smallest_enclosing_circle(pts[:])
  // Diagonal length = 2*sqrt(2); radius = sqrt(2); center = (1, 1).
  let expected_r = (2.0 : Double).sqrt()
  @debug.assert_eq(abs_diff(c.radius, expected_r) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 1.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.y, 1.0) < 1.0e-9, true)
}

///|
test "mec contains all points (fuzz)" {
  // Hand-built spread of 12 points; verify each lies within radius + EPS.
  let pts : Array[Point] = [
    { x: 1.2, y: 3.4 },
    { x: -2.5, y: 0.1 },
    { x: 0.0, y: -1.7 },
    { x: 5.0, y: 2.3 },
    { x: 4.1, y: -3.0 },
    { x: -1.0, y: 4.4 },
    { x: 2.7, y: 1.9 },
    { x: -3.3, y: -2.2 },
    { x: 0.5, y: 0.5 },
    { x: 3.6, y: 4.6 },
    { x: -0.7, y: 2.1 },
    { x: 2.0, y: -2.0 },
  ]
  let c = smallest_enclosing_circle(pts[:])
  // All points must be within radius^2 + EPS of center.
  let all_inside = for i = 0, ok = true; i < pts.length(); {
    let d2 = dist_sq(c.center, pts[i])
    let inside = d2 <= c.radius * c.radius + 1.0e-8
    if inside {
      continue i + 1, ok
    } else {
      continue i + 1, false
    }
  } nobreak {
    ok
  }
  @debug.assert_eq(all_inside, true)
  // And the circle must be `tight`: at least one point must be on the
  // boundary (within a generous tolerance for floating point).
  let some_on_boundary = for i = 0, found = false; i < pts.length(); {
    let d = dist_sq(c.center, pts[i]).sqrt()
    if abs_diff(d, c.radius) < 1.0e-6 {
      continue i + 1, true
    } else {
      continue i + 1, found
    }
  } nobreak {
    found
  }
  @debug.assert_eq(some_on_boundary, true)
}

///|
test "mec interior points do not change result" {
  // Surround the unit disk's corners with several `inside` points; the
  // MEC must still be determined by the four square corners.
  let pts : Array[Point] = [
    { x: -1.0, y: -1.0 },
    { x: 1.0, y: -1.0 },
    { x: 1.0, y: 1.0 },
    { x: -1.0, y: 1.0 },
    { x: 0.0, y: 0.0 },
    { x: 0.3, y: -0.4 },
    { x: -0.5, y: 0.5 },
    { x: 0.7, y: 0.2 },
  ]
  let c = smallest_enclosing_circle(pts[:])
  let expected_r = (2.0 : Double).sqrt()
  @debug.assert_eq(abs_diff(c.radius, expected_r) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 0.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.y, 0.0) < 1.0e-9, true)
}

///|
test "mec collinear three points" {
  // Three collinear points; the circumcircle helper should fall back to
  // the diameter circle of the farthest pair.
  let pts : Array[Point] = [
    { x: 0.0, y: 0.0 },
    { x: 5.0, y: 0.0 },
    { x: 10.0, y: 0.0 },
  ]
  let c = smallest_enclosing_circle(pts[:])
  // MEC is the diameter on (0,0)-(10,0): center (5,0), radius 5.
  @debug.assert_eq(abs_diff(c.radius, 5.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 5.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.y, 0.0) < 1.0e-9, true)
}

///|
test "mec duplicate points" {
  // Duplicates should not break the algorithm; a duplicate is `inside`
  // any circle that already contains the original.
  let pts : Array[Point] = [
    { x: 0.0, y: 0.0 },
    { x: 0.0, y: 0.0 },
    { x: 4.0, y: 0.0 },
    { x: 4.0, y: 0.0 },
    { x: 4.0, y: 3.0 },
  ]
  let c = smallest_enclosing_circle(pts[:])
  // Hypotenuse-as-diameter: 5/2 radius around (2, 1.5).
  @debug.assert_eq(abs_diff(c.radius, 2.5) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.x, 2.0) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c.center.y, 1.5) < 1.0e-9, true)
}

///|
test "contains_point boundary slack" {
  // A point exactly on the boundary should count as contained.
  let c : Circle = { center: { x: 0.0, y: 0.0 }, radius: 5.0 }
  @debug.assert_eq(contains_point(c, { x: 5.0, y: 0.0 }), true)
  @debug.assert_eq(contains_point(c, { x: 0.0, y: 5.0 }), true)
  @debug.assert_eq(contains_point(c, { x: 3.0, y: 4.0 }), true)
  // A point a hair outside should not.
  @debug.assert_eq(contains_point(c, { x: 5.001, y: 0.0 }), false)
}

///|
test "circle_from_three matches circle_from_two for right triangle" {
  // The circumcircle of a right triangle equals the diameter circle on
  // its hypotenuse. Sanity-check that both helpers agree.
  let p : Point = { x: 0.0, y: 0.0 }
  let q : Point = { x: 6.0, y: 0.0 }
  let r : Point = { x: 0.0, y: 8.0 }
  let c1 = circle_from_three(p, q, r)
  let c2 = circle_from_two(q, r) // hypotenuse
  @debug.assert_eq(abs_diff(c1.radius, c2.radius) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c1.center.x, c2.center.x) < 1.0e-9, true)
  @debug.assert_eq(abs_diff(c1.center.y, c2.center.y) < 1.0e-9, true)
}
