# Challenge: Binary Search on Answer

Find the smallest value that satisfies a monotone predicate by binary search.

## What you learn

- Monotone feasibility checks
- Loop invariants for lower/upper bounds
- Separating feasibility from search logic

## Pseudocode sketch

```mbt nocheck
while low < high:
  mid = (low + high) / 2
  if feasible(mid): high = mid
  else: low = mid + 1
```

## Notes

- Time complexity: O(log R * cost(feasible))
- Useful for capacity, speed, or threshold problems
