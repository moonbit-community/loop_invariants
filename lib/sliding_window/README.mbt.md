# Sliding Window Techniques (Reference)

A set of window-based algorithms for subarray queries, including min/max
queues and sum constraints.

## What it demonstrates

- Fixed-size window min/max with deque
- Variable-size window with sum constraints
- Two-pointer window maintenance

## Pseudocode sketch

```mbt nocheck
for right in 0..n-1:
  add right
  while window invalid: remove left
```

## Notes

- Time complexity: typically O(n)
- This package is a reference implementation with invariants
