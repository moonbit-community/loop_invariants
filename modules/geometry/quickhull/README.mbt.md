# Quickhull

## Overview

The **Quickhull** algorithm (Eddy 1977; Bykat 1978) computes the
**convex hull** of `n` points in the plane — the smallest convex
polygon containing every input point. It is the planar specialisation
of a more general convex-hull algorithm by Barber-Dobkin-Huhdanpaa
(1996), and is the geometric analogue of Quicksort.

- **Time**: expected `O(n log n)`; worst case `O(n²)` (like Quicksort)
- **Space**: `O(n)`
- **Signatures**:
  - `point(x, y) -> Point`
  - `convex_hull(points) -> Array[Point]`

Quickhull is one of the simplest hull algorithms to *explain* and
typically among the fastest in practice. Graham scan and Andrew's
monotone-chain achieve a worst-case `O(n log n)` guarantee; Quickhull
beats both on most "random-looking" inputs because it discards points
in big batches.

---

## The idea

```
quickhull(points):
  lo  <- leftmost point
  hi  <- rightmost point
  above <- points strictly above the line lo->hi
  below <- points strictly below the line lo->hi
  return [lo] ++ find_hull(below, lo, hi) ++ [hi] ++ find_hull(above, hi, lo)

find_hull(points, a, b):
  if points is empty: return []
  p_far <- point in `points` farthest from line a->b
  left_set  <- points in `points` strictly left of a->p_far
  right_set <- points in `points` strictly left of p_far->b
  return find_hull(left_set, a, p_far) ++ [p_far] ++ find_hull(right_set, p_far, b)
```

The recursion discards every point inside the triangle `a - p_far - b`,
because such a point is *inside* the partial hull and cannot be a hull
vertex.

---

## The invariant

> At every recursive call, the candidate set contains only points
> strictly outside the current partial hull edge — so any point on the
> final hull that lies in the half-plane bounded by this edge is still
> in the candidate set.

The crucial geometric fact is: **the point farthest from an edge of
the partial hull is itself a hull vertex.** That follows from a simple
support-line argument and is what makes the recursion correct.

---

## Reference implementation

```
pub struct Point { x : Double, y : Double }
pub fn point(x : Double, y : Double) -> Point
pub fn convex_hull(points : Array[Point]) -> Array[Point]
```

The returned array gives hull vertices in **counter-clockwise** order,
starting from the leftmost (ties broken by smallest `y`).

---

## Tests and examples

```mbt check
///|
test "quickhull unit square" {
  let pts = [
    @quickhull.point(0.0, 0.0),
    @quickhull.point(1.0, 0.0),
    @quickhull.point(1.0, 1.0),
    @quickhull.point(0.0, 1.0),
    @quickhull.point(0.5, 0.5),
  ]
  let h = @quickhull.convex_hull(pts)
  debug_inspect(h.length(), content="4")
}
```

```mbt check
///|
test "quickhull triangle" {
  let pts = [
    @quickhull.point(0.0, 0.0),
    @quickhull.point(2.0, 0.0),
    @quickhull.point(1.0, 2.0),
  ]
  let h = @quickhull.convex_hull(pts)
  debug_inspect(h.length(), content="3")
}
```

```mbt check
///|
test "quickhull collinear" {
  // All four points on the x-axis -- hull degenerates to two endpoints.
  let pts = [
    @quickhull.point(0.0, 0.0),
    @quickhull.point(1.0, 0.0),
    @quickhull.point(2.0, 0.0),
    @quickhull.point(3.0, 0.0),
  ]
  let h = @quickhull.convex_hull(pts)
  debug_inspect(h.length(), content="2")
}
```

---

## Complexity

| Case | Time |
|---|---|
| Average (random or "fat" point distributions) | `O(n log n)` |
| Worst (all points on hull + adversarial pivot) | `O(n²)` |

The constant factor is small because the algorithm spends almost all
its time on cross-products (3 multiplications, 2 subtractions each).

---

## Pitfalls

- **Floating-point precision**. The `cross` test is `(b.x - a.x) * (c.y -
  a.y) - (b.y - a.y) * (c.x - a.x)`. With nearly-collinear points this
  is sensitive to cancellation. Robust geometric kernels use adaptive
  exact predicates; this package does not.
- **Collinear inputs**. Interior points on a hull edge are *omitted*
  from the result (consistent with most hull libraries).
- **Duplicate points**. Tolerated. Duplicated extreme points appear at
  most once in the output.
- **All points collinear**. The hull degenerates to two endpoints
  (or one, if all points coincide). The code handles both cases.

---

## When to choose Quickhull

| If you need... | Pick |
|---|---|
| Simplest robust planar hull | Andrew's monotone chain (`O(n log n)` guaranteed) |
| Fastest typical-case performance | **Quickhull (this)** |
| Output-sensitive (`h ≪ n`) | Jarvis march or Chan's algorithm |
| Higher-dimensional hulls | Generalised Quickhull / `Qhull` library |

---

## Related concepts

```
Quickhull (this)            Eddy 1977 / Bykat 1978; O(n log n) expected
Andrew's monotone chain     deterministic O(n log n), very simple
Graham scan                 O(n log n) via angular sort
Jarvis march                O(n h) gift-wrapping, h = hull size
Chan's algorithm            O(n log h) output-sensitive
Akl-Toussaint heuristic     pre-filter with an enclosing quadrilateral
```
