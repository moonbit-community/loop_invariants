# Jarvis March (Gift Wrapping)

## Overview

Jarvis' **gift-wrapping** algorithm (1973) computes the convex hull of
`n` points in the plane by literally wrapping the hull, one vertex at
a time, like ribbon around a parcel. Its hallmark feature is
**output-sensitivity**: the running time is `O(n · h)` where `h` is
the number of hull vertices, so when the hull is small Jarvis beats
`O(n log n)` algorithms like Graham scan or Andrew's monotone chain.

- **Time**: `O(n · h)`, output-sensitive
- **Space**: `O(h)`
- **Signatures**:
  - `jm_point(x, y) -> JmPoint`
  - `convex_hull(points) -> Array[JmPoint]`

Jarvis is the first algorithm of choice when you expect a tiny hull,
e.g. nearly-uniform interior points with a small number of extreme
outliers. For large hulls (`h ≈ n`) prefer Andrew's monotone chain or
Quickhull.

---

## The idea

```
start  <- lowest-leftmost point (definitely on the hull)
current <- start
repeat:
  emit(current)
  next <- candidate
  for each other point p:
    if p is strictly to the right of `current -> next`:
      next <- p
    elif p is collinear with `current -> next` and farther:
      next <- p
  current <- next
until current == start
```

The condition "every remaining point is to the **left** of
`current → next`" characterises a hull edge: such an edge is the
rightmost extreme line through `current`, and turning consistently
left around the boundary traces a CCW hull.

---

## The invariant

> After emitting the `k`-th hull vertex, every input point lies in
> the closed half-plane to the **left** of the most recent directed
> hull edge.

Equivalently: each "most-counter-clockwise" pick never excludes a
true hull vertex, because that vertex would itself satisfy the
"everyone-on-the-left" condition with respect to the chosen edge.

---

## Reference implementation

```
pub struct JmPoint { x : Double, y : Double }
pub fn jm_point(x : Double, y : Double) -> JmPoint
pub fn convex_hull(points : Array[JmPoint]) -> Array[JmPoint]
```

Returns hull vertices counter-clockwise from the lowest-leftmost point.

---

## Tests and examples

```mbt check
///|
test "jarvis square interior" {
  let pts = [
    @jarvis_march.jm_point(0.0, 0.0),
    @jarvis_march.jm_point(1.0, 0.0),
    @jarvis_march.jm_point(1.0, 1.0),
    @jarvis_march.jm_point(0.0, 1.0),
    @jarvis_march.jm_point(0.5, 0.5),
  ]
  let h = @jarvis_march.convex_hull(pts)
  debug_inspect(h.length(), content="4")
}
```

```mbt check
///|
test "jarvis triangle" {
  let pts = [
    @jarvis_march.jm_point(0.0, 0.0),
    @jarvis_march.jm_point(2.0, 0.0),
    @jarvis_march.jm_point(1.0, 2.0),
  ]
  let h = @jarvis_march.convex_hull(pts)
  debug_inspect(h.length(), content="3")
}
```

```mbt check
///|
test "jarvis collinear edge" {
  // Three collinear x-axis points + one above: hull is a triangle.
  let pts = [
    @jarvis_march.jm_point(0.0, 0.0),
    @jarvis_march.jm_point(1.0, 0.0),
    @jarvis_march.jm_point(2.0, 0.0),
    @jarvis_march.jm_point(1.0, 1.0),
  ]
  let h = @jarvis_march.convex_hull(pts)
  debug_inspect(h.length(), content="3")
}
```

---

## Complexity

| Quantity | Cost |
|---|---|
| Starting-vertex scan | `O(n)` |
| Each "next vertex" scan | `O(n)` |
| Total | `O(n · h)` |

**Best case** (`h = 3`, e.g. a triangle filled with interior points)
is `O(n)`. **Worst case** (`h = n`, all points on hull) is `O(n²)`.

---

## When to pick Jarvis vs. alternatives

| Algorithm | Time | When to pick |
|---|---|---|
| **Jarvis (this)** | `O(n h)` | Hull small (`h ≪ n`); simplicity matters |
| Graham scan | `O(n log n)` | General-purpose, fast in practice |
| Andrew's monotone chain | `O(n log n)` | Simplest robust hull; same as Graham essentially |
| Quickhull | `O(n log n)` expected | Fastest typical-case; like Quicksort |
| Chan's algorithm | `O(n log h)` | Output-sensitive *and* asymptotically optimal; complicated |

If you have no idea about `h` and want simplicity + reliability:
**Andrew's monotone chain** is the textbook recommendation. Jarvis is
beautiful and pedagogically clear but rarely wins on real-world data.

---

## Pitfalls

- **Floating-point cross-products**. The "strictly to the right" test
  uses `cross(a, b, c) < 0`. With nearly-collinear points and double
  precision this can flip signs. Robust kernels use adaptive exact
  arithmetic.
- **Collinear ties**. We prefer the *farther* collinear candidate so
  that interior collinear points get dropped, mirroring most hull
  libraries.
- **Infinite loop guard**. If your inputs are degenerate (e.g. all
  coincident), the algorithm could in principle revisit a vertex. The
  implementation here bounds the outer loop to `n` iterations.

---

## Related concepts

```
Jarvis march (this)         O(n h) gift wrapping, 1973
Graham scan                 O(n log n) via angular sort, 1972
Andrew's monotone chain     O(n log n) by sorting x, then sweeping
Quickhull                   O(n log n) expected; geometric Quicksort
Chan's algorithm            O(n log h), output-sensitive AND optimal
```
