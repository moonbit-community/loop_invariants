// ============================================================================
// POLAR SORT  -  sort 2-D points by angle around an origin
// ============================================================================
//
// PROBLEM
//
// Given a set of integer-coordinate points, sort them by **polar angle**
// around a given origin (the standard order used as a preprocessing
// step in Graham scan, line-sweep over arrangements, and angular sort
// queries).
//
// SORT KEY
//
// Comparing two points by the angle their vectors make at the origin
// can be done *exactly* in integer arithmetic via cross products,
// without ever computing `atan2`:
//
//   1. Partition each non-origin point into a "half-plane":
//        upper half: y > 0, or (y == 0 && x > 0)
//        lower half: y < 0, or (y == 0 && x < 0)
//   2. Within the same half-plane, compare by sign of `a × b` (the
//      cross product of position vectors).
//
// This gives a strict weak order matching counter-clockwise angle.
// Points equal to the origin have no well-defined angle; we place
// them at the very front by convention.
//
// COMPLEXITY
//
//   Time : O(n log n) -- the sort is the bottleneck
//   Space: O(n) for the indices used by stable sort
//
// THE INVARIANT
//
//   "After sorting, indices i < j satisfy compare_angle(pts[i],
//    pts[j]) <= 0 with strict less-than for points whose angles
//    actually differ."

///|
fn half(p : (Int64, Int64)) -> Int {
  // Upper half (CCW reference): 0
  // Lower half (-pi to 0):       1
  // Special: (0, 0) -> -1 so it sorts first.
  let (x, y) = p
  if x == 0L && y == 0L {
    return -1
  }
  if y > 0L || (y == 0L && x > 0L) {
    0
  } else {
    1
  }
}

///|
/// Cross product `a × b` (scalar). Returns positive if `b` is CCW from
/// `a` around the origin, negative if CW, zero if collinear.
pub fn cross(a : (Int64, Int64), b : (Int64, Int64)) -> Int64 {
  a.0 * b.1 - a.1 * b.0
}

///|
/// Comparator for polar angle around the origin. Returns a negative
/// number when `a` is angularly before `b`, positive after, and zero
/// when colinear in the same direction.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // (1, 0) precedes (0, 1) when sorting CCW starting from the +x axis.
///   @debug.assert_eq(@polar_sort.cmp_angle((1L, 0L), (0L, 1L)) < 0, true)
/// }
/// ```
pub fn cmp_angle(a : (Int64, Int64), b : (Int64, Int64)) -> Int {
  let ha = half(a)
  let hb = half(b)
  if ha != hb {
    return ha - hb
  }
  let c = cross(a, b)
  if c > 0L {
    -1
  } else if c < 0L {
    1
  } else {
    0
  }
}

///|
/// Sort a list of points around the origin by angle (CCW from the +x
/// axis). Stable. Returns a fresh array.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let pts = [(0L, 1L), (1L, 0L), (-1L, 0L), (0L, -1L)]
///   let s = @polar_sort.sort_around_origin(pts)
///   // CCW from +x: (1,0), (0,1), (-1,0), (0,-1)
///   @debug.assert_eq(s, [(1L, 0L), (0L, 1L), (-1L, 0L), (0L, -1L)])
/// }
/// ```
pub fn sort_around_origin(pts : Array[(Int64, Int64)]) -> Array[(Int64, Int64)] {
  let n = pts.length()
  let res = Array::makei(n, i => pts[i])
  // Simple insertion sort would be O(n^2); use merge sort for stability +
  // O(n log n).
  merge_sort(res, 0, n)
  res
}

///|
/// Sort points by angle around an arbitrary origin `o`. Equivalent to
/// translating each point by `-o` and calling `sort_around_origin`.
pub fn sort_around(
  pts : Array[(Int64, Int64)],
  o : (Int64, Int64),
) -> Array[(Int64, Int64)] {
  let shifted = Array::makei(pts.length(), i => (pts[i].0 - o.0, pts[i].1 - o.1))
  merge_sort(shifted, 0, shifted.length())
  let res = Array::makei(shifted.length(), i => {
    (shifted[i].0 + o.0, shifted[i].1 + o.1)
  })
  res
}

