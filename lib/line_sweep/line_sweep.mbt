// ============================================================================
// LINE SWEEP ALGORITHMS - Computational Geometry
// ============================================================================
//
// Line sweep (plane sweep) processes geometric objects by moving a conceptual
// line across the plane, handling events as they occur.
//
// GENERAL PATTERN:
// 1. Create events from objects (start/end points, intersections)
// 2. Sort events by sweep coordinate
// 3. Maintain active set of objects intersecting sweep line
// 4. Process events in order, updating active set and computing results
//
// APPLICATIONS:
// - Rectangle union area
// - Line segment intersections
// - Closest pair of points
// - Convex hull (gift wrapping)
//
// INVARIANTS:
// 1. Events are processed in sorted order
// 2. Active set contains objects currently intersecting sweep line
// 3. Data structure supports efficient insert/delete/query
//
// TIME COMPLEXITY: O(n log n) for most applications
// SPACE COMPLEXITY: O(n)

///|
const SWEEP_EPS : Double = 0.000000001

// ============================================================================
// RECTANGLE UNION AREA
// ============================================================================

///|
priv struct Rectangle {
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
}

///|
priv enum RectEvent {
  Start(Double, Double, Double) // x, y1, y2 (rectangle starts)
  End(Double, Double, Double)   // x, y1, y2 (rectangle ends)
} derive(Eq)

///|
fn event_x(e : RectEvent) -> Double {
  match e {
    Start(x, _, _) => x
    End(x, _, _) => x
  }
}

///|
fn event_is_start(e : RectEvent) -> Bool {
  match e {
    Start(_, _, _) => true
    End(_, _, _) => false
  }
}

///|
fn event_sort_key(e : RectEvent) -> (Double, Int) {
  match e {
    Start(x, _, _) => (x, 0) // starts first
    End(x, _, _) => (x, 1)
  }
}

///|
/// Compute union area of rectangles using coordinate compression
fn rectangle_union_area(rects : Array[Rectangle]) -> Double {
  if rects.length() == 0 {
    return 0.0
  }

  // Collect all y-coordinates for compression
  let y_coords : Array[Double] = []
  for i = 0; i < rects.length(); i = i + 1 {
    y_coords.push(rects[i].y1)
    y_coords.push(rects[i].y2)
  }

  // Sort and deduplicate y-coordinates
  y_coords.sort()
  let unique_y : Array[Double] = []
  for i = 0; i < y_coords.length(); i = i + 1 {
    if unique_y.length() == 0 || (y_coords[i] - unique_y[unique_y.length() - 1]).abs() > SWEEP_EPS {
      unique_y.push(y_coords[i])
    }
  }

  // Create events
  let events : Array[RectEvent] = []
  for i = 0; i < rects.length(); i = i + 1 {
    events.push(Start(rects[i].x1, rects[i].y1, rects[i].y2))
    events.push(End(rects[i].x2, rects[i].y1, rects[i].y2))
  }

  // Sort events by x-coordinate (starts before ends at same x)
  events.sort_by_key(event_sort_key)

  // Count array: how many rectangles cover each y-segment
  let n_segments = unique_y.length() - 1
  let count = Array::make(n_segments, 0)

  // Binary search for y-coordinate
  fn find_y_index(y : Double) -> Int {
    let mut lo = 0
    let mut hi = unique_y.length() - 1
    while lo < hi {
      let mid = (lo + hi) / 2
      if unique_y[mid] < y - SWEEP_EPS {
        lo = mid + 1
      } else {
        hi = mid
      }
    }
    lo
  }

  // Compute covered length
  fn covered_length() -> Double {
    let mut total = 0.0
    for i = 0; i < n_segments; i = i + 1 {
      if count[i] > 0 {
        total = total + unique_y[i + 1] - unique_y[i]
      }
    }
    total
  }

  let mut total_area = 0.0
  let mut prev_x = event_x(events[0])

  for i = 0; i < events.length(); i = i + 1 {
    let curr_x = event_x(events[i])

    // Add area from previous sweep position
    if curr_x > prev_x + SWEEP_EPS {
      total_area = total_area + covered_length() * (curr_x - prev_x)
    }

    // Update counts
    match events[i] {
      Start(_, y1, y2) => {
        let lo = find_y_index(y1)
        let hi = find_y_index(y2)
        for j = lo; j < hi; j = j + 1 {
          count[j] = count[j] + 1
        }
      }
      End(_, y1, y2) => {
        let lo = find_y_index(y1)
        let hi = find_y_index(y2)
        for j = lo; j < hi; j = j + 1 {
          count[j] = count[j] - 1
        }
      }
    }

    prev_x = curr_x
  }

  total_area
}

// ============================================================================
// MAXIMUM OVERLAP COUNT (Interval Scheduling)
// ============================================================================

///|
priv enum IntervalEvent {
  IntervalStart(Int) // value
  IntervalEnd(Int)   // value
} derive(Eq)

