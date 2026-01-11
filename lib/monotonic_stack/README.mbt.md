# Monotonic Stack (Reference)

Maintain a stack in increasing or decreasing order to answer nearest greater/
smaller element queries.

## What it demonstrates

- Next greater/next smaller element
- Histogram area computation
- Maintaining monotonic invariants

## Pseudocode sketch

```mbt nocheck
for i in 0..n-1:
  while stack not empty and arr[stack.top] >= arr[i]: pop
  stack.push(i)
```

## Notes

- Time complexity: O(n)
- This package is a reference implementation with invariants
