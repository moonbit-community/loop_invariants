# Challenge: Longest Common Subsequence (LCS)

Compute the length of the longest subsequence common to two sequences.

## What you learn

- DP with two dimensions (prefixes of each string)
- Row-by-row optimization to reduce memory
- Classic recurrence with match vs. skip

## Pseudocode sketch

```mbt nocheck
if a[i-1] == b[j-1]:
  dp[i][j] = dp[i-1][j-1] + 1
else:
  dp[i][j] = max(dp[i-1][j], dp[i][j-1])
```

## Notes

- Time complexity: O(n * m)
- Space complexity: O(m) with rolling rows
