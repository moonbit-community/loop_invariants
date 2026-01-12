# AVL Tree

## Overview

An **AVL Tree** is a self-balancing binary search tree where the heights of
left and right subtrees differ by at most 1. This guarantees O(log n) operations.

- **Operations**: O(log n)
- **Space**: O(n)

## The Balance Property

```
Balance Factor = height(right) - height(left)
Valid values: -1, 0, +1

Balanced AVL Tree:        Unbalanced (not AVL):
      [4]                       [4]
     /   \                     /
   [2]   [6]                 [3]
   / \                       /
 [1] [3]                   [2]
                           /
                         [1]
```

## Rotations

### Right Rotation (Left-Heavy)

```
Balance factor at Y is -2 (left subtree too tall)

Before:           After:
    [Y]             [X]
    / \             / \
  [X]  C    →     A  [Y]
  / \                 / \
 A   B               B   C

Y.left = B
X.right = Y
```

### Left Rotation (Right-Heavy)

```
Balance factor at X is +2 (right subtree too tall)

Before:           After:
  [X]               [Y]
  / \               / \
 A  [Y]     →    [X]   C
    / \          / \
   B   C        A   B

X.right = B
Y.left = X
```

### Double Rotations

```
Left-Right Case:           Right-Left Case:
    [Z]                         [Z]
    /                             \
  [X]       First: Left(X)       [X]      First: Right(X)
    \       Then: Right(Z)       /        Then: Left(Z)
    [Y]                        [Y]

Result: [Y] becomes root with [X] and [Z] as children
```

## Algorithm Walkthrough

```
Insert 3, 2, 1 into empty AVL tree:

Step 1: Insert 3
  [3]     bf=0

Step 2: Insert 2
  [3]     bf=-1 (left heavy, but balanced)
  /
[2]

Step 3: Insert 1
  [3]     bf=-2 (unbalanced!)
  /
[2]       Need right rotation at 3
/
[1]

After right rotation:
  [2]     bf=0
  / \
[1] [3]   All nodes balanced!
```

## Rebalancing After Insert

```
After inserting new node, walk up the tree:
1. Update height of each ancestor
2. Check balance factor
3. If |bf| > 1, apply appropriate rotation

Four cases:
bf(node) = -2:
  - bf(left) ≤ 0: Right rotation
  - bf(left) > 0: Left-Right rotation

bf(node) = +2:
  - bf(right) ≥ 0: Left rotation
  - bf(right) < 0: Right-Left rotation
```

## Example Usage

```mbt check
///|
test "avl tree example" {
  let sorted = @avl_tree.avl_sorted([3L, 1L, 4L, 1L][:])
  inspect(sorted, content="[1, 1, 3, 4]")
}
```

## Common Applications

### 1. Ordered Map/Set
```
Maintain sorted collection with:
- Insert: O(log n)
- Delete: O(log n)
- Search: O(log n)
- Find min/max: O(log n)
```

### 2. Range Queries
```
Find all elements in range [a, b]:
- Navigate to split point
- Traverse relevant subtrees
- Time: O(log n + k) where k = result size
```

### 3. Order Statistics
```
Augment each node with subtree size:
- Find k-th smallest: O(log n)
- Count less than x: O(log n)
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Insert | O(log n) |
| Delete | O(log n) |
| Search | O(log n) |
| Min/Max | O(log n) |

**Height bound**: For n nodes, height h ≤ 1.44 log₂(n + 2)

## AVL vs Other BSTs

| Tree | Balance | Height | Use Case |
|------|---------|--------|----------|
| **AVL** | Strict | 1.44 log n | Read-heavy |
| Red-Black | Relaxed | 2 log n | Write-heavy |
| Splay | Amortized | - | Access patterns |
| Treap | Probabilistic | O(log n) expected | Simple code |

**Choose AVL when**: You need guaranteed O(log n) and reads dominate writes.

## Why Heights Differ by at Most 1?

```
Let N(h) = minimum nodes in AVL tree of height h

N(0) = 1
N(1) = 2
N(h) = N(h-1) + N(h-2) + 1  (like Fibonacci!)

This gives: N(h) > φ^h where φ ≈ 1.618 (golden ratio)

So: h < log_φ(n) ≈ 1.44 log₂(n)

The strict balance keeps the tree very compact!
```

## Implementation Notes

- Track height at each node (not balance factor) for simpler code
- After rotation, update heights bottom-up
- Only one or two rotations needed per insert
- Delete may need O(log n) rotations (but still O(log n) total)

