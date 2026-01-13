# Challenge: Palindrome Partition (Min Cuts)

DP for minimal palindrome partitioning cuts.

## Core Idea

1. Precompute a palindrome table `pal[i][j]` for all substrings.
2. Let `dp[i]` be the minimum cuts for the prefix `s[0..i]`.
3. For each end position `i`, scan all starts `j`:
   - If `s[j..i]` is a palindrome, update `dp[i]` from `dp[j-1] + 1`
   - If `j == 0`, then no cut is needed.

This yields O(n^2) time and O(n^2) space.

## Example

```mbt check
///|
test "palindrome partition example" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("aab")
  inspect(cuts, content="1")
}
```

## Another Example

```mbt check
///|
test "palindrome partition no cuts" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("ababa")
  inspect(cuts, content="0")
}
```

## Notes

- Empty string has 0 cuts.
- Single characters are palindromes by definition.
