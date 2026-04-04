# Link-Cut Tree (Dynamic Trees)

## What It Solves

A **Link-Cut Tree (LCT)** maintains a **forest of dynamic trees** where edges
can be added or removed at any time, and path queries can be answered
efficiently. Invented by Sleator and Tarjan (1983).

Operations (amortized O(log n)):

- `link(u, v)` — connect two trees by adding an edge
- `cut(v)` — remove the edge from v to its parent
- `connected(u, v)` — check if u and v are in the same tree
- `find_root(v)` — find the root of v's tree
- `lca(u, v)` — find the lowest common ancestor
- `make_root(v)` — re-root the tree at v
- `path_sum(v)` — sum of values on the path from v to root

Static trees can use Heavy-Light Decomposition or LCA preprocessing; LCT shines
when the tree **changes** over time.

## Core Idea: Preferred Paths

LCT decomposes each represented tree into **preferred paths** — contiguous
chains of nodes ordered by depth. Each preferred path is stored as a **splay
tree**, ordered so that shallower nodes sit to the left.

```
Original tree:                 Preferred paths after access(6):

        0                        [0-1-2]   <- splay tree A
       /|\                           |
      1 2 3                      path-parent
     /|   |                          |
    4 5   6                      [3-6]     <- splay tree B
                                  [4]      <- splay tree C (not preferred)
                                  [5]      <- splay tree D (not preferred)
```

When `access(v)` is called, preferred paths are rewired so that the
**entire root-to-v path** becomes one splay tree, with v at its root.

## Data Structures

### LCTNode — Internal Node

```
  LCTNode {
    parent       : splay-tree parent (-1 if splay root)
    left         : splay-tree left child (shallower side)
    right        : splay-tree right child (deeper side)
    path_parent  : link to ancestor's splay tree (-1 if none)
    reversed     : lazy reversal flag for make_root
    value        : user-supplied node value
    subtree_sum  : aggregate over this splay subtree
  }
```

Pointer semantics (three distinct cases):

```
  Case A — splay internal node:  parent >= 0, parent's child == this node
  Case B — splay root with link: parent < 0, path_parent >= 0
  Case C — tree root:            parent < 0, path_parent < 0
```

### LinkCutTree — Full LCT

Owns an `Array[LCTNode]` indexed by node ID (0-based). Supports the complete
operation set including path aggregation, LCA, and re-rooting.

### DynamicForest — Connectivity Wrapper

Wraps `LinkCutTree` with safety checks that prevent cycles on `link` and
verify edge existence before `cut`. Use this when you only need connectivity
queries.

## Splay Tree: The Auxiliary Structure

Each preferred path is stored in a self-adjusting binary search tree (splay
tree). Keys are **depth in the original tree** — left is shallower, right is
deeper.

### Rotation Cases

```
  ZIG (single rotation — parent is splay root):

      y              x
     / \            / \
    x   C    ->    A   y
   / \                / \
  A   B              B   C


  ZIG-ZIG (same-side — rotate parent first):

        z                  x
       / \                / \
      y   D              A   y
     / \        ->          / \
    x   C                  B   z
   / \                        / \
  A   B                      C   D


  ZIG-ZAG (opposite-side — rotate x twice):

      z                  x
     / \                / \
    y   D              y   z
   / \        ->      / \ / \
  A   x              A  B C  D
     / \
    B   C
```

The zig-zig case rotates the parent before the node, which is what provides the
O(log n) amortized bound (the zig-zag order alone would not).

### Splay Tree vs Original Tree

Splay rotations **do not** change the represented tree topology. They only
rearrange nodes within one preferred path's auxiliary structure.

```
  Original tree (unchanged):      Splay tree (preferred path 0-1-2):

        0                                2
       / \              ->              /
      1   3                            1
     /                                /
    2                                0

  A splay on node 2 gives:

        0                                0
       / \              ->              / \
      1   3                            2   3
     /                                /
    2                                1
```

The left-right relationship inside the splay tree encodes shallow-to-deep
ordering, nothing more.

## Access: The Core Operation

`access(v)` is the building block for all other operations.

**Before `access(v)`:** v is in some splay tree; the path to the root may span
many splay trees connected by `path_parent` pointers.

