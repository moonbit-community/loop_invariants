# Challenge: Difference Array

Apply many range increments efficiently by storing the differences between
adjacent elements.

## What you learn

- Representing range updates with two point updates
- Reconstructing the final array via prefix sum
- Loop invariants for reconstruction

## Pseudocode sketch

```mbt nocheck
// add delta to [l, r]
diff[l] += delta
diff[r + 1] -= delta

// recover array
for i in 0..n-1:
  arr[i] = arr[i-1] + diff[i]
```

## Notes

- Range update: O(1)
- Reconstruction: O(n)
