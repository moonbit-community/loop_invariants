# Block-Cut Tree

A **block-cut tree** turns an undirected graph into a tree (or forest) that
makes articulation structure explicit. It is a bipartite tree between two kinds
of nodes:

- **Block nodes** (also called component nodes): one per biconnected component
- **Vertex nodes**: one per original graph vertex

An articulation point appears in multiple blocks, so it connects to multiple
block nodes in the tree. All other vertices appear in exactly one block. This
bipartite structure makes many connectivity questions easy because the result is
a tree, not an arbitrary graph.

## Terminology

**Biconnected component (block)**: A maximal subgraph with no articulation
points. Equivalently, between any two vertices in a block there exist at least
two vertex-disjoint paths. A single bridge edge is also considered a block.

**Articulation point (cut vertex)**: A vertex whose removal increases the
number of connected components. It is the "glue" between two or more blocks.

## Original graph, blocks, and the block-cut tree

Consider this graph with 7 vertices:

```
  0 --- 1 --- 3 --- 5
  |     |     |
  +--2--+     4
              |
              6
```

Edges: (0,1), (0,2), (1,2), (1,3), (3,4), (3,5), (4,6)

Step 1 - Identify the biconnected components (blocks):

```
Block B0: triangle {0, 1, 2}   edges (0,1),(0,2),(1,2)
Block B1: bridge   {1, 3}      edge  (1,3)
Block B2: triangle {3, 4, 6}   edges (3,4),(4,6),(3,6)?
```

Actually with the edges above:

```
Block B0: triangle {0,1,2}     edges (0,1),(0,2),(1,2)
Block B1: bridge   {1,3}       edge  (1,3)
Block B2: bridge   {3,5}       edge  (3,5)
Block B3: path     {3,4,6}     edges (3,4),(4,6)
```

Step 2 - Build the block-cut tree. Node indices:

- Original vertices: 0, 1, 2, 3, 4, 5, 6  (n = 7)
- Block nodes: B0 = 7, B1 = 8, B2 = 9, B3 = 10 (n + ci)

```
         [B0=7]
        /   |   \
       0    1    2
            |
          [B1=8]
            |
            3
          / | \
      [B2=9] | [B3=10]
        |    |   |  \
        5    |   4    (none)
             |   |
             |   6
             |
```

Simplified, showing only the tree edges:

```
    B0(7)
   / | \
  0  1  2
     |
    B1(8)
     |
     3
   / | \
 B2  |  B3(10)
 (9) |  /  \
  |  | 4    (edges to 3 and 4 and 6)
  5  |
     (3 also in B2, B3)
```

A cleaner ASCII rendering of the block-cut tree for this graph:

```
Vertices:      0   2   1   5   3   4   6
               |   |   |   |   |   |   |
Blocks:         [B0=7]  |   [B2=9] [B3=10]
                    \   |   /       /
                     [B1=8]--------+
                         |
                        (3)
```

Let us use a simpler concrete example throughout this document.

## Worked example: triangle with a tail

### Input graph

```
  0 ------- 1 ------- 3
   \       /
    \     /
     \   /
      \ /
       2
```

Vertices: 0, 1, 2, 3  (n = 4)
Edges: (0,1), (1,2), (2,0), (1,3)

### Step 1: Identify biconnected components

Run DFS from vertex 0. Track discovery time `disc` and low-link value `low`.

```
DFS tree (tree edges solid, back edge dashed):

  0  --disc=0, low=0
  |\ (tree)
  | 1  --disc=1, low=0
  |  \ (tree)
  |   2  --disc=2, low=0
  |    \ (back edge to 0)
  |     0  (back edge, raises low of 2 to min(2, disc[0])=0)
  |
  3  --disc=3, low=3  (tree child of 1)
```

Low-link rule: `low[v] = min(disc[v], low of tree children, disc of back-edge
ancestors)`.

```
  low[3] = disc[3] = 3
  low[2] = min(disc[2], disc[0]) = min(2, 0) = 0
  low[1] = min(disc[1], low[2], low[3]) = min(1, 0, 3) = 0
  low[0] = min(disc[0], low[1]) = min(0, 0) = 0
```

Articulation-point test: vertex u is an articulation point if any tree child v
has `low[v] >= disc[u]`.

```
  u=0: children = {1}, low[1]=0 >= disc[0]=0  => YES (but root: only 1 child,
       so root rule says NO — a root is an articulation point only if it has
       >= 2 tree children).
  u=1: children = {2, 3}
       low[2]=0 >= disc[1]=1? No (0 < 1).
       low[3]=3 >= disc[1]=1? Yes => vertex 1 IS an articulation point.
  u=2: no tree children.
  u=3: no tree children.
```

Vertex **1** is the only articulation point.

