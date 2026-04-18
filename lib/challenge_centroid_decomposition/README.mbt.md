# Challenge: Centroid Decomposition

Centroid decomposition breaks a tree into smaller pieces by repeatedly removing
**centroid** nodes. The removed centroids form a new tree (the centroid tree)
whose height is O(log n).

This challenge builds the centroid tree and returns two arrays:

- `parent[v]`: centroid parent of v (or -1 for the root of the centroid tree)
- `level[v]`: depth of v in the centroid tree

## What is a centroid?

For a tree with `n` nodes, a **centroid** is a node such that when you remove
it, every remaining component has size at most `n/2`.

Every tree has at least one centroid. Some trees have two (adjacent) centroids;
either choice is valid.

## Decomposition algorithm

For each subtree:

1. Compute subtree sizes.
2. Find a centroid `c` of that subtree.
3. Mark `c` as removed.
4. Recurse on each remaining component, setting their centroid parent to `c`.

Because each component is at most half the size, the centroid tree height is
O(log n).

## Diagram: path of 5 nodes

Tree:

```
0 - 1 - 2 - 3 - 4
```

Centroid is `2` (unique). After removing `2`, we recurse on the two halves:

```
centroid tree:

    2
   / \
  1   3
  |   |
  0   4
```

## Diagram: balanced binary tree (7 nodes)

Tree:

```
      0
     / \
    1   2
   / \ / \
  3  4 5  6
```

Centroid is `0` (each side has size 3). After removing 0, each side is size 3
and has its own centroid (1 and 2):

```
centroid tree:

    0
   / \
  1   2
```

(Leaves 3,4 attach under 1; leaves 5,6 attach under 2.)

## Examples

### Example 1: path of 5 nodes

```mbt check
///|
test "centroid decomposition path" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let cd = @challenge_centroid_decomposition.build_centroid(5, edges)
  inspect(cd.parent[2], content="-1")
  inspect(cd.level[2], content="0")
}
```

### Example 2: star

```
    1
    |
2 - 0 - 3
    |
    4
```

```mbt check
///|
test "centroid decomposition star" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let cd = @challenge_centroid_decomposition.build_centroid(5, edges)
  inspect(cd.parent[0], content="-1")
  inspect(cd.level[0], content="0")
  inspect(cd.parent[1], content="0")
}
```

### Example 3: balanced tree

```mbt check
///|
test "centroid decomposition balanced" {
  let edges : Array[(Int, Int)] = [
    (0, 1),
    (0, 2),
    (1, 3),
    (1, 4),
    (2, 5),
    (2, 6),
  ]
  let cd = @challenge_centroid_decomposition.build_centroid(7, edges)
  inspect(cd.parent[0], content="-1")
  inspect(cd.level[0], content="0")
  inspect(cd.parent[1], content="0")
  inspect(cd.parent[2], content="0")
  inspect(cd.level[1], content="1")
  inspect(cd.level[2], content="1")
}
```

## Complexity

- Each decomposition step removes one centroid.
- Each node participates in O(log n) levels.

Overall:

- Time: O(n log n)
- Space: O(n)

## Practical notes and pitfalls

- This method assumes a **tree** (connected and acyclic).
- If there are two centroids, the algorithm may choose either; do not rely on a
  specific choice in tests unless the centroid is unique.
- `level[v]` is depth in the centroid tree, not the original tree.

## When to use it

Centroid decomposition is useful for distance and path queries on static trees,
where you can aggregate information along centroid ancestors in O(log n).
