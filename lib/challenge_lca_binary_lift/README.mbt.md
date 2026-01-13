# Challenge: LCA (Binary Lifting)

Lowest common ancestor with O(log n) queries after preprocessing.

## Core Idea

Precompute `up[k][v]` = the 2^k-th ancestor of node v, along with depths.
To answer LCA(u, v):

1. Lift the deeper node up to the same depth.
2. Lift both nodes from highest power to lowest so they stay below the LCA.
3. Their parents then match and give the LCA.

## Example

```mbt check
///|
test "lca example" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5)]
  let tree = @challenge_lca_binary_lift.build_lca(6, edges[:], 0)
  inspect(@challenge_lca_binary_lift.lca(tree, 3, 4), content="1")
}
```

## Another Example

```mbt check
///|
test "lca across subtrees" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5)]
  let tree = @challenge_lca_binary_lift.build_lca(6, edges[:], 0)
  inspect(@challenge_lca_binary_lift.lca(tree, 4, 5), content="0")
}
```

## Notes

- Preprocessing is O(n log n).
- Each query is O(log n).
