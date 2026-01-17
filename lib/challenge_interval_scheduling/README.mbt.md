# Challenge: Interval Scheduling

Interval scheduling asks for the **maximum number of non-overlapping
intervals** you can select. The optimal solution is a classic greedy algorithm:
**always pick the interval that finishes earliest**.

## Problem statement

Given a list of intervals `(start, end)` (with `start <= end`), select the
largest subset such that no two intervals overlap.

We allow **touching** intervals: if one ends at time `t` and another starts at
`t`, both can be chosen.

## Core idea (greedy)

1. Sort intervals by end time.
2. Keep the last chosen end time.
3. Select the next interval whose start is at or after that end.

Why it works (exchange argument):

- Suppose an optimal solution chooses an interval that ends later than the
  earliest-ending interval. You can swap it with the earliest-ending interval
  without reducing the number of intervals, because it leaves at least as much
  room for later intervals. Repeating this swap produces the greedy solution.

## Diagram: why earliest finish is best

Intervals on a timeline:

```
A: [1, 4)
B: [2, 3)
C: [3, 5)
```

If you pick A (ends at 4), you can only take 1 interval total.
If you pick B (ends at 3), you can still take C.
So earliest finish (B) is always safe.

## Algorithm sketch

```
sort intervals by end
last_end = -infinity
count = 0
for interval in order:
  if interval.start >= last_end:
    take it
    last_end = interval.end
```

## Examples

### Example 1: mixed overlaps

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

One optimal selection is `(1,3)`, `(3,5)`, `(8,9)`.

### Example 2: fully disjoint

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

### Example 3: nested intervals

```
(0, 10) contains all others
```

```mbt check
///|
test "interval scheduling nested" {
  let intervals : Array[(Int, Int)] = [(0, 10), (1, 2), (2, 3), (3, 4)]
  let count = @challenge_interval_scheduling.max_non_overlapping_pairs(
    intervals[:],
  )
  inspect(count, content="3")
}
```

### Example 4: touching intervals

Touching is allowed: end == next start.

```mbt check
///|
test "interval scheduling touching" {
  let intervals : Array[(Int, Int)] = [(0, 2), (2, 4), (4, 6)]
  let count = @challenge_interval_scheduling.max_non_overlapping_pairs(
    intervals[:],
  )
  inspect(count, content="3")
}
```

### Example 5: identical end times

When multiple intervals end at the same time, any of them is safe to pick.

```mbt check
///|
test "interval scheduling tie" {
  let intervals : Array[(Int, Int)] = [(0, 3), (1, 3), (2, 3), (3, 5)]
  let count = @challenge_interval_scheduling.max_non_overlapping_pairs(
    intervals[:],
  )
  inspect(count, content="2")
}
```

## Complexity

- Sorting: O(n log n)
- Scan: O(n)
- Total: O(n log n)

## Practical notes and pitfalls

- Ensure `start <= end` for each interval.
- The greedy proof depends on **earliest finish**, not earliest start.
- If intervals are half-open, the condition `start >= last_end` is correct.

## When to use it

Use interval scheduling whenever you need the maximum number of compatible
choices, such as classroom scheduling, meeting rooms, or task selection.
