# Tarjan's Offline LCA

## Overview

Given a rooted tree on `N` nodes and a fixed batch of `Q` Lowest Common
Ancestor queries `(u_i, v_i)`, Tarjan's offline algorithm answers **all of
them together** in a single DFS at total cost

```
  O((N + Q) * alpha(N))
```

where `alpha` is the inverse Ackermann function (so for any realistic `N`
the factor is essentially constant). This beats `O(Q log N)` binary
lifting when `Q` is large, at the cost of needing every query up front
("offline").

- **Time**: `O((N + Q) * alpha(N))`
- **Space**: `O(N + Q)`
- **Signature**: `tarjan_offline_lca(n, adj, root, queries) -> Array[Int]`

This package provides:

- `tarjan_offline_lca(n, adj, root, queries)` -- answer all queries at once

---

## Compared to online LCA structures

| Method                   | Preprocess     | Per query   | Notes                              |
|--------------------------|----------------|-------------|------------------------------------|
| Naive ancestor walk      | `O(1)`         | `O(N)`      | Trivial, blows up on chains.       |
| Binary lifting           | `O(N log N)`   | `O(log N)`  | Online; supports kth-ancestor too. |
| Euler tour + sparse RMQ  | `O(N log N)`   | `O(1)`      | Online; needs an RMQ structure.    |
| **Tarjan offline**       | --             | --          | All queries together: `O((N+Q) alpha)`. |

The online structures (lifting, Euler+RMQ) are the right choice when
queries arrive one at a time. Tarjan's offline method wins for batch
workloads where the entire query stream is known before answering starts.

---

## How it works

