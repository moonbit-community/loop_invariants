// ============================================================================
// POINT-IN-CONVEX-POLYGON  -  O(log n) binary search
// ============================================================================
//
// PROBLEM
//
// Decide whether a query point `q = (qx, qy)` lies inside (or on the
// boundary of) a convex polygon given as a CCW-ordered list of
// vertices `v[0], v[1], ..., v[n-1]`.
//
// THE TRICK
//
// Pin the polygon at its first vertex `v[0]`. The polygon's interior
// is the union of `n - 2` triangles `(v[0], v[i], v[i+1])` for
// `1 <= i <= n - 2`. A point `q` is inside the polygon iff it lies
// inside exactly one of these triangles.
//
// The triangles fan out from `v[0]`, so they are sorted by angle from
// `v[0]`. We can **binary-search** for the wedge that could contain `q`
// by comparing the cross products:
//
//   cross(v[i] - v[0], q - v[0])  -- which side of ray v[0]v[i]
//
// The binary search picks `i` so that `q` lies between rays
// `v[0]v[i]` and `v[0]v[i+1]` (CCW order). A final cross-product
// check tests whether `q` is on the correct side of the chord
// `v[i] v[i+1]` (inside the convex polygon).
//
// COMPLEXITY
//
//   query : O(log n) per point
//   prep  : O(1)
//
// THE INVARIANT
//
//   "At each step of the binary search [lo, hi], `q` is angularly
//    between rays v[0]v[lo] and v[0]v[hi]."

///|
/// Cross product of (b - a) and (c - a).
fn cross(a : (Int64, Int64), b : (Int64, Int64), c : (Int64, Int64)) -> Int64 {
  (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0)
}

///|
/// Polygon must be **convex** and given **counter-clockwise** with no
/// duplicate or collinear consecutive vertices. Returns:
///
///   1  : strictly inside
///   0  : on the boundary
///  -1  : strictly outside
///
/// Or `-1` for degenerate inputs (fewer than 3 vertices).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Unit square CCW.
///   let poly = [(0L, 0L), (4L, 0L), (4L, 4L), (0L, 4L)]
///   @debug.assert_eq(@point_in_convex_polygon.locate(poly, (2L, 2L)), 1)
///   @debug.assert_eq(@point_in_convex_polygon.locate(poly, (4L, 4L)), 0)
///   @debug.assert_eq(@point_in_convex_polygon.locate(poly, (5L, 5L)), -1)
/// }
/// ```
pub fn locate(poly : Array[(Int64, Int64)], q : (Int64, Int64)) -> Int {
  let n = poly.length()
  if n < 3 {
    return -1
  }
  let v0 = poly[0]
  // q must be in the angular range [v[0]v[1], v[0]v[n-1]].
  // We use signs of cross products.
  let c1 = cross(v0, poly[1], q)
  let cn = cross(v0, poly[n - 1], q)
  if c1 < 0L || cn > 0L {
    return -1
  }
  // Boundary case: on ray v[0]v[1] or v[0]v[n-1] *between* v[0] and the vertex.
  if c1 == 0L {
    // q is on the line through v[0] and poly[1]. Inside iff between them.
    let (ax, ay) = v0
    let (bx, by) = poly[1]
    let (qx, qy) = q
    let dxv = bx - ax
    let dyv = by - ay
    let dxq = qx - ax
    let dyq = qy - ay
    let t_num = dxq * dxv + dyq * dyv
    let t_den = dxv * dxv + dyv * dyv
    if t_num >= 0L && t_num <= t_den {
      return 0
    } else {
      return -1
    }
  }
  if cn == 0L {
    let (ax, ay) = v0
    let (bx, by) = poly[n - 1]
    let (qx, qy) = q
    let dxv = bx - ax
    let dyv = by - ay
    let dxq = qx - ax
    let dyq = qy - ay
    let t_num = dxq * dxv + dyq * dyv
    let t_den = dxv * dxv + dyv * dyv
    if t_num >= 0L && t_num <= t_den {
      return 0
    } else {
      return -1
    }
  }
  // Binary search for the index `i` in [1, n-1) such that
  // cross(v0, poly[i], q) >= 0 and cross(v0, poly[i+1], q) <= 0.
  let mut lo = 1
  let mut hi = n - 1
  while hi - lo > 1 {
    let mid = (lo + hi) / 2
    if cross(v0, poly[mid], q) >= 0L {
      lo = mid
    } else {
      hi = mid
    }
  }
  // Now q is in the wedge bounded by rays v0->poly[lo] and v0->poly[hi].
  // Final test: cross over edge poly[lo] -> poly[hi].
  let c = cross(poly[lo], poly[hi], q)
  if c > 0L {
    1
  } else if c < 0L {
    -1
  } else {
    0
  }
}

