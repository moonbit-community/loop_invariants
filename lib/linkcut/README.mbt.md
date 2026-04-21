# Link-Cut Tree (Dynamic Forest)

## What It Solves

A **Link-Cut Tree (LCT)** maintains a **forest of dynamic trees** where edges
can be added or removed at any time while still supporting fast **path queries**.

Supported operations (all amortized O(log n)):

- `link(u, v)` — connect two trees by adding edge u-v
- `cut(u, v)` — remove edge u-v
- `connected(u, v)` — check whether u and v are in the same tree
- `find_root(v)` — find the root of the tree containing v
- `make_root(v)` — reroot the tree at v
- `lca(u, v)` — lowest common ancestor
- `path_sum_to_root(v)` — sum of values along the path from v to the root

When your tree is static, HLD or LCA are simpler. Use LCT when you need to
**add or remove edges online** alongside path queries.

## Core Idea: Preferred Paths and Splay Trees

The represented forest is decomposed into **preferred paths** — vertical chains
where each internal node has at most one "preferred child". Each preferred path
is stored as an **auxiliary splay tree**, keyed by depth (shallower nodes are
on the left).

Non-preferred edges are represented by **path-parent pointers** that connect
splay trees to each other, forming a higher-level tree of splay trees that
mirrors the represented tree's structure.

### Preferred-path decomposition

```
Represented tree (one possible rooting at 1):

         1
        /|\
       2  3  6
      / \
     4   5

One possible preferred-path state (each bracket is one splay tree):

  [1 - 2 - 4]     preferred path: 1 -> 2 -> 4
  [3]              3's splay tree; path-parent -> 1
  [5]              5's splay tree; path-parent -> 2
  [6]              6's splay tree; path-parent -> 1
```

The arrows inside each splay tree show depth order (left = shallower):

```
Splay tree for path [1 - 2 - 4]:

        2           <-- splay tree root (not necessarily shallowest)
       / \
      1   4         left subtree = nodes above 2 in represented tree
                    right subtree = nodes below 2 in represented tree
```

### Path-parent pointer

When a splay tree S hangs off a node p in another splay tree, the **root of S**
holds a path-parent pointer to p. Regular parent pointers inside S point within
S only.

```
  Splay tree A: root = x         path_parent(x) --> p
  Splay tree B: contains p

  This means the represented tree has an edge (top of A) --> p,
  but the edge is not a "preferred" edge right now.
```

## The `access` Operation

`access(v)` is the fundamental primitive. It makes the path from **v to the
root of its represented tree** a single preferred path, stored in one splay
tree with v at the splay root.

### Step-by-step trace for `access(5)` (tree rooted at 1)

Initial preferred paths:

```
  [1 - 2 - 4]   path-parent: none (this is the root path)
  [3]            path-parent -> 1
  [5]            path-parent -> 2
  [6]            path-parent -> 1
```

Step 1 — splay(5) within its own splay tree (trivial, 5 is alone).
         Cut 5's right child (none here). v = 5.

Step 2 — follow path-parent of 5: reach the splay tree containing 2.
         Splay 2 to the root of its splay tree.
         Cut 2's old right child (4); give 4 a path-parent -> 2.
         Attach 5 as 2's right child. Splay 5 to the root.

After step 2:

```
  [1 - 2 - 5]   the new preferred path from root down through 5
  [3]            path-parent -> 1
  [4]            path-parent -> 2   (was preferred child, now demoted)
  [6]            path-parent -> 1
```

Step 3 — follow path-parent of 5 (which is now the splay tree root):
         reach the splay tree containing 1. Splay 1, cut its right child (2's
         old path). Attach 5's splay tree as 1's right child. Splay 5 again.
         path-parent of 5 is now -1: done.

Final preferred paths:

```
  [1 - 2 - 5]   one splay tree, v=5 at the splay root
  [3]            path-parent -> 1
  [4]            path-parent -> 2
  [6]            path-parent -> 1
```

## Splay Tree Layout vs Represented Tree

Splay rotations only rearrange the **auxiliary** tree layout. The represented
tree topology (which nodes are connected) does not change. The in-order
traversal of a splay tree always gives the preferred-path nodes ordered
**top to bottom** by depth in the represented tree.

```
Represented tree edge: 1 - 2 - 4 (root at 1, depth increases downward)

Splay tree storing [1, 2, 4] — one valid BST layout:

              2
             / \
            1   4
  (depth 0)     (depth 2)
```

## Core Operations

### `make_root(v)`

Reverse the path from the represented root down to v, making v the new root.
Uses `access` followed by a lazy flip of the entire splay subtree.

```
  make_root(v):
    access(v)          -- v is now splay root; its splay tree = root-to-v path
    nodes[v].flip ^= true  -- lazily reverse the path (swap left/right children)
    push_down(v)       -- apply the flip immediately to v's direct children
```

ASCII before/after (tree rooted at 0, path 0-1-2, make_root(2)):

