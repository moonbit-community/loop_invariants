# AVL Tree (Self-Balancing BST)

An AVL tree is a binary search tree (BST) that *keeps itself balanced* after
insertions and deletions. The benefit is predictable performance: lookups,
insertions, and deletions are always O(log n), even when the input order is
adversarial (like already-sorted data).

This package exposes a small public helper (`avl_sorted`) and contains a full
AVL implementation used in the tests. The README focuses on the ideas and
shows multiple working examples with the public API.

## Problem: a BST can become a chain

A plain BST has fast average performance, but it can become extremely tall if
keys arrive in sorted order:

```
Insert 1, 2, 3, 4

1           bf=+3  (right-heavy, height difference = 3)
 \
  2         bf=+2
   \
    3        bf=+1
     \
      4      bf= 0
```

This degenerate tree has height 4, so searches cost O(n). AVL keeps the height
bounded at O(log n) by enforcing that every node's *balance factor* stays in
{-1, 0, +1}.

## AVL idea: keep balance factors in {-1, 0, +1}

For every node, the AVL tree stores its height. The *balance factor* is:

```
balance_factor(node) = height(right_subtree) - height(left_subtree)
```

An AVL tree requires `balance_factor` to be -1, 0, or +1 for every node.
Inserting 1, 2, 3, 4 into an AVL tree produces a balanced result:

```
After inserting 1, 2, 3, 4 (AVL rebalances automatically):

      2        bf= 0
     / \
    1   3      both bf= 0
         \
          4    bf= 0

Height = 3, not 4. All balance factors are valid.
```

If an insert or delete breaks this rule (bf becomes -2 or +2), the tree fixes
itself with a rotation.

## Rotations (local fixes that preserve order)

Rotations are small pointer rearrangements that restore balance without
changing the in-order sequence of keys. There are four cases.

### Case 1: Right rotation (left-left heavy, bf = -2 at y, bf <= 0 at x)

Triggered when a node y has bf = -2 and its left child x is left-heavy or
balanced (bf <= 0).

```
Before rotation:         After right rotation:

      y  bf=-2               x  bf= 0
     / \                    / \
    x   C  bf=0 or -1      A   y  bf= 0
   / \                        / \
  A   B                      B   C

In-order stays: A, x, B, y, C
```

### Case 2: Left rotation (right-right heavy, bf = +2 at x, bf >= 0 at y)

Triggered when a node x has bf = +2 and its right child y is right-heavy or
balanced (bf >= 0).

```
Before rotation:         After left rotation:

  x  bf=+2                   y  bf= 0
 / \                         / \
A   y  bf=0 or +1           x   C
   / \                     / \
  B   C                   A   B

In-order stays: A, x, B, y, C
```

### Case 3: Left-Right rotation (bf = -2 at node, bf = +1 at left child)

Triggered by a "zig-zag" insert: insert into the right subtree of a left child.
First rotate left on the left child, then rotate right on the node.

```
Step 1 - before any rotation:       Step 2 - after left rotation on x:

      z  bf=-2                             z  bf=-2
     / \                                  / \
    x   D  bf=+1                         y   D
   / \                                  / \
  A   y                                x   C
     / \                              / \
    B   C                            A   B

Step 3 - after right rotation on z:

        y  bf= 0
       / \
      x   z
     / \ / \
    A  B C  D

In-order stays: A, x, B, y, C, z, D
```

### Case 4: Right-Left rotation (bf = +2 at node, bf = -1 at right child)

Triggered by a "zig-zag" insert: insert into the left subtree of a right child.
First rotate right on the right child, then rotate left on the node.

```
Step 1 - before any rotation:       Step 2 - after right rotation on z:

  x  bf=+2                               x  bf=+2
 / \                                    / \
A   z  bf=-1                           A   y
   / \                                    / \
  y   D                                  B   z
 / \                                        / \
B   C                                      C   D

Step 3 - after left rotation on x:

        y  bf= 0
       / \
      x   z
     / \ / \
    A  B C  D

In-order stays: A, x, B, y, C, z, D
```

## Step-by-step insertion example: inserting 3, 1, 4, 1, 5, 9, 2

Each step shows the tree shape and the balance factor (bf) at each node. A
rebalancing step is marked with `<-- rebalance`.