**After `access(v)`:** The entire path from v to the tree root is one preferred
path stored in one splay tree, with v at the splay root and no right child.

### Step-by-step Illustration

```
  Original tree:                 Splay trees before access(6):

        0(root)                    ST-A: 0 (root, alone)
        |                          ST-B: 1 - 4  (preferred 1-4)
        1                          ST-C: 2 - 5  (preferred 2-5)
       /|\                         ST-D: 3 - 6  (preferred 3-6)
      2 3 4
     /|   |
    5 6   7

  Step 1 — splay(6) in ST-C:      6 is root of ST-C
  Step 2 — detach 6's right:      nothing to detach
  Step 3 — walk to path_parent(2):
    splay(2) in ST-B
    detach 2's right subtree [5]  -> ST-E: 5 (path_parent -> 2)
    attach 6's tree under 2       -> ST-B now contains 2-6
    splay(6) to root of ST-B
  Step 4 — walk to path_parent(1):
    splay(1) in ST-A (only node)
    detach 1's right (none)
    attach 6's tree under 1       -> one splay tree: 0-1-2-6
    splay(6) to root
  Step 5 — path_parent == -1: done.

  After access(6):
    One splay tree: 0 - 1 - 2 - 6   (path root-to-6)
    6 is splay root, no right child.
```

## make_root: Re-rooting

`make_root(v)` makes v the new root of its tree.

```
  Before make_root(3):          After make_root(3):

    0 (root)                      3 (root)
    |                             |
    1                             2
    |                             |
    2                             1
    |                             |
    3                             0
```

Internally, `access(v)` exposes the path, then the **reversed** flag is
toggled on the splay root. This lazy flag, when pushed down, swaps left and
right children at every node on the path, inverting the shallow-to-deep
ordering so that v becomes leftmost (shallowest) and thus the new root.

## Operations: How They Compose

### link(v, w) — add edge v->w

```
  make_root(v)  ->  v is root of its tree
  access(w)     ->  w's path exposed
  set w as left child of v in splay tree
```

The splay tree edge from w to v encodes "w is parent of v" in the original
tree, because w is on the left (shallower) side.

### cut(v) — remove edge from v to its parent

```
  access(v)     ->  entire root-to-v path in one splay tree
                    v has no right child, ancestors are in left subtree
  detach left   ->  v's left subtree (all ancestors) becomes independent
```

```
  Before cut(2):           After cut(2):

  Splay (left=0-1, v=2):   Left subtree (0-1) becomes its own tree.
       2                        1               2
      /          ->            /
     1                        0
    /
   0
```

### connected(u, v) — same tree?

```
  access(u)   ->  u is splay root of its path
  access(v)   ->  v's access extends preferred paths
                  if same tree, u will gain a parent or path_parent
  check u.parent >= 0 || u.path_parent >= 0
```

### lca(u, v) — lowest common ancestor

```
  access(u)   ->  root-to-u path is preferred
  access(v)   ->  root-to-v path is preferred; shared prefix is now joined
  splay(u)    ->  u moves to position where it diverges from v's path
  if u.path_parent >= 0: that node is the LCA (paths diverged above u)
  else: u itself is the LCA (u is ancestor of v)
```

```
  Tree:                 LCA(3, 5):

      0                   access(3): preferred path 0-1-3
     / \                  access(5): preferred path 0-2-5
    1   2                   (u=3 gets path_parent -> 1)
   / \   \                splay(3): 3 is splay root
  3   4   5               3.path_parent == 1  ->  LCA = 1
```

### path_sum(v) — aggregate on path to root

```
  access(v)   ->  root-to-v path in one splay tree
  return v.subtree_sum   (maintained by push_up after every rotation)
```

## Example Usage

```mbt check
///|
test "dynamic forest" {
  let forest = @lct.DynamicForest::new(4)

  // 0-1-2   and 3 alone
  inspect(forest.link(0, 1), content="true")
  inspect(forest.link(1, 2), content="true")
  inspect(forest.connected(0, 2), content="true")
  inspect(forest.connected(0, 3), content="false")

  // Cut edge (1,2)
  inspect(forest.cut(1, 2), content="true")
  inspect(forest.connected(0, 2), content="false")
}
```

### Example: path sum with LCT

