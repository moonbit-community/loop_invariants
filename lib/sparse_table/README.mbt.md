# Sparse Table (Reference)

Static range queries in O(1) after O(n log n) preprocessing.

## What it demonstrates

- Precomputing ranges of length 2^k
- Querying with two overlapping blocks
- Range min/max and idempotent operations

## Pseudocode sketch

```mbt nocheck
build: st[k][i] = min(st[k-1][i], st[k-1][i + 2^(k-1)])
query(l, r):
  k = log2(r-l)
  ans = min(st[k][l], st[k][r-2^k])
```

## Notes

- Time complexity: preprocess O(n log n), query O(1)
- For a challenge API, see `lib/challenge_sparse_table_rmq`
