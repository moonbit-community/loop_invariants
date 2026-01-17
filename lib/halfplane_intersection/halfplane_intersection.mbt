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
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
const EPS : Double = 1.0e-12

///|
pub(all) struct Point {
  x : Double
  y : Double
} derive(Show)

///|
pub(all) struct HalfPlane {
  p : Point
  v : Point // Direction vector; feasible region is left of v
} derive(Show)

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
fn half(v : Point) -> Int {
  if v.y > 0.0 || (v.y == 0.0 && v.x >= 0.0) {
    0
  } else {
    1
  }
}

///|
fn same_angle(a : HalfPlane, b : HalfPlane) -> Bool {
  abs(cross_vec(a.v, b.v)) <= EPS
}

///|
/// Construct a half-plane whose boundary is the directed line a -> b.
/// The feasible region is to the left of the direction a->b.
pub fn HalfPlane::from_points(a : Point, b : Point) -> HalfPlane {
  { p: a, v: sub(b, a) }
}

///|
/// Compute the intersection polygon of half-planes.
/// Returns None if the intersection is empty or unbounded.
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
  let mut head = 0
  for line in unique {
    for {
      if deque.length() - head >= 2 {
        let p = line_intersection(
          deque[deque.length() - 2],
          deque[deque.length() - 1],
        )
        if not(is_inside(line, p)) {
          let _ = deque.pop()
          continue
        }
      }
      break
    } where {
      invariant: head >= 0 && head <= deque.length(),
      reasoning: (
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
    for {
      if deque.length() - head >= 2 {
        let p = line_intersection(deque[head], deque[head + 1])
        if not(is_inside(line, p)) {
          head = head + 1
          continue
        }
      }
      break
    } where {
      invariant: head >= 0 && head <= deque.length(),
      reasoning: (
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
  }
  for {
    if deque.length() - head >= 3 {
      let p = line_intersection(
        deque[deque.length() - 2],
        deque[deque.length() - 1],
      )
      if not(is_inside(deque[head], p)) {
        let _ = deque.pop()
        continue
      }
    }
    break
  } where {
    invariant: head >= 0 && head <= deque.length(),
    reasoning: (
      #|INVARIANT (final back trim):
      #|The deque represents a feasible intersection except possibly at the back.
      #|MAINTENANCE:
      #|Remove back lines that violate the front constraint.
      #|TERMINATION:
      #|When the back intersection is inside the front half-plane, closure holds.
    ),
  }
  for {
    if deque.length() - head >= 3 {
      let p = line_intersection(deque[head], deque[head + 1])
      if not(is_inside(deque[deque.length() - 1], p)) {
        head = head + 1
        continue
      }
    }
    break
  } where {
    invariant: head >= 0 && head <= deque.length(),
    reasoning: (
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
  let result : Array[Point] = []
  for i in 0..<m {
    let l1 = deque[head + i]
    let l2 = deque[head + (i + 1) % m]
    result.push(line_intersection(l1, l2))
  }
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
  inspect(poly.length(), content="4")
  let min_x = poly[:].iter().map(p => p.x).minimum().unwrap()
  let max_x = poly[:].iter().map(p => p.x).maximum().unwrap()
  let min_y = poly[:].iter().map(p => p.y).minimum().unwrap()
  let max_y = poly[:].iter().map(p => p.y).maximum().unwrap()
  inspect(approx(min_x, 0.0) && approx(max_x, 1.0), content="true")
  inspect(approx(min_y, 0.0) && approx(max_y, 1.0), content="true")
}

///|
test "halfplane empty" {
  let planes : Array[HalfPlane] = [
    HalfPlane::from_points({ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }),
    HalfPlane::from_points({ x: 0.0, y: 1.0 }, { x: 1.0, y: 1.0 }),
  ]
  guard halfplane_intersection(planes) is None else { fail("expected None") }
}