```mbt check
///|
test "lct path sum" {
  let lct = @lct.LinkCutTree::with_values([1, 2, 3, 4])
  lct.link(0, 1)
  lct.link(1, 2)
  lct.link(2, 3)
  // Path 0-1-2-3 sums to 1+2+3+4 = 10
  lct.make_root(0)
  inspect(lct.path_sum(3), content="10")
}
```

## Common Applications

### 1. Dynamic Connectivity

Track connected components as edges are inserted and deleted:

```
  forest = DynamicForest::new(n)
  forest.link(u, v)          // add edge
  forest.cut(u, v)           // remove edge
  forest.connected(u, v)     // query connectivity
```

### 2. Dynamic Minimum/Maximum Spanning Forest

When inserting an edge (u, v, weight):

```
  if not connected(u, v): link(u, v)          // bridge — add directly
  else:
    heavy = max-weight edge on path(u, v)
    if heavy.weight > new weight:
      cut(heavy)
      link(u, v)                              // replace with lighter edge
```

### 3. Dynamic LCA

```
  make_root(u)              // u becomes root temporarily
  lca_node = lca(u, v)     // returns v if v is ancestor of u, etc.
```

Or use `lca(u, v)` directly when the root is fixed.

### 4. Path Aggregation

Store min, max, sum, XOR, or any monoid in `value` and accumulate in
`subtree_sum`. After `access(v)`, `path_sum(v)` returns the aggregate on the
root-to-v path. For node-to-node aggregates, call `make_root(u)` first.

### 5. Euler Tour / Subtree Queries

For subtree queries, use an Euler Tour Tree instead; LCT is optimized for
**path** queries.

## Complexity

| Operation     | Time (amortized) |
|---------------|------------------|
| access        | O(log n)         |
| find_root     | O(log n)         |
| link          | O(log n)         |
| cut           | O(log n)         |
| connected     | O(log n)         |
| lca           | O(log n)         |
| make_root     | O(log n)         |
| path_sum      | O(log n)         |

The amortized analysis uses the potential function
`Phi = sum over all nodes of log(size of splay subtree)`.
Each splay operation has amortized cost O(log n) by the access lemma.
A full sequence of m operations on n nodes runs in O(m log n) total.

## Common Pitfalls

- **Cycle on link:** Linking nodes already in the same tree corrupts the
  structure. `DynamicForest.link` checks connectivity first; `LinkCutTree.link`
  does not — the caller must guarantee distinct trees.

- **Amortized, not worst-case:** Each individual operation can take O(n) in
  the worst case; only sequences of m operations are O(m log n) total.

- **Edge direction:** `LinkCutTree.cut(v)` cuts v from its **parent**. When the
  parent is unknown, use `DynamicForest.cut(u, v)` which re-roots first.

- **Lazy reversal:** `make_root` sets a lazy flag. Push it down (via
  `push_down`) before reading left/right children, or stale children will be
  seen. All internal traversals call `push_down_path` before splaying.

- **Path aggregate direction:** `path_sum(v)` returns the aggregate on the
  path from v to the **current root**. To query the path between two arbitrary
  nodes u and v, call `make_root(u)` first, then `path_sum(v)`.

## LCT vs Other Structures

| Structure        | Link/Cut    | Path Query    | Subtree Query | Use Case           |
|------------------|-------------|---------------|---------------|--------------------|
| Link-Cut Tree    | O(log n)    | O(log n)      | N/A           | dynamic trees      |
| HLD              | N/A         | O(log^2 n)    | O(log^2 n)    | static trees       |
| Euler Tour Tree  | O(log n)    | N/A           | O(log n)      | dynamic forests    |
| Offline LCA      | N/A         | O(alpha(n))   | N/A           | static, batch      |

## Implementation Notes (This Package)

- `LinkCutTree` implements the full LCT backed by a flat `Array[LCTNode]`.
- `DynamicForest` wraps `LinkCutTree` with cycle-prevention and edge-existence
  checks for safe `link` / `cut` / `connected` usage.
- Path aggregates are maintained as `subtree_sum` on splay nodes, updated by
  `push_up` after every structural change.
- `make_root` uses a lazy reversal flag (`reversed`) propagated by `push_down`,
  keeping the re-root operation O(log n) amortized.
- All loops in splay, access, find_root, and push_down_path carry explicit
  loop-invariant proof annotations.
