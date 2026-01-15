// ============================================================================
// CLOSEST PAIR OF POINTS - Divide and Conquer in O(n log n)
// ============================================================================
//
// Find two points with minimum Euclidean distance in 2D plane.
//
// ALGORITHM (Divide and Conquer):
// 1. Sort points by x-coordinate
// 2. Divide into left and right halves
// 3. Recursively find closest pairs in each half
// 4. Merge: check points in strip of width 2*delta around dividing line
//
// KEY INSIGHT: In the merge step, for each point in the strip, we only need
// to check at most 6 points below it (within delta distance in y-coordinate).
// This is because points are at least delta apart in each half.
//
// INVARIANTS:
// 1. Points sorted by x for division, by y for strip processing
// 2. delta = min(left_delta, right_delta) bounds strip width
// 3. At most 6 points within delta×2delta box can be closer than delta
//
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
fn sqrt_f64(x : Double) -> Double {
  if x <= 0.0 {
    0.0
  } else {
    x.sqrt()
  }
}

///|
priv struct Point {
  x : Double
  y : Double
  idx : Int // Original index
}

///|
fn distance(p1 : Point, p2 : Point) -> Double {
  sqrt_f64(distance_sq(p1, p2))
}

///|
fn distance_sq(p1 : Point, p2 : Point) -> Double {
  let dx = p1.x - p2.x
  let dy = p1.y - p2.y
  dx * dx + dy * dy
}

///|
const CP_INF : Double = 1.0e18

///|
/// Find closest pair using brute force (for small inputs)
fn brute_force_closest(points : ArrayView[Point]) -> (Double, Int, Int) {
  let n = points.length()
  let mut min_dist = CP_INF
  let mut p1 = -1
  let mut p2 = -1
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let d = distance(points[i], points[j])
      if d < min_dist {
        min_dist = d
        p1 = points[i].idx
        p2 = points[j].idx
      }
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (brute force inner):
        #|All pairs (i, k) with k in [i+1, j) have been checked.
        #|MAINTENANCE:
        #|Compare point i with point j.
        #|TERMINATION:
        #|At j = n, all pairs with first index i are checked.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (brute force outer):
      #|min_dist is the minimum distance among pairs with first index < i.
      #|MAINTENANCE:
      #|Check all pairs starting at i and update min_dist as needed.
      #|TERMINATION:
      #|At i = n, all pairs are checked and min_dist is optimal.
    ),
  }
  (min_dist, p1, p2)
}

///|
/// Merge step: check strip for closer pairs
fn strip_closest(
  strip : Array[Point],
  delta : Double,
  best_p1 : Int,
  best_p2 : Int,
) -> (Double, Int, Int) {
  let n = strip.length()
  let mut min_dist = delta
  let mut p1 = best_p1
  let mut p2 = best_p2

  // Sort strip by y coordinate
  strip.sort_by(fn(a, b) {
    if a.y < b.y {
      -1
    } else if a.y > b.y {
      1
    } else {
      0
    }
  })

  // Check each point against at most 6 points below it
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n && strip[j].y - strip[i].y < min_dist; j = j + 1 {
      let d = distance(strip[i], strip[j])
      if d < min_dist {
        min_dist = d
        p1 = strip[i].idx
        p2 = strip[j].idx
      }
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (strip inner):
        #|All candidate points below i in [i+1, j) within the y-window
        #|have been checked.
        #|MAINTENANCE:
        #|Compare strip[i] with strip[j] while y-distance < min_dist.
        #|TERMINATION:
        #|At j = n or window break, all relevant pairs for i are checked.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (strip outer):
      #|min_dist is the best distance found so far in the strip for indices < i.
      #|MAINTENANCE:
      #|Check candidates within the y-window; packing argument bounds checks.
      #|TERMINATION:
      #|At i = n, all close pairs in the strip are checked.
    ),
  }
  (min_dist, p1, p2)
}

