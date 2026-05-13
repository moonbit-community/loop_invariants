// ============================================================================
// HALF-PLANE INTERSECTION - Deque Algorithm
// ============================================================================
//
// Each half-plane is defined by a directed line (p, v). The feasible region
// is the set of points to the left of v when looking from p.
//
// The algorithm sorts half-planes by angle and maintains a deque of candidate
// lines whose intersection is non-empty. It runs in O(n log n).
//
// KEY INSIGHT: After sorting by angle, any new half-plane can only invalidate
// the front or back of the deque, never the middle. This monotonicity property
// allows a linear deque scan rather than a quadratic search.
//
// ALGORITHM STEPS:
// 1. Sort half-planes by direction angle (using the half-plane ordering).
// 2. Among parallel half-planes (same angle), keep only the most restrictive.
// 3. Process in sorted order using a deque:
//    a. Pop the back while the last intersection point is outside the new line.
//    b. Pop the front while the first intersection point is outside the new line.
//    c. Push the new half-plane onto the back.
// 4. Final trim: reconcile the front/back wrap-around.
// 5. If fewer than 3 lines remain, the region is empty or unbounded.
// 6. Intersect consecutive lines to produce the polygon vertices.
//
// TIME COMPLEXITY:  O(n log n)  -- dominated by the sort in step 1
// SPACE COMPLEXITY: O(n)

///|
const EPS : Double = 1.0e-12

///|
/// A 2D point (or 2D vector) with floating-point coordinates.
///
/// `Point` is used both for geometric positions and for direction vectors
/// inside `HalfPlane`. All arithmetic (cross product, linear combination) is
/// performed through the private helpers `sub`, `add`, `mul`, and `cross_vec`.
///
/// Example:
/// ```
/// let origin : Point = { x: 0.0, y: 0.0 }
/// let unit_x  : Point = { x: 1.0, y: 0.0 }
/// ```
pub(all) struct Point {
  x : Double
  y : Double
} derive(Debug)

///|
/// A half-plane defined by a directed boundary line.
///
/// The boundary line passes through point `p` with direction vector `v`.
/// The **feasible side** is the half-plane to the *left* of `v` when looking
/// from `p`: a point `q` is inside if `cross(v, q - p) >= 0`.
///
/// ```
///  direction v -->
///  _______________
///  p                  (boundary line)
///  _______________
///
///  LEFT  of v  =  FEASIBLE  (this is the "inside")
///  RIGHT of v  =  INFEASIBLE
/// ```
///
/// Construct a `HalfPlane` from two boundary points using `from_points`.
/// You rarely need to build the struct literal directly.
pub(all) struct HalfPlane {
  p : Point
  v : Point // Direction vector; feasible region is left of v
} derive(Debug)

///|
fn abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
fn sub(a : Point, b : Point) -> Point {
  { x: a.x - b.x, y: a.y - b.y }
}

///|
fn add(a : Point, b : Point) -> Point {
  { x: a.x + b.x, y: a.y + b.y }
}

///|
fn mul(a : Point, k : Double) -> Point {
  { x: a.x * k, y: a.y * k }
}

///|
fn cross_vec(a : Point, b : Point) -> Double {
  a.x * b.y - a.y * b.x
}

///|
fn cross(a : Point, b : Point, c : Point) -> Double {
  cross_vec(sub(b, a), sub(c, a))
}

///|
fn is_inside(h : HalfPlane, q : Point) -> Bool {
  cross(h.p, add(h.p, h.v), q) >= -EPS
}

///|
fn line_intersection(a : HalfPlane, b : HalfPlane) -> Point {
  let u = sub(b.p, a.p)
  let den = cross_vec(a.v, b.v)
  let t = cross_vec(u, b.v) / den
  add(a.p, mul(a.v, t))
}

///|
/// Returns 0 if the direction vector `v` points into the upper half
/// (y > 0, or y == 0 and x >= 0), and 1 otherwise.
///
/// This two-way partition is used to sort half-planes by angle in [0, 2*pi).
/// Vectors in the same half are further ordered by cross product so that
/// the full sort produces a counterclockwise sweep of directions.
fn half(v : Point) -> Int {
  if v.y > 0.0 || (v.y == 0.0 && v.x >= 0.0) {
    0
  } else {
    1
  }
}

///|
/// Returns `true` when half-planes `a` and `b` have parallel direction vectors,
/// i.e. when their directions are the same or exactly opposite.
///
/// The test uses an epsilon comparison on the cross product of the two
/// direction vectors so that near-parallel lines caused by floating-point
/// rounding are treated as identical.
fn same_angle(a : HalfPlane, b : HalfPlane) -> Bool {
  abs(cross_vec(a.v, b.v)) <= EPS
}

///|
/// Construct a `HalfPlane` from two points on its boundary line.
///
/// The boundary is the directed line from `a` to `b`. The feasible region
/// is the half-plane to the **left** of the direction `a -> b`.
///
/// Parameters:
/// - `a` - first point on the boundary (also the base point `p`)
/// - `b` - second point on the boundary; defines the direction `v = b - a`
///
/// Example -- the constraint `y >= 0` (keep the upper half-plane):
/// ```
/// // The x-axis runs left-to-right; left of east is north (y >= 0).
/// let h = HalfPlane::from_points({ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 })
/// ```
pub fn HalfPlane::from_points(a : Point, b : Point) -> HalfPlane {
  { p: a, v: sub(b, a) }
}

