# Dial's Shortest Path

## Overview

Dial's algorithm is a bucketed variant of Dijkstra for graphs with **small
non-negative integer edge weights**. If the maximum edge weight is `C`, then the
shortest path length is at most `C * (n - 1)`. We can scan distances in order
using buckets indexed by distance.

- **Time**: O(E + C * V)
- **Space**: O(E + C * V)

## Example

```mbt check
///|
test "dial shortest path example" {
  let g = @dial_shortest_path.Graph::new(5, 3)
  g.add_edge(0, 1, 1)
  g.add_edge(0, 2, 2)
  g.add_edge(1, 2, 1)
  g.add_edge(1, 3, 3)
  g.add_edge(2, 3, 1)
  g.add_edge(3, 4, 0)
  let dist = @dial_shortest_path.dial_shortest_paths(g, 0)
  inspect(dist, content="[0, 1, 2, 3, 3]")
}
```