The algorithm couples a DFS with a [disjoint-set union (DSU)](https://en.wikipedia.org/wiki/Disjoint-set_data_structure).
At any moment during the DFS the **gray** nodes are exactly the
in-progress root-to-current path, and every **black** node has a finished
subtree whose DSU representative is tagged with the lowest still-open
ancestor of that subtree.

When we are about to finish a node `u`, the chain of still-open ancestors
is `u`'s root path, with `u` itself at the bottom. So for any query
`(u, v)` where `v` is already black:

```
  LCA(u, v)  =  ancestor[ find(v) ]
```

because `find(v)` lands on the DSU representative for the *finished*
subtree containing `v`, and that representative's `ancestor` slot is the
deepest still-open node above (or equal to) `u`.

### Pseudocode

```
dfs(u):
  ancestor[make_set(u)] = u
  for each child c of u:
    dfs(c)
    union(u, c)
    ancestor[find(u)] = u           # re-tag the new bigger set with u
  color[u] = BLACK
  for each query (u, v):
    if color[v] == BLACK:
      answer = ancestor[find(v)]
```

Each query is registered at **both** endpoints. Whichever endpoint
becomes black first sees the other still gray (and does nothing); the
second endpoint to become black reads off the answer.

---

## The load-bearing detail: order of operations inside the pop

In the iterative implementation it is tempting to write, when finishing a
node `u`:

```
  pop u
  union(u, parent(u))           # link u into the parent's set
  ancestor[find(parent)] = parent
  color[u] = BLACK
  resolve queries at u
```

This is **wrong**. By the time we read `ancestor[find(v)]` for a query
`(u, v)` where `v` is a descendant of `u`, the union step above has
already merged `u`'s group into the parent's, and the representative is
tagged with `parent(u)` -- so the answer becomes `parent(u)` instead of
`u`.

The fix is to keep the merge **after** the answer step:

```
  pop u
  color[u] = BLACK
  resolve queries at u           # ancestor[find(u)] still equals u here
  union(u, parent(u))            # only now do we shift the tag up
  ancestor[find(parent)] = parent
```

The same invariant in plain words:

> While answering queries at `u`, the DSU set containing `u` must still
> be tagged with `u`, not with `u`'s parent.

This matches the textbook recursive form, where the `union(u, c)` step
runs *for each child* `c` inside `u`'s own dfs frame, never inside the
child's frame.

---

## Worked example

Tree (rooted at 0):

```
        0
       / \
      1   2
     / \
    3   4
```

Queries: `(3, 4)`, `(3, 2)`, `(4, 2)`.

DFS visiting order: 0 -> 1 -> 3 -> back to 1 -> 4 -> back to 1 -> back
to 0 -> 2.

Trace the DSU representative and the `ancestor` tag of each set:

```
Step                  Sets and ancestor tags
-----------------------------------------------
visit 0               {0}=0
visit 1               {0}=0, {1}=1
visit 3 (leaf)        {0}=0, {1}=1, {3}=3
  finish 3            answer queries at 3   -> none black yet
  union(3, 1)         {0}=0, {1,3}=1
visit 4 (leaf)        {0}=0, {1,3}=1, {4}=4
  finish 4            answer queries at 4
                        query (3, 4): 3 is BLACK
                        ans = ancestor[find(3)] = ancestor[1] = 1
  union(4, 1)         {0}=0, {1,3,4}=1
finish 1              answer queries at 1   -> none registered
  union(1, 0)         {0,1,3,4}=0
visit 2 (leaf)        {0,1,3,4}=0, {2}=2
  finish 2            answer queries at 2
                        query (3, 2): 3 is BLACK
                          ans = ancestor[find(3)] = ancestor[0] = 0
                        query (4, 2): 4 is BLACK
                          ans = ancestor[find(4)] = ancestor[0] = 0
  union(2, 0)         {0,1,2,3,4}=0
finish 0              (no queries)
```

Final answers: `[1, 0, 0]`.

---

## Reference implementation

```
pub fn tarjan_offline_lca(
  n : Int,
  adj : ArrayView[Array[Int]],
  root : Int,
  queries : ArrayView[(Int, Int)],
) -> Array[Int]
```

---

## Tests and examples

### Y-shaped tree

```mbt check
///|
test "tarjan offline lca y shape" {
  // Edges of the example tree above.
  let adj : Array[Array[Int]] = [
    [1, 2], // 0
    [0, 3, 4], // 1
    [0], // 2
    [1], // 3
    [1], // 4
  ]
  let queries : ReadOnlyArray[(Int, Int)] = [(3, 4), (3, 2), (4, 2)]
  let ans = @tarjan_offline_lca.tarjan_offline_lca(5, adj, 0, queries)
  debug_inspect(ans[0], content="1")
  debug_inspect(ans[1], content="0")
  debug_inspect(ans[2], content="0")
}
```

### Linear chain (any pair where one is an ancestor)

```mbt check
///|
test "tarjan offline lca chain ancestor" {
  // 0 - 1 - 2 - 3 - 4
  let adj : Array[Array[Int]] = [
    [1], // 0
    [0, 2], // 1
    [1, 3], // 2
    [2, 4], // 3
    [3], // 4
  ]
  let queries : ReadOnlyArray[(Int, Int)] = [(2, 4), (0, 4), (1, 3)]
  let ans = @tarjan_offline_lca.tarjan_offline_lca(5, adj, 0, queries)
  debug_inspect(ans[0], content="2")
  debug_inspect(ans[1], content="0")
  debug_inspect(ans[2], content="1")
}
```

### Self-query short-circuit

```mbt check
///|
test "tarjan offline lca self query" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [1]]
  let queries : ReadOnlyArray[(Int, Int)] = [(0, 0), (2, 2)]
  let ans = @tarjan_offline_lca.tarjan_offline_lca(3, adj, 0, queries)
  debug_inspect(ans[0], content="0")
  debug_inspect(ans[1], content="2")
}
```

### Re-rooting the same tree

```mbt check
///|
test "tarjan offline lca different roots" {
  // Same edges as the y-shape example: (0,1), (0,2), (1,3), (1,4).
  let adj : Array[Array[Int]] = [[1, 2], [0, 3, 4], [0], [1], [1]]
  let queries : ReadOnlyArray[(Int, Int)] = [(3, 2)]
  let rooted_0 = @tarjan_offline_lca.tarjan_offline_lca(5, adj, 0, queries)
  let rooted_1 = @tarjan_offline_lca.tarjan_offline_lca(5, adj, 1, queries)
  // Under root 0, both 3 and 2 share ancestor 0.
  // Under root 1, the tree becomes 1 - 0 - 2 and 1 - 3 / 4, so LCA(3, 2) = 1.
  debug_inspect(rooted_0[0], content="0")
  debug_inspect(rooted_1[0], content="1")
}
```

---

## Complexity

| Phase              | Cost                |
|--------------------|---------------------|
| Adjacency walk     | `O(N)`              |
| DSU work           | `O((N + Q) alpha(N))` |
| Query bookkeeping  | `O(N + Q)`          |

### Why DSU here is almost linear

Each tree edge contributes exactly one `union` (when the child's subtree
is merged into the parent's set), so the total number of unions is
`N - 1`. Each query contributes two `find` calls. With path compression
and union by rank, both `find` and `union` cost `O(alpha)` amortized,
where `alpha` is the inverse Ackermann function. For all realistic input
sizes, `alpha <= 4`.

### Why not just use binary lifting?

When `Q` is small (say `Q < N / log N`), each binary-lifting query at
`O(log N)` is competitive. As `Q` grows past that, the offline algorithm
amortizes the DSU bookkeeping across all queries and wins outright. It
also has a much smaller memory footprint -- `O(N)` instead of
`O(N log N)` for the ancestor table.

---

## Common applications

- **Distance queries on a static tree**: `dist(u, v) = depth[u] +
  depth[v] - 2 * depth[LCA(u, v)]`.
- **Auxiliary trees and offline processing**: many tree problems reduce
  to a batch of LCA queries plus simple arithmetic.
- **Tree path queries**: combined with sparse tables on the Euler tour,
  the LCA gives the path; offline LCA cheaply answers the LCA half of
  the work when many path queries are given as a batch.

---

## Common pitfalls

- **Order of operations on pop**: see the "load-bearing detail" section
  above. Answering queries *after* the union breaks descendant queries.
- **Undirected adjacency**: the algorithm expects undirected adjacency
  and discovers parent/child orientation from `root` during the DFS.
  Passing only forward edges works too, but back-edges to the parent
  must either be absent or be detected and skipped (the implementation
  skips them automatically).
- **Disconnected nodes**: nodes unreachable from `root` are left at
  their initial `White` color; queries that touch such a node leave the
  sentinel `-1` in the answers.
- **Self-queries**: `(u, u)` is answered without entering the DFS pass
  for efficiency, mirroring the natural definition LCA(u, u) = u.

---

## Related concepts

```
Tarjan offline LCA              -- this function
Binary lifting LCA              -- online, O(N log N) prep, O(log N) per query
Euler tour + sparse RMQ         -- online, O(N log N) prep, O(1) per query
Heavy path decomposition        -- O(log N) per query, supports path updates
Auxiliary tree / virtual tree   -- compresses a subset of nodes by LCAs
DSU + offline processing        -- the same trick powers offline rank-of-set,
                                   offline connectivity, and Kruskal's RC.
```
