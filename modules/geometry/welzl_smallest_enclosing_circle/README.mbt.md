# Welzl's Smallest Enclosing Circle

## Overview

Given a finite set of points in the plane, compute the unique smallest
circle (a.k.a. *minimum bounding disk*, *minimum enclosing ball* in 2D,
*smallest enclosing circle*) that contains all of them.

The MEC always exists and is unique. By the **boundary structure theorem**
it is determined by at most three input points lying exactly on its
boundary: either two antipodal points (the diameter case) or three points
that span the unique circumscribed circle.

- **Time**: `O(n)` expected on a uniformly random permutation of the
  input; `O(n^3)` worst case on adversarial orderings.
- **Space**: `O(1)` beyond the input view.
- **Signature**:
  `smallest_enclosing_circle(points : ArrayView[Point]) -> Circle`

The package does *not* shuffle its input. Callers wanting the expected
linear bound should shuffle the points beforehand; see the
"Randomization" section below.

## Where it sits among 2D geometry primitives

| Problem                                  | Typical complexity | Package                                 |
|------------------------------------------|--------------------|-----------------------------------------|
| Convex hull                              | `O(n log n)`       | `@convex_hull`                          |
| Closest pair                             | `O(n log n)`       | `@closest_pair`                         |
| Diameter (farthest pair on hull)         | `O(n log n)`       | `@rotating_calipers_diameter`           |
| **Smallest enclosing circle**            | **`O(n)` exp.**    | **this package**                        |
| Point-in-polygon                         | `O(n)`             | `@point_in_polygon`                     |
| Line-segment intersection                | `O((n + k) log n)` | `@line_segment_intersection`            |

The MEC is in some sense *dual* to the convex hull: only hull vertices
can be on the MEC boundary, but the MEC is generally much smaller than
the hull. There is no need to compute the hull first; Welzl's algorithm
works directly on the raw point set.

## The boundary structure theorem

> The smallest enclosing circle of `n >= 2` points has either 2 or 3
> input points on its boundary.

*Sketch.* The MEC is non-empty (because the input is finite) and convex
in the space of (center, radius) pairs satisfying all the
"contains point p" linear-in-(center, radius^2 - center^2) constraints.
The optimum touches at most three independent constraints; in two
dimensions a circle has three degrees of freedom (cx, cy, r) so three
active constraints exactly pin it down.

This theorem is what makes the algorithm finish in three nested loops:
each level fixes one more boundary point.

## The iterative algorithm

```
circle = empty
for i in 0..n:
    if points[i] not in circle:
        circle = degenerate circle at points[i]
        for j in 0..i:
            if points[j] not in circle:
                circle = diameter circle of (points[i], points[j])
                for k in 0..j:
                    if points[k] not in circle:
                        circle = circumcircle(points[i], points[j], points[k])
return circle
```

### Three coupled loop invariants

```
(OUTER  over i)  circle is the MEC of points[0..i)
(MIDDLE over j)  circle is the MEC of points[0..j) constrained to pass
                 through points[i]
(INNER  over k)  circle is the MEC of points[0..k) constrained to pass
                 through both points[i] and points[j]; for k > 0 these
                 two boundary points plus the most recently escaping
                 point uniquely determine the circle.
```

Each invariant is restored whenever its associated point is found
strictly outside: by the boundary structure theorem the new optimum
must put that point on its boundary, and the inner loop re-enters one
more level down. The base of the recursion (three boundary points) is
the unique circumscribed circle, computed in closed form.

## ASCII illustration: three boundary points

The most common case for a `wide` input is three boundary points on the
MEC:

```
                        *  (a)
                       /|\\
                      / | \\
                     /  |  \\
                    /   |   \\
                   /    |    \\
              ----*-----*-----*----    diameter chord
                 (b)  center   (c)
                  \\    |     /
                   \\   |    /
                    \\  |   /
                     \\ |  /
                      \\| /
                       \\|/
                        *

Three input points a, b, c lie exactly on the boundary; the circle
is the unique circumscribed circle. Computed as the intersection of
the perpendicular bisectors of ab and ac.
```

