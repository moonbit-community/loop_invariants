# Li Chao Tree (Reference)

Maintain a dynamic set of lines and query min/max at x in O(log C) time.

## What it demonstrates

- Segment tree over x-coordinates
- Inserting lines by comparing midpoints
- Querying the best line at a point

## Pseudocode sketch

```mbt nocheck
insert(line, node_range):
  keep better line at midpoint
  recurse to side where new line may win
```

## Notes

- Time complexity: O(log C) per insert/query
- This package is a reference implementation with invariants
