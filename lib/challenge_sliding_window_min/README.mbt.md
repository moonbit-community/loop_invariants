# Challenge: Sliding Window Minimum

Maintain the minimum of each fixed-size window using a monotonic deque.

## What you learn

- Keeping indices in increasing order
- Maintaining increasing values to keep the minimum at the front
- Removing expired indices as the window moves

## Pseudocode sketch

```mbt nocheck
for i in 0..n-1:
  drop indices < i-k+1
  drop larger values from the back
  push i
  answer is arr[deque.front]
```

## Notes

- Time complexity: O(n)
- Space complexity: O(k)