For the *diameter* case the MEC passes through only two points (the
farthest pair), and any third active point would force the circle to
shrink -- contradicting optimality.

## Geometric primitives

### `circle_from_two(p, q)`

The circle with `pq` as a diameter:

```
center = (p + q) / 2
radius = |p - q| / 2
```

This is the *smallest* circle through `p` and `q` (any smaller circle
cannot contain both endpoints).

### `circle_from_three(a, b, c)`

The unique circle through three non-collinear points. Translate so
that `a` is the origin, and let `B = b - a`, `C = c - a`. The
circumcenter (relative to `a`) is

```
D    =  2 · (B.x · C.y  -  B.y · C.x)
u.x  =  ( C.y · |B|^2  -  B.y · |C|^2 ) / D
u.y  =  ( B.x · |C|^2  -  C.x · |B|^2 ) / D
```

and the final center is `a + u`, the radius is `|u|`. `D` is twice
the signed area of the triangle `abc`; it vanishes iff the three are
collinear. The package detects this and falls back to the diameter
circle of the farthest pair.

### `contains_point(c, p)`

```
|p - center|^2  <=  radius^2 + EPS
```

We compare squared distances to avoid one `sqrt` per check. The slack
`EPS = 1e-10` absorbs round-off so a freshly computed boundary point
is not pushed back outside its own circle.

## Randomization: why the expected time is linear

Fix the algorithm's deterministic rebuild work *per outer iteration `i`*.
Without rebuilding, every iteration costs `O(1)`. A rebuild happens iff
`points[i]` is on the boundary of the i-prefix MEC.

By the boundary structure theorem the i-prefix MEC has at most 3
boundary points. If the input is a uniformly random permutation, the
probability that `points[i]` is one of those three is

```
Pr[ rebuild at i ]  <=  3 / i.
```

Conditional on a rebuild, the middle loop runs in `O(i)` time and
itself rebuilds with probability `<= 2 / j` at step `j`. The inner
loop adds another `<= 1 / k` factor. Summing all three levels using
linearity of expectation and harmonic sums gives

```
E[work]  =  sum_{i=1..n} O(1) + (3/i) · ( O(i) + sum_{j=1..i} (2/j) · O(j) )
         =  sum_{i=1..n} O(1) + O(3) + O(6) · i
         =  O(n).
```

This argument is called *backwards analysis* (Seidel, 1991): we imagine
*removing* the last point of the prefix and ask how likely the removal
would change the MEC.

The bound only applies under randomization. If the caller feeds points
in worst-case order (e.g. boundary points last), the algorithm still
returns the correct answer but the running time can degrade to
`O(n^3)`. The convention in this package is to leave shuffling to the
caller, both because `Array.shuffle` is environment-dependent and
because some callers already know their input is random.

## Reference implementation

```
pub fn smallest_enclosing_circle(points : ArrayView[Point]) -> Circle
```

## Tests and examples

### Single point

```mbt check
///|
test "welzl single point" {
  let pts : Array[@welzl_smallest_enclosing_circle.Point] = [
    { x: 7.0, y: -3.0 },
  ]
  let c = @welzl_smallest_enclosing_circle.smallest_enclosing_circle(pts[:])
  debug_inspect(c.radius, content="0")
  debug_inspect(c.center.x, content="7")
  debug_inspect(c.center.y, content="-3")
}
```

### Diameter circle for two points

```mbt check
///|
test "welzl two points" {
  let pts : Array[@welzl_smallest_enclosing_circle.Point] = [
    { x: 0.0, y: 0.0 },
    { x: 6.0, y: 8.0 },
  ]
  let c = @welzl_smallest_enclosing_circle.smallest_enclosing_circle(pts[:])
  // |(0,0) - (6,8)| = 10, so radius = 5; center = (3, 4).
  debug_inspect(c.radius, content="5")
  debug_inspect(c.center.x, content="3")
  debug_inspect(c.center.y, content="4")
}
```

