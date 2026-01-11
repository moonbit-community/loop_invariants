# Challenge: Prefix Sum Array

Build prefix sums so any range sum can be answered in O(1) after O(n)
preprocessing.

## What you learn

- Turning a running sum into a reusable prefix array
- Using `prefix[r+1] - prefix[l]` for inclusive ranges
- Simple loop invariants for accumulation

## Pseudocode sketch

```mbt nocheck
///|
let prefix = build_prefix_sum(arr)

///|
let sum_lr = prefix[r + 1] - prefix[l]
```

## Notes

- Preprocessing: O(n)
- Range query: O(1)
