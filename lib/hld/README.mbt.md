# Heavy-Light Decomposition (HLD)

## What HLD Solves

**Heavy-Light Decomposition** turns tree path queries into a small number of
contiguous ranges. Once you map each node to a position, path queries become a
handful of segment-tree queries.

Typical tasks:

- Sum / min / max on the path between `u` and `v`
- Update all values on a path
- Query a whole subtree in one contiguous range

HLD works on **static trees** (topology does not change).

## Big Picture

HLD labels each node with:

- `heavy_child[u]`: the child with the largest subtree
- `chain_head[u]`: top node of u's heavy chain
- `position[u]`: a linear index for segment tree use

**Key property**: heavy edges form chains, and each chain is contiguous in the
`position` order.

That means **any path** breaks into **O(log n) chain segments**.

## The Heavy/Light Idea (Why It Is O(log n))

A light edge always jumps into a subtree of **at most half** the size.
Therefore, on any root-to-leaf path, you can only cross about `log2(n)` light
edges before the subtree size drops to 1.

```
Start at subtree size n
Light edge -> size <= n/2
Light edge -> size <= n/4
Light edge -> size <= n/8
...
After k light edges: size <= n / 2^k
```

So there are at most O(log n) light edges, and thus only O(log n) chain jumps.

## Step 1: Compute Subtree Sizes and Heavy Children

We do a DFS to get sizes and pick the heaviest child at each node.

Example tree:

```
      0
     /|\
    1 2 3
   /|   |
  4 5   6
 /
7
```

Subtree sizes and heavy child:

```
Node:  0  1  2  3  4  5  6  7
Size:  8  4  1  2  2  1  1  1
Heavy: 1  4  -  6  7  -  -  -
```

Heaviest edges: `0-1`, `1-4`, `4-7`, and `3-6`.

## Step 2: Build Chains and Positions

We run a second DFS, always visiting the heavy child first.
This makes each heavy path **contiguous** in the linear order.

Chains (head -> nodes):

```
Chain A (head=0): 0 -> 1 -> 4 -> 7
Chain B (head=2): 2
Chain C (head=5): 5
Chain D (head=3): 3 -> 6
```

Positions (used by a segment tree):

```
Node:     0  1  4  7  2  5  3  6
Position: 0  1  2  3  4  5  6  7
```

Notice each chain is a continuous slice.

## Step 3: Decompose a Path into Ranges

To query `u -> v`, you repeatedly climb the deeper chain head.
Each climb produces one **contiguous** range in the segment tree.

Example: `u=7`, `v=6`

```
Chains: 7 in head=0, 6 in head=3
Depth(head 0) < depth(head 3) -> climb v side

Ranges touched:
1) chain D segment: pos[3]..pos[6] = [6..7]
2) now v jumps to parent(head 3) = 0
3) u and v now in same chain (head 0)
4) final segment: pos[0]..pos[7] = [0..3]
```

Total = 2 segment tree queries.

## Subtree Queries Are One Range

Because the heavy-first DFS assigns positions in a subtree contiguously:

```
subtree(u) == [position[u], position[u] + subtree_size[u] - 1]
```

So subtree sums or subtree updates are just one range in the segment tree.

## Edge vs Vertex Values

HLD can handle both, but the mapping differs:

### Vertex values
Store value at `position[u]` directly.

### Edge values
Store the edge `(parent[u], u)` at `position[u]` (the deeper endpoint).
When querying a path:

- compute LCA
- **exclude** `position[lca]` if you only want edge values

## LCA via HLD

```
while head[u] != head[v]:
  if depth[head[u]] < depth[head[v]]: v = parent[head[v]]
  else: u = parent[head[u]]
return (deeper of u,v)
```

This finds the LCA in O(log n) chain jumps.

## Example Usage (Conceptual)

```mbt nocheck
///|
// Build a tree
let hld = HLD::new(n)
for (u, v) in edges {
  hld.add_edge(u, v)
}

// Decompose
hld.build(0)

// Build a segment tree on values ordered by position[]
for u in 0..<n {
  segtree.set(hld.get_position(u), value[u])
}

// Path query u-v
let mut ans = 0
let mut a = u
let mut b = v
while hld.get_chain_head(a) != hld.get_chain_head(b) {
  if depth[head[a]] < depth[head[b]] { swap(a, b) }
  let head = hld.get_chain_head(a)
  ans += segtree.query(pos[head]..pos[a])
  a = parent[head]
}
// Final segment in same chain
ans += segtree.query(min(pos[a],pos[b])..max(pos[a],pos[b]))
```

## Concrete Range Decomposition Example (Hardcoded)

```
Given the earlier tree:
head = [0,0,2,3,0,5,3,0]
pos  = [0,1,4,6,2,5,7,3]

Path 7 -> 6 produces ranges:
- [6..7]  (chain head 3 to node 6)
- [0..3]  (chain head 0 to node 7)
```

## Common Pitfalls

- **Wrong heavy child**: pick the child with the largest subtree.
- **Edge values**: store on the deeper endpoint and exclude LCA.
- **Disconnected graph**: HLD is for a tree; handle components separately.
- **Root choice**: any root works, but arrays depend on the root.
- **Indices**: be consistent with 0-based indexing in arrays.

## Complexity

| Step | Time | Space |
|------|------|-------|
| Compute sizes + heavy child | O(n) | O(n) |
| Decompose and assign positions | O(n) | O(n) |
| Path query | O(log^2 n) | O(1) extra |
| Subtree query | O(log n) | O(1) extra |

## HLD vs Other Techniques

| Method | Path Query | Subtree Query | Notes |
|--------|------------|---------------|-------|
| HLD | O(log^2 n) | O(log n) | supports updates + queries |
| Euler Tour | O(n) | O(log n) | good for subtree only |
| Binary Lifting | O(log n) | - | LCA only |
| Link-Cut Tree | O(log n) | - | dynamic trees |

## Implementation Notes (This Package)

- `HLD::build(root)` runs both DFS passes
- `HLD::lca(u, v)` uses chain heads
- `HLD::path_length(u, v)` is provided for convenience
- `HLD::count_chains(u, v)` shows the logarithmic chain jump property

This package provides the decomposition and helper queries. You provide the
segment tree (or Fenwick) on top of `position[]` to answer your own queries.
