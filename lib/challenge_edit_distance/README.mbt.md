# Challenge: Edit Distance (Levenshtein)

Compute the minimum number of edits (insert, delete, substitute) to transform
one string into another.

## What you learn

- DP over prefixes with three transitions
- Cost model for substitution vs. match
- Rolling-row optimization

## Pseudocode sketch

```mbt nocheck
if a[i-1] == b[j-1]: cost = 0 else cost = 1

dp[i][j] = min(
  dp[i-1][j] + 1,      // delete
  dp[i][j-1] + 1,      // insert
  dp[i-1][j-1] + cost  // substitute
)
```

## Notes

- Time complexity: O(n * m)
- Space complexity: O(m)
