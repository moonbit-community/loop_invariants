# Lowest Common Ancestor (LCA)

## Overview

The **Lowest Common Ancestor** of two nodes u and v in a tree is the deepest
node that is an ancestor of both. This package uses **Binary Lifting** for
efficient queries.

- **Preprocessing**: O(n log n)
- **Query**: O(log n)
- **Space**: O(n log n)

## Visual Example

```
Tree:
          0 (root)
        / | \
       1  2  3
      / \
     4   5

LCA(4, 5) = 1    (immediate parent of both)
LCA(4, 2) = 0    (must go up to root)
LCA(4, 3) = 0    (must go up to root)
LCA(1, 5) = 1    (1 is ancestor of 5)
```

## The Binary Lifting Technique

### Key Insight

Precompute 2^k-th ancestors for each node. Any ancestor can be reached
by combining powers of 2 (like binary representation of a number).

```
up[v][k] = 2^k-th ancestor of node v

up[v][0] = parent[v]
up[v][1] = up[up[v][0]][0]  (grandparent)
up[v][2] = up[up[v][1]][1]  (great-great-grandparent)
...
up[v][k] = up[up[v][k-1]][k-1]
```

### Example Table

```
Tree:     0
         / \
        1   2
       / \
      3   4
     /
    5

Depth:  0  1  2  2  3
Node:   0  1  2  3  4  5

up table (2^k ancestor):
        k=0  k=1  k=2
node 0:  -1   -1   -1
node 1:   0   -1   -1
node 2:   0   -1   -1
node 3:   1    0   -1
node 4:   1    0   -1
node 5:   3    1    0
```

## LCA Query Algorithm

### Step 1: Bring Nodes to Same Depth

```
LCA(5, 2):
  depth[5] = 3, depth[2] = 1
  diff = 3 - 1 = 2 = binary 10

  Lift node 5 by 2:
    k=0: bit not set, skip
    k=1: bit set, lift by 2^1 = 2
         5 → up[5][1] = 1

  Now both at depth 1: node 1 and node 2
```

### Step 2: Binary Search for LCA

```
After leveling: u=1, v=2

Check from high k down to 0:
  k=1: up[1][1]=-1, up[2][1]=-1, equal → don't jump
  k=0: up[1][0]=0, up[2][0]=0, equal → don't jump

Both already have same 2^k ancestors at every level?
That means LCA = up[1][0] = 0

Actually, we first check if u == v:
  1 ≠ 2, so continue

After loop, return up[1][0] = 0

LCA(5, 2) = 0 ✓
```

### Complete Example

```
LCA(4, 5):
  depth[4] = 2, depth[5] = 3
  Lift 5 by 1: 5 → 3
  Now depth[3] = 2 = depth[4]

  Check: 3 ≠ 4
  k=1: up[3][1]=0, up[4][1]=0, equal → don't jump
  k=0: up[3][0]=1, up[4][0]=1, equal → don't jump

  Return up[3][0] = 1

LCA(4, 5) = 1 ✓
```

## Common Operations

### Distance Between Nodes

```
dist(u, v) = depth[u] + depth[v] - 2 * depth[LCA(u, v)]

Example: dist(4, 5)
  LCA(4, 5) = 1
  dist = 2 + 3 - 2*1 = 3

Path: 4 → 1 → 3 → 5 (3 edges)
```

### k-th Ancestor

```
To find the k-th ancestor of v:
- Decompose k into binary: k = sum of 2^i
- Jump using up[v][i] for each set bit

10th ancestor of node v:
  10 = 8 + 2 = 2^3 + 2^1
  v → up[v][1] → up[...][3]
```

### Path Queries

```
Query on path from u to v:
1. Find LCA(u, v)
2. Query u → LCA path
3. Query LCA → v path
4. Combine results
```

## Common Applications

### 1. Tree Distance Queries

```
Given: Tree with weighted edges
Query: Distance between any two nodes

Solution:
- Precompute dist_to_root[v] during DFS
- dist(u, v) = dist_to_root[u] + dist_to_root[v]
             - 2 * dist_to_root[LCA(u, v)]
```

### 2. Subtree Checks

```
Is u an ancestor of v?
  LCA(u, v) == u

Is v in the subtree of u?
  Same as above!
```

### 3. Path Aggregation

```
Maximum edge weight on path from u to v:
- Store max weight to each 2^k ancestor
- Query by combining along path to LCA
```

### 4. Tree Isomorphism

```
LCA queries help compare tree structures efficiently.
```

## Example Usage

```mbt check
///|
test "lca basic" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (1, 5)]
  let lca = @lca.LCA::new(6, edges)
  inspect(lca.query(4, 5), content="1")
  inspect(lca.query(4, 2), content="0")
}
```

```mbt check
///|
test "lca ancestor" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let lca = @lca.LCA::new(5, edges)
  inspect(lca.query(1, 4), content="1")
  inspect(lca.query(3, 4), content="1")
}
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Preprocessing | O(n log n) |
| LCA query | O(log n) |
| Distance query | O(log n) |
| k-th ancestor | O(log n) |
| Path enumeration | O(path length) |

### Space Breakdown

```
up[n][log n] table: O(n log n)
depth[n]: O(n)
Total: O(n log n)
```

## LCA vs Other Methods

| Method | Preprocess | Query | Space |
|--------|------------|-------|-------|
| **Binary Lifting** | O(n log n) | O(log n) | O(n log n) |
| Euler Tour + RMQ | O(n) | O(1) | O(n) |
| Heavy-Light Decomp | O(n) | O(log n) | O(n) |
| Naive (DFS each) | O(1) | O(n) | O(1) |

**Choose Binary Lifting when**: You need simple implementation with good performance.

## Weighted LCA

For trees with edge weights:

```
Structure:
  lca: LCA           // Standard LCA structure
  dist_to_root[v]    // Weighted distance from root

Query weighted distance:
  dist(u, v) = dist_to_root[u] + dist_to_root[v]
             - 2 * dist_to_root[LCA(u, v)]
```

## Implementation Notes

- Root is typically node 0
- Use -1 to indicate "no ancestor"
- log_n should be ceil(log2(n)) + 1
- Handle edge cases: same node, invalid indices
