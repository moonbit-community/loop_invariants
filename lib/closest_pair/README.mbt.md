# Closest Pair of Points

## Overview

The **Closest Pair** problem finds the minimum distance between any two points
in the plane. The divide-and-conquer approach achieves O(n log n) time.

- **Time**: O(n log n)
- **Space**: O(n)

## The Problem

```
Given n points in 2D, find the pair with minimum Euclidean distance.

Points: (0,0), (3,4), (1,1), (4,4), (5,2)

         5 |
         4 |   *       *
         3 |
         2 |               *
         1 |   *
         0 *───────────────────
           0   1   2   3   4   5

Brute force: Check all n(n-1)/2 pairs → O(n²)
Divide and conquer: O(n log n)
```

## The Key Insight

```
Divide points by x-coordinate, solve recursively,
then carefully merge in the "strip" near the dividing line.

The strip check is O(n), not O(n²), because:
- Only check points within distance d of mid-line
- For each point, only check next 7 points in y-sorted order!

Why only 7? Geometry limits how many points can fit
in a d × 2d rectangle while being at least d apart.
```

## Algorithm Walkthrough

```
Points: (0,0), (1,1), (3,0), (4,1), (6,0), (7,1)

Step 1: Sort by x-coordinate
  Already sorted: (0,0), (1,1), (3,0), (4,1), (6,0), (7,1)

Step 2: Divide at median x
  Left:  (0,0), (1,1), (3,0)
  Right: (4,1), (6,0), (7,1)
  Mid-line: x = 3.5

Step 3: Solve recursively
  Left min:  d((0,0), (1,1)) = √2 ≈ 1.41
  Right min: d((6,0), (7,1)) = √2 ≈ 1.41
  d = min(√2, √2) = √2

Step 4: Check strip (x in [3.5-√2, 3.5+√2])
  Strip points (by y): (3,0), (4,1)
  d((3,0), (4,1)) = √2

Final answer: √2 (multiple pairs achieve this)
```

## Visual: The Strip

```
After recursive calls, d = min distance in each half.

                    │
     *              │      *
          *         │          *
                    │
     *              │      *
                    │
    ←───── d ─────→ │ ←───── d ─────→
                    │
              ←─ strip ─→

Points in strip: distance < d from mid-line
Key insight: Each point needs only compare with
next 7 points when sorted by y-coordinate!
```

## Why Only 7 Comparisons?

```
Consider point p in the strip at position (x, y).
Any closer point must be in a d × 2d rectangle:

    ┌─────────────────┐
    │    │     │      │ ↑
    │    │  *  │      │ d
    │    │  p  │      │ ↓
    │    │     │      │ ↑
    │    │     │      │ d
    └─────────────────┘ ↓
    ←─ d ─→   ← d →
         mid-line

This rectangle has area 2d × 2d = 4d².
Each point needs d² area around it.
Maximum points that fit: 8 (including p itself).
So at most 7 others to check!
```

## Example Usage

```mbt check
///|
test "closest pair example" {
  let points : Array[(Double, Double)] = [(0.0, 0.0), (1.0, 0.0), (4.0, 0.0)]
  let (dist, p1, p2) = @closest_pair.closest_pair(points)
  inspect(dist, content="1")
  inspect((p1, p2), content="(0, 1)")
}
```

## The Algorithm

```
def closest_pair(points):
    if len(points) <= 3:
        return brute_force(points)

    # Divide
    mid = len(points) // 2
    mid_x = points[mid].x
    left = points[:mid]
    right = points[mid:]

    # Conquer
    d_left = closest_pair(left)
    d_right = closest_pair(right)
    d = min(d_left, d_right)

    # Combine: check strip
    strip = [p for p in points if |p.x - mid_x| < d]
    strip.sort(by=y)

    for i in range(len(strip)):
        for j in range(i+1, min(i+8, len(strip))):
            if strip[j].y - strip[i].y >= d:
                break
            d = min(d, dist(strip[i], strip[j]))

    return d
```

## Common Applications

### 1. Collision Detection
```
Find objects that might collide (closest pairs).
Often combined with spatial data structures for updates.
```

### 2. Clustering
```
Hierarchical clustering starts by finding closest pairs.
Repeatedly merge closest clusters.
```

### 3. Nearest Neighbor Search
```
Find the closest point to a query point.
Closest pair is building block for k-nearest neighbors.
```

### 4. Geographic Analysis
```
Find closest pair of cities, facilities, etc.
Input: latitude/longitude coordinates.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Brute force | O(n²) |
| Divide and conquer | O(n log n) |
| Randomized | O(n) expected |

**Recurrence**: T(n) = 2T(n/2) + O(n) = O(n log n)

## Closest Pair vs Other Techniques

| Method | Time | Notes |
|--------|------|-------|
| **D&C (this)** | O(n log n) | Deterministic, simple |
| Randomized | O(n) expected | Grid-based hashing |
| Sweep line | O(n log n) | Alternative approach |
| k-d tree | O(n log n) | Good for k-nearest too |

**Choose Divide & Conquer when**: You need a deterministic O(n log n) solution with clear correctness proof.

## Extension: k-Closest Pairs

```
To find k closest pairs, not just the minimum:
1. Use a max-heap of size k
2. During merge step, add all strip pairs to heap
3. Final heap contains k closest pairs

Time: O(n log n + n log k)
```

## Implementation Notes

- Pre-sort points by x before recursion (or use indices)
- Pass y-sorted list through recursion for efficient strip sorting
- Handle duplicate x-coordinates carefully
- For integer coordinates, compare squared distances to avoid floating-point issues
- Base case: 2-3 points, use brute force

