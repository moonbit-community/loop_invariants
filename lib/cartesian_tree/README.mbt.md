# Cartesian Tree

## What It Is

A **Cartesian Tree** is a binary tree built from an array that satisfies two
properties at the same time:

1. **In-order property**: in-order traversal yields the original array order.
2. **Heap property**: each node is the minimum (or maximum) in its subtree.

This makes it a natural tool for **Range Minimum Query (RMQ)**.

## The Problem

Given an array `arr`, answer queries like:

```
min(arr[l..r])
```

Many queries should be fast after preprocessing.

## Key Insight

Because the tree is a heap by value and keeps array order, the **minimum
on a range [l, r]** is the **Lowest Common Ancestor (LCA)** of the nodes at
indices `l` and `r`.

So RMQ becomes:

```
RMQ(l, r) = LCA(node[l], node[r])
```

## Properties (Easy to Remember)

For an array `arr` and its Cartesian tree:

- The root is the global minimum of the array.
- The left subtree contains exactly the elements left of the minimum.
- The right subtree contains exactly the elements right of the minimum.
- In-order traversal returns the original array.

Example:

```
Array: [3, 2, 6, 1, 9]

Cartesian Tree (min-heap):
        1 (idx 3)
       / \
      2   9
     / \
    3   6

In-order: 3, 2, 6, 1, 9  ✓
```

## O(n) Construction (Monotonic Stack)

We build the tree in one pass.

Algorithm idea:

- Keep a stack of indices with **increasing values**.
- For each new value, pop all larger values.
- The last popped node becomes the left child.
- The new node becomes the right child of the remaining top (if any).

Why this works:

- The stack represents the **rightmost path** of the tree so far.
- Each index is pushed once and popped once → O(n).

## RMQ via LCA

After building the tree, preprocess it for LCA (e.g., binary lifting or Euler
Tour + RMQ). Then:

```
RMQ(l, r) = value at LCA(node[l], node[r])
```

This gives **O(1)** or **O(log n)** queries depending on the LCA method.

## Example

```mbt check
///|
test "cartesian tree rmq example" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  inspect(@cartesian_tree.range_min(arr[:], 1, 3), content="Some(1)")
  inspect(@cartesian_tree.range_min(arr[:], 0, 2), content="Some(2)")
}
```

## Complexity

- Build tree: **O(n)**
- LCA preprocessing: **O(n log n)** (or **O(n)** with Euler tour)
- RMQ query: **O(1)** (after preprocessing)

## Common Applications

- **Range Minimum Query** (classic use)
- **Largest rectangle in histogram** (nearest smaller to left/right)
- **Treaps** (Cartesian tree with random priorities)

## Pitfalls

- If values are not distinct, define a tie-breaking rule (e.g., smaller index
  wins) so the tree is deterministic.
- For RMQ, be consistent about inclusive ranges and index order.

## When to Use

Choose a Cartesian tree when you need:

- Many RMQ queries
- Optimal preprocessing + query time
- A structure that preserves array order
