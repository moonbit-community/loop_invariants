# Challenge: BFS on a Grid (Shortest Path)

This challenge asks you to compute the **shortest path length** on a grid with
blocked cells, moving only in 4 directions.

## Problem statement

You are given:

- a rectangular grid of 0/1 values
  - `0` = free cell
  - `1` = blocked cell
- a start cell `(sr, sc)` and a target cell `(tr, tc)`

Return the minimum number of steps to reach the target, or `None` if there is
no path.

Moves are allowed only in these 4 directions:

- up, down, left, right

## Why BFS works here

Every move has the same cost (1). In an unweighted graph, **BFS visits nodes
in increasing distance order**. The first time you visit a cell, you have found
its shortest distance.

## Think of the grid as a graph

Each open cell is a node. Each node has up to 4 neighbors (the four directions)
that are still inside the grid and not blocked. BFS on this implicit graph is
exactly the shortest-path algorithm we want.

## Algorithm outline

1. Validate bounds and check that start/target are open.
2. Use a queue for BFS.
3. Store distance in a 2D array (`-1` = unvisited).
4. Pop from the queue, and push all valid neighbors with distance + 1.
5. At the end, read the distance of the target.

## Examples

### Example 1: basic path

```mbt check
///|
test "basic path" {
  let grid : Array[Array[Int]] = [[0, 0, 0], [1, 1, 0], [0, 0, 0]]
  let dist = @challenge_bfs_grid.shortest_path_grid(grid, 0, 0, 2, 2)
  inspect(dist, content="Some(4)")
}
```

### Example 2: unreachable target

```mbt check
///|
test "unreachable" {
  let grid : Array[Array[Int]] = [[0, 1], [1, 0]]
  let dist = @challenge_bfs_grid.shortest_path_grid(grid, 0, 0, 1, 1)
  inspect(dist, content="None")
}
```

### Example 3: start equals target

```mbt check
///|
test "start is target" {
  let grid : Array[Array[Int]] = [[0, 0], [0, 0]]
  let dist = @challenge_bfs_grid.shortest_path_grid(grid, 1, 1, 1, 1)
  inspect(dist, content="Some(0)")
}
```

### Example 4: blocked start or target

```mbt check
///|
test "blocked endpoints" {
  let grid : Array[Array[Int]] = [[1, 0], [0, 0]]
  let d1 = @challenge_bfs_grid.shortest_path_grid(grid, 0, 0, 1, 1)
  let d2 = @challenge_bfs_grid.shortest_path_grid(grid, 0, 1, 0, 0)
  inspect(d1, content="None")
  inspect(d2, content="None")
}
```

## Complexity

Let `R` be the number of rows and `C` be the number of columns.

- Time: O(R * C)
- Space: O(R * C) for the queue and distance grid

## Practical notes and pitfalls

- The grid is assumed to be **rectangular**. All rows should have the same
  length.
- Mark cells as visited when you enqueue them, not when you dequeue them,
  to avoid multiple queue entries.
- Indices are `(row, col)` and must be within bounds.
