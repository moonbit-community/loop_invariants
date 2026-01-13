# Gomory-Hu Tree

## Overview

A Gomory-Hu tree is a weighted tree that encodes **all-pairs min-cut values**
for an undirected graph. The min-cut between two vertices equals the minimum
edge weight on their path in the tree.

- **Time**: O(n · maxflow)
- **Space**: O(n + m)

## Quick Start

```mbt check
///|
test "gomory-hu tree example" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L), (1, 2, 3L), (1, 3, 1L)]
  let tree = @gomory_hu_tree.gomory_hu_tree(4, edges[:])
  inspect(tree.min_cut(0, 2), content="3")
  inspect(tree.min_cut(2, 3), content="1")
}
```

## Why It Works (Sketch)

The algorithm runs `n-1` max-flow computations. After each flow between
`s` and its current parent `t`, the resulting min-cut partitions the vertices.
We attach `s` to `t` with the cut value, and redirect other vertices to keep
the parent structure consistent. Repeating this builds a tree where the
minimum edge on the path between any two vertices equals their min-cut.

## Using the Tree

To answer `min_cut(u, v)`, walk the unique path between u and v in the tree
and take the minimum edge weight along that path.

## When to Use

- You need **all-pairs** min-cut values (not just a single source).
- The graph is undirected and capacities are non-negative.

## Notes

- Building the tree requires `n-1` max-flow computations.
- The tree has `n` vertices and `n-1` edges.
