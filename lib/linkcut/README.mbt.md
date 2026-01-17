# Link‑Cut Tree (Dynamic Forest)

## What It Solves

A **Link‑Cut Tree (LCT)** maintains a **forest of dynamic trees** where edges
can be added or removed while still supporting fast **path queries**.

You can do (amortized O(log n)):

- `link(u, v)` — connect two trees
- `cut(u, v)` — remove an edge
- `connected(u, v)` — check connectivity
- `path_sum(u, v)` or other path aggregates

Static trees can use HLD/LCA; LCT is designed for **dynamic** trees.

## Core Idea: Preferred Paths + Splay Trees

Each represented tree is decomposed into **preferred paths**.
Each preferred path is stored as a **splay tree** (an auxiliary tree).

```
Represented tree:            Preferred paths (one possible state):
      1                               [1-2-4]
     /|\                              [3]
    2 3 6                             [5]
   /|                                 [6]
  4 5
```

Preferred paths change as we access nodes. The key operation is `access`.

## The Access Operation (Most Important)

`access(x)` makes the path from **x to root** a single preferred path.
That path becomes one splay tree with `x` at its root.

```
Before access(5):               After access(5):
Preferred paths:                Preferred paths:
  [1-2-4]                         [1-2-5]
  [3]                             [3]
  [5]                             [4]

Result: the path 1-2-5 is now the preferred path.
```

This is the building block for **link**, **cut**, **find_root**, and **lca**.

## Visual: Splay Tree vs Represented Tree

Splay rotations only rearrange the **auxiliary** tree; the represented tree
(topology of edges) does not change.

```
Represented tree:         Splay tree (preferred path order by depth)
     1                                 1
    / \                               / \
   2   3                             2   3
```

## Core Operations (High‑Level)

### make_root(x)

Reverse the preferred path so that `x` becomes the tree root.

```
make_root(x):
  access(x)
  flip the path (lazy reversal)
```

### link(u, v)

Connect two trees by linking `u` under `v`:

```
make_root(u)
access(v)
attach u as a child of v
```

### cut(u, v)

Remove the edge between u and v:

```
make_root(u)
access(v)
if v.left == u: cut it
```

### find_root(x)

```
access(x)
walk to leftmost node in the splay tree (shallowest)
```

## Worked Example (Dynamic Connectivity)

```
Start with 5 isolated nodes: 0 1 2 3 4

link(1, 0) -> 0-1
link(2, 1) -> 0-1-2
link(4, 3) -> 3-4

connected(0, 2) = true
connected(0, 3) = false

cut(1, 2) -> separates {0,1} and {2}
connected(0, 2) = false
```

## Example Usage (Conceptual)

The Link‑Cut Tree in this package is internal, so the following is
**illustrative** only.

```mbt nocheck
///|
let lct = LinkCutTree::new(5)

lct.link(1, 0)
lct.link(2, 1)
inspect(lct.connected(0, 2), content="true")

lct.cut(1, 2)
inspect(lct.connected(0, 2), content="false")
```

## Path Aggregates (Optional)

You can store values in nodes and aggregate them along the preferred path.
Example: path sum from `u` to `v`.

```
make_root(u)
access(v)
answer = v.path_sum   // aggregate in v's splay tree
```

This package maintains `path_sum` for each splay subtree.

## Complexity (Amortized)

| Operation | Time |
|-----------|------|
| access | O(log n) |
| link | O(log n) |
| cut | O(log n) |
| find_root | O(log n) |
| connected | O(log n) |
| path query | O(log n) |

## Common Pitfalls

- **Amortized bounds**: worst‑case for a single op can be larger.
- **Must reroot**: use `make_root(u)` before linking or cutting.
- **Dynamic only**: LCT is overkill for static trees.
- **Subtree queries**: LCT is designed for **path** queries, not subtree sums.

## When to Use Link‑Cut Trees

- You need to **add/remove edges** online.
- You need **path queries** after each update.
- You cannot rebuild heavy‑light or Euler tours each time.

If your tree is static, HLD or LCA are simpler and often faster.
