# Union-Find (Disjoint Set Union) - Beginner-Friendly Guide

Union-Find (also called DSU) manages **disjoint sets** and supports two fast
operations:

- **Find**: which set is this element in?
- **Union**: merge two sets.

With path compression and union-by-rank, both operations are **almost O(1)**.

---

## 1) The problem it solves

You have items that slowly become connected:

```
union(0, 1)
union(1, 2)
union(3, 4)
```

Now you want to answer:

```
connected(0, 2)?  -> yes
connected(0, 4)?  -> no (until we connect them)
```

Union-Find answers these in nearly constant time.

---

## 2) The data structure (forest of trees)

Each set is stored as a tree.
The root represents the set ID.

Initial state — 5 elements, each its own root (`parent[i] = i`, `rank[i] = 0`):

```
index:   0   1   2   3   4
parent:  0   1   2   3   4
rank:    0   0   0   0   0

 [0] [1] [2] [3] [4]   <- each node is its own root
```

---

## 3) Union by rank — step by step

Union by rank keeps trees shallow by always attaching the tree with the
**lower rank** under the tree with the **higher rank**.  The rank is an upper
bound on tree height and is incremented only when two roots of equal rank are
merged.

### Step 1: union(0, 1) — both have rank 0 (equal), so rank of chosen root grows

```
Before:           After:
[0]  [1]          [0]      <- root_0 chosen, rank[0] becomes 1
                   |
                  [1]

parent: [0,1,...] -> [0,0,...]
rank:   [0,0,...] -> [1,0,...]
```

### Step 2: union(2, 3) — both have rank 0 (equal), rank of chosen root grows

```
Before:           After:
[2]  [3]          [2]      <- root_2 chosen, rank[2] becomes 1
                   |
                  [3]

parent: [...,2,3,...] -> [...,2,2,...]
rank:   [...,0,0,...] -> [...,1,0,...]
```

### Step 3: union(4, 5) — same pattern

```
Before:           After:
[4]  [5]          [4]      <- root_4 chosen, rank[4] becomes 1
                   |
                  [5]
```

### Step 4: union(0, 2) — rank[0]=1 equals rank[2]=1, so rank of chosen root grows

```
Before:           After:
  [0]    [2]            [0]          <- rank[0] becomes 2
   |      |            /   \
  [1]    [3]         [1]   [2]
                            |
                           [3]

parent[2] = 0
rank[0]   = 2
```

### Step 5: union(0, 4) — rank[0]=2 > rank[4]=1, so [4] goes under [0]

```
Before:               After:
     [0]                     [0]
    /   \                  / | \
  [1]   [2]             [1] [4] [2]
          |                  |    |
         [3]                [5]  [3]

parent[4] = 0     (rank stays unchanged; rank[0] is already higher)
rank: no change
```

The tree stays shallow because the smaller (lower-rank) tree is always
attached beneath the larger one.

---

## 4) Path compression — step by step

Every `find(x)` call shortens the path to the root.  After the call, every
node that was on the path points **directly** to the root.  Future finds on
any of those nodes cost O(1).

### Before find(4) — a deep chain

Suppose after a sequence of unions we have built this chain:

```
 [0]              root
  |
 [1]
  |
 [2]
  |
 [3]
  |
 [4]              <- we call find(4)
```

### Pass 1: walk up to discover the root

```
find(4) -> follow parent chain: 4 -> 3 -> 2 -> 1 -> 0
root = 0
```

### Pass 2: compress — redirect every node on the path to the root

```
parent[4] = 0
parent[3] = 0
parent[2] = 0
parent[1] = 0    (was already 0; no change)
```

### After find(4) — flat tree

```
      [0]           root
   / | | \
 [1][2][3][4]       all children point directly to root
```

Any future call to `find(1)`, `find(2)`, `find(3)`, or `find(4)` now takes
exactly **one** step.

---

## 5) Combined effect: amortized near-constant time

Alone, each optimisation already improves performance significantly.
Together they achieve the theoretical optimum:

```
Operation      Single call (worst)   Amortized per call
-----------    -------------------   ------------------
find           O(log n)              O(alpha(n))
union          O(log n)              O(alpha(n))
connected      O(log n)              O(alpha(n))
```

`alpha(n)` is the inverse Ackermann function.  For every practical input size
(including the number of atoms in the observable universe), `alpha(n) <= 4`.

---

## 6) Example: connectivity queries

```mbt check
///|
test "union find connectivity" {
  let uf = @union_find.UnionFind::new(5)
  inspect(uf.connected(0, 4), content="false")
  let _ = uf.union(0, 1)
  let _ = uf.union(1, 2)
  let _ = uf.union(3, 4)
  inspect(uf.connected(0, 2), content="true")
  inspect(uf.connected(0, 4), content="false")
  let _ = uf.union(2, 3)
  inspect(uf.connected(0, 4), content="true")
}
```

---

## 7) Example: counting components

```mbt check
///|
test "union find count sets" {
  let uf = @union_find.UnionFind::new(6)
  inspect(uf.count_sets(), content="6")
  let _ = uf.union(0, 1)
  let _ = uf.union(2, 3)
  inspect(uf.count_sets(), content="4")
  let _ = uf.union(0, 2)
  inspect(uf.count_sets(), content="3")
}
```

---

## 8) Example: sizes of components

```mbt check
///|
test "union find set size" {
  let uf = @union_find.UnionFind::new(5)
  let _ = uf.union(0, 1)
  let _ = uf.union(1, 2)
  inspect(uf.set_size(0), content="3")
  inspect(uf.set_size(3), content="1")
  let _ = uf.union(2, 3)
  inspect(uf.set_size(3), content="4")
}
```

---

## 9) Typical use cases

```
Connectivity in graphs
Kruskal's minimum spanning tree
Connected components in images
Grouping friends in social networks
Equivalence classes (A = B, B = C)
```

---

## 10) Kruskal's MST (how DSU fits)

Kruskal's algorithm:

```
1. Sort edges by weight
2. For each edge (u, v):
   if not connected(u, v):
     union(u, v)
     add edge to MST
```

Union-Find makes step 2 extremely fast.

---

## 11) Complexity

```
Operation      Cost (amortized)
find           O(alpha(n))
union          O(alpha(n))
connected      O(alpha(n))
count_sets     O(1)
set_size       O(n * alpha(n))
```

`alpha(n)` is the inverse Ackermann function (so small it is < 5 for any real input).

---

## 12) Common pitfalls

- Forgetting to call `find` before comparing roots.
- Assuming `set_size(x)` works on non-roots (this implementation handles it).
- Mixing up 0-indexed and 1-indexed element IDs.
