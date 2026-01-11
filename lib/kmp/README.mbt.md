# KMP (Knuth-Morris-Pratt)

Linear-time string matching using a prefix-function (failure function) to
avoid re-checking characters after a mismatch.

## What it includes

- `compute_failure` (prefix function / LPS)
- `kmp_search`, `kmp_find_first`, `kmp_count`
- A Z-function implementation and `z_search`

## Example

```mbt check
///|
test "kmp example" {
  let text = "ababcababa"
  let pattern = "aba"
  inspect(@kmp.kmp_search(text, pattern), content="[0, 5, 7]")
  inspect(@kmp.kmp_find_first(text, "cab"), content="4")
  inspect(@kmp.kmp_count(text, pattern), content="3")
}
```

## Notes

- Time complexity: `O(n + m)`.
- Useful when you need all pattern occurrences or fast substring search.
