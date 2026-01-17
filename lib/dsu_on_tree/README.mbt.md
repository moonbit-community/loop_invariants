# DSU on Tree (Small-to-Large Merging)

## Overview

**DSU on Tree** (also called Small-to-Large or Sack) is a technique for answering
subtree queries efficiently. It processes each subtree by keeping the heavy
child's data and merging light children into it.

- **Time**: O(n log n)
- **Space**: O(n)
- **Key Feature**: Efficient subtree queries without persistent data structures

## The Key Insight

```
Problem: For each node, answer a query about its subtree
         (e.g., count of each color, mode, distinct elements)

Naive: For each node, traverse its entire subtree → O(n²)

DSU on Tree insight:
  - Heavy-Light decomposition identifies a "heavy child" for each node
  - Keep the heavy child's data structure when processing parent
  - Only rebuild for light children (each node is a light child O(log n) times)

Result: O(n log n) total time!
```

## Understanding Heavy-Light Decomposition for DSU

```
Heavy child: The child with the largest subtree size
Light child: All other children

Key property: Any path from root to leaf has O(log n) light edges

Tree example:
          1
         /|\
        2 3 4  ← 3 has largest subtree, so 3 is heavy
       /|   |
      5 6   7  ← 5 is heavy child of 2
     / \
    8   9     ← 8 is heavy child of 5

Heavy path: 1 → 3, 2 → 5 → 8
Light edges: 1→2, 1→4, 2→6, 5→9
```

## The Algorithm

```
For each node u (post-order DFS):

1. Recursively solve light children with keep=false
   (Their data structures are discarded after use)

2. Recursively solve heavy child with keep=true
   (Keep its data structure!)

3. Add all nodes from light subtrees + node u to the data structure

4. Record the answer for node u

5. If keep=false for u, clear the data structure
```

## Visual: Processing Order

```
Tree:       Processing order for DSU on tree:
    1
   /|\       1. Process 4 (light), discard data
  2 3 4      2. Process 6 (light), discard data
 /|          3. Process 5 (heavy of 2), keep data
5 6          4. Process 2: add 6's subtree to 5's data, record answer
             5. Process 3 (heavy of 1), keep data
             6. Process 1: add 2,4 subtrees to 3's data, record answer

Key: When processing node u, we reuse data from heavy child!
```

## Algorithm Walkthrough

```
Problem: For each node, find sum of colors with maximum frequency

Tree:        Colors:
    0         0: red
   /|\        1: blue
  1 2 3       2: red
 / \          3: blue
4   5         4: green

Subtree sizes: 0→6, 1→3, 2→1, 3→1, 4→1, 5→1
Heavy children: 0→1, 1→4 (or 5)

Process order:
1. Node 5 (leaf): freq={blue:1}, max_freq=1, answer=blue
2. Node 4 (leaf): freq={green:1}, max_freq=1, answer=green
3. Node 1 (heavy=4): Keep 4's data, add 5
   freq={green:1, blue:1}, max=1, answer=green+blue
4. Node 2 (leaf): freq={red:1}, answer=red
5. Node 3 (leaf): freq={blue:1}, answer=blue
6. Node 0 (heavy=1): Keep 1's data, add 2,3,0
   freq={green:1, blue:2, red:2}, max=2, answer=blue+red
```

## Example Usage

```mbt check
///|
test "dsu on tree example" {
  let adj : Array[Array[Int]] = []
  for _ in 0..<5 {
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
  let colors : Array[Int] = [1, 2, 1, 2, 3]
  let result = @dsu_on_tree.subtree_color_mode_sum(adj, colors)
  inspect(result, content="[3, 2, 1, 2, 3]")
}
```

```mbt check
///|
test "dsu on tree tie" {
  let adj : Array[Array[Int]] = []
  for _ in 0..<3 {
    adj.push([])
  }
  adj[0].push(1)
  adj[1].push(0)
  adj[1].push(2)
  adj[2].push(1)
  let colors : Array[Int] = [5, 5, 7]
  let result = @dsu_on_tree.subtree_color_mode_sum(adj, colors)
  // Node 1's subtree has colors {5,7} so max frequency is 1, sum = 12
  // Node 0's subtree includes all nodes, max frequency is 2 for color 5
  inspect(result, content="[5, 12, 7]")
}
```

## Why O(n log n)?

```
Each node is "added" to a data structure how many times?

A node is added when:
  1. Processing its own subtree: 1 time
  2. Being merged as a light child: Only happens when parent has a heavier sibling

Key observation: Each node is in a light subtree O(log n) times
  (Every time we go through a light edge, subtree size at least doubles)

Total work: O(n log n)
```

## Common Applications

### 1. Color Mode Queries
```
For each subtree, find the most frequent color
or sum of all colors with maximum frequency.
```

### 2. Distinct Count
```
For each subtree, count the number of distinct values.
```

### 3. K-th Element
```
For each subtree, find the k-th smallest element.
Requires a balanced BST or similar.
```

### 4. Range Queries in Trees
```
Answer queries about paths or subtrees efficiently.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Total processing | O(n log n) |
| Per-node work | O(subtree_size × log n) amortized |
| Space | O(n) for data structure |

## DSU on Tree vs Other Approaches

| Technique | Time | Use Case |
|-----------|------|----------|
| **DSU on Tree** | O(n log n) | Subtree queries, online |
| Euler Tour + Segment Tree | O(n log n) | Range/subtree queries |
| Heavy-Light Decomposition | O(n log² n) | Path + subtree queries |
| Centroid Decomposition | O(n log n) | Path queries |

**Choose DSU on Tree when**: You need subtree queries and can't use Euler tour reduction.

## The "Small-to-Large" Name

```
The technique is also called "small-to-large" merging:

When merging two sets:
  - Always merge the smaller set into the larger one
  - Each element moves O(log n) times total

This is exactly what happens with light/heavy children:
  - Light children are "smaller" sets
  - Heavy child is the "larger" set
  - We merge light into heavy
```

## Implementation Notes

- First compute subtree sizes to identify heavy children
- Process tree in post-order (bottom-up)
- Use a global data structure, clear when keep=false
- Track maximum frequency and sum separately
- Be careful with root's keep parameter (usually false)
