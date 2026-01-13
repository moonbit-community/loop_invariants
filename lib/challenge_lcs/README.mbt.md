# Challenge: Longest Common Subsequence (LCS)

Compute the length of the longest subsequence common to two sequences.

## What you learn

- DP with two dimensions (prefixes of each string)
- Row-by-row optimization to reduce memory
- Classic recurrence with match vs. skip

## Core Idea

Let dp[i][j] be the LCS length for prefixes a[0..i) and b[0..j). If the last
characters match, extend by 1; otherwise take the best of skipping one char.

## Pseudocode sketch

```mbt nocheck
if a[i-1] == b[j-1]:
  dp[i][j] = dp[i-1][j-1] + 1
else:
  dp[i][j] = max(dp[i-1][j], dp[i][j-1])
```

## Example

```mbt check
///|
test "lcs length basic" {
  let a : Array[Char] = ['A', 'B', 'C', 'B', 'D', 'A', 'B']
  let b : Array[Char] = ['B', 'D', 'C', 'A', 'B', 'A']
  let len = @challenge_lcs.lcs_length(a[:], b[:])
  inspect(len, content="4")
}
```

## Another Example

```mbt check
///|
test "lcs length short" {
  let a : Array[Char] = ['a', 'b', 'c']
  let b : Array[Char] = ['a', 'c']
  let len = @challenge_lcs.lcs_length(a[:], b[:])
  inspect(len, content="2")
}
```

## Notes

- Time complexity: O(n * m)
- Space complexity: O(m) with rolling rows