///|
test "convex unit square interior" {
  let p = [(0L, 0L), (4L, 0L), (4L, 4L), (0L, 4L)]
  @debug.assert_eq(locate(p, (2L, 2L)), 1)
  @debug.assert_eq(locate(p, (1L, 3L)), 1)
}

///|
test "convex unit square boundary" {
  let p = [(0L, 0L), (4L, 0L), (4L, 4L), (0L, 4L)]
  // Corners.
  @debug.assert_eq(locate(p, (0L, 0L)), 0)
  @debug.assert_eq(locate(p, (4L, 0L)), 0)
  @debug.assert_eq(locate(p, (4L, 4L)), 0)
  @debug.assert_eq(locate(p, (0L, 4L)), 0)
  // Mid-edges.
  @debug.assert_eq(locate(p, (2L, 0L)), 0)
  @debug.assert_eq(locate(p, (4L, 2L)), 0)
  @debug.assert_eq(locate(p, (2L, 4L)), 0)
  @debug.assert_eq(locate(p, (0L, 2L)), 0)
}

///|
test "convex unit square outside" {
  let p = [(0L, 0L), (4L, 0L), (4L, 4L), (0L, 4L)]
  @debug.assert_eq(locate(p, (5L, 5L)), -1)
  @debug.assert_eq(locate(p, (-1L, 2L)), -1)
  @debug.assert_eq(locate(p, (2L, -1L)), -1)
  @debug.assert_eq(locate(p, (5L, 2L)), -1)
}

///|
test "convex pentagon" {
  // CCW regular-ish pentagon (integer-approximation).
  let p = [(10L, 0L), (3L, 9L), (-8L, 5L), (-8L, -5L), (3L, -9L)]
  // Centre is inside.
  @debug.assert_eq(locate(p, (0L, 0L)), 1)
  // Far outside.
  @debug.assert_eq(locate(p, (100L, 100L)), -1)
  // Near edge (sanity).
  @debug.assert_eq(locate(p, (10L, 0L)), 0) // a vertex
}

///|
test "convex degenerate" {
  let triangle = [(0L, 0L), (4L, 0L), (0L, 3L)]
  @debug.assert_eq(locate(triangle, (1L, 1L)), 1)
  @debug.assert_eq(locate(triangle, (2L, 2L)), -1) // outside via hypotenuse
  // Fewer than 3 vertices.
  @debug.assert_eq(locate([], (0L, 0L)), -1)
  @debug.assert_eq(locate([(0L, 0L)], (0L, 0L)), -1)
  @debug.assert_eq(locate([(0L, 0L), (1L, 1L)], (0L, 0L)), -1)
}

///|
test "convex large polygon binary search correctness" {
  // 8-gon, large enough that the binary search is non-trivial.
  let p = [
    (4L, 0L),
    (3L, 3L),
    (0L, 4L),
    (-3L, 3L),
    (-4L, 0L),
    (-3L, -3L),
    (0L, -4L),
    (3L, -3L),
  ]
  @debug.assert_eq(locate(p, (0L, 0L)), 1)
  @debug.assert_eq(locate(p, (5L, 0L)), -1)
  @debug.assert_eq(locate(p, (4L, 0L)), 0)
  @debug.assert_eq(locate(p, (3L, 3L)), 0)
  @debug.assert_eq(locate(p, (2L, 1L)), 1)
}
