# Bellman-Ford (Shortest Paths with Negative Edges)

Bellman-Ford computes shortest paths from a single source in a directed,
weighted graph. Unlike Dijkstra, it **allows negative edge weights** and can
**detect negative cycles** (cycles whose total weight is negative).

If a negative cycle is reachable from the source, there is no well-defined
"shortest" path for vertices that can reach that cycle, because you can loop
forever and keep decreasing the path cost.

This package provides two ways to use the algorithm:

- `@bellman_ford.bellman_ford`: a simple wrapper returning distances and a
  negative-cycle flag.
- `@bellman_ford.BellmanFord`: a full solver with `add_edge`, `compute`,
  `get_distance`, and `get_path`.

## Problem statement

Given a directed graph with vertices `0..n-1` and weighted edges
`(u -> v, w)`, find the shortest path distance from a source `s` to every
vertex `v`. If any negative cycle is reachable from `s`, report that as well.

## The core idea: relaxation

A single **relaxation** tries to improve the best-known distance to a vertex:

```
If dist[u] + w < dist[v], then dist[v] = dist[u] + w
```

If we repeatedly relax all edges, shorter and shorter paths are discovered.

## Why V-1 rounds are enough

A *simple* path (one that does not repeat vertices) has at most `V - 1` edges.
Bellman-Ford uses this fact:

- After 1 round, all shortest paths that use at most 1 edge are correct.
- After 2 rounds, all shortest paths with at most 2 edges are correct.
- ...
- After `V - 1` rounds, all shortest paths are correct.

This is the key invariant: **after k rounds, `dist[v]` is the shortest distance
using at most k edges**.

## ASCII art: relaxation rounds on a 4-vertex graph

Consider this directed graph with a negative edge:

```
    (4)         (-2)
0 -------> 1 -------> 2
|                     |
+-----(5)-----------> |        dist[2] via 0->1->2 = 4 + (-2) = 2
                      |
                      v (3)
                      3
```

Edges: `0->1 (+4)`, `0->2 (+5)`, `1->2 (-2)`, `2->3 (+3)`

**Initialization** (all distances start at infinity except source):

```
  vertex:   0      1      2      3
  dist:     0     INF    INF    INF
```

**Round 1** (relax all edges once):

```
  relax 0->1 (+4):  dist[1] = 0+4  = 4
  relax 0->2 (+5):  dist[2] = 0+5  = 5
  relax 1->2 (-2):  dist[2] = 4-2  = 2   <-- improvement!
  relax 2->3 (+3):  dist[3] = 2+3  = 5

  vertex:   0      1      2      3
  dist:     0      4      2      5
```

**Round 2** (no edge can improve any distance):

```
  relax 0->1 (+4):  4 >= 4, no change
  relax 0->2 (+5):  5 >= 2, no change
  relax 1->2 (-2):  2 >= 2, no change
  relax 2->3 (+3):  5 >= 5, no change

  vertex:   0      1      2      3
  dist:     0      4      2      5      (converged)
```

The algorithm terminates early because round 2 produced no relaxations. Final
shortest paths: `0` (cost 0), `0->1` (cost 4), `0->1->2` (cost 2),
`0->1->2->3` (cost 5).

## Step-by-step convergence over V-1 rounds

For a graph with V vertices, the algorithm needs at most V-1 rounds to
propagate information along the longest possible simple path (one that visits
every vertex exactly once, using V-1 edges).

```
  Round k:  dist[v] holds the shortest path to v using AT MOST k edges
  ---------------------------------------------------------------
  k=0:      dist[src]=0, dist[others]=INF   (0 edges used)
  k=1:      all 1-hop shortest paths are correct
  k=2:      all 2-hop shortest paths are correct
  ...
  k=V-1:    all shortest paths are correct  (final answer)
```

If a V-th relaxation round still improves some distance, then the "path" would
need V or more edges, which means it must revisit a vertex -- forming a cycle.
If that cycle reduces the total cost, it is a **negative cycle**.

## Detecting negative cycles

After `V - 1` rounds, all simple shortest paths are finalized. If **any** edge
can still relax, then some path can be improved indefinitely, which means a
negative cycle is reachable from the source.

The implementation runs one extra pass to set `has_negative_cycle`.

### Visualization of negative cycle detection

Consider the cycle `1 -> 2 -> 1` with edge weights `-2` and `-2`:

```
    (+1)      (-2)
0 -------> 1 <------> 2
           |    (-2)
           +----------^
```

Edges: `0->1 (+1)`, `1->2 (-2)`, `2->1 (-2)`

