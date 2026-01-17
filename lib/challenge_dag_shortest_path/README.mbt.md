# Challenge: DAG Shortest Paths

This challenge computes shortest paths in a **DAG** (directed acyclic graph)
using topological order + dynamic programming.

Because a DAG has no cycles, we can process nodes in topological order and
finalize distances in one pass. Negative edge weights are allowed.

## Problem statement

Given a directed graph with `n` nodes and weighted edges, compute the shortest
path distance from a source `src` to every node. If the graph has a cycle,
return `None` (no valid topological order).

## Key idea: topological order

A topological order is a linear order of nodes where every edge goes forward.
In a DAG, such an order exists and can be found with Kahn's algorithm.

Once we have the order, we relax edges in that order:

```
for u in topo_order:
  for (u -> v, w):
    dist[v] = min(dist[v], dist[u] + w)
```

## Diagram: a small DAG

```
0 --> 1 --> 3
 \    \
  \-> 2 -->/
```

One valid topological order:

```
0, 1, 2, 3
```

## Examples

### Example 1: basic DAG

```mbt check
///|
test "dag shortest path example" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 2),
    (0, 2, 5),
    (1, 2, 1),
    (1, 3, 2),
    (2, 3, 1),
  ]
  let dist = @challenge_dag_shortest_path.dag_shortest_paths(4, edges[:], 0)
  guard dist is Some(d) else { fail("expected distances") }
  inspect(d, content="[0, 2, 3, 4]")
}
```

### Example 2: negative edges (still fine in a DAG)

```mbt check
///|
test "dag shortest path negative edges" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 2),
    (0, 2, 5),
    (1, 2, -4),
    (2, 3, 3),
    (1, 3, 6),
  ]
  let dist = @challenge_dag_shortest_path.dag_shortest_paths(4, edges[:], 0)
  guard dist is Some(d) else { fail("expected distances") }
  inspect(d, content="[0, 2, -2, 1]")
}
```

### Example 3: unreachable nodes

Unreachable nodes keep a very large distance (INF). This test only checks that
reachable nodes are correct.

```mbt check
///|
test "dag shortest path unreachable" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1)]
  let dist = @challenge_dag_shortest_path.dag_shortest_paths(4, edges[:], 0)
  guard dist is Some(d) else { fail("expected distances") }
  inspect(d[0], content="0")
  inspect(d[1], content="1")
  inspect(d[2] > 1000000, content="true")
}
```

### Example 4: cycle detection

If there is a cycle, topological order does not exist, so the function returns
`None`.

```mbt check
///|
test "dag shortest path cycle" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, 2), (2, 0, 3)]
  let dist = @challenge_dag_shortest_path.dag_shortest_paths(3, edges[:], 0)
  inspect(dist is None, content="true")
}
```

## Complexity

- Topological order: O(n + m)
- Relaxation: O(n + m)
- Total: O(n + m)

## Practical notes and pitfalls

- Works only for DAGs; cycles return `None`.
- Negative edges are allowed because there are no cycles.
- Unreachable nodes remain at a large INF value.

## When to use it

Use this method when you have a DAG and need shortest paths fast and exactly,
including with negative weights.
