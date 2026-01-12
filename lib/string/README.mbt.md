# String Algorithms (Reference)

A collection of classic string algorithms with detailed invariants.

## What it covers

- Prefix function / Z-function variants
- Palindrome checks and expansions
- Substring search helpers

## Pseudocode sketch

```mbt nocheck
compute prefix/z arrays
use them for pattern matching
```

## Example

```mbt check
///|
test "string algorithms example" {
  let s : Array[Char] = ['a', 'b', 'b', 'a']
  let (start, len) = @string.longest_palindrome_range(s[:])
  inspect((start, len), content="(0, 4)")
  let a : Array[Char] = ['A', 'B', 'C']
  let b : Array[Char] = ['A', 'C']
  inspect(@string.lcs_length(a[:], b[:]), content="2")
}
```

## Notes

- This package is a reference implementation with invariants
- For callable APIs, see the `challenge_*` string packages