```
Insert 3:
  3 [bf=0]

Insert 1:
    3 [bf=-1]
   /
  1 [bf=0]

Insert 4:
    3 [bf=0]
   / \
  1   4

Insert 1 (duplicate, goes right of existing 1):
      3 [bf=-1]
     / \
    1   4
     \
      1

Insert 5:
      3 [bf=0]
     / \
    1   4 [bf=+1]
     \   \
      1   5

Insert 9:  bf at 4 becomes +2, left rotation on 4  <-- rebalance
      3 [bf=+1]
     / \
    1   5 [bf=0]    (was 4 before rotation)
     \  / \
      1 4   9

Insert 2:  bf at 1 (left of 3) becomes +2, left-right rotation  <-- rebalance
        3 [bf=0]
       / \
      1   5
     / \ / \
    1  2 4  9

Final tree (7 keys, height 3, all balance factors in {-1, 0, +1}).
In-order: 1 1 2 3 4 5 9
```

## What this package provides

`avl_sorted` inserts all keys into an AVL tree and returns the in-order
traversal. That traversal is always sorted, and duplicates are preserved.

## Examples

### Example 1: duplicates are preserved

```mbt check
///|
test "avl_sorted keeps duplicates" {
  let sorted = @avl_tree.avl_sorted([3L, 1L, 4L, 1L][:])
  inspect(sorted, content="[1, 1, 3, 4]")
}
```

### Example 2: already-sorted input still works

In a plain BST this would create a chain, but AVL rebalances internally.
You still get a correct sorted order in O(log n) time per insertion.

```mbt check
///|
test "sorted and reverse-sorted inputs" {
  // let ascending = [| for i in 0..<7 => (i + 1).to_int64() |]
  let ascending = [ for i in 1L..<8L => i ]
  let ascending_sorted = @avl_tree.avl_sorted(ascending)
  inspect(
    ascending_sorted,
    content=(
      #|[1, 2, 3, 4, 5, 6, 7]
    ),
  )
  let descending = [ for i in 8L>..1L => i ]
  let descending_sorted = @avl_tree.avl_sorted(descending)
  inspect(descending_sorted, content="[1, 2, 3, 4, 5, 6, 7]")
}
```

### Example 3: a zig-zag input (Left-Right case)

The input `[3, 1, 2]` triggers a left-right rotation internally. The AVL tree
fixes the imbalance while keeping the in-order traversal correct.

```
Insert 3:     Insert 1:     Insert 2 -> Left-Right rotation:
  3             3               2
               /               / \
              1               1   3
```

```mbt check
///|
test "zig-zag insertion input" {
  let sorted = @avl_tree.avl_sorted([3L, 1L, 2L][:])
  inspect(sorted, content="[1, 2, 3]")
}
```

### Example 4: string keys (any type with Compare)

```mbt check
///|
test "string keys" {
  let sorted = @avl_tree.avl_sorted(["pear", "plum", "kiwi", "date"][:])
  inspect(sorted, content="[\"date\", \"kiwi\", \"pear\", \"plum\"]")
}
```

### Example 5: large batch, still deterministic

Even for larger inputs, AVL keeps the height bounded and the output sorted.

```mbt check
///|
test "larger input" {
  let data = [ for i in 0..<50 => ((i * 37 + 13) % 50).to_int64() ]
  let sorted = @avl_tree.avl_sorted(data[:])
  inspect(sorted.length(), content="50")
  inspect(sorted[0], content="0")
  inspect(sorted[49], content="49")
}
```

## How deletion is handled (conceptual)

Deletion in AVL follows standard BST deletion, then rebalances:

1. Remove the node (or swap with its inorder successor if it has two children).
2. Update heights on the path back to the root.
3. Perform rotations when a balance factor becomes -2 or +2.

```
Delete 5 from:              Rebalance (right rotation on 7):

      5 [bf=+1]                    7 [bf=0]
     / \                          / \
    3   7 [bf=-1]                3   9
       / \                      / \
      6   9                    2   4
     ...

The path from the deleted node (5) to the root is the only place that can
become unbalanced, so the fix remains O(log n).
```

## Complexity

| Operation | Time     | Notes                                    |
|-----------|----------|------------------------------------------|
| Insert    | O(log n) | At most one rotation sequence per insert |
| Search    | O(log n) | Guaranteed by height bound               |
| Delete    | O(log n) | May trigger rotations up to root         |
| Space     | O(n)     | One node per key                         |

## When to use AVL

Use AVL trees when you need strict worst-case bounds on lookup time. AVL trees
keep a tighter balance than red-black trees (height <= 1.44 log n vs
2 log n), so they are faster for read-heavy workloads. If you expect heavy
updates and slightly looser balancing is acceptable, a red-black tree may
perform fewer rotations per insertion in practice.
