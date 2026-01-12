# Centroid Decomposition

## Overview

**Centroid Decomposition** divides a tree by repeatedly removing centroids,
creating a decomposition tree of logarithmic depth. This enables efficient
path queries and distance computations on trees.

- **Build**: O(n log n)
- **Depth**: O(log n)
- **Space**: O(n)

## What is a Centroid?

```
A centroid is a node whose removal splits the tree
such that no remaining subtree has more than n/2 nodes.

Tree with 7 nodes:
        1
       /|\
      2 3 4
     /|   |
    5 6   7

Subtree sizes from node 2:
  - Remove 2: largest remaining = 4 nodes (via 1)

Subtree sizes from node 1:
  - Remove 1: largest remaining = 3 nodes (subtree of 2)

Node 1 is the centroid: max subtree ≤ 7/2 = 3.5 ✓

Every tree has at least one centroid!
```

## The Key Insight

```
After removing centroid, each subtree has ≤ n/2 nodes.
Apply recursively: each level halves the problem size.

Level 0: n nodes → find centroid c₀
Level 1: each subtree ≤ n/2 nodes → find their centroids
Level 2: each subtree ≤ n/4 nodes
...
Level log(n): single nodes

This gives a centroid tree of depth O(log n)!
```

## Algorithm Walkthrough

```
Tree:
        1
       /|\
      2 3 4
     /|   |
    5 6   7

Step 1: Find centroid of whole tree
  Sizes: 5→1, 6→1, 7→1, 2→3, 4→2, 3→1, 1→7
  Centroid: 1 (removing it → max subtree = 3)

Step 2: Remove 1, decompose subtrees
  Subtree rooted at 2: {2, 5, 6}
    Centroid: 2
  Subtree rooted at 3: {3}
    Centroid: 3
  Subtree rooted at 4: {4, 7}
    Centroid: 4

Step 3: Continue recursively
  {5}, {6}, {7} are single nodes

Centroid Tree:
        1
       /|\
      2 3 4
     /|   |
    5 6   7

(In general, centroid tree structure differs from original!)
```

## Finding the Centroid

```
Algorithm:
1. Compute subtree sizes via DFS
2. For each node u, check if it's a centroid:
   - All children subtrees ≤ n/2
   - Parent's portion ≤ n/2 (n - size[u])

def find_centroid(tree, n):
    sizes = compute_sizes(tree)
    for u in tree:
        is_centroid = true
        for child in u.children:
            if sizes[child] > n/2:
                is_centroid = false
        if n - sizes[u] > n/2:
            is_centroid = false
        if is_centroid:
            return u
```

## Visual: Centroid Tree vs Original

```
Original Tree:           Centroid Tree:
    1                         4
   / \                       /|\
  2   3                     2 1 5
 / \   \                   /| |\
4   5   6                 3 7 6 8
|   |
7   8

The centroid tree has depth O(log n) even if
the original tree is a long chain!

Original: Chain of 8      Centroid Tree:
1-2-3-4-5-6-7-8              4
                            / \
                           2   6
                          /|   |\
                         1 3   5 7
                                 |
                                 8

Depth reduced from 7 to 3!
```

## Example Usage

```mbt nocheck
// Build centroid tree for a 5-node path: 0-1-2-3-4
let ct = CentroidTree::new(5)
ct.add_edge(0, 1)
ct.add_edge(1, 2)
ct.add_edge(2, 3)
ct.add_edge(3, 4)
ct.build()

// Node 2 is the centroid (middle of path)
ct.get_depth(2)  // 0 - root of centroid tree
ct.get_parent(2) // -1 - no parent
```

## Common Applications

### 1. Path Queries
```
Query: Count paths of length exactly k
For each centroid:
  - Gather distances to all nodes in subtree
  - Count pairs summing to k
  - Recurse on child subtrees
Time: O(n log n) for all queries
```

### 2. Distance Queries
```
Query: Find closest node with property P
Precompute: For each centroid, store distances
            to all nodes in its subtree
Query: Walk up centroid tree, check each level
Time: O(log n) per query after O(n log n) preprocess
```

### 3. Tree Coloring
```
Query: Count pairs of same-colored nodes at distance ≤ d
Decompose by centroid, aggregate counts at each level.
```

## Why O(n log n) Total?

```
Each node appears in O(log n) centroid subtrees.

Work per node at each level: O(1) or O(degree)
Total work: O(n × log n)

Key insight: When processing centroid c,
we only process nodes in c's current subtree.
Each node is in at most O(log n) such subtrees.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build centroid tree | O(n log n) |
| Find one centroid | O(n) |
| Depth of decomposition | O(log n) |

## Centroid Decomposition vs Other Techniques

| Technique | Preprocess | Query | Use Case |
|-----------|------------|-------|----------|
| **Centroid** | O(n log n) | O(log n) | Path queries |
| Heavy-Light | O(n) | O(log² n) | Path updates |
| Euler Tour | O(n) | O(1) subtree | Subtree queries |
| LCA | O(n log n) | O(log n) | Ancestor queries |

**Choose Centroid Decomposition when**: You need efficient path counting or distance queries on trees.

## Implementation Notes

- Mark nodes as "removed" instead of actually removing them
- Store parent in centroid tree for walking up during queries
- Use two DFS passes: one for sizes, one to find centroid
- Handle the case where multiple nodes could be centroids (pick any)
- For weighted edges, track distances during decomposition

