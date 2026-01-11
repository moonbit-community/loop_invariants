# Challenge: Binary Lifting

Precompute 2^k ancestors to jump up a tree in O(log n) time.

## What you learn

- Building the jump table `up[k][v]`
- Using bit decomposition to lift by k steps
- Loop invariants for table construction

## Pseudocode sketch

```mbt nocheck
for k in 1..LOG:
  up[k][v] = up[k-1][ up[k-1][v] ]

lift(v, dist):
  for k in 0..LOG:
    if dist has bit k: v = up[k][v]
```

## Notes

- Preprocessing: O(n log n)
- Query: O(log n)
