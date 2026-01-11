# Challenge: Floyd-Warshall

All-pairs shortest paths by dynamic programming over intermediate vertices.

## What you learn

- Triple-nested DP with intermediate vertex k
- Relaxation: dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
- Detecting negative cycles via dist[i][i] < 0

## Pseudocode sketch

```mbt nocheck
for k in 0..n-1:
  for i in 0..n-1:
    for j in 0..n-1:
      dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
```

## Notes

- Time complexity: O(n^3)
- Space complexity: O(n^2)
