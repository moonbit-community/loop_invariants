# Palindromic Tree (Eertree) (Reference)

Maintain all distinct palindromic substrings of a string in linear time.
Each node represents a unique palindrome, with suffix links for fast updates.

## What it demonstrates

- Two special roots for odd/even palindromes
- Suffix-link traversal to find the next extendable palindrome
- Counting occurrences of each palindrome

## Pseudocode sketch

```mbt nocheck
let tree = Eertree::new()
for c in s {
  tree.add_char(c)
}
```

## Example

```mbt check
///|
test "eertree example" {
  inspect(@eertree.distinct_count("ababa"), content="5")
  inspect(@eertree.longest_length("abacaba"), content="7")
}
```

## Notes

- This package is a reference implementation with invariants.
- Time complexity: `O(n)` for building the tree.
