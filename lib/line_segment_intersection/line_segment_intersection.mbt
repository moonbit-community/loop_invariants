// ============================================================================
// LINE SEGMENT INTERSECTION - Orientation Tests
// ============================================================================
//
// Two segments (a,b) and (c,d) intersect if and only if their orientations
// differ, with careful handling of collinear cases.
//
// TIME COMPLEXITY: O(1)
// SPACE COMPLEXITY: O(1)

///|
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Debug, Eq)

///|
fn cross(a : Point, b : Point, c : Point) -> Int64 {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
fn on_segment(a : Point, b : Point, p : Point) -> Bool {
  let min_x = if a.x < b.x { a.x } else { b.x }
  let max_x = if a.x > b.x { a.x } else { b.x }
  let min_y = if a.y < b.y { a.y } else { b.y }
  let max_y = if a.y > b.y { a.y } else { b.y }
  p.x >= min_x && p.x <= max_x && p.y >= min_y && p.y <= max_y
}

///|
/// Return true if segments (a,b) and (c,d) intersect.
pub fn segments_intersect(a : Point, b : Point, c : Point, d : Point) -> Bool {
  let o1 = cross(a, b, c)
  let o2 = cross(a, b, d)
  let o3 = cross(c, d, a)
  let o4 = cross(c, d, b)
  if o1 == 0 && on_segment(a, b, c) {
    return true
  }
  if o2 == 0 && on_segment(a, b, d) {
    return true
  }
  if o3 == 0 && on_segment(c, d, a) {
    return true
  }
  if o4 == 0 && on_segment(c, d, b) {
    return true
  }
  ((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) &&
  ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0))
}
