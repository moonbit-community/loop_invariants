# Challenge: Longest Common Subsequence (LCS)

The **longest common subsequence** is the longest sequence of characters that
appears in both strings (not necessarily contiguously).

This challenge computes the **length** of the LCS using dynamic programming
with rolling rows.

## Problem statement

Given two sequences `a` and `b`, find:

```
LCS length of a and b
```

A subsequence keeps relative order but can skip characters.

Example:

- a = "ABCBDAB"
- b = "BDCABA"
- LCS length = 4 (one LCS is "BCBA")

## DP definition

Let:

```
dp[i][j] = LCS length of a[0..i) and b[0..j)
```

Transition:

```
if a[i-1] == b[j-1]:
  dp[i][j] = dp[i-1][j-1] + 1
else:
  dp[i][j] = max(dp[i-1][j], dp[i][j-1])
```

Base:

```
dp[0][*] = 0
 dp[*][0] = 0
```

## Diagram: small DP table

Example: a = "AB", b = "AC"

```
      ''  A  C
   +-----------
'' | 0  0  0
 A | 0  1  1
 B | 0  1  1
```

Answer: dp[2][2] = 1

## Rolling row optimization

We only need the previous row to compute the current row. That reduces memory
from O(m*n) to O(n).

## Examples

### Example 1: classic case

```mbt check
///|
test "lcs length basic" {
  let a : Array[Char] = ['A', 'B', 'C', 'B', 'D', 'A', 'B']
  let b : Array[Char] = ['B', 'D', 'C', 'A', 'B', 'A']
  let len = @challenge_lcs.lcs_length(a, b)
  inspect(len, content="4")
}
```

### Example 2: short strings

```mbt check
///|
test "lcs length short" {
  let a : Array[Char] = ['a', 'b', 'c']
  let b : Array[Char] = ['a', 'c']
  let len = @challenge_lcs.lcs_length(a, b)
  inspect(len, content="2")
}
```

### Example 3: identical strings

```mbt check
///|
test "lcs identical" {
  let a : Array[Char] = ['A', 'B', 'C']
  let b : Array[Char] = ['A', 'B', 'C']
  let len = @challenge_lcs.lcs_length(a, b)
  inspect(len, content="3")
}
```

### Example 4: no common characters

```mbt check
///|
test "lcs none" {
  let a : Array[Char] = ['x', 'y']
  let b : Array[Char] = ['a', 'b']
  let len = @challenge_lcs.lcs_length(a, b)
  inspect(len, content="0")
}
```

### Example 5: longer words

```mbt check
///|
test "lcs longer words" {
  let a : Array[Char] = ['A', 'G', 'G', 'T', 'A', 'B']
  let b : Array[Char] = ['G', 'X', 'T', 'X', 'A', 'Y', 'B']
  let len = @challenge_lcs.lcs_length(a, b)
  inspect(len, content="4")
}
```

## Complexity

Let `m = len(a)`, `n = len(b)`:

- Time: O(m * n)
- Space: O(n) with rolling rows

## Practical notes and pitfalls

- LCS is not the same as longest common substring (substring must be contiguous).
- Use rolling rows if memory is tight; full table is needed only to reconstruct
  the actual LCS string.

## When to use it

Use LCS when you need a similarity measure based on ordered subsequences,
for example in diff tools or sequence alignment.