Biconnected components (grouped by where the DFS stack pops):

```
  B0: edges {(0,1),(1,2),(2,0)}  -- the triangle -- vertices {0,1,2}
  B1: edges {(1,3)}              -- the bridge   -- vertices {1,3}
```

### Step 2: Assign block-cut tree node indices

```
  Original vertices: 0, 1, 2, 3         (indices 0 to 3)
  Block nodes:       B0=4, B1=5          (indices n=4 to n+c-1=5)
```

### Step 3: Draw the block-cut tree

Each block node connects to every vertex it contains:

```
  B0(4) -- 0
  B0(4) -- 1
  B0(4) -- 2
  B1(5) -- 1
  B1(5) -- 3
```

The tree looks like:

```
      0    2
       \  /
       B0(4)
         |
         1          <-- articulation point
         |
       B1(5)
         |
         3
```

Vertex 1 is in both B0 and B1, confirming it is the articulation point.
Vertices 0, 2, 3 each appear in exactly one block.

### Step 4: Verify with the API

```mbt check
///|
test "triangle with tail" {
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

## Example 2: a simple cycle

A cycle with no chords has no articulation points; the whole cycle is one
biconnected component. The block-cut tree has a single block node connected to
all vertices.

```
  0 --- 1
  |     |
  3 --- 2
```

Edges: (0,1), (1,2), (2,3), (3,0)

All four vertices belong to B0. The block-cut tree is a star:

```
     B0(4)
   / | | \
  0  1  2  3
```

No vertex is an articulation point.

```mbt check
///|
test "cycle becomes one block" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
  let tree = @block_cut_tree.build_block_cut_tree(4, edges[:])
  let block = 4
  inspect(tree.adj[block].length(), content="4")
  assert_true(tree.adj[block].contains(0))
  assert_true(tree.adj[block].contains(1))
  assert_true(tree.adj[block].contains(2))
  assert_true(tree.adj[block].contains(3))
}
```

## Example 3: disconnected graph

Each connected component is processed independently and yields its own
sub-tree in the block-cut forest.

```
  0 --- 1 --- 2       3 --- 4
```

Edges: (0,1), (1,2), (3,4)

Three blocks: bridge (0,1), bridge (1,2), bridge (3,4).

```
  B0(6) -- 0   B0(6) -- 1
  B1(7) -- 1   B1(7) -- 2
  B2(8) -- 3   B2(8) -- 4
```

Block-cut tree (two separate components):

```
  Component A:          Component B:
    0                     3
    |                     |
   B0(6)                B2(8)
    |                     |
    1                     4
    |
   B1(7)
    |
    2
```

Vertex 1 is an articulation point inside component A.

```mbt check
///|
test "disconnected graph" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
  let tree = @block_cut_tree.build_block_cut_tree(6, edges[:])
  // There are three blocks: (0,1), (1,2), (3,4)
  inspect(tree.component_count, content="3")
}
```

## Output format

`build_block_cut_tree(n, edges)` returns a `BlockCutTree` struct:

| Field                | Type              | Meaning                              |
|----------------------|-------------------|--------------------------------------|
| `original_vertices`  | `Int`             | Number of original vertices `n`      |
| `component_count`    | `Int`             | Number of biconnected components `c` |
| `adj`                | `Array[Array[Int]]` | Adjacency list of the block-cut tree |

Node index layout (size of `adj` is `n + c`):

```
  0 .. n-1      original vertex nodes
  n .. n+c-1    block (component) nodes
```

The adjacency list is undirected: if block node `b` contains vertex `v`, then
`adj[b]` contains `v` AND `adj[v]` contains `b`.

## Practical notes

- The algorithm assumes an **undirected** graph. Multi-edges are handled
  correctly because the underlying biconnected-components algorithm tracks
  edge IDs.
- Bridge edges form singleton blocks: a block whose edge list has length 1.
- Articulation points appear as vertex nodes with degree > 1 in the block-cut
  tree (connected to more than one block node).
- Non-articulation vertices have degree exactly 1 in the block-cut tree
  (connected to exactly one block node).
- Isolated vertices (degree 0 in the original graph) produce no blocks and do
  not appear in `adj` at all.

## Complexity

- Time: O(V + E)
- Space: O(V + E)

Both bounds follow from the linear-time biconnected-components algorithm and
the single pass to build the bipartite adjacency structure.

## When to use it

Use a block-cut tree when you need:

- **Articulation-aware connectivity**: determine whether removing a vertex
  disconnects two others.
- **Tree LCA / distance queries**: compress a complex graph into a tree,
  then apply LCA for path queries.
- **Structural decomposition**: enumerate all biconnected components and the
  cut vertices that join them.
- **Network reliability**: identify single points of failure (articulation
  points) and robust sub-networks (blocks with size > 1 edge).
