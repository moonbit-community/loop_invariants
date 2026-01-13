# Treap (Randomized BST)

## Overview

A **Treap** combines a Binary Search Tree (BST) with a Heap using random priorities.
This randomization ensures **expected O(log n)** height without complex rebalancing.

- **Insert/Delete/Search**: O(log n) expected
- **Order statistics**: O(log n)
- **Space**: O(n)

## The Key Insight

Each node has two properties:
1. **Key**: Satisfies BST property (left < key < right)
2. **Priority**: Random value satisfying max-heap property (parent ≥ children)

```
        (5, p=90)           BST order: 2 < 5 < 8
        /       \           Heap order: 90 > 70, 90 > 45
   (2, p=70)  (8, p=45)
```

The random priorities keep the tree balanced **with high probability**.

## Quick Start Tutorial

### 1) Insert and Search

```mbt check
///|
test "treap quick start" {
  let t = @treap.Treap::new()
  t.insert(5L)
  t.insert(3L)
  t.insert(7L)
  t.insert(1L)
  t.insert(9L)
  inspect(t.size(), content="5")
  inspect(t.contains(5L), content="true")
  inspect(t.contains(10L), content="false")
}
```

### 2) Delete a Key

```mbt check
///|
test "treap delete example" {
  let t = @treap.Treap::new()
  t.insert(5L)
  t.insert(3L)
  t.insert(7L)
  inspect(t.delete(3L), content="true")
  inspect(t.contains(3L), content="false")
  inspect(t.size(), content="2")
}
```

### 3) Order Statistics (k-th and rank)

```mbt check
///|
test "treap order statistics" {
  let t = @treap.Treap::new()
  t.insert(5L)
  t.insert(3L)
  t.insert(7L)
  t.insert(1L)
  t.insert(9L)
  inspect(t.kth_element(0), content="Some(1)")
  inspect(t.kth_element(2), content="Some(5)")
  inspect(t.kth_element(4), content="Some(9)")
  inspect(t.kth_element(5), content="None")
  inspect(t.count_less_than(5L), content="2")
  inspect(t.count_less_than(10L), content="5")
}
```

### 4) Min/Max and Inorder Traversal

```mbt check
///|
test "treap min max and to_array" {
  let t = @treap.Treap::new()
  t.insert(5L)
  t.insert(3L)
  t.insert(7L)
  t.insert(1L)
  t.insert(9L)
  inspect(t.min(), content="Some(1)")
  inspect(t.max(), content="Some(9)")
  inspect(t.to_array(), content="[1, 3, 5, 7, 9]")
}
```

## Structure Visualization

```
Insert keys: 5, 3, 7, 2, 4 with random priorities

Step 1: Insert 5                    Step 2: Insert 3 (priority > 5's)
        (5, p=50)                           (3, p=80)
                                                  \
                                               (5, p=50)

Step 3: Insert 7                    Final tree depends on priorities!
        (3, p=80)
             \                      With priorities [50, 80, 30, 90, 40]:
          (5, p=50)                         (2, p=90)
                \                                  \
             (7, p=30)                          (3, p=80)
                                                     \
                                                  (5, p=50)
                                                  /      \
                                             (4, p=40) (7, p=30)
```

## Split and Merge Operations

Treap operations are elegantly built on **split** and **merge**:

### Split(tree, key) → (left, right)
Divides tree into keys < key and keys ≥ key.

```
Split at key=5:

        (3, p=80)                  Left tree:        Right tree:
            \                         (3)               (7)
         (7, p=50)          →            \
         /      \                      (4)
      (4)      (9)
                                      All keys < 5    All keys ≥ 5
```

### Merge(left, right) → tree
Combines two trees where all keys in left < all keys in right.

```
Merge uses priorities to decide root:

Left:        Right:           If left.priority > right.priority:
  (3, p=80)    (7, p=50)              (3, p=80)
      \                                    \
    (4, p=40)                          merge(4, (7,9))

                              Result:
                                  (3, p=80)
                                       \
                                    (7, p=50)
                                    /      \
                                 (4)      (9)
```

## Insert Using Split/Merge

```
Insert key k with random priority p:
1. split(root, k) → (left, right)
2. root = merge(merge(left, new_node(k,p)), right)

Insert 6:
        (5)                    Split at 6:
       /   \                   left=(5,4)  right=(8)
     (4)   (8)
                               merge(merge(left, 6), right)
                                       (5)
                                      /   \
                                    (4)   (6)
                                            \
                                           (8)
```

## Delete Using Split/Merge

```
Delete key k:
1. split(root, k) → (left, mid_and_right)
2. split(mid_and_right, k+1) → (mid, right)
3. root = merge(left, right)    // mid (containing k) is discarded

Delete 6:
Split at 6, then at 7:
  left = keys < 6
  mid = keys == 6 (discarded)
  right = keys > 6

Merge left and right: done!
```

## Why Randomization Works

Expected tree height is O(log n) because:
- Random priorities create a structure equivalent to a randomly built BST
- Probability of highly unbalanced tree is exponentially small

```
With n insertions, expected height ≈ 2 ln(n) ≈ 1.39 log₂(n)

This matches the performance of AVL/Red-Black trees without
the complexity of maintaining balance invariants!
```

## Common Applications

1. **Order Statistics**
   - Find k-th smallest element in O(log n)
   - Count elements less than x

2. **Dynamic Sorted Set**
   - Insert/delete in O(log n)
   - No worst-case O(n) like naive BST

3. **Range Operations**
   - Split to extract a range
   - Merge to combine results

4. **Implicit Treap (Rope)**
   - Index-based operations on sequences
   - Efficient string editing

## Complexity Analysis

| Operation | Expected Time | Worst Case |
|-----------|---------------|------------|
| Insert    | O(log n)      | O(n)*      |
| Delete    | O(log n)      | O(n)*      |
| Search    | O(log n)      | O(n)*      |
| Split     | O(log n)      | O(n)*      |
| Merge     | O(log n)      | O(n)*      |
| k-th element | O(log n)   | O(n)*      |

*Worst case is extremely unlikely with good random priorities.

## Treap vs Other BSTs

| Structure    | Insert    | Delete    | Search    | Code Complexity |
|--------------|-----------|-----------|-----------|-----------------|
| **Treap**    | O(log n)* | O(log n)* | O(log n)* | Simple          |
| AVL Tree     | O(log n)  | O(log n)  | O(log n)  | Moderate        |
| Red-Black    | O(log n)  | O(log n)  | O(log n)  | Complex         |
| Splay Tree   | O(log n)† | O(log n)† | O(log n)† | Moderate        |
| Skip List    | O(log n)* | O(log n)* | O(log n)* | Simple          |

*Expected time, †Amortized time

**Choose Treap when**: You want balanced BST performance with simple implementation.

## Implementation Notes

- Random priority generator should be fast (LCG works well)
- Store subtree sizes for order statistics
- Split/merge approach is more elegant than rotations
- Can support duplicates by allowing equal keys
