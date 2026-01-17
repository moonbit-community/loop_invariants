# Closest Pair of Points (Divide and Conquer)

The **closest pair** problem asks: given `n` points in the plane, find the two
points with minimum Euclidean distance.

A brute-force solution checks all pairs in `O(n^2)`. The divide-and-conquer
algorithm solves it in **`O(n log n)`**.

This package provides:

- `closest_pair(points)` returning `(distance, index1, index2)`

---

## The problem

Given a list of 2D points, find the closest two:

```
Points: (0,0), (3,4), (1,1), (4,4), (5,2)

   y
   5 |            *
   4 |      *     *
   3 |
   2 |               *
   1 |   *
   0 *-------------------- x
     0  1  2  3  4  5
```

Brute force: check all pairs -> `O(n^2)`.

---

## Core idea

1. Sort points by x-coordinate.
2. Split into left and right halves.
3. Recursively solve both halves.
4. Let `delta = min(left_best, right_best)`.
5. Build a **strip** of points within distance `delta` of the mid line.
6. Check only the strip, sorted by y-coordinate.

Key geometry insight: in the strip, **each point only needs to compare with the
next ~7 points** in y-sorted order.

---

## Walkthrough example

Points (already x-sorted):

```
(0,0), (1,1), (3,0), (4,1), (6,0), (7,1)
```

Split at `x = 3.5`:

```
Left:  (0,0), (1,1), (3,0)
Right: (4,1), (6,0), (7,1)
```

- Left best = sqrt(2) between (0,0) and (1,1)
- Right best = sqrt(2) between (6,0) and (7,1)
- `delta = sqrt(2)`

Strip: points with `|x - 3.5| < delta` are `(3,0)` and `(4,1)`.
Their distance is also `sqrt(2)`, so the answer stays the same.

---

## Visual: the strip

```
After recursion, delta is known.

                |
    *           |      *
        *       |         *
                |
    *           |      *
                |
    <-- delta -->|<-- delta -->
                |
        strip = points with |x - mid| < delta
```

---

## Why only ~7 comparisons?

In the strip, any closer point must lie inside a rectangle of size
`delta` by `2 * delta` around a point. Packing arguments show you can fit
at most 8 points in that rectangle while keeping distances >= delta.
So each point only checks a constant number of neighbors.

---

## Pseudocode sketch

```text
closest(points):
  if n <= 3: return brute_force(points)
  split points by x into left/right
  d_left = closest(left)
  d_right = closest(right)
  d = min(d_left, d_right)

  strip = points with |x - mid_x| < d
  sort strip by y
  for i in strip:
    for j in next few points while y-distance < d:
      d = min(d, dist(i, j))
  return d
```

---

## Example 1: Simple line

```mbt check
///|
test "closest pair line" {
  let points : Array[(Double, Double)] = [(0.0, 0.0), (1.0, 0.0), (4.0, 0.0)]
  let (dist, p1, p2) = @closest_pair.closest_pair(points)
  inspect(dist, content="1")
  inspect((p1, p2), content="(0, 1)")
}
```

---

## Example 2: Triangle

```mbt check
///|
test "closest pair triangle" {
  let points : Array[(Double, Double)] = [(0.0, 0.0), (3.0, 0.0), (1.5, 0.5)]
  let (dist, _, _) = @closest_pair.closest_pair(points)
  // Closest distance is about 1.58
  inspect(dist < 1.6 && dist > 1.5, content="true")
}
```

---

## Example 3: Two clusters

```mbt check
///|
test "closest pair cluster" {
  let points : Array[(Double, Double)] = [
    (0.0, 0.0),
    (10.0, 10.0),
    (0.1, 0.0),
    (10.1, 10.0),
  ]
  let (dist, _, _) = @closest_pair.closest_pair(points)
  inspect(dist < 0.15 && dist > 0.05, content="true")
}
```

---

## Applications

- Collision detection
- Clustering (single-link)
- Geographic proximity queries
- Preprocessing for nearest-neighbor search

---

## Implementation notes

- Pre-sorting by x is essential for `O(n log n)`
- Strip check is linear because of the constant bound
- For integer coordinates, comparing squared distances avoids floating-point

---

## Complexity

- Time: `O(n log n)`
- Space: `O(n)`

---

## Reference implementation

```mbt
///| pub fn closest_pair(points : Array[(Double, Double)]) -> (Double, Int, Int)
```