///|
/// Compute the convex polygon that is the intersection of all given half-planes.
///
/// Each half-plane is a `HalfPlane` value whose feasible side is to the left of
/// its direction vector `v` (see `HalfPlane::from_points`).
///
/// Returns `Some(polygon)` where `polygon` is the list of vertices in
/// **counterclockwise** order, or `None` when the intersection is empty or
/// unbounded (fewer than three bounding edges survive the deque).
///
/// ## Algorithm
///
/// 1. Sort by angle -- half-planes whose directions sweep counterclockwise.
/// 2. Deduplicate parallel half-planes -- among equal-angle pairs keep the
///    more restrictive one (the one whose boundary is further "inward").
/// 3. Maintain a deque of candidate half-planes. For each new half-plane:
///    - Pop the back while the intersection of the last two deque lines lies
///      outside the new half-plane.
///    - Pop the front while the intersection of the first two deque lines lies
///      outside the new half-plane.
///    - Push the new half-plane onto the back.
/// 4. Final wrap-around trim: reconcile the front and back.
/// 5. If fewer than 3 half-planes remain, return `None`.
/// 6. Intersect each consecutive pair of surviving half-planes to obtain the
///    polygon vertices.
///
/// ## Complexity
///
/// - Time: O(n log n) for sorting; O(n) for deque processing.
/// - Space: O(n).
///
/// ## Usage
///
/// ```
/// // Unit square: four half-planes forming 0 <= x <= 1, 0 <= y <= 1.
/// let planes : Array[HalfPlane] = [
///   HalfPlane::from_points({ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }), // y >= 0
///   HalfPlane::from_points({ x: 1.0, y: 0.0 }, { x: 1.0, y: 1.0 }), // x <= 1
///   HalfPlane::from_points({ x: 1.0, y: 1.0 }, { x: 0.0, y: 1.0 }), // y <= 1
///   HalfPlane::from_points({ x: 0.0, y: 1.0 }, { x: 0.0, y: 0.0 }), // x >= 0
/// ]
/// let poly = halfplane_intersection(planes).unwrap()
/// // poly has 4 vertices in CCW order.
/// ```
///
/// ## Unbounded regions
///
/// If the intersection has no finite boundary (e.g. only `x >= 0` and `y >= 0`
/// are given), the function returns `None`. Add a large bounding box to force
/// a bounded result:
///
/// ```
/// // Bounding box [-1e6, 1e6]^2 keeps the result finite.
/// let big = 1.0e6
/// let bbox : Array[HalfPlane] = [
///   HalfPlane::from_points({ x: -big, y: -big }, { x:  big, y: -big }),
///   HalfPlane::from_points({ x:  big, y: -big }, { x:  big, y:  big }),
///   HalfPlane::from_points({ x:  big, y:  big }, { x: -big, y:  big }),
///   HalfPlane::from_points({ x: -big, y:  big }, { x: -big, y: -big }),
/// ]
/// ```
pub fn halfplane_intersection(halfplanes : Array[HalfPlane]) -> Array[Point]? {
  if halfplanes.length() == 0 {
    return None
  }
  let lines = halfplanes
  lines.sort_by((a, b) => {
    let ha = half(a.v)
    let hb = half(b.v)
    if ha != hb {
      ha - hb
    } else {
      let c = cross_vec(a.v, b.v)
      if c > EPS {
        -1
      } else if c < -EPS {
        1
      } else {
        0
      }
    }
  })

  // Remove redundant parallel half-planes, keeping the most restrictive.
  let unique : Array[HalfPlane] = []
  for line in lines {
    if unique.length() == 0 {
      unique.push(line)
      continue
    }
    let last_idx = unique.length() - 1
    let last = unique[last_idx]
    if same_angle(last, line) {
      if is_inside(last, line.p) {
        unique[last_idx] = line
      }
    } else {
      unique.push(line)
    }
  }
  let deque : Array[HalfPlane] = []
  let head = for line in unique; head = 0 {
    for ;; {
      if deque.length() - head >= 2 {
        let p = line_intersection(
          deque[deque.length() - 2],
          deque[deque.length() - 1],
        )
        if !is_inside(line, p) {
          let _ = deque.pop()
          continue
        }
      }
      break
    } where {
      proof_invariant: head >= 0 && head <= deque.length(),
      proof_reasoning: (
        #|INVARIANT (pop back):
        #|The deque stores half-planes whose intersection is non-empty. If the
        #|last intersection point violates the new line, we discard the back
        #|because it cannot contribute to the feasible region.
        #|MAINTENANCE:
        #|Pop the back until the new line contains the last intersection.
        #|TERMINATION:
        #|When the intersection is inside the new line, the back is stable.
      ),
    }
    let head = for head = head; deque.length() - head >= 2; {
      if deque.length() - head >= 2 {
        let p = line_intersection(deque[head], deque[head + 1])
        if !is_inside(line, p) {
          continue head + 1
        }
      }
      break head
    } nobreak {
      head
    } where {
      proof_invariant: head >= 0 && head <= deque.length(),
      proof_reasoning: (
        #|INVARIANT (pop front):
        #|If the front intersection point violates the new line, the front line
        #|cannot be part of the final intersection and is removed.
        #|MAINTENANCE:
        #|Advance head until the new line contains the front intersection.
        #|TERMINATION:
        #|When the front is valid, the deque is consistent with the new line.
      ),
    }
    deque.push(line)
    continue head
  } nobreak {
    head
  }
  for ;; {
    if deque.length() - head >= 3 {
      let p = line_intersection(
        deque[deque.length() - 2],
        deque[deque.length() - 1],
      )
      if !is_inside(deque[head], p) {
        let _ = deque.pop()
        continue
      }
    }
    break
  } where {
    proof_invariant: head >= 0 && head <= deque.length(),
    proof_reasoning: (
      #|INVARIANT (final back trim):
      #|The deque represents a feasible intersection except possibly at the back.
      #|MAINTENANCE:
      #|Remove back lines that violate the front constraint.
      #|TERMINATION:
      #|When the back intersection is inside the front half-plane, closure holds.
    ),
  }
  let head = for head = head; deque.length() - head >= 3; {
    if deque.length() - head >= 3 {
      let p = line_intersection(deque[head], deque[head + 1])
      if !is_inside(deque[deque.length() - 1], p) {
        continue head + 1
      }
    }
    break head
  } nobreak {
    head
  } where {
    proof_invariant: head >= 0 && head <= deque.length(),
    proof_reasoning: (
      #|INVARIANT (final front trim):
      #|The deque represents a feasible intersection except possibly at the front.
      #|MAINTENANCE:
      #|Remove front lines that violate the back constraint.
      #|TERMINATION:
      #|When the front intersection is inside the back half-plane, closure holds.
    ),
  }
  let m = deque.length() - head
  if m < 3 {
    return None
  }
  let result : Array[Point] = [
    for i in 0..<m => {
      let l1 = deque[head + i]
      let l2 = deque[head + (i + 1) % m]
      line_intersection(l1, l2)
    }
  ]
  Some(result)
}

