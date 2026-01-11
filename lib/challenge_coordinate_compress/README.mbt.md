# Challenge: Coordinate Compression

Map arbitrary values to a compact 0..k-1 range while preserving order.
Useful for replacing large IDs with dense indices.

## What you learn

- Sorting and deduplicating values
- Binary search to map each value to its rank
- Handling negative and large numbers uniformly

## Pseudocode sketch

```mbt nocheck
///|
let uniq = sort_and_unique(values)

///|
let idx = lower_bound(uniq, value)
```

## Notes

- Preprocessing: O(n log n)
- Mapping each value: O(log n)
