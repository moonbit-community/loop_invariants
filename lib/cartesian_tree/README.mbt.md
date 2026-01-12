# Cartesian Tree

## Overview

A **Cartesian Tree** is a binary tree built from an array that satisfies both
BST in-order property and heap property on values. It enables O(1) range
minimum queries after preprocessing.

- **Build**: O(n)
- **RMQ**: O(1) with LCA preprocessing
- **Space**: O(n)

## The Two Properties

```
Array: [3, 2, 6, 1, 9]

Cartesian Tree:
        1 (index 3)
       / \
      2   9 (index 4)
     / \
    3   6
 (idx 0) (idx 2)

1. HEAP PROPERTY: Parent ≤ all descendants
   1 ≤ {2, 3, 6, 9} ✓
   2 ≤ {3, 6} ✓

2. IN-ORDER PROPERTY: In-order traversal = original array
   3 → 2 → 6 → 1 → 9 ✓
```

## Why These Properties Work

```
Key insight: For range [l, r], the minimum element is
the Lowest Common Ancestor of nodes at positions l and r!

Array: [3, 2, 6, 1, 9]
        0  1  2  3  4

        1 (idx 3)
       / \
      2   9
     / \
    3   6

RMQ(0, 2) = min of indices 0,1,2
  LCA of node[0]=3 and node[2]=6 is node[1]=2
  Answer: 2 ✓

RMQ(0, 4) = min of indices 0,1,2,3,4
  LCA of node[0]=3 and node[4]=9 is node[3]=1
  Answer: 1 ✓
```

## O(n) Construction with Stack

```
Process elements left to right with monotonic stack:

Array: [3, 2, 6, 1, 9]

Step 1: Push 3
  Stack: [3]
  Tree:  3

Step 2: Push 2 (2 < 3, so 3 becomes left child of 2)
  Pop 3
  Stack: [2]
  Tree:  2
        /
       3

Step 3: Push 6 (6 > 2, so 6 becomes right child of 2)
  Stack: [2, 6]
  Tree:  2
        / \
       3   6

Step 4: Push 1 (1 < all, pop everything)
  Pop 6, pop 2
  2 becomes left child of 1
  Stack: [1]
  Tree:    1
          /
         2
        / \
       3   6

Step 5: Push 9 (9 > 1, becomes right child of 1)
  Stack: [1, 9]
  Tree:    1
          / \
         2   9
        / \
       3   6

Final tree built in O(n)!
```

## RMQ via LCA

```
After building Cartesian Tree:
1. Preprocess for LCA (binary lifting or Euler tour)
2. For RMQ(l, r):
   - Find nodes at positions l and r
   - Return LCA's value

LCA preprocessing: O(n log n) or O(n)
LCA query: O(log n) or O(1)
```

## Example Usage

```mbt check
///|
test "cartesian tree rmq example" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  inspect(@cartesian_tree.range_min(arr[:], 1, 3), content="Some(1)")
  inspect(@cartesian_tree.range_min(arr[:], 0, 2), content="Some(2)")
}
```

## Common Applications

### 1. Range Minimum Query (RMQ)
```
Preprocess array for O(1) minimum queries on any range.
Combined with LCA gives optimal O(n) / O(1) solution.
```

### 2. All Nearest Smaller Values
```
For each element, find nearest smaller element to left/right.
Parent in Cartesian Tree is one of these!
```

### 3. Largest Rectangle in Histogram
```
For each bar, find how far it extends left and right.
Cartesian tree structure encodes this naturally.
```

### 4. Treaps
```
A Treap is a Cartesian Tree where:
- Keys define BST order
- Random priorities define heap property
This gives expected O(log n) operations.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build tree | O(n) |
| LCA preprocessing | O(n log n) or O(n) |
| RMQ query | O(1) |

## Why O(n) Construction?

```
Each element is pushed and popped at most once!

Stack operations:
- Each of n elements pushed exactly once: n pushes
- Each of n elements popped at most once: ≤ n pops
- Total operations: ≤ 2n = O(n)

The stack maintains the rightmost path of the tree.
```

## Cartesian Tree vs Other RMQ Methods

| Method | Preprocessing | Query | Space |
|--------|---------------|-------|-------|
| **Cartesian + LCA** | O(n) | O(1) | O(n) |
| Sparse Table | O(n log n) | O(1) | O(n log n) |
| Segment Tree | O(n) | O(log n) | O(n) |
| Sqrt Decomposition | O(n) | O(√n) | O(n) |

**Choose Cartesian Tree when**: You need optimal O(n)/O(1) RMQ.

## The Stack Invariant

```
Stack maintains rightmost path of current tree,
with values in increasing order (min-heap on stack).

After processing index i:
- Stack contains nodes on rightmost path
- For any node in stack, all left descendants are complete
- Next element will attach to rightmost position
```

## Implementation Notes

- Store parent pointers for LCA queries
- Use monotonic stack (decreasing) for construction
- Map array indices to tree nodes for queries
- For RMQ, preprocess LCA using binary lifting or Euler tour
- Cartesian Tree is unique for any array (assuming distinct elements)

