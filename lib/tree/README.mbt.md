# Tree Techniques (Beginner-Friendly Guide)

This folder is a **tutorial** for common tree techniques. It does not expose a
public API. Instead, it explains how to:

- represent a tree,
- run DFS/BFS iteratively (no recursion),
- compute Euler tour ranges,
- answer subtree queries with a Fenwick tree or segment tree,
- compute LCA (lowest common ancestor).

All code snippets are small, runnable, and use only basic arrays and loops.

---

## 1) What is a tree?

A tree is a connected graph with **n nodes and n-1 edges**.
That means:

- there is exactly one simple path between any two nodes,
- no cycles.

We often **root** a tree at a node (usually 0). Then every node (except root)
has a parent.

Example tree (root = 0):

```
      0
     / \
    1   2
   / \   \
  3   4   5
```

Edges:
`(0,1) (0,2) (1,3) (1,4) (2,5)`

---

## 2) Adjacency list (the standard representation)

```mbt check
///|
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  for edge in edges {
    let (u, v) = edge
    if u < 0 || u >= n || v < 0 || v >= n {
      continue
    }
    adj[u].push(v)
    adj[v].push(u)
  }
  adj
}
```

This is the most flexible structure for tree algorithms.

---

## 3) Iterative DFS to get parent and depth

We avoid recursion by using an explicit stack.

```mbt check
///|
fn parent_and_depth(
  n : Int,
  adj : Array[Array[Int]],
  root : Int,
) -> (Array[Int], Array[Int]) {
  let parent = Array::make(n, -1)
  let depth = Array::make(n, 0)
  parent[root] = root
  let stack : Array[Int] = [root]
  for pop_next = stack.length() > 0; pop_next; {
    let v = stack[stack.length() - 1]
    ignore(stack.pop())
    for u in adj[v] {
      if u != parent[v] {
        parent[u] = v
        depth[u] = depth[v] + 1
        stack.push(u)
      }
    }
    continue stack.length() > 0
  }
  (parent, depth)
}
```

Depth is the distance from the root in edges.

---

## 4) Euler tour (flattening the tree)

The Euler tour assigns each node a contiguous range in an array.
This makes subtree queries look like **range queries**.

We store:

- `tin[v]`: when we first enter v
- `tout[v]`: last time index in v's subtree (inclusive)
- `order`: nodes in visitation order

```mbt check
///|
fn euler_tour(
  n : Int,
  adj : Array[Array[Int]],
  root : Int,
) -> (Array[Int], Array[Int], Array[Int]) {
  let tin = Array::make(n, -1)
  let tout = Array::make(n, -1)
  let order : Array[Int] = []
  let stack : Array[(Int, Int, Int)] = [(root, -1, 0)]
  let _ = for timer = 0 {
    let frame = stack.pop()
    match frame {
      None => break ()
      Some((v, p, state)) =>
        if state == 0 {
          tin[v] = timer
          order.push(v)
          stack.push((v, p, 1))
          for u in adj[v] {
            if u != p {
              stack.push((u, v, 0))
            }
          }
          continue timer + 1
        } else {
          tout[v] = timer - 1
          continue timer
        }
    }
  }
  (tin, tout, order)
}
```

### Why it works (visual)

For the example tree:

```
      0
     / \
    1   2
   / \   \
  3   4   5
```

One possible `order`:

```
order index: 0  1  2  3  4  5
node:        0  2  5  1  4  3
```

Then:

```
subtree of node 1 = indices [tin[1], tout[1]] = [3, 5]
nodes: order[3..5] = [1, 4, 3]
```

The subtree is always a **contiguous segment**.

### Euler tour as a linearization

The diagram below shows how the tree maps to a flat array. Each node occupies
exactly the positions `[tin[v], tout[v]]` in `order[]`:

```
Tree:                   Euler order array (index 0..5):
                        +---+---+---+---+---+---+
      0                 | 0 | 2 | 5 | 1 | 4 | 3 |
     / \                +---+---+---+---+---+---+
    1   2                 0   1   2   3   4   5
   / \   \
  3   4   5       tin[0]=0  tout[0]=5   (whole tree)
                  tin[2]=1  tout[2]=2   (subtree: 2,5)
                  tin[1]=3  tout[1]=5   (subtree: 1,4,3)
```

