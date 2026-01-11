# Challenge: 0/1 Knapsack

Choose each item at most once to maximize value within a capacity limit.

## What you learn

- DP over items and capacity
- Transition by taking or skipping an item
- Iteration order to avoid reuse

## Pseudocode sketch

```mbt nocheck
for item in items:
  for cap from W down to weight[item]:
    dp[cap] = max(dp[cap], dp[cap - w] + value)
```

## Notes

- Time complexity: O(n * W)
- Space complexity: O(W)
