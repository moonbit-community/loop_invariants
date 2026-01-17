# Bridges and Articulation Points

This package finds **bridges** and **articulation points** in an undirected
graph using a DFS + low-link algorithm (Tarjan).

- A **bridge** is an edge whose removal disconnects the graph.
- An **articulation point** is a vertex whose removal disconnects the graph.

These are the edges and vertices that represent single points of failure.

## Problem statement

Given an undirected graph with vertices `0..n-1` and edges `(u, v)`, find:

- all bridge edges
- all articulation points

## Core idea: discovery time and low-link

During DFS:

- `disc[u]` = the time when we first discover `u`
- `low[u]` = the minimum `disc` reachable from `u`'s subtree using
  **at most one back edge**

### Bridge rule

For a tree edge `(u, v)` where `u` is the DFS parent of `v`:

- `(u, v)` is a bridge if `low[v] > disc[u]`

That means `v`'s subtree cannot reach `u` or any ancestor of `u` without using
this edge.

### Articulation point rules

- **Root rule**: the DFS root is an articulation point iff it has 2+ children.
- **Non-root rule**: a vertex `u` is an articulation point if it has a child
  `v` with `low[v] >= disc[u]`.

## Public API

```
@bridges.find_bridges(n, edges)
@bridges.articulation_points(n, edges)
```

Both functions return arrays. The order is DFS-dependent, so sort if you need
stable output.

## Examples

### Example 1: triangle with a tail

```
0---1---3
 \ /
  2
```

Only edge `(1, 3)` is a bridge, and vertex `1` is the articulation point.

```mbt check
///|
test "triangle with tail" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let bridges = @bridges.find_bridges(4, edges[:])
  let normalized = bridges.map(e => if e.0 < e.1 { e } else { (e.1, e.0) })
  normalized.sort_by((a, b) => if a.0 == b.0 { a.1 - b.1 } else { a.0 - b.0 })
  inspect(normalized, content="[(1, 3)]")
  let cuts = @bridges.articulation_points(4, edges[:])
  cuts.sort_by((a, b) => a - b)
  inspect(cuts, content="[1]")
}
```

### Example 2: cycle (no bridges)

```mbt check
///|
test "cycle has no bridges" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
  let bridges = @bridges.find_bridges(4, edges[:])
  let cuts = @bridges.articulation_points(4, edges[:])
  inspect(bridges.length(), content="0")
  inspect(cuts.length(), content="0")
}
```

### Example 3: a line

```
0 - 1 - 2 - 3
```

Every edge is a bridge; vertices 1 and 2 are articulation points.

```mbt check
///|
test "line graph" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let bridges = @bridges.find_bridges(4, edges[:])
  inspect(bridges.length(), content="3")
  let cuts = @bridges.articulation_points(4, edges[:])
  cuts.sort_by((a, b) => a - b)
  inspect(cuts, content="[1, 2]")
}
```

### Example 4: star

```
    1
    |
2 - 0 - 3
    |
    4
```

All edges are bridges, and the center is the only articulation point.

```mbt check
///|
test "star graph" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let bridges = @bridges.find_bridges(5, edges[:])
  inspect(bridges.length(), content="4")
  let cuts = @bridges.articulation_points(5, edges[:])
  inspect(cuts, content="[0]")
}
```

## Practical notes and pitfalls

- These definitions are for **undirected** graphs.
- A single edge in a tree is always a bridge.
- A vertex of degree 1 is never an articulation point (removing it cannot
  disconnect the rest).

## Complexity

- Time: O(V + E)
- Space: O(V + E)

## When to use it

Use this when you need to identify fragile edges or vertices, such as:

- network reliability analysis
- critical links in transport or communication graphs
- graph decomposition and preprocessing
