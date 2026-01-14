# Treap (Randomized BST)

## Overview

A **Treap** combines a Binary Search Tree (BST) with a Heap using random priorities.
This randomization ensures **expected O(log n)** height without complex rebalancing
rotations like AVL or Red-Black trees.

- **Insert/Delete/Search**: O(log n) expected
- **Order statistics**: O(log n)
- **Space**: O(n)
- **Key Feature**: Simple implementation with balanced performance

Treap is generic over the key type: `Treap[T]` where `T : Compare`.

## The Key Insight

```
Problem: BSTs can become unbalanced (O(n) height) with adversarial input

AVL/Red-Black solution: Complex rotation rules to maintain balance

Treap insight: Use RANDOMIZATION instead of complex rules!
  - Give each node a random "priority"
  - Maintain BST property by key
  - Maintain max-heap property by priority
  - Random priorities → expected O(log n) height

The structure is equivalent to inserting keys in random order!
```

## Understanding the Two Properties

```
Each node has:
  - key: determines BST order (left < node < right)
  - priority: random value, determines heap order (parent > children)

Example treap with keys and priorities:

        (key=5, pri=90)        BST check: 2 < 5 < 8 ✓
        /           \          Heap check: 90 > 70, 90 > 45 ✓
  (key=2, pri=70) (key=8, pri=45)

The random priorities act like "timestamps" that determine
which node becomes an ancestor of which.
```

## Why Random Priorities Give O(log n) Height

```
Key theorem: A treap has the same structure as a BST built by
inserting keys in order of DECREASING priority.

If priorities are random, this is equivalent to random insertion order!

Random BST analysis:
  - Expected depth of any node: O(log n)
  - Expected height of tree: ~2 ln(n) ≈ 1.39 log₂(n)
  - Probability of height > c·log(n): exponentially small in c

No adversarial input can defeat this because YOU control the randomness,
not the input provider!
```

## Visual: How Priorities Determine Structure

```
Keys to insert: 1, 2, 3, 4, 5 (worst case for naive BST!)

Naive BST (no priorities):     Treap with random priorities:
      1                        Suppose priorities are:
       \                         1→30, 2→90, 3→50, 4→70, 5→10
        2
         \                     Build by decreasing priority order:
          3                    2(90), 4(70), 3(50), 1(30), 5(10)
           \
            4                        (2, pri=90)
             \                      /          \
              5                (1, pri=30)  (4, pri=70)
                                            /        \
Height = 5 (O(n)!)                    (3, pri=50)  (5, pri=10)

                               Height = 3 (O(log n)!)
```

## Core Operations: Split and Merge

Unlike AVL/Red-Black trees that use rotations, treaps use **split** and **merge**:

### Split(tree, key) → (left, right)

Divides tree into two parts:
- `left`: all nodes with key < given key
- `right`: all nodes with key ≥ given key

```
Split at key=6:

        (5, p=90)                  left:           right:
       /        \                   (5, p=90)       (8, p=70)
  (3, p=50)  (8, p=70)      →      /                    \
      \      /     \           (3, p=50)            (9, p=30)
   (4,p=20)(7,p=40)(9,p=30)        \
                                (4, p=20)

All keys < 6              All keys ≥ 6
```

### Split Algorithm Walkthrough

```
split(root, key):
  if root is null: return (null, null)

  if root.key < key:
    // Root goes to left tree
    // Recursively split right subtree
    (left_part, right_part) = split(root.right, key)
    root.right = left_part
    return (root, right_part)
  else:
    // Root goes to right tree
    // Recursively split left subtree
    (left_part, right_part) = split(root.left, key)
    root.left = right_part
    return (left_part, root)

Time: O(height) = O(log n) expected
```

### Merge(left, right) → tree

Combines two trees where ALL keys in left < ALL keys in right.
Uses priorities to decide which root is on top.

```
Merge left and right trees:

left:           right:
  (3, p=80)       (7, p=50)
      \               \
   (5, p=40)       (9, p=30)

Compare priorities: 80 > 50, so (3, p=80) becomes root
Recursively merge (5, p=40) with (7, p=50) subtree:
  Compare: 50 > 40, so (7, p=50) wins
  Recursively merge (5, p=40) with null, and (9, p=30)

Result:
        (3, p=80)
              \
           (7, p=50)
           /      \
      (5, p=40) (9, p=30)
```

### Merge Algorithm

```
merge(left, right):
  if left is null: return right
  if right is null: return left

  if left.priority > right.priority:
    // left root becomes the overall root
    left.right = merge(left.right, right)
    return left
  else:
    // right root becomes the overall root
    right.left = merge(left, right.left)
    return right

Time: O(height of result) = O(log n) expected
```

### Why Merge Preserves Both Invariants

```
BST property: Guaranteed by precondition that all keys in left < all keys in right
  - Left subtree of result has keys from left tree (smaller)
  - Right subtree has keys from right tree (larger)

Heap property: We always choose the higher-priority node as root
  - Recursive calls maintain this for subtrees
  - Each level picks the max-priority available node
```

## Insert Using Split/Merge

```
insert(key):
  1. Create new node with key and RANDOM priority
  2. Split tree at key → (left, right)
  3. Merge: tree = merge(merge(left, new_node), right)

Visual for inserting 6:

Original:           Split at 6:              After merge:
    (5, p=90)       left:    right:              (5, p=90)
   /        \        (5)      (8)               /        \
 (3)       (8)       / \        \             (3)       (8)
                   (3) (4)     (9)            / \       /  \
                                            (4) (6)←new (9)
```

## Delete Using Split/Merge

