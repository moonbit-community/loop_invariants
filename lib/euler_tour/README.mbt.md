# Euler Tour

## Overview

The **Euler Tour** technique linearizes a tree into an array, enabling subtree
queries to be answered as range queries. It records entry and exit times for
each node during a DFS traversal.

- **Build**: O(n)
- **Space**: O(n)

## The Key Insight

```
DFS visits nodes in a specific order. By recording when we
enter and exit each node, subtrees become contiguous ranges!

Tree:           DFS Order:
     1              1 (enter)
    /|\             2 (enter)
   2 3 4            5 (enter, exit)
  /|                6 (enter, exit)
 5 6                2 (exit)
                    3 (enter, exit)
                    4 (enter, exit)
                    1 (exit)

Euler tour: [1, 2, 5, 5, 6, 6, 2, 3, 3, 4, 4, 1]
            └─────subtree of 2─────┘
```

## Entry and Exit Times

```
      tin  tout
  1:   0    11
  2:   1     6
  3:   7     8
  4:   9    10
  5:   2     3
  6:   4     5

Subtree of node u = all nodes with tin in [tin[u], tout[u]]

Subtree of 2: tin in [1, 6]
  → Nodes 2, 5, 6 (check: tin[5]=2, tin[6]=4 are in [1,6] ✓)
```

## Algorithm Walkthrough

```
DFS from root 1:

  timer = 0

  Visit 1: tin[1] = 0
    Visit 2: tin[2] = 1
      Visit 5: tin[5] = 2, tout[5] = 3
      Visit 6: tin[6] = 4, tout[6] = 5
    tout[2] = 6
    Visit 3: tin[3] = 7, tout[3] = 8
    Visit 4: tin[4] = 9, tout[4] = 10
  tout[1] = 11

Final:
  Node:  1  2  3  4  5  6
  tin:   0  1  7  9  2  4
  tout: 11  6  8 10  3  5
```

## Two Types of Euler Tours

```
Type 1: Entry/Exit times only
  Array size: n (each node once)
  tin[u], tout[u] are times

Type 2: Full tour with entries and exits
  Array size: 2n (each node twice)
  tour[i] = node visited at step i

For subtree queries, Type 1 suffices.
For LCA queries, Type 2 is often used.
```

## Example Usage

```mbt nocheck
// Build Euler tour for tree
let tour = EulerTour::new(n)
for edge in edges {
  tour.add_edge(edge.u, edge.v)
}
tour.build(root=0)

// Now subtree of u is range [tin[u], tout[u]]
let subtree_start = tour.tin(u)
let subtree_end = tour.tout(u)

// Query subtree sum using a range data structure
let sum = segment_tree.query(subtree_start, subtree_end)
```

## Common Applications

### 1. Subtree Queries
```
Query: Sum/min/max of values in subtree
Solution:
  1. Build Euler tour to get tin/tout
  2. Put values at positions tin[u]
  3. Use segment tree/Fenwick tree on flattened array
  4. Query range [tin[u], tout[u]-1]

Time: O(log n) per query after O(n) preprocessing
```

### 2. Subtree Updates
```
Query: Add value to all nodes in subtree
Solution:
  1. Flatten tree via Euler tour
  2. Range update on [tin[u], tout[u]-1]
  3. Use lazy segment tree for range updates
```

### 3. LCA via RMQ
```
Record depths in Euler tour (Type 2).
LCA(u, v) = node with minimum depth between
            first occurrence of u and first occurrence of v.

Use sparse table for O(1) LCA queries!
```

### 4. Path Queries
```
Combine with LCA:
  path(u, v) = path(u, lca) + path(lca, v)

Or use Heavy-Light Decomposition for more complex queries.
```

## Visual: Subtree as Range

```
Tree:                 Flattened (by tin):
      A                pos: 0  1  2  3  4  5
     /|\               val: A  B  D  E  C  F
    B C F
   /|
  D E

tin: A=0, B=1, C=4, D=2, E=3, F=5
tout: A=6, B=4, C=5, D=3, E=4, F=6

Subtree of B: positions [1, 3] = [B, D, E]
              (tout[B]=4, so range is [1, 4-1])
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build Euler tour | O(n) |
| Check if u is ancestor of v | O(1) |
| Subtree query (with seg tree) | O(log n) |

## Euler Tour vs Other Tree Techniques

| Technique | Preprocess | Query | Best For |
|-----------|------------|-------|----------|
| **Euler Tour** | O(n) | O(log n) | Subtree queries |
| Heavy-Light | O(n) | O(log² n) | Path queries/updates |
| Centroid | O(n log n) | O(log n) | Distance queries |
| LCA | O(n log n) | O(log n) | Ancestor queries |

**Choose Euler Tour when**: You need efficient subtree operations.

## Checking Ancestor Relationship

```
u is an ancestor of v iff:
  tin[u] ≤ tin[v] AND tout[u] ≥ tout[v]

This is O(1) after preprocessing!

Example:
  Is 1 ancestor of 5?
  tin[1]=0 ≤ tin[5]=2 ✓
  tout[1]=11 ≥ tout[5]=3 ✓
  Yes!
```

## Implementation Notes

- Use iterative DFS with explicit stack to avoid stack overflow on deep trees
- For Type 2 tour, record node on both entry and exit
- tin[u] is always < tout[u] for the same node
- Children of u have tin values in (tin[u], tout[u])
- Size of subtree = (tout[u] - tin[u] + 1) / 2 for Type 2

