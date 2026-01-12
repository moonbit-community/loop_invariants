# Manacher's Algorithm (Reference)

Compute palindrome radii around every center in linear time. This allows
fast retrieval of the longest palindromic substring and counts of palindromes.

## What it demonstrates

- Odd and even center expansion with reuse
- Maintaining a rightmost palindrome window
- Linear-time palindrome enumeration

## Pseudocode sketch

```mbt nocheck
let (odd, even) = manacher_radii(s)
let best = longest_palindrome(s)
```

## Example

```mbt check
///|
test "manacher example" {
  inspect(@manacher.longest_palindrome("cbbd"), content="bb")
  inspect(@manacher.count_palindromes("aaa"), content="6")
}
```

## Notes

- This package is a reference implementation with invariants.
- For a public API, see `lib/challenge_manacher`.
- Time complexity: `O(n)`.
