# Splay Tree

## Overview

A **Splay Tree** is a self-adjusting binary search tree that moves recently
accessed nodes to the root via rotations. This "splaying" operation provides
amortized O(log n) time for all operations.

- **Amortized Time**: O(log n) per operation
- **Key Advantage**: Frequently accessed elements become faster to find
- **No Balance Info**: Unlike AVL/Red-Black, no height/color storage needed

This splay tree is generic over the key type: `T : Compare`.

## Core Idea

- After access, **rotate the node to the root** (splaying).
- Zig/zig-zig/zig-zag rotations keep BST order while reshaping the tree.
- Frequently accessed keys move near the root, giving good amortized bounds.

## The Key Insight

```
Move accessed nodes to root via rotations.
Recently accessed = near root = fast next access.

Access 'x':
       y               x
      / \             / \
     x   C    →     A   y
    / \                 / \
   A   B               B   C

Three cases based on parent/grandparent positions:
  - Zig: x is child of root → single rotation
  - Zig-Zig: x and parent are same-side children
  - Zig-Zag: x and parent are opposite-side children
```

## Rotation Cases

```
Zig (single rotation when parent is root):
      p              x
     / \            / \
    x   C   →     A   p
   / \                / \
  A   B              B   C

Zig-Zig (x and p both left children):
        g              x
       / \            / \
      p   D   →     A   p
     / \                / \
    x   C              B   g
   / \                    / \
  A   B                  C   D

Zig-Zag (x is right child, p is left child):
      g                g              x
     / \              / \            / \
    p   D    →      x   D    →     p   g
   / \              / \            / \ / \
  A   x            p   C          A B C D
     / \          / \
    B   C        A   B
```

## Algorithm Walkthrough

```
Initial tree:         After accessing 1:
       5                    1
      / \                    \
     3   7                    5
    /                        / \
   1                        3   7

Splay(1):
Step 1: Zig-Zig (1 and 3 both left children of 5)
       5              3              1
      /              / \              \
     3       →     1   5      →       3
    /                    \              \
   1                      7              5
                                          \
                                           7

After accessing 7:
       1                    7
        \                  /
         3       →       1
          \               \
           5               3
            \               \
             7               5

Splay(7): Rotate 7 up through 5, then 3, then 1
```

## Example Usage

```mbt nocheck
// Create splay tree
let tree = SplayTree::new()

// Insert elements (each insertion splays the node to root)
tree.insert(5)
tree.insert(3)
tree.insert(7)
tree.insert(1)

// Find splays the found node to root
tree.find(1)  // 1 is now at root

// Delete splays node, removes it, joins subtrees
tree.delete(3)

// Split around a key
let (left, right) = tree.split(4)
// left contains elements < 4, right contains >= 4
```

## Common Applications

### 1. LRU Cache Implementation
```
Recently accessed items stay near root.
Perfect for implementing cache eviction policies.
```

### 2. Network Routing Tables
```
Frequently accessed routes become faster.
Self-optimizing for traffic patterns.
```

### 3. Compression Algorithms
```
Move-to-front heuristic in data compression.
Recently seen symbols at front of list.
```

### 4. Rope (Text Editor)
```
Sequence operations with split/join.
Recently edited regions stay accessible.
```

## Complexity Analysis

| Operation | Amortized | Worst Case |
|-----------|-----------|------------|
| Search | O(log n) | O(n) |
| Insert | O(log n) | O(n) |
| Delete | O(log n) | O(n) |
| Split | O(log n) | O(n) |
| Join | O(log n) | O(n) |

Amortized analysis uses potential function:
Φ = Σ log(size of subtree)

## Splay Tree vs Other BSTs

| Feature | Splay | AVL | Red-Black |
|---------|-------|-----|-----------|
| Balance info | None | Height | Color |
| Worst case op | O(n) | O(log n) | O(log n) |
| Amortized | O(log n) | O(log n) | O(log n) |
| Cache behavior | Excellent | Good | Good |
| Implementation | Simple | Medium | Complex |

**Choose Splay Tree when**: Access patterns are non-uniform (some elements accessed more).

## Working Set Property

```
If you access element x, then access other elements,
then access x again:

Time for second access to x ≈ O(log k)
where k = number of distinct elements accessed in between

This is optimal for working set sequences!
```

## Implementation Notes

- Implement bottom-up splaying (splay after each operation)
- For split: splay the split point, then detach right subtree
- For join: splay max of left tree, attach right as right child
- Consider top-down splaying for better cache performance
- Null pointers for empty subtrees (or use sentinel)
