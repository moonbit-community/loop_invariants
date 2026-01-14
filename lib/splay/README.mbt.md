# Splay (Reference)

Splay-based operations for dynamic trees and sequence structures.
This package focuses on the core splaying procedure and invariants.

## What it demonstrates

- Zig / zig-zig / zig-zag rotations
- Maintaining parent pointers
- Bringing a node to the root in amortized logarithmic time

## Core Idea

A splay tree rotates a chosen node up to the root. Repeated access keeps
recently used nodes near the top, yielding amortized O(log n) operations.

## Typical Uses

- Sequence data structures (implicit keys)
- Dynamic trees (via link-cut)

## Rotation Cases (Intuition)

- **Zig**: parent is root; single rotation.
- **Zig-Zig**: node and parent are both left or both right children; rotate
  parent, then rotate node.
- **Zig-Zag**: node is a left child and parent is a right child (or vice versa);
  rotate node twice.

## Pseudocode sketch

```mbt nocheck
while x is not root:
  if parent is root: zig
  else if x and parent are both left/right: zig-zig
  else: zig-zag
```

## Notes

- Amortized time: O(log n)
- This package is a reference implementation with invariants (not a public API)
- Keys are generic: operations require `T : Compare`.
