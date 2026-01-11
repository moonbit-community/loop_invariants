# Rolling Hash (Reference)

Compute substring hashes in O(1) after O(n) preprocessing. Useful for
string matching, palindromes, and substring equality.

## What it demonstrates

- Prefix hash construction
- Power table for base^k
- Constant-time substring hash extraction

## Pseudocode sketch

```mbt nocheck
hash(l, r) = pref[r] - pref[l] * base^(r-l)
```

## Notes

- Time complexity: O(1) per query after O(n) setup
- This package is a reference implementation with invariants
