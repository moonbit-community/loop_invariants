# Challenge: Unbounded Knapsack

Choose items multiple times to maximize value within a capacity limit.

## What you learn

- DP over capacity with unlimited item usage
- Forward iteration to allow reuse in the same iteration

## Pseudocode sketch

```mbt nocheck
for cap in 0..W:
  for item in items:
    dp[cap] = max(dp[cap], dp[cap - w] + value)
```

## Notes

- Time complexity: O(n * W)
- Space complexity: O(W)
