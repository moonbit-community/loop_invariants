# Bridges and Articulation Points

This package finds **bridges** and **articulation points** in an undirected
graph using a DFS + low-link algorithm (Tarjan).

- A **bridge** is an edge whose removal disconnects the graph.
- An **articulation point** is a vertex whose removal disconnects the graph.

These are the edges and vertices that represent single points of failure in
a network.

## Problem statement

Given an undirected graph with vertices `0..n-1` and edges `(u, v)`, find:

- all bridge edges
- all articulation points

## Core idea: discovery time and low-link

During DFS two values are tracked for every vertex `u`:

- `disc[u]` = the DFS timestamp when `u` is first visited (starts at 0,
  increments by 1 with each new visit)
- `low[u]` = the minimum `disc` value reachable from `u`'s DFS subtree using
  any combination of tree edges followed by **at most one back edge**

`low[u]` is computed as:

```
low[u] = min(
    disc[u],
    min(disc[w])  for every back edge (u, w),
    min(low[v])   for every tree edge (u, v)
)
```

### Bridge rule

For a tree edge `(u, v)` where `u` is the DFS parent of `v`:

```
(u, v) is a bridge  iff  low[v] > disc[u]
```

If `low[v] > disc[u]`, then no vertex in `v`'s subtree has a back edge that
reaches `u` or any ancestor of `u`.  Cutting `(u, v)` therefore splits the
graph.

### Articulation point rules

- **Root rule**: the DFS root is an articulation point iff it has 2 or more
  DFS children.  Removing it disconnects those subtrees from each other.
- **Non-root rule**: a non-root vertex `u` is an articulation point if it has
  at least one DFS child `v` with `low[v] >= disc[u]`.  The subtree rooted at
  `v` cannot bypass `u` to reach `u`'s ancestors.

## DFS tree walkthrough

Consider the graph:

```
0 --- 1 --- 3
 \   /
  \ /
   2
```

Edges: `(0,1)`, `(1,2)`, `(2,0)`, `(1,3)`.  DFS starts at vertex 0.

### Step-by-step DFS

```
Visit 0: disc[0]=0, low[0]=0
  Visit 1: disc[1]=1, low[1]=1
    Visit 2: disc[2]=2, low[2]=2
      Back edge (2->0): low[2] = min(low[2], disc[0]) = min(2,0) = 0
    Return to 1: low[1] = min(low[1], low[2]) = min(1,0) = 0
    Visit 3: disc[3]=3, low[3]=3
      (no neighbors other than parent 1)
    Return to 1: low[1] = min(low[1], low[3]) = min(0,3) = 0
  Return to 0: low[0] = min(low[0], low[1]) = min(0,0) = 0
```

### Annotated DFS tree

```
         0   disc=0, low=0
         |  \
(tree)   |   \_____(back edge to 0)_____
         |                               \
         1   disc=1, low=0               |
        / \                              |
(tree)/   \(tree)                        |
     /     \                             |
    3        2   disc=2, low=0 <---------+
disc=3
low=3
```

Legend:
- Solid lines = DFS tree edges
- Dashed arc = back edge (2 -> 0)

### Identifying the bridge

After DFS the values are:

```
vertex  disc  low
  0      0     0
  1      1     0
  2      2     0
  3      3     3
```

Check every tree edge with the bridge rule `low[v] > disc[u]`:

```
edge (0,1): low[1]=0  > disc[0]=0?  No  -> not a bridge
edge (1,2): low[2]=0  > disc[1]=1?  No  -> not a bridge
edge (1,3): low[3]=3  > disc[1]=1?  Yes -> BRIDGE
```

Result: `(1, 3)` is the only bridge.

### Identifying articulation points

Apply the non-root rule `low[v] >= disc[u]` for each tree edge `(u, v)`:

```
edge (0,1): low[1]=0 >= disc[0]=0?  Yes, but 0 is the root -> use root rule
edge (1,2): low[2]=0 >= disc[1]=1?  No
edge (1,3): low[3]=3 >= disc[1]=1?  Yes -> vertex 1 is an articulation point
```

Root rule for vertex 0: it has exactly 1 DFS child (vertex 1), so it is NOT
an articulation point.

Result: `[1]` is the only articulation point.

## A more complex example: two biconnected components

```
0 --- 1 --- 4
|     |
2 --- 3
```

Edges: `(0,1)`, `(0,2)`, `(1,3)`, `(2,3)`, `(1,4)`.  DFS from 0.

