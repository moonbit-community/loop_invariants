# Gomory-Hu Tree

## Overview

A Gomory-Hu tree is a weighted tree that encodes **all-pairs min-cut values**
for an undirected graph. The min-cut between two vertices equals the minimum
edge weight on their path in the tree.

- **Time**: O(n · maxflow)
- **Space**: O(n + m)

## Example

```mbt check
///|
test "gomory-hu tree example" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L), (1, 2, 3L), (1, 3, 1L)]
  let tree = @gomory_hu_tree.gomory_hu_tree(4, edges[:])
  inspect(tree.min_cut(0, 2), content="3")
  inspect(tree.min_cut(2, 3), content="1")
}
```
