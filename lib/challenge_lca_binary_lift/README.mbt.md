# Challenge: LCA::new(Binary Lifting)

The **lowest common ancestor (LCA)** of two nodes in a tree is the deepest
node that is an ancestor of both. Binary lifting answers LCA queries in O(log n)
after O(n log n) preprocessing.

## Problem statement

Given a rooted tree, answer queries:

```
lca(u, v) = lowest common ancestor of u and v
```

## Core idea: binary lifting

Precompute a jump table:

```
up[k][v] = the 2^k-th ancestor of v
```

Then to answer LCA::new(u, v):

1. If depths differ, lift the deeper node upward to match depths.
2. Lift both nodes together from highest power to lowest, keeping them just
   below the LCA.
3. The parent of either node is the LCA.

## Diagram: example tree

```
        0
      /   \
     1     2
    / \     \
   3   4     5
      /
     6
```

- LCA::new(3, 4) = 1
- LCA::new(6, 5) = 0
- LCA::new(4, 6) = 4 (ancestor of itself)

## Example jump table (partial)

For node 6 in the tree above:

```
up[0][6] = 4   (1 step)
up[1][6] = 1   (2 steps)
up[2][6] = 0   (4 steps)
```

So lifting 6 by 3 steps uses 2 + 1: 6 -> 1 -> 0.

## Examples

### Example 1: basic queries

```mbt check
///|
test "lca example" {
  let edges : Array[(Int, Int)] = [
    (0, 1),
    (0, 2),
    (1, 3),
    (1, 4),
    (2, 5),
    (4, 6),
  ]
  let tree = @challenge_lca_binary_lift.build_lca(7, edges, 0)
  inspect(@challenge_lca_binary_lift.lca(tree, 3, 4), content="1")
  inspect(@challenge_lca_binary_lift.lca(tree, 6, 5), content="0")
}
```

### Example 2: same node

```mbt check
///|
test "lca same node" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let tree = @challenge_lca_binary_lift.build_lca(4, edges, 0)
  inspect(@challenge_lca_binary_lift.lca(tree, 2, 2), content="2")
}
```

### Example 3: ancestor relationship

```mbt check
///|
test "lca ancestor" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let tree = @challenge_lca_binary_lift.build_lca(4, edges, 0)
  inspect(@challenge_lca_binary_lift.lca(tree, 1, 3), content="1")
}
```

### Example 4: across subtrees

```mbt check
///|
test "lca across subtrees" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5)]
  let tree = @challenge_lca_binary_lift.build_lca(6, edges, 0)
  inspect(@challenge_lca_binary_lift.lca(tree, 4, 5), content="0")
}
```

## Complexity

- Preprocessing: O(n log n)
- Query: O(log n)
- Space: O(n log n)

## Practical notes and pitfalls

- The input should be a **tree** (connected and acyclic).
- The root only affects depths; LCA results are still correct.
- If nodes are in different components, LCA is undefined; avoid such queries.

## When to use it

Use binary lifting when you need many LCA queries on a static tree.
