# Challenge: Line Sweep (Max Overlap)

Compute the maximum number of overlapping intervals by sorting endpoints and
sweeping left to right.

## What you learn

- Event representation (start +1, end -1)
- Sorting events by position, with tie handling
- Maintaining a running count and maximum

## Pseudocode sketch

```mbt nocheck
sort events
for event in events:
  active += event.delta
  best = max(best, active)
```

## Notes

- Time complexity: O(n log n)
- Space complexity: O(n)
