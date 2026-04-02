# Challenge: Tree Diameter (Two BFS)

The **diameter** of a tree is the length of the longest path between any two
nodes.

This package computes the diameter length using two BFS passes.

This package provides:

- `tree_diameter(n, edges)`

---

## Core idea

For a tree:

1. Pick any node `s` and run BFS to find the farthest node `A`.
2. Run BFS again from `A` to find the farthest node `B`.
3. The distance from `A` to `B` is the diameter length.

Why it works: in a tree, the farthest node from any start is always an endpoint
of some diameter.

---

## Visual intuition

Example chain:

```
0 - 1 - 2 - 3 - 4
```

- Start from `0`, farthest is `4`.
- Start from `4`, farthest is `0`.
- Distance is 4 edges (the diameter).

Example star:

```
    1
    |
2 - 0 - 3
    |
    4
```

The longest path goes between any two leaves, e.g. `1 -> 0 -> 3`, so the
length is 2.

---

## API summary

- Two BFS passes: `O(n)` time
- Adjacency list: `O(n)` memory

---

## Example 1: Chain

```mbt check
///|
test "tree diameter chain" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  inspect(@challenge_tree_diameter.tree_diameter(5, edges[:]), content="4")
}
```

---

## Example 2: Star

```mbt check
///|
test "tree diameter star" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
  inspect(@challenge_tree_diameter.tree_diameter(4, edges[:]), content="2")
}
```

---

## Example 3: Single node

```mbt check
///|
test "tree diameter single" {
  let edges : Array[(Int, Int)] = []
  inspect(@challenge_tree_diameter.tree_diameter(1, edges[:]), content="0")
}
```

---

## When to use this algorithm

Use this when you need the longest path in a tree. It is simple, fast, and
works for any connected tree with `n - 1` edges.

If the graph is not a tree, you need different techniques (e.g., for general
graphs, diameter is harder).

---

## Reference implementation

```mbt nocheck
///| pub fn tree_diameter(n : Int, edges : ArrayView[(Int, Int)]) -> Int
```
