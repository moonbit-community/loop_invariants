# String Hashing (Reference)

Compute prefix hashes and compare substrings in O(1) time after preprocessing.

## What it demonstrates

- Polynomial rolling hash
- Power table construction
- Collision mitigation patterns

## Pseudocode sketch

```mbt nocheck
hash(l, r) = pref[r] - pref[l] * pow_base[r-l]
```

## Example

```mbt check
///|
test "string hash example" {
  let hits = @string_hash.hash_pattern_match("abababab", "aba")
  inspect(hits, content="[0, 2, 4]")
}
```

## Notes

- This package is a reference implementation with invariants