// ============================================================================
// TESTS
// ============================================================================

///|
fn approx(a : Double, b : Double) -> Bool {
  abs(a - b) <= 1.0e-8
}

///|
test "halfplane square" {
  let planes : Array[HalfPlane] = [
    HalfPlane::from_points({ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }),
    HalfPlane::from_points({ x: 1.0, y: 0.0 }, { x: 1.0, y: 1.0 }),
    HalfPlane::from_points({ x: 1.0, y: 1.0 }, { x: 0.0, y: 1.0 }),
    HalfPlane::from_points({ x: 0.0, y: 1.0 }, { x: 0.0, y: 0.0 }),
  ]
  let poly = halfplane_intersection(planes).unwrap()
  debug_inspect(poly.length(), content="4")
  let min_x = poly[:].iter().map(p => p.x).minimum().unwrap()
  let max_x = poly[:].iter().map(p => p.x).maximum().unwrap()
  let min_y = poly[:].iter().map(p => p.y).minimum().unwrap()
  let max_y = poly[:].iter().map(p => p.y).maximum().unwrap()
  debug_inspect(approx(min_x, 0.0) && approx(max_x, 1.0), content="true")
  debug_inspect(approx(min_y, 0.0) && approx(max_y, 1.0), content="true")
}

///|
test "halfplane empty" {
  let planes : Array[HalfPlane] = [
    HalfPlane::from_points({ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }),
    HalfPlane::from_points({ x: 0.0, y: 1.0 }, { x: 1.0, y: 1.0 }),
  ]
  guard halfplane_intersection(planes) is None else { fail("expected None") }
}

///|
test "halfplane keeps most restrictive parallel line" {
  let planes : Array[HalfPlane] = [
    HalfPlane::from_points({ x: 0.0, y: 2.0 }, { x: 0.0, y: 0.0 }),
    HalfPlane::from_points({ x: 1.0, y: 2.0 }, { x: 1.0, y: 0.0 }),
    HalfPlane::from_points({ x: 3.0, y: 0.0 }, { x: 3.0, y: 2.0 }),
    HalfPlane::from_points({ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }),
    HalfPlane::from_points({ x: 3.0, y: 2.0 }, { x: 0.0, y: 2.0 }),
  ]
  let poly = halfplane_intersection(planes).unwrap()
  let min_x = poly[:].iter().map(p => p.x).minimum().unwrap()
  let max_x = poly[:].iter().map(p => p.x).maximum().unwrap()
  let min_y = poly[:].iter().map(p => p.y).minimum().unwrap()
  let max_y = poly[:].iter().map(p => p.y).maximum().unwrap()
  debug_inspect(approx(min_x, 1.0) && approx(max_x, 3.0), content="true")
  debug_inspect(approx(min_y, 0.0) && approx(max_y, 2.0), content="true")
}