A range query `[tin[v], tout[v]]` on this flat array answers any subtree
question in O(1) (prefix sums) or O(log n) (Fenwick / segment tree).

---

## 5) Subtree sums with Euler + prefix sums

If values are static (no updates), a prefix sum is enough.

```mbt check
///|
fn prefix_sums(values : ArrayView[Int]) -> Array[Int] {
  let n = values.length()
  let pref = Array::make(n, 0)
  let _ = for i in 0..<n; acc = 0 {
    let next_acc = acc + values[i]
    pref[i] = next_acc
    continue next_acc
  }
  pref
}

///|
test "euler tour subtree sums" {
  let n = 6
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5)]
  let values : Array[Int] = [5, 1, 4, 2, 3, 6]
  let adj = build_adj(n, edges[:])
  let (tin, tout, order) = euler_tour(n, adj, 0)
  let euler_values : Array[Int] = []
  for v in order {
    euler_values.push(values[v])
  }
  let pref = prefix_sums(euler_values)
  let subtree_sum = (v : Int) => {
    let l = tin[v]
    let r = tout[v]
    let before = if l > 0 { pref[l - 1] } else { 0 }
    pref[r] - before
  }

  // Subtree(1) has nodes {1,3,4} = 1 + 2 + 3 = 6
  inspect(subtree_sum(1), content="6")
  // Subtree(2) has nodes {2,5} = 4 + 6 = 10
  inspect(subtree_sum(2), content="10")
}
```

If you need **updates**, replace prefix sums with a Fenwick tree or segment
tree built over the Euler order.

---

## 6) Fenwick tree on the Euler tour (dynamic subtree updates)

When node values change, a Fenwick tree (Binary Indexed Tree) replaces the
static prefix-sum array. The Euler tour converts "subtree of v" into a plain
range `[tin[v], tout[v]]` in the flat array, and the Fenwick tree answers
range sums in O(log n).

```
  Tree nodes                  Fenwick array (1-indexed, over Euler order)
  ----------                  -----------------------------------------
  node 0 (val=5)              index: 1  2  3  4  5  6
  node 2 (val=4)              value: 5  4  6  1  3  2
  node 5 (val=6)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  node 1 (val=1)              subtree(1) = Fenwick.range_sum(4, 6) = 6
  node 4 (val=3)              subtree(2) = Fenwick.range_sum(2, 3) = 10
  node 3 (val=2)
```

Steps:
1. Run `euler_tour` to get `tin`, `tout`, `order`.
2. Build a `FenwickTree` over `euler_values` (values reordered by `order`).
3. Subtree sum of node v = `fenwick.range_sum(tin[v]+1, tout[v]+1)`.
4. Point update on node v = `fenwick.update(tin[v]+1, delta)`.

The `fenwick.mbt` file contains `FenwickTree` with `update`, `prefix_sum`,
`range_sum`, and `find_kth`, all with loop invariants proving correctness.

### How the Fenwick tree represents ranges

Each index i in the Fenwick array stores the sum of a range whose length is
`lowbit(i) = i & (-i)`:

```
n = 8   (array indices 1..8)

tree[1] covers [1,1]      lowbit(1)=1
tree[2] covers [1,2]      lowbit(2)=2
tree[3] covers [3,3]      lowbit(3)=1
tree[4] covers [1,4]      lowbit(4)=4
tree[5] covers [5,5]      lowbit(5)=1
tree[6] covers [5,6]      lowbit(6)=2
tree[7] covers [7,7]      lowbit(7)=1
tree[8] covers [1,8]      lowbit(8)=8

Query prefix_sum(7):  tree[7] + tree[6] + tree[4]
                   = [7,7]  + [5,6]  + [1,4]  = [1,7]  (correct)

Update at position 5: tree[5], tree[6], tree[8]
                    = [5,5],  [5,6],  [1,8]   (all contain 5, correct)
```

---

## 7) Segment tree on the Euler tour (lazy range updates)

A segment tree over the Euler array supports both range queries **and** lazy
range updates in O(log n). This is useful when you need to add a value to all
nodes in a subtree at once.

### Segment tree memory layout

