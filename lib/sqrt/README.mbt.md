# Sqrt Decomposition (Reference, Extended)

An extended sqrt-decomposition toolkit with detailed invariants and multiple
query/update patterns.

## What it demonstrates

- Block sizing and index mapping
- Partial-block handling
- Mixing exact blocks with boundary scans
- How invariants justify each step

## Core Idea

Split the array into blocks of size about √n. A query over [l, r] is handled by:

1. Scan the left partial block.
2. Use precomputed aggregates for full blocks in the middle.
3. Scan the right partial block.

This keeps each query at O(√n) while updates are O(1) or O(√n) depending on
the aggregate.

## Pseudocode Sketch

```mbt nocheck
block_size = ceil_sqrt(n)
block = i / block_size

range_sum(l, r):
  sum = 0
  while l <= r and l % block_size != 0:
    sum += a[l]; l++
  while l + block_size - 1 <= r:
    sum += block_sum[l / block_size]
    l += block_size
  while l <= r:
    sum += a[l]; l++
  return sum
```

## Notes

- Time complexity: typically O(√n) per query.
- This package is a reference implementation with invariants (not a public API).
