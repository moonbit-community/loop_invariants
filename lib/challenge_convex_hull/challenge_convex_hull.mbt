// ============================================================================
// Challenge: Convex Hull (Monotone Chain)
// ============================================================================

///|
pub(all) struct Point {
  x : Int
  y : Int
} derive(Eq, Show)

///|
fn point_compare(a : Point, b : Point) -> Int {
  if a.x != b.x {
    a.x - b.x
  } else {
    a.y - b.y
  }
}

///|
fn cross(a : Point, b : Point, c : Point) -> Int {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
/// Compute the convex hull in CCW order using the monotone chain algorithm.
#warnings("+missing_invariant+missing_reasoning")
pub fn convex_hull(points : ArrayView[Point]) -> Array[Point] {
  let n = points.length()
  if n <= 1 {
    return points.to_array()
  }
  let pts = points.to_array()
  pts.sort_by(point_compare)
  let lower : Array[Point] = []
  for i = 0; i < pts.length(); i = i + 1 {
    let p = pts[i]
    while lower.length() >= 2 &&
          cross(lower[lower.length() - 2], lower[lower.length() - 1], p) <= 0 {
      let _ = lower.pop()

    }
    lower.push(p)
  } where {
    invariant: i >= 0 && i <= pts.length(),
    reasoning: (
      #|INVARIANT (lower hull):
      #|lower is the convex hull of pts[0..i) for the lower chain in CCW order.
      #|MAINTENANCE:
      #|Pop while the last turn is non-left, then push the new point.
      #|TERMINATION:
      #|At i = n, lower is the full lower chain.
    ),
  }
  let upper : Array[Point] = []
  for i = pts.length() - 1; i >= 0; i = i - 1 {
    let p = pts[i]
    while upper.length() >= 2 &&
          cross(upper[upper.length() - 2], upper[upper.length() - 1], p) <= 0 {
      let _ = upper.pop()

    }
    upper.push(p)
  } where {
    invariant: i >= 0 && i < pts.length(),
    reasoning: (
      #|INVARIANT (upper hull):
      #|upper is the convex hull of pts[i..] for the upper chain in CCW order.
      #|MAINTENANCE:
      #|Pop while the last turn is non-left, then push the new point.
      #|TERMINATION:
      #|When i < 0, upper is the full upper chain.
    ),
  }
  if lower.length() > 0 {
    let _ = lower.pop()

  }
  if upper.length() > 0 {
    let _ = upper.pop()

  }
  lower.append(upper)
  lower
}

///|
test "convex_hull_square" {
  let pts : Array[Point] = [
    { x: 0, y: 0 },
    { x: 2, y: 0 },
    { x: 2, y: 2 },
    { x: 0, y: 2 },
    { x: 1, y: 1 },
  ]
  let hull = convex_hull(pts[:])
  assert_eq(hull, [
    { x: 0, y: 0 },
    { x: 2, y: 0 },
    { x: 2, y: 2 },
    { x: 0, y: 2 },
  ])
}
