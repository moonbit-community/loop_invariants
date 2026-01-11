# Challenge: BFS on a Grid

Shortest path on a grid with obstacles using breadth-first search.

## What you learn

- Level-order traversal to guarantee shortest paths
- Converting 2D coordinates to queue entries
- Boundary and obstacle checks

## Pseudocode sketch

```mbt nocheck
queue.push(start)
while queue not empty:
  pop front
  for each direction:
    if in bounds and not visited: enqueue
```

## Notes

- Time complexity: O(R * C)
- Space complexity: O(R * C)