```
Before:                After make_root(2):

    0                      2
    |                      |
    1                      1
    |                      |
    2                      0

Splay tree for [0,1,2]:    Splay tree for [2,1,0] (reversed path):

      1                          1
     / \                        / \
    0   2                      2   0
```

### `link(u, v)`

Add an edge between u and v, merging their trees. u must not already be
connected to v.

```
  link(u, v):
    make_root(u)      -- u becomes root of its tree
    find_root(v)      -- verify u and v are in different trees
    access(v)         -- v's path to its root is now one splay tree
    nodes[v].right = u  -- attach u as right (deeper) child of v
    nodes[u].parent = v
    update(v)

Before link(u, v):

  Tree A:    Tree B:
    ...         ...
     u           v
                 |
                ...

After link(u, v) [u is now a child of v]:

  Tree B:
    ...
     v
    / \
   ... u
         \
         (u's old tree)
```

### `cut(u, v)`

Remove the edge between u and v. The edge must exist.

```
  cut(u, v):
    make_root(u)      -- u becomes root; edge u-v is now the leftmost splay edge
    access(v)         -- splay tree contains [..., u, v]; u is v's left child
    nodes[v].left = -1   -- detach u
    nodes[u].parent = -1
    update(v)

Splay tree after access(v) [u is v's immediate left child]:

      v
     / \
    u   (nil)    <-- cut here: nodes[v].left = -1

After cut:  u's splay tree    v's splay tree
              [u]               [v, ...]
```

### `find_root(v)`

Find the root of the represented tree containing v.

```
  find_root(v):
    access(v)         -- splay tree is [root ... v] in depth order
    walk left until no left child   -- leftmost node = shallowest = root
    splay(root)       -- move root to splay-tree root for future efficiency

  Splay tree after access(v):

      (some node)
      /          \
    root          v
    (no left child)

  Walk left -> reach root.
```

### `lca(u, v)`

Lowest common ancestor with a fixed root.

```
  lca(u, v):
    access(u)         -- preferred path: [root ... u]
    result = access(v)   -- access(v) returns the last node splayed during
                         -- the walk that was in u's path == the LCA
    return result
```

## Worked Example (Dynamic Connectivity)

```
Start with 5 isolated nodes: 0  1  2  3  4

link(1, 0):  0-1
link(2, 1):  0-1-2
link(4, 3):  3-4

connected(0, 2) -> true
connected(0, 3) -> false

cut(1, 2):   0-1    2

connected(0, 2) -> false
connected(0, 1) -> true
```

## Example Usage (Conceptual)

The Link-Cut Tree in this package is internal (`priv`). The following is
**illustrative** only and will not compile directly.

```mbt nocheck
///|
let lct = LinkCutTree(5)

lct.link(1, 0)
lct.link(2, 1)
inspect(lct.connected(0, 2), content="true")

lct.cut(1, 2)
inspect(lct.connected(0, 2), content="false")
```

## Path Aggregates

Each node stores a `value : Int64`. The splay tree maintains `path_sum` — the
sum of all `value` fields in that splay subtree — via `update` after every
structural change. To query the sum of values on the path from v to the root:

```
  make_root(u)   -- fix the root
  access(v)      -- splay tree is exactly the path u..v
  answer = nodes[v].path_sum
```

## Complexity

| Operation        | Amortized time |
|------------------|---------------|
| `access`         | O(log n)      |
| `link`           | O(log n)      |
| `cut`            | O(log n)      |
| `find_root`      | O(log n)      |
| `make_root`      | O(log n)      |
| `connected`      | O(log n)      |
| `lca`            | O(log n)      |
| `path_sum_to_root` | O(log n)    |

The amortized analysis uses the **access lemma**: the total number of
preferred-path changes across any sequence of m operations on an n-node forest
is O((m + n) log n).

Worst-case for a single operation can be O(n).

## Invariants Maintained

1. The in-order traversal of any splay tree gives its preferred-path nodes
   ordered from shallowest (tree root side) to deepest.
2. Each splay tree represents a maximal contiguous preferred path in the
   represented tree.
3. Path-parent pointers connect the root of one splay tree to a node in the
   splay tree that covers the segment immediately above it in the represented
   tree.
4. For any node v: `nodes[v].path_sum` equals the sum of `value` over all
   nodes in v's splay subtree.
5. The lazy `flip` flag is pushed down before any child is accessed, ensuring
   that left/right children reflect actual depth order at the time of use.

## Common Pitfalls

- **Amortized bounds**: a single operation can take O(n) time; only sequences
  are guaranteed O(log n) amortized.
- **Must reroot before link/cut**: call `make_root(u)` before `link(u, v)` or
  `cut(u, v)` to ensure u is the root of its tree and the edge is the leftmost
  splay edge after `access`.
- **Subtree queries are hard**: LCT is designed for path queries. Subtree
  aggregates require additional bookkeeping (virtual subtree sums).
- **Overkill for static trees**: use HLD or binary lifting for static topologies.
