# Splay Tree (Reference)

Self-adjusting BST that moves accessed nodes to the root via rotations.

## What it demonstrates

- Zig/Zig-Zag rotations
- Amortized performance via potential argument
- Split/join around a key

## Pseudocode sketch

```mbt nocheck
splay(x):
  while parent exists:
    rotate cases (zig, zig-zig, zig-zag)
```

## Notes

- Amortized time: O(log n) per operation
- This package is a reference implementation with invariants
