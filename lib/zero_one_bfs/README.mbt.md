# 0-1 BFS

## Overview

0-1 BFS computes single-source shortest paths in a graph where every edge
weight is either 0 or 1. It replaces Dijkstra's priority queue with a deque:

- **weight = 0** → push neighbor to front
- **weight = 1** → push neighbor to back

This preserves nondecreasing distances in the deque and runs in linear time.

- **Time**: O(V + E)
- **Space**: O(V + E)

## Core Idea

- Maintain a deque of nodes in **nondecreasing distance** order.
- Edge weight 0 goes to front; weight 1 goes to back.
- Each edge is relaxed once, giving linear time.

## Example

```mbt check
///|
test "0-1 bfs example" {
  let g = @zero_one_bfs.Graph::new(5)
  g.add_edge(0, 1, 0)
  g.add_edge(1, 2, 1)
  g.add_edge(0, 2, 1)
  g.add_edge(2, 3, 0)
  g.add_edge(1, 3, 1)
  g.add_edge(3, 4, 1)
  let dist = @zero_one_bfs.zero_one_bfs(g, 0)
  inspect(dist, content="[0, 0, 1, 1, 2]")
}
```

## Another Example

```mbt check
///|
test "0-1 bfs undirected" {
  let g = @zero_one_bfs.Graph::new(4)
  g.add_undirected_edge(0, 1, 0)
  g.add_undirected_edge(1, 2, 1)
  g.add_undirected_edge(2, 3, 0)
  let dist = @zero_one_bfs.zero_one_bfs(g, 0)
  inspect(dist, content="[0, 0, 1, 1]")
}
```
