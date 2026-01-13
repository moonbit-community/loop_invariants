# Challenge: Tree Diameter

Two BFS/DFS sweeps to find the longest path length in a tree.

## Core Idea

Pick any node, run BFS/DFS to find the farthest node `A`.  
Run BFS/DFS again from `A`; the farthest node `B` is an endpoint of the
diameter, and the distance `dist(A, B)` is the diameter length.

Why this works: the farthest node from any start must be an endpoint of some
diameter in a tree.

## Example

```mbt check
///|
test "tree diameter example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  inspect(@challenge_tree_diameter.tree_diameter(5, edges[:]), content="4")
}
```

## Another Example

```mbt check
///|
test "tree diameter star" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
  inspect(@challenge_tree_diameter.tree_diameter(4, edges[:]), content="2")
}
```

## Notes

- The tree is assumed to be connected.
- Edge count must be `n-1`.
