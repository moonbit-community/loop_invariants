# AVL Tree (Balanced BST)

## Problem

We want a binary search tree that keeps operations fast **even after many inserts**.
Plain BSTs can become a chain and slow down to O(n).

## Simple Solution

An **AVL tree** keeps every node almost balanced:

> The height difference between left and right is at most 1.

After every insert (or delete), we **rotate** to restore this rule.

## How It Works

### 1. Track height and balance

```
balance = height(right) - height(left)
valid: -1, 0, +1
```

### 2. After insert

Walk upward:

1. Update height
2. Compute balance
3. If balance is outside [-1, 1], rotate

### 3. Rotations

- **Left rotation** fixes a right-heavy node
- **Right rotation** fixes a left-heavy node
- **Double rotation** fixes zig-zag shapes

You only rotate a few nodes, so it stays fast.

## Example

```mbt check
///|
test "avl tree example" {
  let sorted = @avl_tree.avl_sorted([3L, 1L, 4L, 1L][:])
  inspect(sorted, content="[1, 1, 3, 4]")
}
```

## Complexity

- Insert/Search/Delete: **O(log n)**
- Space: **O(n)**

The tree height is always O(log n), so operations stay fast.

## When to Use

Use AVL when:

- You want **guaranteed** O(log n)
- Reads are frequent and must be fast

If writes are much more frequent, a red-black tree may be cheaper to update.
