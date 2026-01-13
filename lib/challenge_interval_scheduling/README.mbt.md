# Challenge: Interval Scheduling

Select the maximum number of non-overlapping intervals by sorting by end time.

## What you learn

- Greedy choice: earliest finishing interval is always safe
- Maintaining the last chosen end time
- Proof by exchange argument

## Core Idea

Sort intervals by end time. Always pick the next interval whose start is not
before the end of the last chosen interval. This greedy choice maximizes the
count.

## Pseudocode sketch

```mbt nocheck
sort intervals by end
for interval in intervals:
  if interval.start >= last_end:
    take interval
```

## Example

```mbt check
///|
test "interval scheduling basic" {
  let intervals : Array[(Int, Int)] = [
    (1, 3),
    (2, 4),
    (3, 5),
    (0, 7),
    (5, 9),
    (8, 9),
  ]
  let count = @challenge_interval_scheduling.max_non_overlapping_pairs(
    intervals[:],
  )
  inspect(count, content="3")
}
```

## Another Example

```mbt check
///|
test "interval scheduling disjoint" {
  let intervals : Array[(Int, Int)] = [(0, 1), (2, 3), (4, 5)]
  let count = @challenge_interval_scheduling.max_non_overlapping_pairs(
    intervals[:],
  )
  inspect(count, content="3")
}
```

## Notes

- Time complexity: O(n log n)
- Space complexity: O(1) besides sorting
