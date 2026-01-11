# Convex Hull (Reference)

Compute the convex hull of points in the plane, usually with the monotone
chain algorithm.

## What it demonstrates

- Sorting by x/y
- Building lower and upper hulls with cross products
- Removing non-left turns

## Pseudocode sketch

```mbt nocheck
sort points
for p in points:
  while hull makes non-left turn: pop
  push p
```

## Notes

- Time complexity: O(n log n)
- This package is a reference implementation with invariants
