# Challenge: Two Pointers / Sliding Window

Use two indices to maintain a window that satisfies a condition, often
reducing O(n^2) scans to O(n).

## What you learn

- Growing and shrinking a window while preserving an invariant
- Counting subarrays that meet a constraint
- Reasoning about monotone movement of pointers

## Pseudocode sketch

```mbt nocheck
for right in 0..n-1:
  expand window with right
  while window violates constraint:
    move left
```

## Notes

- Typical time complexity: O(n)
- Space complexity: O(1) beyond input
