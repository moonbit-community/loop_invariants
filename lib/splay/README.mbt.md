# Splay (Reference)

Splay-based operations for dynamic trees and sequence structures.
This package focuses on the core splaying procedure and invariants.

## What it demonstrates

- Zig / zig-zig / zig-zag rotations
- Maintaining parent pointers
- Bringing a node to the root in amortized logarithmic time

## Pseudocode sketch

```mbt nocheck
while x is not root:
  if parent is root: zig
  else if x and parent are both left/right: zig-zig
  else: zig-zag
```

## Notes

- Amortized time: O(log n)
- This package is a reference implementation with invariants
