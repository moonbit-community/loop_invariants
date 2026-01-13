# Challenge: Edit Distance (Levenshtein)

Compute the minimum number of edits (insert, delete, substitute) to transform
one string into another.

## What you learn

- DP over prefixes with three transitions
- Cost model for substitution vs. match
- Rolling-row optimization

## Core Idea

Let dp[i][j] be the minimum edits to convert the first i chars of a into the
first j chars of b. Transition with insert, delete, or substitute; matching
characters costs 0.

## Pseudocode sketch

```mbt nocheck
if a[i-1] == b[j-1]: cost = 0 else cost = 1

dp[i][j] = min(
  dp[i-1][j] + 1,      // delete
  dp[i][j-1] + 1,      // insert
  dp[i-1][j-1] + cost  // substitute
)
```

## Example

```mbt check
///|
test "edit distance basic" {
  let a : Array[Char] = ['k', 'i', 't', 't', 'e', 'n']
  let b : Array[Char] = ['s', 'i', 't', 't', 'i', 'n', 'g']
  let dist = @challenge_edit_distance.edit_distance(a[:], b[:])
  inspect(dist, content="3")
}
```

## Another Example

```mbt check
///|
test "edit distance short" {
  let a : Array[Char] = ['f', 'l', 'a', 'w']
  let b : Array[Char] = ['l', 'a', 'w', 'n']
  let dist = @challenge_edit_distance.edit_distance(a[:], b[:])
  inspect(dist, content="2")
}
```

## Notes

- Time complexity: O(n * m)
- Space complexity: O(m)