For n leaves the iterative segment tree uses indices `[1, 2n)`:

```
n = 4 leaves (values a, b, c, d)

                   tree[1]
                  /        \
           tree[2]          tree[3]
           /    \            /    \
       tree[4] tree[5]  tree[6] tree[7]
         a        b        c        d
         (n+0)   (n+1)   (n+2)   (n+3)
```

Leaves live at indices `n` through `2n-1`. Internal node `i` combines
children `2i` and `2i+1`.

### Lazy propagation for subtree range-add

To add delta to all nodes in the subtree of v:
1. Convert to Euler range: `l = tin[v]`, `r = tout[v]`.
2. Call `segment_tree.range_update(l, r+1, delta)`.
3. Lazy values are pushed down only when a partial-overlap node is visited,
   so the O(log n) guarantee holds.

```
Lazy segment tree node at index i covering interval [l, r):

  tree[i]    = true sum of arr[l..r) (with lazy already applied to this node)
  lazy[i]    = pending delta to add to every element in [l, r)

  true_sum(i) = tree[i]   (already up to date AT this node)
  child sums  = tree[2i]  + lazy[i]*(mid-l)     (lazy not yet pushed)
                tree[2i+1]+ lazy[i]*(r-mid)
```

---

## 8) LCA (lowest common ancestor) by parent climbing

The LCA of two nodes is their deepest shared ancestor.
This simple version is O(height), good for small trees.

```mbt check
///|
fn lca_naive(u : Int, v : Int, parent : Array[Int], depth : Array[Int]) -> Int {
  let a = for a = u {
    if depth[a] > depth[v] {
      continue parent[a]
    } else {
      break a
    }
  }
  let b = for b = v {
    if depth[b] > depth[a] {
      continue parent[b]
    } else {
      break b
    }
  }
  for a = a, b = b {
    if a == b {
      break a
    } else {
      continue parent[a], parent[b]
    }
  }
}

///|
test "lca by parent climbing" {
  let n = 6
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5)]
  let adj = build_adj(n, edges[:])
  let (parent, depth) = parent_and_depth(n, adj, 0)
  inspect(lca_naive(3, 4, parent, depth), content="1")
  inspect(lca_naive(3, 5, parent, depth), content="0")
}
```

For large inputs or many queries, use **binary lifting**:
precompute `up[v][k] = 2^k-th ancestor`. Then LCA is O(log n).

### LCA parent-climbing diagram

```
      0   depth=0
     / \
    1   2   depth=1
   / \   \
  3   4   5   depth=2

LCA(3, 5):
  Step 1 - equalize depths:
    a=3 (depth 2) vs b=5 (depth 2)  -- already equal
  Step 2 - climb together:
    a=3, b=5  -> parent: a=1, b=2
    a=1, b=2  -> parent: a=0, b=0  -> LCA = 0

LCA(3, 4):
  Depths equal at 2.
  a=3, b=4  -> parent: a=1, b=1  -> LCA = 1
```

---

## 9) When to use which technique

```
Need subtree sum (static)      -> Euler tour + prefix sums
Need subtree sum (dynamic)     -> Euler tour + Fenwick/segment tree
Need LCA for a few queries     -> parent climbing
Need LCA for many queries      -> binary lifting
Need path queries + updates    -> HLD or Link-Cut Tree
```

---

## Common pitfalls

- Forgetting that trees are undirected: add edges both ways.
- Mixing inclusive/exclusive ranges for `tout`.
- Using LCA on a non-rooted tree (always pick a root).
- Assuming DFS order is unique (it depends on adjacency order).

---

## Complexity at a glance

```
Build adjacency list                O(n)
Iterative DFS                       O(n)
Euler tour                          O(n)
Subtree sum query (prefix sums)     O(1)
Subtree point update (Fenwick)      O(log n)
Subtree range query (Fenwick)       O(log n)
Subtree range update (lazy seg)     O(log n)
LCA (parent climbing)               O(height)
LCA (binary lifting)                O(log n) per query
Fenwick find-kth                    O(log n)
Inversion count                     O(n log n)
2D Fenwick update/query             O(log n * log m)
Persistent segment tree update      O(log n) time, O(log n) new nodes
```
