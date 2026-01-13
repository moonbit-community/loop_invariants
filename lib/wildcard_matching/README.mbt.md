# Wildcard Matching

## Overview

Match a string against a pattern containing:

- `?` = any single character
- `*` = any sequence (including empty)

This package uses dynamic programming with a rolling 1D table.

- **Time**: O(n * m)
- **Space**: O(m)

## DP Recurrence

Let `dp[j]` be whether `text[0..i)` matches `pattern[0..j)`:

- If `pattern[j-1] == '*'`: `dp[j] = dp[j] || dp[j-1]`
- If `pattern[j-1] == '?'` or exact match: `dp[j] = prev` (diagonal)
- Otherwise: `dp[j] = false`

## API

- `wildcard_match(text, pattern)` returns Bool.

## Example Usage

```mbt check
///|
test "wildcard basic" {
  inspect(@wildcard_matching.wildcard_match("aaabxc", "a*b?c"), content="true")
  inspect(@wildcard_matching.wildcard_match("abc", "a?c"), content="true")
}
```

```mbt check
///|
test "wildcard star" {
  inspect(@wildcard_matching.wildcard_match("", "*"), content="true")
  inspect(@wildcard_matching.wildcard_match("hello", "h*o"), content="true")
}
```