```
  After round 1:
    dist[0]=0, dist[1]=1, dist[2]=-1

  After round 2 (= V-1 = 2 rounds for 3 vertices):
    relax 2->1 (-2): dist[1] = -1 + (-2) = -3  <-- still improving!
    dist[0]=0, dist[1]=-3, dist[2]=-5

  Extra detection round:
    relax 1->2 (-2): dist[2] = -3 + (-2) = -5  <-- can relax again!
    => negative cycle detected
```

The cycle weight is `(-2) + (-2) = -4`. Traversing it repeatedly drives
distances toward negative infinity, so no finite shortest path exists for
vertices reachable via this cycle.

## Examples

### Example 1: basic graph (no negative edges)

```mbt check
///|
test "basic graph" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 5),
    (0, 2, 2),
    (2, 1, 1),
    (1, 3, 3),
    (2, 3, 6),
  ]
  let (dist, neg) = @bellman_ford.bellman_ford(4, edges[:], 0)
  inspect(dist, content="[0, 3, 2, 6]")
  inspect(neg, content="false")
}
```

Shortest paths:
- `0 -> 2` costs 2
- `0 -> 2 -> 1` costs 3
- `0 -> 2 -> 1 -> 3` costs 6

### Example 2: negative edge but no negative cycle

```mbt check
///|
test "negative edge without negative cycle" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 4),
    (0, 2, 5),
    (1, 2, -2),
    (2, 3, 3),
  ]
  let (dist, neg) = @bellman_ford.bellman_ford(4, edges[:], 0)
  inspect(dist, content="[0, 4, 2, 5]")
  inspect(neg, content="false")
}
```

Here the path `0 -> 1 -> 2` (cost 2) beats the direct edge `0 -> 2` (cost 5).

### Example 3: detect a negative cycle

```mbt check
///|
test "negative cycle detection" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, -2), (2, 1, -2)]
  let (_dist, neg) = @bellman_ford.bellman_ford(3, edges[:], 0)
  inspect(neg, content="true")
}
```

The cycle `1 -> 2 -> 1` has total weight `-4`, so there is no finite shortest
path to vertices that can reach it.

### Example 4: path reconstruction with the full solver

```mbt check
///|
test "path reconstruction" {
  let bf = @bellman_ford.BellmanFord::new(4)
  bf.add_edge(0, 1, 2L)
  bf.add_edge(1, 2, 2L)
  bf.add_edge(0, 2, 10L)
  bf.add_edge(2, 3, 1L)
  let result = bf.compute(0)
  inspect(result.get_path(3), content="Some([0, 1, 2, 3])")
  inspect(result.get_distance(3), content="Some(5)")
}
```

### Example 5: unreachable vertices

```mbt check
///|
test "unreachable vertices" {
  let bf = @bellman_ford.BellmanFord::new(4)
  bf.add_edge(0, 1, 3L)
  bf.add_edge(2, 3, 1L)
  let result = bf.compute(0)
  inspect(result.get_distance(0), content="Some(0)")
  inspect(result.get_distance(1), content="Some(3)")
  inspect(result.get_distance(2), content="None")
  inspect(result.get_distance(3), content="None")
}
```

## Step-by-step intuition (small walk-through)

Suppose we have edges:

```
0 -> 1 (4)
0 -> 2 (5)
1 -> 2 (-2)
2 -> 3 (3)
```

Initialization:
- `dist[0] = 0`, all others are infinity

Round 1:
- Relax `0 -> 1`: dist[1] = 4
- Relax `0 -> 2`: dist[2] = 5
- Relax `1 -> 2`: dist[2] becomes 2 (better than 5)
- Relax `2 -> 3`: dist[3] becomes 5

Round 2:
- No further improvements, so we can stop early.

This matches the output in Example 2.

## Practical notes and pitfalls

- **Undirected negative edges are dangerous**: a single negative undirected edge
  implies a negative cycle (u -> v -> u). Bellman-Ford will correctly report a
  negative cycle in that case.
- **Only cycles reachable from the source are detected**: the check uses
  `dist[u] < INF`, so a negative cycle in a disconnected component is ignored.
- **Unreachable vertices stay at infinity**: use `get_distance` to see `None`
  for unreachable nodes, or check the large sentinel in the wrapper.
- **Weights should fit in Int64**: the internal solver uses Int64 to reduce the
  risk of overflow on large graphs.
- **Wrapper returns Int distances**: if you need large distances, use
  `@bellman_ford.BellmanFord` directly to keep Int64 results.
- **Early exit is safe**: if one full round produces no relaxation, distances
  are already final and the algorithm can stop early.

## Complexity

- Time: O(V * E)
- Space: O(V)

## When to use Bellman-Ford

Use it when:
- You have negative edge weights, or
- You must detect negative cycles.

If all edges are non-negative, Dijkstra is faster.
