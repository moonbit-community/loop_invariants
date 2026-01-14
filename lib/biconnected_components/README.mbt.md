# Biconnected Components

## Overview

A **biconnected component** (or 2-vertex-connected component) is a maximal
subgraph where removing any single vertex does **not** disconnect the remaining
vertices. This package finds all biconnected components and articulation points.

- **Time**: O(V + E)
- **Space**: O(V + E)
- **Key Feature**: Identifies critical vertices (articulation points)

## The Key Insight

```
Problem: Find maximal 2-connected subgraphs

Key observation:
  A vertex u is an articulation point if removing it disconnects the graph.

  In DFS terms:
    u is articulation point if some child v has low[v] >= disc[u]
    meaning v's subtree cannot reach above u!

  Biconnected component = edges between consecutive articulation points

Edge stack technique:
  Push edges during DFS.
  When we find articulation boundary (low[v] >= disc[u]),
  pop edges until (u,v) - these form one component!

Why it works:
  The edge stack contains the current DFS path.
  An articulation point separates components.
  Popping gives exactly the edges in one block.
```

## Visual: Articulation Points

```
Graph:
    0───1───2
        │
        3
        │
        4

Vertex 1 is articulation: removing it disconnects {0} from {2,3,4}
Vertex 3 is articulation: removing it disconnects {4} from {0,1,2}

Biconnected components:
  Block 1: {edge(0,1), edge(1,2)} - vertices {0,1,2}
  Block 2: {edge(1,3)} - just the bridge
  Block 3: {edge(3,4)} - just the bridge

Articulation points: {1, 3}
```

## Visual: DFS Low-Link

```
Graph with cycle:
    0───1───2
    │       │
    └───────┘

DFS from 0:
  disc: [0, 1, 2]

  low computation:
    low[2] = min(disc[2], back edge to 0) = 0
    low[1] = min(disc[1], low[2]) = 0
    low[0] = 0

  Check articulation:
    At edge (0,1): low[1]=0 < disc[0]=0? No
    At edge (1,2): low[2]=0 < disc[1]=1? Yes, but 1 is not root

  Result: No articulation points (the cycle is 2-connected)
  One biconnected component with all 3 edges
```

## The Algorithm

```
biconnected_components(n, edges):
  disc = [-1] * n   // Discovery time
  low = [0] * n     // Lowest reachable
  time = 0
  edge_stack = []
  components = []
  articulation_points = set()

  dfs(u, parent):
    disc[u] = low[u] = time++
    children = 0

    for each neighbor v of u:
      if disc[v] == -1:  // Tree edge
        children++
        edge_stack.push((u, v))
        dfs(v, u)
        low[u] = min(low[u], low[v])

        // Check articulation point condition
        if (parent == -1 and children > 1) or
           (parent != -1 and low[v] >= disc[u]):
          articulation_points.add(u)
          // Pop component
          component = []
          while edge_stack.top() != (u, v):
            component.append(edge_stack.pop())
          component.append(edge_stack.pop())
          components.append(component)

      else if v != parent:  // Back edge
        low[u] = min(low[u], disc[v])
        if disc[v] < disc[u]:
          edge_stack.push((u, v))

  for each vertex u:
    if disc[u] == -1:
      dfs(u, -1)
      // Remaining edges form last component
      if edge_stack is not empty:
        components.append(edge_stack)
        edge_stack = []

  return components, articulation_points
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

```mbt check
///|
test "biconnected no articulation" {
  // Complete graph K4 - no articulation points
  let edges : Array[(Int, Int)] = [
    (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3),
  ]
  let res = @biconnected_components.biconnected_components(4, edges[:])
  inspect(res.components.length(), content="1")
  inspect(res.articulation_points.length(), content="0")
}
```

## Algorithm Walkthrough

```
Graph: 0-1-2-0 and 1-3

Edges: (0,1), (1,2), (2,0), (1,3)

DFS from 0:
  visit(0): disc[0]=0, low[0]=0
    push (0,1), visit(1): disc[1]=1, low[1]=1
      push (1,2), visit(2): disc[2]=2, low[2]=2
        back edge to 0: low[2] = min(2, 0) = 0
        push (2,0)
      return: low[1] = min(1, 0) = 0
      low[2]=0 >= disc[1]=1? Yes!
      But parent != -1 and low[v] >= disc[u]:
        low[2]=0 < disc[1]=1, so NO articulation here

      push (1,3), visit(3): disc[3]=3, low[3]=3
        no neighbors except parent
      return: low[1] = min(0, 3) = 0
      low[3]=3 >= disc[1]=1? Yes!
      1 is articulation point!
      Pop until (1,3): component = [(1,3)]

    return: low[0] = min(0, 0) = 0
    low[1]=0 >= disc[0]=0? Yes, but 0 is root with 1 child
    Root needs 2+ children to be articulation

  Remaining stack: [(0,1), (1,2), (2,0)]
  This forms component 2.

Result:
  Components: [[(1,3)], [(0,1), (1,2), (2,0)]]
  Articulation points: [1]
```

## Why Low-Link Works

```
low[u] = minimum discovery time reachable from u's subtree

If low[child] >= disc[u]:
  - Child's subtree cannot reach any ancestor of u
  - Removing u disconnects child's subtree
  - u is an articulation point

If low[child] < disc[u]:
  - Child's subtree has back edge to u's ancestor
  - Removing u does NOT disconnect (path exists via back edge)
  - u is NOT articulation point

Special case: DFS root
  Root is articulation iff it has 2+ DFS children
  (removing root disconnects children)
```

## Common Applications

### 1. Network Reliability
```
Find single points of failure.
Articulation points = critical vertices.
Bridges = critical edges.
```

### 2. Block-Cut Tree
```
Compress graph into tree of blocks and cut vertices.
Useful for graph decomposition problems.
```

### 3. Graph Connectivity
```
2-edge-connected vs 2-vertex-connected.
Biconnected components partition edges.
```

### 4. Social Network Analysis
```
Identify key connectors in networks.
People whose removal fragments the network.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| DFS traversal | O(V + E) | Visit each vertex/edge once |
| Edge stack operations | O(E) | Each edge pushed/popped once |
| Low-link computation | O(V + E) | During DFS |
| **Total** | **O(V + E)** | Linear in graph size |

## Biconnected vs Bridge Finding

```
Biconnected components: Group by articulation points
  - Maximal 2-vertex-connected subgraphs
  - Share articulation points between blocks

Bridge finding: Find cut edges
  - Edge (u,v) is bridge if low[v] > disc[u]
  - Removing bridge disconnects graph
  - Every bridge is its own "trivial" component

A biconnected component is either:
  - A single bridge edge, or
  - A 2-connected subgraph with no bridges
```

## Block-Cut Tree

```
Represent graph as tree of:
  - Block nodes (biconnected components)
  - Cut nodes (articulation points)

Edges connect:
  - Each cut vertex to blocks containing it
  - Forms a tree structure!

Use cases:
  - Tree DP on blocks
  - Path queries through blocks
  - Graph decomposition
```

## Implementation Notes

- Handle disconnected graphs with outer loop
- Root of DFS tree is special case for articulation
- Edge stack holds directed edges (order matters for popping)
- Back edges update low[] but don't start new components
- Empty graph or single vertex: no components

