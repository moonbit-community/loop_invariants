# Disjoint Sparse Table (Reference)

A variant of sparse table that supports O(1) queries for any associative
operation by precomputing disjoint block prefixes.

## What it demonstrates

- Building prefix minima for disjoint blocks
- Choosing a level by the highest differing bit
- O(1) range query via two precomputed values

## Pseudocode sketch

```mbt nocheck
k = highest_bit(l ^ (r-1))
answer = op(table[k][l], table[k][r-1])
```

## Notes

- Preprocess O(n log n), query O(1)
- For a challenge API, see `lib/challenge_disjoint_sparse_table`
