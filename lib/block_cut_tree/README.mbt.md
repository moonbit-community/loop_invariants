# Block-Cut Tree

## Overview

The **Block-Cut Tree** is a tree representation of an undirected graph that
captures its biconnected structure. It's a bipartite tree where one set of
nodes represents **biconnected components** (blocks) and the other represents
**articulation points** (cut vertices).

- **Time**: O(V + E)
- **Space**: O(V + E)
- **Key Feature**: Reduces graph connectivity queries to tree queries

## The Key Insight

```
Problem: Answer connectivity queries accounting for articulation points

A biconnected component (block) is a maximal subgraph with no cut vertex.
Removing any single vertex won't disconnect a block.

Block-Cut Tree insight:
  - Create a node for each block
  - Create a node for each articulation point
  - Connect articulation point to all blocks containing it
  - Result: A tree that captures the "skeleton" of connectivity!

Graph:          Block-Cut Tree:
0 - 1 - 3         [Block{0,1,2}] --- [ArtPt 1] --- [Block{1,3}]
|   |
2 --+           Blocks: {0,1,2} and {1,3}
                Articulation point: 1
```

## Visual: Block-Cut Tree Construction

```
Original Graph:              Biconnected Components:
    0---1---4                  Block A: {0,1,2,3}  (the square)
    |\ /|                      Block B: {1,4}      (edge 1-4)
    | X |                      Block C: {4,5,6}    (the triangle)
    |/ \|
    3---2   5                Articulation Points: 1, 4
            |\
            6-+              Block-Cut Tree:
                               [Block A] --- [AP 1] --- [Block B] --- [AP 4] --- [Block C]

Node indexing:
  - Original vertices: 0, 1, 2, 3, 4, 5, 6
  - Block nodes: 7, 8, 9 (starting from n)
```

## How Blocks and Cut Vertices Relate

```
Articulation Point (Cut Vertex):
  A vertex whose removal disconnects the graph.
  Appears in MULTIPLE biconnected components.

Non-Cut Vertex:
  Appears in exactly ONE biconnected component.

Example:
  Graph: 0-1-2 (a path)

  Blocks: {0,1} and {1,2}
  Articulation point: 1 (appears in both blocks)
  Non-cut vertices: 0, 2 (each in one block)

  Block-Cut Tree:
    [Block{0,1}] --- [1] --- [Block{1,2}]
```

## Algorithm: Building Block-Cut Tree

```
1. Run DFS to find biconnected components:
   - Track discovery time (tin) and low values
   - low[u] = min reachable tin via back edges
   - u is articulation point if:
     * u is root with 2+ children, OR
     * u is non-root with child v where low[v] >= tin[u]

2. Use a stack to track edges in current component:
   - Push edges during DFS
   - Pop component when articulation point found

3. Build bipartite tree:
   - One node per component (indexed n, n+1, ...)
   - One node per original vertex (indexed 0..n-1)
   - Connect component nodes to their vertices
```

## Example Usage

```mbt check
///|
test "block-cut tree example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let tree = @block_cut_tree.build_block_cut_tree(4, edges[:])
  let comp0 = 4
  let comp1 = 5
  let comp0_tri = tree.adj[comp0].length() == 3 &&
    tree.adj[comp0].contains(0) &&
    tree.adj[comp0].contains(1) &&
    tree.adj[comp0].contains(2)
  let comp1_tri = tree.adj[comp1].length() == 3 &&
    tree.adj[comp1].contains(0) &&
    tree.adj[comp1].contains(1) &&
    tree.adj[comp1].contains(2)
  let comp0_edge = tree.adj[comp0].length() == 2 &&
    tree.adj[comp0].contains(1) &&
    tree.adj[comp0].contains(3)
  let comp1_edge = tree.adj[comp1].length() == 2 &&
    tree.adj[comp1].contains(1) &&
    tree.adj[comp1].contains(3)
  assert_true((comp0_tri && comp1_edge) || (comp1_tri && comp0_edge))
}
```

## Algorithm Walkthrough

```
Graph: 0-1-2-0, 1-3 (triangle with pendant)

DFS from 0:
  Visit 0: tin[0]=0, low[0]=0
    Visit 1: tin[1]=1, low[1]=1
      Visit 2: tin[2]=2, low[2]=2
        Back edge 2→0: low[2]=min(2,0)=0
      low[1]=min(1,0)=0

      Visit 3: tin[3]=3, low[3]=3
        No more edges from 3
      low[3]=3 >= tin[1]=1 → 1 is articulation point!
      Component found: {1,3}

    low[0]=min(0,0)=0
    low[1]=0 < tin[0]=0? No, but 0 is root with 1 child

  Component found: {0,1,2}

Block-Cut Tree:
  Nodes: 0,1,2,3 (vertices), 4,5 (blocks)
  Block 4 = {0,1,2}: edges 4-0, 4-1, 4-2
  Block 5 = {1,3}: edges 5-1, 5-3

  Result: [0]--[B4]--[1]--[B5]--[3]
                |
               [2]
```

## Common Applications

### 1. Two-Vertex Connectivity Queries
```
"Are u and v still connected if we remove vertex x?"
Answer: Check if x is on the path from u to v in block-cut tree.
```

### 2. Counting Articulation Points on Paths
```
Path from u to v in block-cut tree alternates:
  vertex → block → vertex → block → ...
Count articulation points = (path length in tree) / 2
```

### 3. Graph Decomposition
```
Decompose graph into 2-connected components.
Each block can be processed independently for certain problems.
```

### 4. Network Reliability
```
Find critical points whose failure disconnects the network.
Articulation points are exactly the critical vertices.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Build Block-Cut Tree | O(V + E) | Single DFS |
| Tree Size | O(V + B) | B = number of blocks |
| Space | O(V + E) | Store graph + tree |

## Key Properties

```
1. Tree structure: Block-cut tree is always a tree (or forest)

2. Bipartite: Alternates between block nodes and vertex nodes

3. Size bound: At most 2V nodes (V vertices + at most V blocks)

4. Articulation points: Appear in multiple blocks, hence connected
   to multiple block nodes in the tree

5. Path meaning: Path in block-cut tree = sequence of blocks
   and articulation points connecting two vertices
```

## Block-Cut Tree vs Other Structures

| Structure | What it captures | Use case |
|-----------|-----------------|----------|
| Block-Cut Tree | 2-connectivity | Cut vertex queries |
| Bridge Tree | Bridge edges | Cut edge queries |
| Cactus Graph | Simple cycles | Cycle-based queries |

**Choose Block-Cut Tree when**: You need to analyze vertex connectivity
and articulation points.

## Implementation Notes

- Node indexing: vertices 0..n-1, blocks n..n+c-1
- Track which block each vertex belongs to
- For articulation points, track all containing blocks
- DFS with low-link values (similar to Tarjan's SCC)
- Use a stack to collect edges in each component

