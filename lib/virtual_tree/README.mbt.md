# Virtual Tree (Auxiliary Tree)

## Overview

A **Virtual Tree** is the minimal subtree that connects a given subset of nodes
in a rooted tree. It preserves ancestor relationships while dramatically reducing
the tree size from n nodes to O(k) nodes, where k is the number of important nodes.

- **Time**: O(k log k) to build
- **Space**: O(k)
- **Key Feature**: Compress tree queries to only relevant nodes

## The Key Insight

```
Problem: Answer queries on a tree, but only k nodes matter

Full tree has n nodes, but we only care about k "important" nodes.
Processing all n nodes wastes time!

Virtual Tree insight:
  1. Keep only important nodes + their LCAs
  2. The LCAs are needed to preserve ancestor relationships
  3. Result: O(k) nodes instead of O(n)!

Full Tree (n=10):              Virtual Tree (k=3 important):
        1                              1
       /|\                            / \
      2 3 4                          2   4
     /|   |                         /
    5 6   7                        5
   / \   /|\
  8   9 A B C   (A,B,C = 10,11,12)

Important nodes: {5, 9, 7}
LCA(5,9) = 2, LCA(9,7) = 1
Virtual tree: {1, 2, 5, 9, 7} with edges preserving ancestry
```

## Visual: Building a Virtual Tree

```
Original Tree:              Important nodes: {3, 4, 5}
        0
       / \                  Step 1: Sort by DFS order (tin)
      1   2                   Nodes: [1, 3, 4, 5] (after sorting)
     / \   \
    3   4   5               Step 2: Add LCAs of consecutive pairs
                              LCA(3,4) = 1, LCA(4,5) = 0
DFS order (tin):              All nodes: {0, 1, 3, 4, 5}
  0:0, 1:1, 3:2, 4:3, 2:4, 5:5
                            Step 3: Build tree using stack
                              Result:
                                    0
                                   / \
                                  1   5
                                 / \
                                3   4
```

## Algorithm: Building Virtual Tree

```
build_virtual_tree(important_nodes):
  1. Sort nodes by DFS entry time (tin)

  2. Add LCAs of consecutive nodes:
     for i in 1..len(nodes):
       nodes.add(LCA(nodes[i-1], nodes[i]))

  3. Remove duplicates and sort again by tin

  4. Build tree using stack:
     stack = [nodes[0]]
     for node in nodes[1..]:
       // Pop until stack top is ancestor of node
       while not is_ancestor(stack.top, node):
         // Connect popped node to new top
         add_edge(stack.second_top, stack.top)
         stack.pop()
       stack.push(node)

     // Clear remaining stack
     while stack.size > 1:
       add_edge(stack.second_top, stack.top)
       stack.pop()
```

## Example Usage

```mbt check
///|
test "virtual tree example" {
  let adj : Array[Array[Int]] = []
  for _ in 0..<6 {
    adj.push([])
  }
  adj[0].push(1)
  adj[1].push(0)
  adj[0].push(2)
  adj[2].push(0)
  adj[1].push(3)
  adj[3].push(1)
  adj[1].push(4)
  adj[4].push(1)
  adj[2].push(5)
  adj[5].push(2)
  let vt = @virtual_tree.build_virtual_tree(adj, [3, 4, 5])
  inspect(vt.nodes, content="[0, 1, 3, 4, 5]")
}
```

## Why We Need LCAs

```
Without LCAs, we lose ancestor relationships:

Tree:       0           Important: {3, 5}
           / \
          1   2         Without LCA:
         /     \          3 --- 5  (Wrong! They're not siblings)
        3       5
                        With LCA (node 0):
                              0
                             / \
                            3   5  (Correct ancestry preserved)
```

## Algorithm Walkthrough

```
Tree:           Important nodes: [3, 4, 5]
      0
     / \
    1   2
   / \   \
  3   4   5

Step 1: DFS to compute tin/tout and LCA structure
  tin:  [0, 1, 2, 3, 4, 5]
  tout: [5, 3, 5, 2, 3, 5]

Step 2: Sort important nodes by tin
  [3, 4, 5] → [3, 4, 5] (tin = 2, 3, 5)

Step 3: Add LCAs of consecutive pairs
  LCA(3, 4) = 1 (tin = 1)
  LCA(4, 5) = 0 (tin = 0)
  All nodes: [0, 1, 3, 4, 5]

Step 4: Build tree with stack
  Process 0: stack = [0]
  Process 1: 0 is ancestor of 1, push → stack = [0, 1]
  Process 3: 1 is ancestor of 3, push → stack = [0, 1, 3]
  Process 4: 1 is ancestor of 4
             3 not ancestor of 4, pop 3, add edge 1→3
             push 4 → stack = [0, 1, 4]
  Process 5: 0 is ancestor of 5
             4 not ancestor of 5, pop 4, add edge 1→4
             1 not ancestor of 5, pop 1, add edge 0→1
             push 5 → stack = [0, 5]
  Clear: pop 5, add edge 0→5

Result edges: 1→3, 1→4, 0→1, 0→5
```

## Common Applications

### 1. Tree Path Queries on Subsets
```
Query: Sum of path lengths between all pairs in subset S
Solution: Build virtual tree of S, run DP on small tree
Time: O(k²) instead of O(k² * n)
```

### 2. Subtree Queries
```
Find minimum spanning tree connecting k nodes.
Virtual tree gives exactly the minimal connector.
```

### 3. Interactive Tree Problems
```
Multiple queries with different subsets.
Build virtual tree per query for efficiency.
```

### 4. Competitive Programming
```
"Query on k nodes in a tree" problems.
Virtual tree reduces complexity from O(n) to O(k) per query.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Preprocess LCA | O(n log n) | Binary lifting or similar |
| Build Virtual Tree | O(k log k) | Sorting + LCA queries |
| Virtual Tree Size | O(k) | At most 2k-1 nodes |

## Key Properties

```
1. Size bound: |virtual_tree| ≤ 2k - 1
   (k important nodes + at most k-1 LCAs)

2. Preserves ancestry: If u is ancestor of v in original tree,
   and both are in virtual tree, then u is ancestor of v in virtual tree

3. Edge weights: Can preserve path lengths by storing
   original tree distances as virtual tree edge weights
```

## Implementation Notes

- Precompute LCA structure (binary lifting) in O(n log n)
- Sort by DFS entry time for correct processing order
- The stack-based construction is elegant and O(k)
- Store edge weights if path distances matter
- Virtual tree root is the LCA of all important nodes

