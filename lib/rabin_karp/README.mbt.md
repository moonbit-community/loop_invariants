# Rabin-Karp (Reference)

Rolling-hash based pattern matching. Efficient for multiple pattern checks and
average-case linear search, with verification on hash matches.

## What it demonstrates

- Polynomial rolling hash construction
- O(1) hash updates for sliding windows
- Collision-safe verification

## Pseudocode sketch

```mbt nocheck
///|
let hits = rabin_karp_search(text, pattern)
```

## Notes

- This package is a reference implementation with invariants.
- For a public API, see `lib/challenge_rabin_karp`.
- Expected time complexity: `O(n + m)`.
