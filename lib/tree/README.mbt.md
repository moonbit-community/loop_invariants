# Tree Techniques (Beginner-Friendly Guide)

This folder is a **tutorial** for common tree techniques. It does not expose a
public API. Instead, it explains how to:

- represent a tree,
- run DFS/BFS iteratively (no recursion),
- compute Euler tour ranges,
- answer subtree queries,
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
  while stack.length() > 0 {
    let v = stack[stack.length() - 1]
    ignore(stack.pop())
    for u in adj[v] {
      if u != parent[v] {
        parent[u] = v
        depth[u] = depth[v] + 1
        stack.push(u)
      }
    }
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

## 6) LCA (lowest common ancestor) by parent climbing

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

---

## 7) When to use which technique

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
Build adjacency list      O(n)
Iterative DFS             O(n)
Euler tour                O(n)
Subtree sum query         O(1) with prefix sums
LCA (parent climbing)     O(height)
LCA (binary lifting)      O(log n) per query
```