///|
fn interval_event_val(e : IntervalEvent) -> Int {
  match e {
    IntervalStart(v) => v
    IntervalEnd(v) => v
  }
}

///|
fn interval_event_sort_key(e : IntervalEvent) -> (Int, Int) {
  match e {
    IntervalStart(v) => (v, 0) // starts before ends at same point
    IntervalEnd(v) => (v, 1)
  }
}

///|
/// Find maximum number of overlapping intervals
fn max_overlap(intervals : Array[(Int, Int)]) -> Int {
  if intervals.length() == 0 {
    return 0
  }

  let events : Array[IntervalEvent] = []
  for i = 0; i < intervals.length(); i = i + 1 {
    let (start, end) = intervals[i]
    events.push(IntervalStart(start))
    events.push(IntervalEnd(end))
  }

  // Sort: by value, starts before ends at same point
  events.sort_by_key(interval_event_sort_key)

  let mut current = 0
  let mut max_count = 0

  for i = 0; i < events.length(); i = i + 1 {
    match events[i] {
      IntervalStart(_) => {
        current = current + 1
        if current > max_count {
          max_count = current
        }
      }
      IntervalEnd(_) => current = current - 1
    }
  }

  max_count
}

// ============================================================================
// CLOSEST PAIR OF POINTS
// ============================================================================

///|
priv struct Point2D {
  x : Double
  y : Double
} derive(Eq)

///|
fn point_dist(p1 : Point2D, p2 : Point2D) -> Double {
  let dx = p1.x - p2.x
  let dy = p1.y - p2.y
  (dx * dx + dy * dy).sqrt()
}

///|
/// Closest pair using divide and conquer
fn closest_pair(points : Array[Point2D]) -> Double {
  if points.length() < 2 {
    return 1.0e308
  }

  // Sort by x
  let sorted_x = points.copy()
  sorted_x.sort_by_key(fn (p) { p.x })

  closest_pair_rec(sorted_x)
}

///|
fn closest_pair_rec(points : ArrayView[Point2D]) -> Double {
  let n = points.length()

  if n <= 3 {
    // Brute force for small sets
    let mut min_dist = 1.0e308
    for i = 0; i < n; i = i + 1 {
      for j = i + 1; j < n; j = j + 1 {
        let d = point_dist(points[i], points[j])
        if d < min_dist {
          min_dist = d
        }
      }
    }
    return min_dist
  }

  let mid = n / 2
  let mid_x = points[mid].x

  // Recursively find closest in each half
  let left_min = closest_pair_rec(points[:mid])
  let right_min = closest_pair_rec(points[mid:])
  let mut delta = if left_min < right_min { left_min } else { right_min }

  // Check strip around dividing line
  let strip : Array[Point2D] = []
  for i = 0; i < n; i = i + 1 {
    if (points[i].x - mid_x).abs() < delta {
      strip.push(points[i])
    }
  }

  // Sort strip by y
  strip.sort_by_key(fn (p) { p.y })

  // Check nearby points in strip
  for i = 0; i < strip.length(); i = i + 1 {
    for j = i + 1; j < strip.length() && strip[j].y - strip[i].y < delta; j = j + 1 {
      let d = point_dist(strip[i], strip[j])
      if d < delta {
        delta = d
      }
    }
  }

  delta
}

// ============================================================================
// SEGMENT INTERSECTION DETECTION
// ============================================================================

///|
priv struct Segment {
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
}

///|
/// Check if two segments intersect
fn segments_intersect(s1 : Segment, s2 : Segment) -> Bool {
  fn ccw(ax : Double, ay : Double, bx : Double, by : Double, cx : Double, cy : Double) -> Double {
    (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
  }

  let d1 = ccw(s1.x1, s1.y1, s1.x2, s1.y2, s2.x1, s2.y1)
  let d2 = ccw(s1.x1, s1.y1, s1.x2, s1.y2, s2.x2, s2.y2)
  let d3 = ccw(s2.x1, s2.y1, s2.x2, s2.y2, s1.x1, s1.y1)
  let d4 = ccw(s2.x1, s2.y1, s2.x2, s2.y2, s1.x2, s1.y2)

  if ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0)) &&
     ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0)) {
    return true
  }

  // Check collinear cases
  fn on_segment(px : Double, py : Double, ax : Double, ay : Double, bx : Double, by : Double) -> Bool {
    let min_x = if ax < bx { ax } else { bx }
    let max_x = if ax > bx { ax } else { bx }
    let min_y = if ay < by { ay } else { by }
    let max_y = if ay > by { ay } else { by }
    px >= min_x - SWEEP_EPS && px <= max_x + SWEEP_EPS && py >= min_y - SWEEP_EPS && py <= max_y + SWEEP_EPS
  }

  if d1.abs() < SWEEP_EPS && on_segment(s2.x1, s2.y1, s1.x1, s1.y1, s1.x2, s1.y2) { return true }
  if d2.abs() < SWEEP_EPS && on_segment(s2.x2, s2.y2, s1.x1, s1.y1, s1.x2, s1.y2) { return true }
  if d3.abs() < SWEEP_EPS && on_segment(s1.x1, s1.y1, s2.x1, s2.y1, s2.x2, s2.y2) { return true }
  if d4.abs() < SWEEP_EPS && on_segment(s1.x2, s1.y2, s2.x1, s2.y1, s2.x2, s2.y2) { return true }

  false
}