///|
/// Recursive closest pair
fn closest_pair_rec(
  points_x : ArrayView[Point],
  points_y : Array[Point],
) -> (Double, Int, Int) {
  let n = points_x.length()

  // Base case: use brute force for small inputs
  if n <= 3 {
    return brute_force_closest(points_x)
  }
  let mid = n / 2
  let mid_point = points_x[mid]

  // Divide points_y into left and right
  let left_y : Array[Point] = []
  let right_y : Array[Point] = []
  points_y.each(fn(p) {
    if p.x <= mid_point.x {
      left_y.push(p)
    } else {
      right_y.push(p)
    }
  })

  // Recursive calls
  let (d_left, l1, l2) = closest_pair_rec(points_x[0:mid], left_y)
  let (d_right, r1, r2) = closest_pair_rec(points_x[mid:], right_y)

  // Find minimum of the two
  let mut delta = d_left
  let mut p1 = l1
  let mut p2 = l2
  if d_right < delta {
    delta = d_right
    p1 = r1
    p2 = r2
  }

  // Build strip of points within delta of mid line
  let strip : Array[Point] = []
  points_y.each(fn(p) {
    let dx = p.x - mid_point.x
    if dx < 0.0 {
      if -dx < delta {
        strip.push(p)
      }
    } else if dx < delta {
      strip.push(p)
    }
  })

  // Check strip
  strip_closest(strip, delta, p1, p2)
}

///|
/// Find closest pair of points
/// Returns (distance, index1, index2)
pub fn closest_pair(points : Array[(Double, Double)]) -> (Double, Int, Int) {
  let n = points.length()
  if n < 2 {
    return (CP_INF, -1, -1)
  }

  // Create Point array with indices
  let pts : Array[Point] = Array::makei(n, fn(i) {
    { x: points[i].0, y: points[i].1, idx: i }
  })

  // Sort by x for divide and conquer
  let pts_x = pts.copy()
  pts_x.sort_by(fn(a, b) {
    if a.x < b.x {
      -1
    } else if a.x > b.x {
      1
    } else {
      0
    }
  })

  // Sort by y for strip processing
  let pts_y = pts.copy()
  pts_y.sort_by(fn(a, b) {
    if a.y < b.y {
      -1
    } else if a.y > b.y {
      1
    } else {
      0
    }
  })
  closest_pair_rec(pts_x[:], pts_y)
}

///|
/// Simple O(n²) closest pair for verification
fn closest_pair_naive(points : Array[(Double, Double)]) -> (Double, Int, Int) {
  let n = points.length()
  if n < 2 {
    return (CP_INF, -1, -1)
  }
  let mut min_dist = CP_INF
  let mut p1 = -1
  let mut p2 = -1
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let dx = points[i].0 - points[j].0
      let dy = points[i].1 - points[j].1
      let d = sqrt_f64(dx * dx + dy * dy)
      if d < min_dist {
        min_dist = d
        p1 = i
        p2 = j
      }
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (naive inner):
        #|All pairs (i, k) with k in [i+1, j) have been checked.
        #|MAINTENANCE:
        #|Compare point i with point j.
        #|TERMINATION:
        #|At j = n, all pairs with first index i are checked.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (naive outer):
      #|All pairs with first index < i have been checked.
      #|MAINTENANCE:
      #|Scan all pairs starting at i.
      #|TERMINATION:
      #|At i = n, all pairs are checked.
    ),
  }
  (min_dist, p1, p2)
}

// ============================================================================
// K-CLOSEST PAIRS (extension)
// ============================================================================

///|
/// Find k closest pairs using naive approach
fn k_closest_pairs(
  points : Array[(Double, Double)],
  k : Int,
) -> Array[(Double, Int, Int)] {
  let n = points.length()
  let pairs : Array[(Double, Int, Int)] = []
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let dx = points[i].0 - points[j].0
      let dy = points[i].1 - points[j].1
      let d = sqrt_f64(dx * dx + dy * dy)
      pairs.push((d, i, j))
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (pair enum inner):
        #|All pairs (i, k) with k in [i+1, j) have been added to pairs.
        #|MAINTENANCE:
        #|Add pair (i, j) with its distance.
        #|TERMINATION:
        #|At j = n, all pairs with first index i are added.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (pair enum outer):
      #|pairs contains distances for all pairs with first index < i.
      #|MAINTENANCE:
      #|Enumerate pairs starting at i.
      #|TERMINATION:
      #|At i = n, all point pairs are collected.
    ),
  }

  // Sort by distance
  pairs.sort_by(fn(a, b) {
    if a.0 < b.0 {
      -1
    } else if a.0 > b.0 {
      1
    } else {
      0
    }
  })

  // Take first k
  let result : Array[(Double, Int, Int)] = []
  for i = 0; i < k && i < pairs.length(); i = i + 1 {
    result.push(pairs[i])
  } where {
    invariant: i >= 0 && i <= k && i <= pairs.length(),
    reasoning: (
      #|INVARIANT (take k):
      #|result contains the first i pairs from the sorted list.
      #|MAINTENANCE:
      #|Append pairs[i] to result.
      #|TERMINATION:
      #|At i = k or i = pairs.length(), result has the k smallest pairs.
    ),
  }
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "closest pair basic" {
  let points : Array[(Double, Double)] = [
    (0.0, 0.0),
    (1.0, 0.0),
    (2.0, 0.0),
    (3.0, 0.0),
  ]
  let (dist, _, _) = closest_pair(points)
  // Closest pairs are adjacent, distance 1.0
  inspect(dist < 1.1 && dist > 0.9, content="true")
}

