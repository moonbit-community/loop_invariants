# Splay Tree

## Overview

A **Splay Tree** is a self-adjusting binary search tree that moves accessed nodes
to the root via rotations. It provides O(log n) amortized time for all operations
without storing balance information.

- **Operations**: O(log n) amortized
- **Space**: O(n)
- **Key Feature**: Recently accessed elements are near the root

## The Key Insight

```
Traditional BSTs: Access patterns can degrade to O(n) per operation
                  (e.g., accessing elements in sorted order)

Splay tree insight: "Move to front"
  - Every access rotates the node to the root
  - Frequently accessed nodes stay near the top
  - The tree self-balances over time

Amortized O(log n) for any access sequence!
```

## Understanding Tree Rotations

```
Right rotation at x:          Left rotation at y:

      y                              x
     / \                            / \
    x   C    ──────────►          A   y
   / \       Right rotate            / \
  A   B      at x                   B   C

              ◄──────────
              Left rotate
              at y

Key property: BST order is preserved after rotation
  A < x < B < y < C (unchanged)
```

## The Three Splay Cases

### Case 1: Zig (Parent is Root)
```
When x's parent is the root, do a single rotation:

Before:              After zig:
      p (root)             x (root)
     / \                  / \
    x   C      ─────►    A   p
   / \                      / \
  A   B                    B   C

Only happens at the last step (once per splay).
```

### Case 2: Zig-Zig (Same Direction)
```
When x and parent are both left children (or both right):

Before:              After zig-zig:
        g                   x
       / \                 / \
      p   D               A   p
     / \        ─────►       / \
    x   C                   B   g
   / \                         / \
  A   B                       C   D

IMPORTANT: Rotate grandparent first, then parent!
This is what gives the O(log n) amortized bound.
```

### Case 3: Zig-Zag (Different Directions)
```
When x is left child and parent is right child (or vice versa):

Before:              After zig-zag:
      g                     x
     / \                   / \
    A   p                 g   p
       / \     ─────►    / \ / \
      x   D             A  B C  D
     / \
    B   C

Rotate x twice: first with parent, then with grandparent.
```

## Splay Algorithm Walkthrough

```
Tree before splay(30):

           50
          /  \
        25    70
       /  \
      10   30    ← we want to splay this node
          /  \
         27   40

Step 1: Zig-Zag (30 is right child, 25 is left child)
  - 30 and 25 have different directions
  - Rotate 30 left, then rotate 30 right

After step 1:
           50
          /  \
        30    70
       /  \
      25   40
     /  \
    10   27

Step 2: Zig (30's parent 50 is root)
  - Single right rotation

After step 2:
        30  ← now root!
       /  \
      25   50
     /  \    \
    10   27   70
            /
           40
```

## Visual: Why Zig-Zig Rotates Grandparent First

```
WRONG way (rotate parent first):
      g              g            x
     /              /            / \
    p    ───►      x    ───►    A   g
   /              / \              /
  x              A   p            p
 /                    \          /
A                      B        B

This doesn't improve tree balance!

RIGHT way (rotate grandparent first):
      g              p              x
     /              / \            / \
    p    ───►      x   g   ───►   A   p
   /              /                  / \
  x              A                  B   g
 /
A

This path-halving is key to O(log n) amortized time!
```

## Why Splay Trees Work

```
The potential function argument:

Define potential Φ(T) = Σ log(size(subtree(v))) for all v

Key insight: Splaying a deep node to the root
  - Does O(depth) rotations
  - But ALSO improves the tree structure
  - The "cost" is paid by reducing potential

Amortized cost = actual cost + ΔΦ ≤ 3 log n

Even if we access the deepest node repeatedly,
the tree restructures to make future accesses cheap!
```

## Common Applications

### 1. Dynamic Sequences
```
Splay trees can implement sequences with:
- Split at position k: O(log n) amortized
- Concatenate two sequences: O(log n) amortized
- Reverse a range: O(log n) amortized (with lazy propagation)
```

### 2. Link-Cut Trees
```
The auxiliary trees in link-cut trees are splay trees.
Splaying makes path operations efficient.
```

### 3. Cache-Friendly Access
```
If some elements are accessed more frequently:
- They naturally migrate toward the root
- Access time adapts to the access pattern
- No need to know the pattern in advance!
```

### 4. Optimal BST Approximation
```
Splay trees achieve within a constant factor of
the optimal static BST for any access sequence.
(Dynamic Optimality Conjecture - still unproven!)
```

## Rotation Cases (Summary)

- **Zig**: parent is root; single rotation.
- **Zig-Zig**: node and parent are both left or both right children; rotate
  parent, then rotate node.
- **Zig-Zag**: node is a left child and parent is a right child (or vice versa);
  rotate node twice.

## Pseudocode

```mbt nocheck
///|
fn splay(x : Node) -> Unit {
  while x is not root {
    let p = x.parent
    if p is root {
      // Zig case
      if x is left_child { rotate_right(p) }
      else { rotate_left(p) }
    } else {
      let g = p.parent
      if same_direction(x, p) {
        // Zig-Zig: rotate grandparent first!
        if x is left_child {
          rotate_right(g)
          rotate_right(p)
        } else {
          rotate_left(g)
          rotate_left(p)
        }
      } else {
        // Zig-Zag: rotate parent, then grandparent
        if x is left_child {
          rotate_right(p)
          rotate_left(g)
        } else {
          rotate_left(p)
          rotate_right(g)
        }
      }
    }
  }
}
```

## Complexity Analysis

| Operation | Amortized Time |
|-----------|----------------|
| Search | O(log n) |
| Insert | O(log n) |
| Delete | O(log n) |
| Split | O(log n) |
| Join | O(log n) |

## Splay Tree vs Other BSTs

| Tree | Worst Case | Amortized | Extra Storage |
|------|------------|-----------|---------------|
| **Splay** | O(n) | O(log n) | None |
| AVL | O(log n) | O(log n) | Balance factor |
| Red-Black | O(log n) | O(log n) | Color bit |
| Treap | O(n) | O(log n) expected | Priority |

**Choose Splay when**: You want adaptive performance, simple implementation,
or need split/join operations.

## Implementation Notes

- Amortized time: O(log n)
- This package is a reference implementation with invariants
- Maintain parent pointers for efficient bottom-up splaying
- Keys are generic: operations require `T : Compare`
- Top-down splaying is an alternative that avoids parent pointers

