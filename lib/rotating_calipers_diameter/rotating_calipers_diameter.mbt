// ============================================================================
// ROTATING CALIPERS - Diameter of a Convex Polygon
// ============================================================================
//
// Given a convex polygon in counter-clockwise order, the diameter is the
// maximum distance between any two vertices. Rotating calipers finds an
// antipodal vertex for each edge and tracks the best distance in O(n).
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(1)

///|
pub(all) struct Point {
  x : Int64
  y : Int64
} derive(Show, Eq)

///|
pub(all) struct DiameterResult {
  i : Int
  j : Int
  dist2 : Int64
} derive(Show)

///|
fn cross(a : Point, b : Point, c : Point) -> Int64 {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
fn dist2(a : Point, b : Point) -> Int64 {
  let dx = a.x - b.x
  let dy = a.y - b.y
  dx * dx + dy * dy
}

///|
/// Compute the diameter (maximum squared distance) of a convex polygon.
/// Returns None for empty input.
///
/// REQUIREMENTS:
/// - points form a convex polygon in CCW order
/// - no duplicate consecutive vertices
pub fn convex_diameter(points : Array[Point]) -> DiameterResult? {
  let n = points.length()
  if n == 0 {
    return None
  }
  if n == 1 {
    return Some({ i: 0, j: 0, dist2: 0L })
  }
  if n == 2 {
    return Some({ i: 0, j: 1, dist2: dist2(points[0], points[1]) })
  }
  let (best_i, best_j, best) = for i = 0, j = 1, best_i = 0, best_j = 1, best = dist2(
                                       points[0],
                                       points[1],
                                     ); i < n; {
    let next_i = (i + 1) % n
    let j = for j = j {
      let next_j = (j + 1) % n
      let area_now = cross(points[i], points[next_i], points[j])
      let area_next = cross(points[i], points[next_i], points[next_j])
      if area_next > area_now {
        continue next_j
      } else {
        break j
      }
    } where {
      invariant: j >= 0 && j < n,
      reasoning: (
        #|INVARIANT (advance antipodal):
        #|j is a candidate antipodal vertex for edge (i, i+1). Each step moves j
        #|forward only when the area of the triangle increases, so area_now is
        #|non-decreasing along the loop.
        #|MAINTENANCE:
        #|If moving to next_j increases the area, that vertex is more antipodal
        #|and we advance j.
        #|TERMINATION:
        #|When area_next <= area_now, j is locally maximal for this edge.
      ),
    }
    let d = dist2(points[i], points[j])
    let (best_i, best_j, best) = if d > best {
      (i, j, d)
    } else {
      (best_i, best_j, best)
    }
    continue i + 1, j, best_i, best_j, best
  } nobreak {
    (best_i, best_j, best)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (outer calipers):
      #|For all processed edges up to i, best stores the maximum distance found
      #|among pairs (edge_vertex, antipodal_vertex). The pointer j is positioned
      #|at a maximal-area antipodal vertex for the current edge.
      #|MAINTENANCE:
      #|Advance j to maintain antipodality for edge (i, i+1), then update best.
      #|TERMINATION:
      #|At i = n, all edges are processed and best is the diameter.
    ),
  }
  Some({ i: best_i, j: best_j, dist2: best })
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "diameter square" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 2L, y: 0L },
    { x: 2L, y: 2L },
    { x: 0L, y: 2L },
  ]
  let result = convex_diameter(points).unwrap()
  inspect(result.dist2, content="8")
}

///|
test "diameter triangle" {
  let points : Array[Point] = [
    { x: 0L, y: 0L },
    { x: 4L, y: 0L },
    { x: 0L, y: 3L },
  ]
  let result = convex_diameter(points).unwrap()
  inspect(result.dist2, content="25")
}

///|
test "diameter two points" {
  let points : Array[Point] = [{ x: -1L, y: 0L }, { x: 2L, y: 0L }]
  let result = convex_diameter(points).unwrap()
  inspect(result.dist2, content="9")
}

///|
test "diameter hexagon advances antipodal pointer multiple times" {
  let points : Array[Point] = [
    { x: 1L, y: 0L },
    { x: 2L, y: 1L },
    { x: 1L, y: 2L },
    { x: 0L, y: 2L },
    { x: -1L, y: 1L },
    { x: 0L, y: 0L },
  ]
  let result = convex_diameter(points).unwrap()
  inspect(result.dist2, content="9")
}

///|
test "diameter keeps antipodal state across outer iterations" {
  let points : Array[Point] = [
    { x: -22L, y: 6L },
    { x: -14L, y: -23L },
    { x: 18L, y: -26L },
    { x: 24L, y: 21L },
    { x: 1L, y: 18L },
  ]
  let result = convex_diameter(points).unwrap()
  inspect(result.dist2, content="3380")
  inspect(
    (result.i == 1 && result.j == 3) || (result.i == 3 && result.j == 1),
    content="true",
  )
}
