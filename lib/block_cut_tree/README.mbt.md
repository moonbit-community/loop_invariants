# Block-Cut Tree

## Problem

We want a structure that shows **how articulation points connect biconnected blocks**.
This makes connectivity questions easier because the result is a tree.

## Simple Idea

1. Find all **biconnected components** (blocks)
2. Find all **articulation points** (cut vertices)
3. Build a bipartite tree:
   - One node per block
   - One node per articulation point
   - Connect a block to every articulation point it contains

The result is a tree (or forest).

## Complexity

- Time: **O(V + E)**
- Space: **O(V + E)**

## Example

```mbt check
///|
test "block-cut tree example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let tree = @block_cut_tree.build_block_cut_tree(4, edges[:])
  let comp0 = 4
  let comp1 = 5
  let comp0_tri = tree.adj[comp0].length() == 3 &&
    tree.adj[comp0].contains(0) &&
    tree.adj[comp0].contains(1) &&
    tree.adj[comp0].contains(2)
  let comp1_tri = tree.adj[comp1].length() == 3 &&
    tree.adj[comp1].contains(0) &&
    tree.adj[comp1].contains(1) &&
    tree.adj[comp1].contains(2)
  let comp0_edge = tree.adj[comp0].length() == 2 &&
    tree.adj[comp0].contains(1) &&
    tree.adj[comp0].contains(3)
  let comp1_edge = tree.adj[comp1].length() == 2 &&
    tree.adj[comp1].contains(1) &&
    tree.adj[comp1].contains(3)
  assert_true((comp0_tri && comp1_edge) || (comp1_tri && comp0_edge))
}
```

## When to Use

Use block-cut trees when you need:

- Articulation-aware connectivity queries
- Decomposition into 2-vertex-connected blocks
- A tree structure for easier LCA / path queries
