# Challenge: DFS Subtree Sizes

This challenge computes subtree sizes in a rooted tree using DFS. Each node's
subtree size is the number of nodes in its subtree (including itself).

## Problem statement

Given a tree as an undirected adjacency list and a chosen root, compute:

```
size[u] = number of nodes in the subtree of u (rooted at root)
```

## Core idea

A node's subtree size is:

```
size[u] = 1 + sum(size[v]) for all children v of u
```

So we do a DFS, record a traversal order, and then process nodes in reverse
order (post-order).

## Diagram: example tree

```
      0
     / \
    1   2
   / \   \
  3   4   5
           \
            6
```

Root = 0.

Subtree sizes:

- size[3] = 1
- size[4] = 1
- size[1] = 1 + 1 + 1 = 3
- size[6] = 1
- size[5] = 1 + 1 = 2
- size[2] = 1 + 2 = 3
- size[0] = 1 + 3 + 3 = 7

## How the algorithm works

1. DFS from the root and record nodes in the order they are discovered.
2. Process that order backwards so children are handled before parents.
3. For each node, start at 1 and add sizes of its children.

The implementation uses an explicit stack to avoid recursion.

## Examples

### Example 1: small tree

```mbt check
///|
test "dfs subtree basic" {
  let adj : Array[Array[Int]] = [[1, 2], [0], [0, 3], [2]]
  let size = @challenge_dfs_subtree.subtree_sizes(adj, 0)
  inspect(size, content="[4, 1, 2, 1]")
}
```

### Example 2: chain with middle root

```
0 - 1 - 2
```

Root at 1.

```mbt check
///|
test "dfs subtree chain" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [1]]
  let size = @challenge_dfs_subtree.subtree_sizes(adj, 1)
  inspect(size, content="[1, 3, 1]")
}
```

### Example 3: larger tree

```mbt check
///|
test "dfs subtree larger" {
  let adj : Array[Array[Int]] = [
    [1, 2], // 0
    [0, 3, 4], // 1
    [0, 5], // 2
    [1], // 3
    [1], // 4
    [2, 6], // 5
    [5], // 6
  ]
  let size = @challenge_dfs_subtree.subtree_sizes(adj, 0)
  inspect(size, content="[7, 3, 3, 1, 1, 2, 1]")
}
```

## Complexity

- Time: O(n)
- Space: O(n)

## Practical notes and pitfalls

- The input graph must be a tree (connected and acyclic).
- The adjacency list is undirected, so track the parent to avoid revisiting.
- If the root is invalid, this implementation returns an empty array.

## When to use it

Subtree sizes are a common building block for tree DP, centroid decomposition,
and many range or path problems on trees.
