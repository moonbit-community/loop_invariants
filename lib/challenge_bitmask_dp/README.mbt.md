# Challenge: Bitmask DP (TSP)

Solve the traveling salesman problem for small n by DP over subsets.

## What you learn

- Encoding visited sets as bitmasks
- Transitioning from (mask, u) to (mask | 1<<v, v)
- Closing the tour by returning to the start

## Pseudocode sketch

```mbt nocheck
for mask in 1..(1<<n)-1:
  for u in 0..n-1:
    for v in 0..n-1:
      if v not in mask:
        dp[mask|1<<v][v] = min(dp[mask|1<<v][v], dp[mask][u] + dist[u][v])
```

## Notes

- Time complexity: O(n^2 * 2^n)
- Works for n <= ~20 in practice
