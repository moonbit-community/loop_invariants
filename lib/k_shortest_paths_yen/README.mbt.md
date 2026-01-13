# Yen's K Shortest Loopless Paths

## Overview

Yen's algorithm enumerates the **k shortest simple (loopless) paths** between a
source and a target in a directed graph with **non-negative weights**.

It repeatedly takes the current shortest path and creates **spur deviations**
from each prefix. The best candidate among those deviations becomes the next
shortest path.

- **Time**: O(k * n * (m log n)) in typical sparse cases
- **Space**: O(n + m)

## Key Idea

Given the previous shortest path `P`:

1. Choose a spur node along `P`.
2. Keep the prefix (root path) up to the spur node.
3. Temporarily block any edges that would recreate the same root path.
4. Block the root path's earlier nodes to ensure the new path is loopless.
5. Run Dijkstra from the spur node to the target.

Each spur deviation yields a candidate path. The smallest candidate becomes the
next shortest path.

## API

- `yen_k_shortest_paths(n, edges, source, target, k)`
  - Returns up to `k` shortest loopless paths.
  - Each result has `nodes` and total `cost`.
  - Returns an empty array if no path exists or inputs are invalid.

## Example Usage

```mbt check
///|
test "yen k shortest paths" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 3, 1L),
    (0, 2, 3L),
    (2, 3, 2L),
    (1, 2, 1L),
  ]
  let paths = @k_shortest_paths_yen.yen_k_shortest_paths(4, edges[:], 0, 3, 3)
  inspect(paths[0].cost, content="2")
  inspect(paths[1].cost, content="4")
  inspect(paths[2].cost, content="5")
}
```

## When To Use

- You need **multiple** shortest alternatives, not just the single shortest path.
- You need **simple paths** (no repeated vertices).
- Edge weights are non-negative (so Dijkstra applies).
