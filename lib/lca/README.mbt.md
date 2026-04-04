# Lowest Common Ancestor (LCA) with Binary Lifting

## Overview

The **Lowest Common Ancestor** of two nodes `u` and `v` in a rooted tree is the deepest
node that is an ancestor of both. It is the core primitive behind:

- Distance queries between nodes
- Subtree containment checks
- Tree path aggregation problems

This package uses **binary lifting** for efficient preprocessing and queries:

- **Preprocess**: O(n log n)
- **Query**: O(log n)
- **Space**: O(n log n)

## Tree Diagram and LCA Examples

```
Tree rooted at 0:

          0           depth 0
        / | \
       1  2  3        depth 1
      / \
     4   5            depth 2

LCA(4, 5) = 1   (both are children of 1)
LCA(4, 2) = 0   (paths to root diverge at 0)
LCA(4, 3) = 0   (paths to root diverge at 0)
LCA(1, 5) = 1   (1 is already an ancestor of 5)
```

The LCA is the last shared node on the two root-to-node paths:

```
path(root -> 4) = [0, 1, 4]
path(root -> 2) = [0, 2]
                        ^
                   last shared = 0    =>  LCA(4, 2) = 0

path(root -> 4) = [0, 1, 4]
path(root -> 5) = [0, 1, 5]
                        ^
                   last shared = 1    =>  LCA(4, 5) = 1
```

## Binary Lifting Table

For each node `v` and each power `k`, precompute:

```
up[v][k] = 2^k-th ancestor of v  (or -1 if it doesn't exist)
```

The recurrence is:

```
up[v][0] = parent(v)
up[v][k] = up[ up[v][k-1] ][k-1]
           ^-- 2^k ancestor = 2^(k-1) ancestor of the 2^(k-1) ancestor
```

### Example Table

Tree:

```
    0
   / \
  1   2
 / \
3   4
/
5
```

Depths and ancestor table (log_n = 3 for n = 6):

```
node  | depth | up[][0]  | up[][1]  | up[][2]
      |       | (parent) | (2^1=2nd)| (2^2=4th)
------+-------+----------+----------+----------
  0   |   0   |   -1     |   -1     |   -1
  1   |   1   |    0     |   -1     |   -1
  2   |   1   |    0     |   -1     |   -1
  3   |   2   |    1     |    0     |   -1
  4   |   2   |    1     |    0     |   -1
  5   |   3   |    3     |    1     |    0
```

Any ancestor reachable in `k` steps is found by decomposing `k` into bits.
For example, to jump 5 = (101)_2 levels: jump 2^2, then jump 2^0.

## Step-by-Step LCA Query: LCA(5, 4)

### Step 1: Equalize Depths

Find which node is deeper and bring it up to the same depth:

```
depth[5] = 3,  depth[4] = 2
diff = 3 - 2 = 1 = (001)_2

Lift node 5 by 2^0 = 1:
  up[5][0] = 3

After lifting:   curr_u = 3,  curr_v = 4
Both at depth 2.
```

### Step 2: Check if Equal

```
curr_u = 3,  curr_v = 4  =>  not equal, continue.
```

### Step 3: Jump Together from Highest Bit

Scan k from log_n-1 down to 0. Jump both nodes when their 2^k ancestors differ:

```
k=2: up[3][2] = -1,  up[4][2] = -1   (equal -> no jump)
k=1: up[3][1] =  0,  up[4][1] =  0   (equal -> no jump)
k=0: up[3][0] =  1,  up[4][0] =  1   (equal -> no jump)
```

No jumps were made, so curr_u = 3, curr_v = 4 remain.

### Step 4: Return Parent

```
LCA(5, 4) = up[curr_u][0] = up[3][0] = 1
```

### Another Example: LCA(5, 2)

```
depth[5] = 3,  depth[2] = 1
diff = 2 = (010)_2

Lift node 5 by 2^1 = 2:
  up[5][1] = 1

After lifting:   curr_u = 1,  curr_v = 2
Both at depth 1. Not equal, continue.

k=2: up[1][2] = -1,  up[2][2] = -1   (equal -> no jump)
k=1: up[1][1] = -1,  up[2][1] = -1   (equal -> no jump)
k=0: up[1][0] =  0,  up[2][0] =  0   (equal -> no jump)

LCA(5, 2) = up[curr_u][0] = up[1][0] = 0
```

## Common Operations Using LCA

### Distance Between Nodes

```
dist(u, v) = depth[u] + depth[v] - 2 * depth[LCA(u, v)]
```

### Ancestor Check

```
Is u ancestor of v?   LCA(u, v) == u
```

### k-th Ancestor

Decompose `k` into powers of two and jump using `up[v][bit]`:

```
k = 5 = (101)_2
  jump 2^2:  v -> up[v][2]
  jump 2^0:  v -> up[v][0]
```

### Path Queries

Split the path at the LCA and combine results:

```
query(u, v) = combine(query(u, lca), query(lca, v))
```

## Weighted Trees (Distance Queries)

Store `dist_to_root[v]` during DFS:

```
dist(u, v) = dist_to_root[u] + dist_to_root[v]
           - 2 * dist_to_root[LCA(u, v)]
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
test "lca distance via depths" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (1, 3)]
  let lca = @lca.LCA::new(4, edges)
  let l = lca.query(2, 3)
  let dist = lca.depth[2] + lca.depth[3] - 2 * lca.depth[l]
  inspect(dist, content="2")
}
```

## Common Pitfalls

- **Rooted tree**: LCA depends on a root (here root = 0).
- **Invalid nodes**: queries outside `[0..n-1]` return `-1`.
- **Disconnected graph**: this expects a tree, not a forest.
- **Log size**: use `ceil(log2(n)) + 1` for ancestor table height.

## Complexity

| Operation      | Time       | Space          |
|----------------|------------|----------------|
| Build          | O(n log n) | O(n log n)     |
| LCA query      | O(log n)   | O(1) extra     |
| Distance query | O(log n)   | O(1) extra     |
| k-th ancestor  | O(log n)   | O(1) extra     |

## Binary Lifting vs Other Methods

| Method             | Preprocess | Query    | Notes                     |
|--------------------|------------|----------|---------------------------|
| Binary Lifting     | O(n log n) | O(log n) | simple, fast              |
| Euler Tour + RMQ   | O(n)       | O(1)     | more complex              |
| HLD                | O(n)       | O(log n) | if you already need HLD   |

Binary lifting is usually the best balance of simplicity and speed.