```
delete(key):
  1. Split at key → (left, mid_and_right)
  2. Split mid_and_right at key+ε → (mid, right)
     (mid contains nodes with exactly this key)
  3. If deleting one copy: mid = merge(mid.left, mid.right)
  4. Return merge(left, merge(mid, right))

For deleting ALL copies of key:
  3. Simply discard mid entirely
  4. Return merge(left, right)
```

## Quick Start Tutorial

### 0) Empty Treap

```mbt check
///|
test "treap empty" {
  let t : @treap.Treap[Int64] = @treap.Treap::new()
  inspect(t.size(), content="0")
  inspect(t.min(), content="None")
  inspect(t.max(), content="None")
  inspect(t.kth_element(0), content="None")
}
```

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

### 2b) Duplicates (delete removes one copy)

```mbt check
///|
test "treap duplicates" {
  let t = @treap.Treap::new()
  t.insert(5L)
  t.insert(5L)
  t.insert(5L)
  inspect(t.size(), content="3")
  inspect(t.delete(5L), content="true")
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

## Order Statistics: How They Work

```
Each node stores subtree_size = 1 + left.size + right.size

To find k-th element (0-indexed):
  if k < left.size:
    return find_kth(left, k)
  else if k == left.size:
    return current node
  else:
    return find_kth(right, k - left.size - 1)

To count elements less than x:
  if current.key >= x:
    return count_less(left, x)
  else:
    return left.size + 1 + count_less(right, x)

Both operations: O(log n) expected
```

## Visual: Subtree Sizes for Order Statistics

```
Treap with subtree sizes:

        (5, size=5)
       /           \
  (3, size=2)   (8, size=2)
    /               \
 (1, size=1)     (9, size=1)

kth_element(2):  // Find 3rd smallest (0-indexed)
  At (5): left.size = 2, k = 2
    k == left.size → return 5 ✓

kth_element(3):  // Find 4th smallest
  At (5): left.size = 2, k = 3
    k > left.size → go right, k = 3 - 2 - 1 = 0
  At (8): left.size = 0, k = 0
    k == left.size → return 8 ✓
```

## Split/Merge vs Rotation-Based Approach

```
Rotation approach (like AVL):
  - Insert at leaf, then rotate up to restore balance
  - Delete at node, swap with successor, rotate to restore
  - Need to handle many cases (LL, LR, RL, RR rotations)

Split/Merge approach:
  - Insert: split at key, merge three pieces
  - Delete: split at key, split again, merge two pieces
  - Only TWO operations to implement!

Split/Merge is simpler and equally efficient.
The elegance comes from treating the tree as a "sequence"
that can be cut and concatenated.
```

## Common Applications

### 1. Order Statistics
```
Find k-th smallest element in O(log n).
Count elements less than x.
Essential for competitive programming!
```

### 2. Dynamic Sorted Set
```
Insert/delete in O(log n) expected.
No worst-case O(n) like naive BST.
Simpler than AVL/Red-Black.
```

### 3. Range Operations
```
Split to extract a range [l, r].
Perform operation on extracted subtree.
Merge back into main tree.
```

### 4. Implicit Treap (Rope)
```
Use position as implicit key (not stored explicitly).
Supports:
  - Insert/delete at position: O(log n)
  - Reverse a range: O(log n)
  - Move a range: O(log n)
Efficient for text editors, rope data structures.
```

### 5. Persistent Treap
```
Copy-on-write for functional persistence.
Keep old versions while making new modifications.
Each operation creates O(log n) new nodes.
```

## Complexity Analysis

| Operation | Expected Time | Worst Case |
|-----------|---------------|------------|
| Insert    | O(log n)      | O(n)*      |
| Delete    | O(log n)      | O(n)*      |
| Search    | O(log n)      | O(n)*      |
| Split     | O(log n)      | O(n)*      |
| Merge     | O(log n)      | O(n)*      |
| k-th element | O(log n)   | O(n)*      |
| count_less_than | O(log n) | O(n)*    |

*Worst case requires all random priorities to be in sorted order—
probability is 1/n!, essentially impossible for large n.

## Treap vs Other BSTs

| Structure    | Insert    | Delete    | Search    | Code Complexity |
|--------------|-----------|-----------|-----------|-----------------|
| **Treap**    | O(log n)* | O(log n)* | O(log n)* | Simple          |
| AVL Tree     | O(log n)  | O(log n)  | O(log n)  | Moderate        |
| Red-Black    | O(log n)  | O(log n)  | O(log n)  | Complex         |
| Splay Tree   | O(log n)† | O(log n)† | O(log n)† | Moderate        |
| Skip List    | O(log n)* | O(log n)* | O(log n)* | Simple          |

*Expected time, †Amortized time

**Choose Treap when**: You want balanced BST performance with simple implementation,
or need split/merge operations for range queries.

## Probability Analysis

```
Why is the treap almost certainly balanced?

Expected height: E[height] = O(log n)

More precisely: Pr[height > c · ln(n)] ≤ n^(1-c) for c > 1

For n = 10^6 nodes:
  Pr[height > 100] < 10^(-6)
  Pr[height > 200] < 10^(-30)

The probability of a badly unbalanced treap is astronomically small!
```

## Implementation Notes

- Random priority generator should be fast (LCG or xorshift works well)
- Store subtree sizes for order statistics
- Split/merge approach is more elegant than rotations
- Can support duplicates by allowing equal keys
- Update subtree sizes after every split/merge

## Advanced: Implicit Keys

```
For sequence operations (like a rope):
  - Don't store keys explicitly
  - Position in inorder traversal IS the key
  - Split by count, not by key value

This enables:
  - Insert at position i
  - Delete at position i
  - Reverse range [l, r]
  - All in O(log n)!
```