///|
fn merge_sort(arr : Array[(Int64, Int64)], lo : Int, hi : Int) -> Unit {
  if hi - lo <= 1 {
    return
  }
  let mid = lo + (hi - lo) / 2
  merge_sort(arr, lo, mid)
  merge_sort(arr, mid, hi)
  merge(arr, lo, mid, hi)
}

///|
fn merge(arr : Array[(Int64, Int64)], lo : Int, mid : Int, hi : Int) -> Unit {
  let buf = Array::makei(hi - lo, _ => (0L, 0L))
  let mut i = lo
  let mut j = mid
  let mut k = 0
  while i < mid && j < hi {
    if cmp_angle(arr[i], arr[j]) <= 0 {
      buf[k] = arr[i]
      i = i + 1
    } else {
      buf[k] = arr[j]
      j = j + 1
    }
    k = k + 1
  }
  while i < mid {
    buf[k] = arr[i]
    i = i + 1
    k = k + 1
  }
  while j < hi {
    buf[k] = arr[j]
    j = j + 1
    k = k + 1
  }
  for x in 0..<(hi - lo) {
    arr[lo + x] = buf[x]
  }
}

///|
test "polar sort axes" {
  let pts : Array[(Int64, Int64)] = [(0L, 1L), (1L, 0L), (-1L, 0L), (0L, -1L)]
  @debug.assert_eq(sort_around_origin(pts), [
    (1L, 0L),
    (0L, 1L),
    (-1L, 0L),
    (0L, -1L),
  ])
}

///|
test "polar sort all 8 octants" {
  let pts : Array[(Int64, Int64)] = [
    (1L, 1L),
    (-1L, 1L),
    (1L, 2L),
    (2L, 1L),
    (-2L, -1L),
    (-1L, -2L),
    (1L, -1L),
    (-1L, -1L),
  ]
  let s = sort_around_origin(pts)
  // Verify it is non-decreasing in angle.
  for i in 0..<(s.length() - 1) {
    @debug.assert_eq(cmp_angle(s[i], s[i + 1]) <= 0, true)
  }
}

///|
test "polar sort origin point first" {
  let pts : Array[(Int64, Int64)] = [(1L, 0L), (0L, 0L), (0L, 1L)]
  let s = sort_around_origin(pts)
  @debug.assert_eq(s[0], (0L, 0L))
}

///|
test "polar sort stability for colinear" {
  // (2, 0) and (5, 0) are both on +x at distance 2 and 5. They should
  // keep their input order (stable).
  let pts : Array[(Int64, Int64)] = [(2L, 0L), (5L, 0L), (0L, 1L)]
  let s = sort_around_origin(pts)
  @debug.assert_eq(s[0], (2L, 0L))
  @debug.assert_eq(s[1], (5L, 0L))
}

///|
test "polar sort around shifted origin" {
  // Around (10, 10): (11, 10) is at angle 0, (10, 11) at pi/2, etc.
  let pts : Array[(Int64, Int64)] = [
    (10L, 11L),
    (11L, 10L),
    (9L, 10L),
    (10L, 9L),
  ]
  let s = sort_around(pts, (10L, 10L))
  @debug.assert_eq(s, [(11L, 10L), (10L, 11L), (9L, 10L), (10L, 9L)])
}

///|
test "polar sort empty / single" {
  let empty : Array[(Int64, Int64)] = []
  @debug.assert_eq(sort_around_origin(empty), empty)
  let one : Array[(Int64, Int64)] = [(7L, 3L)]
  @debug.assert_eq(sort_around_origin(one), one)
}

///|
test "polar sort cross product sign" {
  // a = (1, 0), b = (0, 1): cross = 1 > 0 -> b is CCW from a.
  @debug.assert_eq(cross((1L, 0L), (0L, 1L)), 1L)
  // a = (0, 1), b = (1, 0): cross = -1.
  @debug.assert_eq(cross((0L, 1L), (1L, 0L)), -1L)
  // Colinear.
  @debug.assert_eq(cross((1L, 0L), (5L, 0L)), 0L)
}
