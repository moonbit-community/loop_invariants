# Union-Find (Disjoint Set Union)

## Overview

**Union-Find** (also called DSU - Disjoint Set Union) maintains a collection of
disjoint sets and supports:
- **Union**: Merge two sets in **O(α(n))** amortized
- **Find**: Find which set an element belongs to in **O(α(n))** amortized

Where α(n) is the inverse Ackermann function, effectively constant (< 5 for all practical n).

## The Data Structure

Union-Find uses a forest of trees where each tree is one set:

```
Initial state (4 elements, each in its own set):

  [0]   [1]   [2]   [3]
   |     |     |     |
  (0)   (1)   (2)   (3)

parent[i] = i for all elements (each is its own root)
```

## How Union Works

Union(0, 1) - merge sets containing 0 and 1:

```
Before:           After:
  [0]   [1]         [0]
   |     |         /  \
  (0)   (1)      (0)  (1)

parent[1] = 0  (1's parent is now 0)
```

Union(2, 3), then Union(0, 2):

```
Step 1: Union(2,3)      Step 2: Union(0,2)
    [0]     [2]              [0]
   /  \      |              / | \
  (0) (1)   (3)           (0)(1)(2)
                               |
                              (3)

With union by size, smaller tree attaches to larger.
```

## Path Compression

The key optimization: when finding a root, make all nodes point directly to it:

```
Before find(3):          After find(3):
      [0]                     [0]
       |                    / | \ \
      (1)                 (1)(2)(3)(4)
       |
      (2)
       |
      (3)
       |
      (4)

All nodes now point directly to root!
```

## Visualization of Operations

```
Initial: 6 elements in 6 sets

Step 1: union(0, 1)     [0]─(1)
Step 2: union(2, 3)     [0]─(1)  [2]─(3)
Step 3: union(4, 5)     [0]─(1)  [2]─(3)  [4]─(5)
Step 4: union(0, 2)     [0]┬(1)  [4]─(5)
                           └(2)─(3)
Step 5: union(0, 4)     [0]┬(1)
                           ├(2)─(3)
                           └(4)─(5)

Now all 6 elements are in one set!
```

## Use Cases

### 1. Connectivity Queries

```mbt check
///|
test "connectivity" {
  let uf = @union_find.UnionFind::new(5)

  // Initially disconnected
  inspect(uf.connected(0, 4), content="false")

  // Build connections
  let _ = uf.union(0, 1)
  let _ = uf.union(1, 2)
  let _ = uf.union(3, 4)

  // Check connectivity
  inspect(uf.connected(0, 2), content="true") // 0-1-2
  inspect(uf.connected(0, 4), content="false") // Different components
  let _ = uf.union(2, 3)
  inspect(uf.connected(0, 4), content="true") // Now connected!
}
```

### 2. Counting Components

```mbt check
///|
test "counting components" {
  let uf = @union_find.UnionFind::new(6)
  inspect(uf.count_sets(), content="6") // 6 singletons
  let _ = uf.union(0, 1)
  let _ = uf.union(2, 3)
  inspect(uf.count_sets(), content="4") // {0,1}, {2,3}, {4}, {5}
  let _ = uf.union(0, 2)
  inspect(uf.count_sets(), content="3") // {0,1,2,3}, {4}, {5}
}
```

### 3. Kruskal's MST Algorithm

```
Kruskal's Algorithm for Minimum Spanning Tree:
1. Sort edges by weight
2. For each edge (u, v):
   if not connected(u, v):
     union(u, v)
     add edge to MST

Union-Find makes step 2 nearly O(1)!
```

## Common Applications

1. **Network Connectivity**: Are two computers connected?
2. **Image Processing**: Connected component labeling
3. **Social Networks**: Find friend groups
4. **Kruskal's MST**: Build minimum spanning tree
5. **Equivalence Classes**: Merge equivalent items
6. **Percolation**: Does water flow from top to bottom?

## Complexity Analysis

| Operation    | Naive | With Optimizations |
|--------------|-------|-------------------|
| Find         | O(n)  | O(α(n)) ≈ O(1)    |
| Union        | O(n)  | O(α(n)) ≈ O(1)    |
| Connected    | O(n)  | O(α(n)) ≈ O(1)    |

**Two key optimizations:**
1. **Path compression**: Flatten tree during find
2. **Union by size/rank**: Attach smaller tree under larger

Together they achieve nearly constant time!

## The Inverse Ackermann Function

α(n) grows incredibly slowly:
- α(10^80) < 5 (more atoms than in universe)
- For all practical purposes, α(n) ≤ 4

This makes Union-Find one of the most efficient data structures!

## Variants

### Weighted Union-Find
Track relationships between elements (e.g., "A is 3 units from B"):

```
Used in: Puzzle solving, physics simulations
```

### Union-Find with Rollback
Undo union operations:

```
Used in: Offline graph algorithms, divide-and-conquer
```

## Why Trees?

The tree structure allows efficient merging:

```
Merging two arrays: O(n)
Merging two trees:  O(1) - just change one pointer!

     [A]        [B]
    / | \        |
   .  .  .      ...

After union(A, B):

         [A]
        / | \ \
       .  .  . [B]
                |
               ...
```

## Implementation Notes

- Use 0-indexed elements
- `parent[i] = i` means i is a root
- `size[i]` is only valid when i is a root
- Path compression happens during `find()`, not `union()`