///|
/// Check if any pair of segments intersect (simple O(n²) for small n)
fn any_intersection(segments : Array[Segment]) -> Bool {
  for i = 0; i < segments.length(); i = i + 1 {
    for j = i + 1; j < segments.length(); j = j + 1 {
      if segments_intersect(segments[i], segments[j]) {
        return true
      }
    }
  }
  false
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "rectangle union single" {
  let rects : Array[Rectangle] = [{ x1: 0.0, y1: 0.0, x2: 2.0, y2: 3.0 }]
  let area = rectangle_union_area(rects)
  inspect(area > 5.9 && area < 6.1, content="true")
}

///|
test "rectangle union disjoint" {
  let rects : Array[Rectangle] = [
    { x1: 0.0, y1: 0.0, x2: 1.0, y2: 1.0 },
    { x1: 2.0, y1: 0.0, x2: 3.0, y2: 1.0 }
  ]
  let area = rectangle_union_area(rects)
  inspect(area > 1.9 && area < 2.1, content="true")
}

///|
test "rectangle union overlapping" {
  let rects : Array[Rectangle] = [
    { x1: 0.0, y1: 0.0, x2: 2.0, y2: 2.0 },
    { x1: 1.0, y1: 1.0, x2: 3.0, y2: 3.0 }
  ]
  // Area = 4 + 4 - 1 = 7
  let area = rectangle_union_area(rects)
  inspect(area > 6.9 && area < 7.1, content="true")
}

///|
test "rectangle union contained" {
  let rects : Array[Rectangle] = [
    { x1: 0.0, y1: 0.0, x2: 4.0, y2: 4.0 },
    { x1: 1.0, y1: 1.0, x2: 3.0, y2: 3.0 }
  ]
  // Smaller completely inside larger
  let area = rectangle_union_area(rects)
  inspect(area > 15.9 && area < 16.1, content="true")
}

///|
test "max overlap" {
  let intervals : Array[(Int, Int)] = [(1, 4), (2, 5), (3, 6)]
  inspect(max_overlap(intervals), content="3")
}

///|
test "max overlap disjoint" {
  let intervals : Array[(Int, Int)] = [(1, 2), (3, 4), (5, 6)]
  inspect(max_overlap(intervals), content="1")
}

///|
test "max overlap empty" {
  let intervals : Array[(Int, Int)] = []
  inspect(max_overlap(intervals), content="0")
}

///|
test "closest pair simple" {
  let points : Array[Point2D] = [
    { x: 0.0, y: 0.0 },
    { x: 1.0, y: 0.0 },
    { x: 4.0, y: 0.0 }
  ]
  let dist = closest_pair(points)
  inspect(dist > 0.9 && dist < 1.1, content="true")
}

///|
test "closest pair diagonal" {
  let points : Array[Point2D] = [
    { x: 0.0, y: 0.0 },
    { x: 1.0, y: 1.0 },
    { x: 3.0, y: 3.0 }
  ]
  // Closest is sqrt(2) ≈ 1.414
  let dist = closest_pair(points)
  inspect(dist > 1.4 && dist < 1.5, content="true")
}

///|
test "segments intersect" {
  let s1 : Segment = { x1: 0.0, y1: 0.0, x2: 2.0, y2: 2.0 }
  let s2 : Segment = { x1: 0.0, y1: 2.0, x2: 2.0, y2: 0.0 }
  inspect(segments_intersect(s1, s2), content="true")
}

///|
test "segments parallel" {
  let s1 : Segment = { x1: 0.0, y1: 0.0, x2: 2.0, y2: 0.0 }
  let s2 : Segment = { x1: 0.0, y1: 1.0, x2: 2.0, y2: 1.0 }
  inspect(segments_intersect(s1, s2), content="false")
}

///|
test "any intersection found" {
  let segments : Array[Segment] = [
    { x1: 0.0, y1: 0.0, x2: 2.0, y2: 2.0 },
    { x1: 0.0, y1: 2.0, x2: 2.0, y2: 0.0 }
  ]
  inspect(any_intersection(segments), content="true")
}

///|
test "any intersection none" {
  let segments : Array[Segment] = [
    { x1: 0.0, y1: 0.0, x2: 1.0, y2: 0.0 },
    { x1: 2.0, y1: 0.0, x2: 3.0, y2: 0.0 }
  ]
  inspect(any_intersection(segments), content="false")
}