### Right triangle: MEC is the hypotenuse diameter

```mbt check
///|
test "welzl right triangle" {
  let pts : Array[@welzl_smallest_enclosing_circle.Point] = [
    { x: 0.0, y: 0.0 },
    { x: 3.0, y: 0.0 },
    { x: 0.0, y: 4.0 },
  ]
  let c = @welzl_smallest_enclosing_circle.smallest_enclosing_circle(pts[:])
  // Hypotenuse from (3,0) to (0,4) has length 5; MEC center (1.5, 2),
  // radius 2.5.
  debug_inspect(c.radius, content="2.5")
  debug_inspect(c.center.x, content="1.5")
  debug_inspect(c.center.y, content="2")
}
```

### Interior points do not matter

```mbt check
///|
test "welzl interior points do not matter" {
  let pts : Array[@welzl_smallest_enclosing_circle.Point] = [
    { x: -1.0, y: -1.0 },
    { x: 1.0, y: -1.0 },
    { x: 1.0, y: 1.0 },
    { x: -1.0, y: 1.0 },
    { x: 0.0, y: 0.0 },
    { x: 0.5, y: -0.2 },
  ]
  let c = @welzl_smallest_enclosing_circle.smallest_enclosing_circle(pts[:])
  // The MEC is still pinned by the 4 corners; center (0,0).
  debug_inspect(c.center.x, content="0")
  debug_inspect(c.center.y, content="0")
}
```

## Common applications

- **Bounding sphere for collision detection**: in physics engines and
  ray tracers the MEC of a polygon (or its 3D analogue, the smallest
  enclosing ball of a mesh) gives an ultra-cheap rejection test before
  more expensive intersection queries.
- **Smallest-radius transmitter / antenna placement**: where should a
  single broadcast tower sit to reach `n` listeners with minimum
  power? The answer is the MEC center, the power is `r^2`.
- **Robust clustering anchors**: the *1-center* problem in k-clustering
  uses the MEC as the within-cluster radius; iterating per cluster
  yields the k-center cost function.
- **Computational chemistry / structural biology**: the smallest
  bounding sphere of an atom cloud is a coarse but useful descriptor
  in pre-screening filters.
- **Sketch -> ink stroke fitting**: in handwriting / vector graphics,
  thickening a polyline by the MEC of its samples gives a "fat" stroke
  guaranteed to contain every input.

## Common pitfalls

- **Collinear triples**: `circle_from_three` checks for a near-zero
  determinant and falls back to the diameter circle of the farthest
  pair. Without this guard, the algorithm would produce `inf` or
  `NaN` for inputs lying exactly on a line.
- **Numerical instability near collinearity**: even when three points
  are not exactly collinear, an almost-collinear triple can produce a
  very large but finite radius. If your input has very narrow
  triangles, consider rescaling coordinates so they lie in roughly
  `[-1, 1]` before calling.
- **Boundary slack**: `EPS = 1e-10` is appropriate for coordinates up
  to about `1e6` in magnitude. Larger ranges may need a proportionally
  larger slack; smaller ranges can tighten it.
- **Empty input**: returns `Circle { center: (0, 0), radius: 0 }`.
  Callers that distinguish "no points" from "one point at origin"
  should special-case the input length before calling.
- **Worst-case ordering**: do not feed the points in convex-hull order
  or sorted by angle around the centroid; both are pessimal for the
  rebuilding probability. Shuffle the array first if the input might
  be structured.

## Related concepts

```
Boundary structure theorem      MEC fixed by <= 3 input points
Welzl 1991                      the iterative algorithm in this file
Megiddo 1983                    O(n) deterministic via parametric search
Backwards analysis (Seidel)     the standard tool for randomised geometric algorithms
Smallest enclosing ball         3D analogue; >= 4 boundary points
Smallest enclosing ellipse      Khachiyan-style O(1/eps) approximations
1-center problem                same problem in computational facility location
```
