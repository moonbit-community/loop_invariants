# Challenge: Max Flow (Edmonds-Karp)

Edmonds-Karp is a BFS-based augmenting path algorithm for computing maximum
flow in a directed graph with non-negative capacities.

It is a specialization of Ford-Fulkerson that always chooses the shortest
augmenting path in terms of number of edges, which guarantees polynomial time.

## Problem statement

Given a directed graph with capacities, find the maximum amount of flow you can
send from source `s` to sink `t` without exceeding edge capacities and while
preserving flow conservation at intermediate nodes.

## Core idea

1. Build the **residual graph** (edges with remaining capacity).
2. Run BFS to find the shortest augmenting path from `s` to `t`.
3. Push as much flow as possible (the bottleneck capacity).
4. Update residual capacities and repeat until no path exists.

## Diagram: small flow network

```
    3        2
0 ----> 1 ----> 3
|      ^ \      ^
|      |  \     |
| 2    |1  \2   |4
v      |    \   |
2 ---->+----->  |
      (to 3)
```

BFS finds shortest augmenting paths; each augmentation increases total flow.

## Examples

### Example 1: small graph

```mbt check
///|
test "edmonds-karp example" {
  let g = @challenge_edmonds_karp.make(4)
  @challenge_edmonds_karp.add_edge(g, 0, 1, 3)
  @challenge_edmonds_karp.add_edge(g, 0, 2, 2)
  @challenge_edmonds_karp.add_edge(g, 1, 2, 1)
  @challenge_edmonds_karp.add_edge(g, 1, 3, 2)
  @challenge_edmonds_karp.add_edge(g, 2, 3, 4)
  let flow = @challenge_edmonds_karp.max_flow(g, 0, 3)
  inspect(flow, content="5")
}
```

### Example 2: classic 6-node network

This is the well-known example from textbooks (max flow = 23).

```
      16        12        20
  s ----> 1 --------> 3 ------> t
  | \      \        ^  ^
  |  \13    \10     |  |
  |   v      v      |  |
  |    2 ----> 4 ---+  |
  |      14     4      |
  |         \          |
  +----------> 1 <-----+
             4
```

```mbt check
///|
test "edmonds-karp classic" {
  let g = @challenge_edmonds_karp.make(6)
  let s = 0
  let t = 5
  @challenge_edmonds_karp.add_edge(g, s, 1, 16)
  @challenge_edmonds_karp.add_edge(g, s, 2, 13)
  @challenge_edmonds_karp.add_edge(g, 1, 2, 10)
  @challenge_edmonds_karp.add_edge(g, 2, 1, 4)
  @challenge_edmonds_karp.add_edge(g, 1, 3, 12)
  @challenge_edmonds_karp.add_edge(g, 3, 2, 9)
  @challenge_edmonds_karp.add_edge(g, 2, 4, 14)
  @challenge_edmonds_karp.add_edge(g, 4, 3, 7)
  @challenge_edmonds_karp.add_edge(g, 3, t, 20)
  @challenge_edmonds_karp.add_edge(g, 4, t, 4)
  let flow = @challenge_edmonds_karp.max_flow(g, s, t)
  inspect(flow, content="23")
}
```

### Example 3: single edge

```mbt check
///|
test "edmonds-karp simple" {
  let g = @challenge_edmonds_karp.make(2)
  @challenge_edmonds_karp.add_edge(g, 0, 1, 7)
  let flow = @challenge_edmonds_karp.max_flow(g, 0, 1)
  inspect(flow, content="7")
}
```

## Complexity

- Each BFS: O(E)
- Each augmentation increases the shortest path length at most O(V) times
- Total: O(V * E^2)

## Practical notes and pitfalls

- Capacities must be non-negative integers.
- The algorithm returns 0 if `s` or `t` is invalid.
- Add edges in both directions if the original graph is undirected.
- Edmonds-Karp is simple but can be slow for very large graphs; consider Dinic
  for better performance.

## When to use it

Use Edmonds-Karp when you need a simple, correct max-flow implementation and
input sizes are moderate.
