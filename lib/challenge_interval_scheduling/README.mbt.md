# Challenge: Interval Scheduling

Select the maximum number of non-overlapping intervals by sorting by end time.

## What you learn

- Greedy choice: earliest finishing interval is always safe
- Maintaining the last chosen end time
- Proof by exchange argument

## Pseudocode sketch

```mbt nocheck
sort intervals by end
for interval in intervals:
  if interval.start >= last_end:
    take interval
```

## Notes

- Time complexity: O(n log n)
- Space complexity: O(1) besides sorting
