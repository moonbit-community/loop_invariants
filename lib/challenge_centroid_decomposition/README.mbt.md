# Challenge: Centroid Decomposition

Decompose a tree into a centroid tree with parent and level arrays.

## Core Idea

For each subtree:
1. Compute subtree sizes.
2. Find a centroid (no child subtree exceeds half the size).
3. Remove the centroid and recurse on each component.

The resulting centroid tree has height O(log n), which makes it useful for
distance queries, path counting, and dynamic updates on trees.

## Example

```mbt check
///|
test "centroid decomposition example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let cd = @challenge_centroid_decomposition.build_centroid(5, edges[:])
  inspect(cd.level[2] == 0, content="true")
}
```

## Another Example

```mbt check
///|
test "centroid root" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let cd = @challenge_centroid_decomposition.build_centroid(5, edges[:])
  inspect(cd.parent[2] == -1, content="true")
}
```

## Notes

- The centroid is stored with `parent = -1`.
- `level[v]` is the depth in the centroid tree.
