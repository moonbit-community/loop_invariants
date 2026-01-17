# Centroid Decomposition (Tree Divide & Conquer)

## What It Is

**Centroid decomposition** breaks a tree into smaller pieces by repeatedly
removing a **centroid**. The centroids become the nodes of a new tree
(the *centroid tree*), which has **O(log n)** height.

This structure makes many tree queries fast because any node has only
O(log n) centroid ancestors.

## The Problem It Solves

Tree problems often ask for *path* or *distance* queries (not just subtree
queries). Examples:

- Count pairs of nodes at distance k
- Find the nearest "marked" node to a query node
- Count paths with certain properties

Centroid decomposition turns these into **logarithmic** queries after
preprocessing.

## What Is a Centroid?

For a tree with `n` nodes, a **centroid** is a node whose removal splits the
tree into components of size at most `n/2`.

Facts:

- Every tree has **at least one centroid**.
- There can be two centroids (adjacent) in some trees.

Example (n = 7):

```
        1
       /|\
      2 3 4
     /|   |
    5 6   7

Removing node 1 leaves components of size 3,1,2  (all <= 7/2)
So node 1 is a centroid.
```

## Core Idea of Decomposition

1. Find a centroid `c` of the current tree.
2. Remove `c`. The tree splits into smaller subtrees.
3. Recurse on each subtree and connect their centroids under `c`.

Because each subtree is at most half the size, the centroid tree has
**O(log n)** depth.

## How to Find a Centroid

Two DFS passes:

1. Compute subtree sizes.
2. Walk again to find a node where no component exceeds n/2.

Pseudo-logic:

```
size[u] = 1 + sum(size[child])

u is centroid if:
  max( size[child] for children, n - size[u] ) <= n/2
```

## Why It Helps

Any node appears in the decomposition path only once per level, and the
height is O(log n). So operations that combine data along centroid ancestors
are typically **O(log n)**.

## Example Usage

```mbt check
///|
test "centroid path" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let cd = @centroid.build_centroid(5, edges[:])
  inspect(cd.depth(2), content="0")
  inspect(cd.parent(2), content="-1")
}
```

```mbt check
///|
test "centroid star" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let cd = @centroid.build_centroid(5, edges[:])
  inspect(cd.depth(0), content="0")
  inspect(cd.parent(1), content="0")
}
```

## Common Applications

### 1. Nearest Marked Node
Maintain for each centroid the best distance to a marked node. Query walks
up the centroid ancestors and takes the minimum.

### 2. Count Pairs at Distance k
For each centroid, combine distances in its subtrees using counting arrays
or maps. This gives O(n log n) total time for all counts.

### 3. Path Queries with Constraints
If you can break a path into contributions from centroid ancestors, you
get logarithmic query time.

## Complexity

- Build centroid tree: **O(n log n)**
- Depth of centroid tree: **O(log n)**
- Typical query: **O(log n)**

## Pitfalls

- Always mark removed nodes so they are skipped in DFS.
- If values are weighted, store distances while climbing centroid ancestors.
- Handle the case of two possible centroids (either choice is valid).

## When to Use

Use centroid decomposition when:

- The tree is static (no edge updates), and
- You need many path/distance queries

If you only need subtree queries, Euler tours are simpler.
