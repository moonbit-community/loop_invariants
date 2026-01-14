# Biconnected Components

## Overview

A **biconnected component** (also called a *block*) is a maximal subgraph where
removing any single vertex does **not** disconnect the remaining vertices.
Articulation points are exactly the vertices that lie between blocks.

- **Build**: O(V + E)
- **Space**: O(V + E)

## Core Idea

- Use DFS low-link values to detect **articulation boundaries**.
- Maintain an **edge stack**; popping yields a maximal biconnected block.
- A vertex with `low[child] >= disc[parent]` separates blocks.

## Key Idea (Tarjan DFS)

During DFS, we compute:

- `disc[u]`: discovery time of `u`
- `low[u]`: smallest discovery time reachable from `u`'s subtree using at most
  one back edge

For a tree edge `(u, v)`:
- If `low[v] >= disc[u]`, then `(u, v)` is the boundary of a new block.
- The edges popped from the DFS edge stack form a **biconnected component**.

## Example

```
Graph: 0-1-2-0 and 1-3

Blocks:
  { (0,1), (1,2), (2,0) }  // cycle
  { (1,3) }                // bridge

Articulation points: {1}
```

## Example Usage

```mbt check
///|
test "biconnected components example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let res = @biconnected_components.biconnected_components(4, edges[:])
  let sizes = res.components.map(fn(c) { c.length() })
  sizes.sort_by(fn(a, b) { a - b })
  inspect(sizes, content="[1, 3]")
  res.articulation_points.sort_by(fn(a, b) { a - b })
  inspect(res.articulation_points, content="[1]")
}
```

## How the Edge Stack Works

```
When we enter a tree edge (u, v), push (u, v).

When low[v] >= disc[u], pop until (u, v):
  these edges form one biconnected component.

Why it works:
- low[v] tells us whether v's subtree can reach an ancestor of u
- if it cannot, then (u, v) is the boundary between blocks
```

## Applications

- Finding articulation points
- Block–cut tree decomposition
- Reliability analysis of networks
- Bridge/biconnected decomposition in planar graphs