///|
test "closest pair triangle" {
  let points : Array[(Double, Double)] = [(0.0, 0.0), (3.0, 0.0), (1.5, 0.5)]
  let (dist, _, _) = closest_pair(points)
  // Point 2 is closest to both 0 and 1
  // Distance from (1.5, 0.5) to (0, 0) = sqrt(2.25 + 0.25) = sqrt(2.5) ≈ 1.58
  // Distance from (1.5, 0.5) to (3, 0) = sqrt(2.25 + 0.25) = sqrt(2.5) ≈ 1.58
  // Distance from (0, 0) to (3, 0) = 3
  inspect(dist < 1.6 && dist > 1.5, content="true")
}

///|
test "closest pair two points" {
  let points : Array[(Double, Double)] = [(0.0, 0.0), (3.0, 4.0)]
  let (dist, p1, p2) = closest_pair(points)
  // Distance = 5.0 (3-4-5 triangle)
  inspect(dist < 5.1 && dist > 4.9, content="true")
  inspect((p1 == 0 && p2 == 1) || (p1 == 1 && p2 == 0), content="true")
}

///|
test "closest pair cluster" {
  let points : Array[(Double, Double)] = [
    (0.0, 0.0),
    (10.0, 10.0),
    (0.1, 0.0),
    (10.1, 10.0),
  ]
  let (dist, _, _) = closest_pair(points)
  // Closest are (0,0) and (0.1,0) with distance 0.1
  inspect(dist < 0.15 && dist > 0.05, content="true")
}

///|
test "closest pair vs naive" {
  let points : Array[(Double, Double)] = [
    (1.0, 2.0),
    (3.0, 4.0),
    (5.0, 1.0),
    (2.0, 3.0),
    (4.0, 5.0),
  ]
  let (dist1, _, _) = closest_pair(points)
  let (dist2, _, _) = closest_pair_naive(points)
  // Both should give same distance
  let diff = dist1 - dist2
  let abs_diff = if diff < 0.0 { -diff } else { diff }
  inspect(abs_diff < 0.001, content="true")
}

///|
test "closest pair single" {
  let points : Array[(Double, Double)] = [(0.0, 0.0)]
  let (dist, _, _) = closest_pair(points)
  inspect(dist > 1.0e17, content="true") // INF
}

///|
test "closest pair empty" {
  let points : Array[(Double, Double)] = []
  let (dist, _, _) = closest_pair(points)
  inspect(dist > 1.0e17, content="true")
}

///|
test "k closest pairs" {
  let points : Array[(Double, Double)] = [
    (0.0, 0.0),
    (1.0, 0.0),
    (2.0, 0.0),
    (10.0, 0.0),
  ]
  let pairs = k_closest_pairs(points, 2)
  inspect(pairs.length(), content="2")
  // First two closest pairs should be (0,1) and (1,2) with distance 1.0
  inspect(pairs[0].0 < 1.1, content="true")
  inspect(pairs[1].0 < 1.1, content="true")
}

///|
test "sqrt_f64" {
  let s = sqrt_f64(4.0)
  inspect(s > 1.99 && s < 2.01, content="true")
  let s2 = sqrt_f64(2.0)
  inspect(s2 > 1.41 && s2 < 1.42, content="true")
}