### Annotated DFS tree

```
    0   disc=0, low=0
   / \
  1   2   disc[1]=1,low=0   disc[2]=2,low=0
  |\   \
  | \   3   disc[3]=3, low=0
  |  \  |
  4   +-+ (back edge 3->0 via 2->0 cycle)
disc=4
low=4
```

### disc / low table

```
vertex  disc  low
  0      0     0
  1      1     0
  2      2     0
  3      3     0
  4      4     4
```

### Bridge and articulation point checks

```
edge (0,1): low[1]=0 > disc[0]=0?   No  -> not a bridge
edge (1,2): low[2]=0 > disc[1]=1?   No  -> not a bridge
edge (1,3): low[3]=0 > disc[1]=1?   No  -> not a bridge  (depends on DFS order)
edge (1,4): low[4]=4 > disc[1]=1?   Yes -> BRIDGE
```

Articulation point check:
```
edge (1,4): low[4]=4 >= disc[1]=1?  Yes -> vertex 1 is an articulation point
```

## Public API

```
@bridges.find_bridges(n, edges)
@bridges.articulation_points(n, edges)
```

Both functions take:
- `n` - number of vertices (vertices are `0..n-1`)
- `edges` - an `ArrayView[(Int, Int)]` of undirected edges

Both return arrays.  The order is DFS-dependent, so sort if you need
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
  let bridges = @bridges.find_bridges(4, edges)
  let normalized = bridges.map(e => if e.0 < e.1 { e } else { (e.1, e.0) })
  normalized.sort_by((a, b) => if a.0 == b.0 { a.1 - b.1 } else { a.0 - b.0 })
  inspect(normalized, content="[(1, 3)]")
  let cuts = @bridges.articulation_points(4, edges)
  cuts.sort_by((a, b) => a - b)
  inspect(cuts, content="[1]")
}
```

### Example 2: cycle (no bridges)

A pure cycle has no bridges and no articulation points because every edge
participates in a cycle: removing any single edge still leaves the graph
connected.

```mbt check
///|
test "cycle has no bridges" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
  let bridges = @bridges.find_bridges(4, edges)
  let cuts = @bridges.articulation_points(4, edges)
  inspect(bridges.length(), content="0")
  inspect(cuts.length(), content="0")
}
```

### Example 3: a line

```
0 - 1 - 2 - 3
```

Every edge is a bridge; vertices 1 and 2 are articulation points.

```
vertex  disc  low
  0      0     0
  1      1     1
  2      2     2
  3      3     3
```

No back edges exist, so `low[v] = disc[v]` for all `v`.  Every tree edge
satisfies `low[v] > disc[u]` (since `disc[v] = disc[u] + 1`).

```mbt check
///|
test "line graph" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let bridges = @bridges.find_bridges(4, edges)
  inspect(bridges.length(), content="3")
  let cuts = @bridges.articulation_points(4, edges)
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

All edges are bridges, and the center vertex 0 is the only articulation point.
The root rule fires: vertex 0 has 4 DFS children and no back edges, so every
leaf is in its own subtree isolated from the others.

```mbt check
///|
test "star graph" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let bridges = @bridges.find_bridges(5, edges)
  inspect(bridges.length(), content="4")
  let cuts = @bridges.articulation_points(5, edges)
  inspect(cuts, content="[0]")
}
```

## Practical notes and pitfalls

- These definitions are for **undirected** graphs only.  For directed graphs
  use Tarjan's SCC algorithm instead.
- A single edge in a tree is always a bridge; a tree with `n` vertices has
  exactly `n-1` bridges.
- A vertex of degree 1 (a leaf) is never an articulation point: removing it
  cannot disconnect the rest of the graph.
- Multi-edges (parallel edges between the same pair of vertices) are handled
  by tracking the parent vertex rather than the parent edge index.  If your
  graph has true multi-edges you may need an edge-index variant to avoid
  treating the second copy of an edge as a back edge.
- The returned arrays are in DFS discovery order; sort them if you need
  deterministic output independent of the adjacency-list ordering.

## Complexity

- Time: O(V + E)
- Space: O(V + E)

## When to use it

Use this when you need to identify fragile edges or vertices, such as:

- network reliability analysis (which links are single points of failure?)
- critical links in transport or communication graphs
- preprocessing for biconnected component decomposition
- graph problems that require contracting bridges
