# Dominator Tree (Lengauer-Tarjan)

## Overview

A vertex **u dominates v** if every path from the start node to v must pass
through u. The **immediate dominator** (idom) is the closest strict dominator.
The dominator tree connects each node to its immediate dominator.

This package implements the **Lengauer-Tarjan algorithm**.

- **Time**: O((V + E) · α(V)) ≈ nearly linear
- **Space**: O(V + E)
- **Key Feature**: Foundation for compiler optimizations

## The Key Insight

```
Problem: For each vertex, find the "gateway" from start

Naive: For each v, remove candidates and check reachability → O(V²·E)

Lengauer-Tarjan insight:
  Use DFS tree structure + semi-dominators!

Semi-dominator sdom[v]:
  Minimum DFS number reachable from v via:
    - Tree edges (going down)
    - Followed by ONE non-tree edge (jumping up)

Key theorem:
  idom[v] is either sdom[v] or idom[sdom[v]]

  This means we can compute idom in nearly linear time
  by processing in reverse DFS order with union-find!
```

## Visual: Dominator Tree

```
Control Flow Graph:        Dominator Tree:

    0 (entry)                   0
    │                           │
    ▼                           ├──1
    1                           │  ├──2
   / \                          │  └──3
  ▼   ▼                         └──4
  2   3                            └──5
   \ /
    ▼
    4
    │
    ▼
    5

Dominance:
  0 dominates all (entry)
  1 dominates 2, 3 (before the branch)
  4 dominates 5 (only path)

idom[1]=0, idom[2]=1, idom[3]=1, idom[4]=1, idom[5]=4
```

## The Algorithm (Simplified)

```
lengauer_tarjan(n, edges, start):
  // Phase 1: DFS numbering
  dfs_order = DFS from start
  for each v in dfs_order:
    dfn[v] = DFS number
    parent[v] = DFS parent

  // Phase 2: Compute semi-dominators
  // Process in reverse DFS order
  for v in reverse(dfs_order):
    for each predecessor u of v:
      if dfn[u] < dfn[v]:  // Tree ancestor
        sdom[v] = min(sdom[v], dfn[u])
      else:  // u is descendant or unrelated
        // Find minimum sdom in u's ancestor chain
        sdom[v] = min(sdom[v], eval(u))

    bucket[sdom[v]].add(v)

    // Process bucket for v's parent
    for each w in bucket[parent[v]]:
      u = eval(w)
      idom[w] = u if sdom[u] < sdom[w] else parent[v]

    link(parent[v], v)  // Union-find link

  // Phase 3: Finalize idom
  for v in dfs_order:
    if idom[v] != vertex[sdom[v]]:
      idom[v] = idom[idom[v]]

  return idom
```

## Example Usage

```mbt check
///|
test "dominator tree example" {
  let edges : Array[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 3),
    (1, 3),
    (3, 4),
    (4, 5),
    (2, 5),
  ]
  let dom = @dominator_tree.build_dominator_tree(6, edges[:], 0).unwrap()
  inspect(dom.idom[3], content="1")
  inspect(dom.dominates(1, 5), content="true")
}
```

```mbt check
///|
test "dominator diamond" {
  // Diamond: 0 → 1,2 → 3
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let dom = @dominator_tree.build_dominator_tree(4, edges[:], 0).unwrap()
  inspect(dom.idom[3], content="0")
  // 3's idom is 0, not 1 or 2 (both paths converge)
}
```

## Algorithm Walkthrough

```
Graph: 0→1→2→3, 1→3 (diamond shortcut)

DFS from 0:
  Order: [0, 1, 2, 3]
  dfn: [0, 1, 2, 3]
  parent: [-1, 0, 1, 2]

Process in reverse order:

v=3:
  Predecessors: 2, 1
  From 2: dfn[2]=2 < dfn[3]=3 (tree edge)
          sdom[3] = min(INF, 2) = 2
  From 1: dfn[1]=1 < dfn[3]=3 (non-tree edge)
          sdom[3] = min(2, 1) = 1
  Add 3 to bucket[1]

v=2:
  Predecessors: 1
  From 1: dfn[1]=1 < dfn[2]=2 (tree edge)
          sdom[2] = 1
  Add 2 to bucket[1]

v=1:
  Process bucket[1] = {3, 2}
  For w=3: u = eval(3) in subtree of 1
           idom[3] = 1 (since sdom[eval(3)] >= sdom[3])
  For w=2: u = eval(2)
           idom[2] = 1

v=0:
  Process bucket[0] = {1}
  idom[1] = 0

Final idom: [-1, 0, 1, 1]
  idom[0] = -1 (root)
  idom[1] = 0
  idom[2] = 1
  idom[3] = 1
```

## Why Semi-Dominators Work

```
Theorem: sdom[v] is the minimum dfn of any vertex u where:
  - There's a path u → v using only vertices with dfn > dfn[v]
  - (except u itself)

This means:
  - sdom[v] is on the "boundary" of v's dominators
  - idom[v] is between sdom[v] and the root

Key lemma:
  For any v, idom[v] is an ancestor of sdom[v] in DFS tree.

  Either:
    - idom[v] = sdom[v], or
    - idom[v] = idom[w] for some w between sdom[v] and v
      where sdom[w] is minimized

The union-find tracks this efficiently!
```

## Common Applications

### 1. Compiler Optimization
```
Build dominator tree for control flow graph.
Used in SSA construction, dead code elimination.
```

### 2. Dominance Frontier
```
Frontier[v] = nodes just outside v's dominance.
Key for placing phi nodes in SSA.
```

### 3. Program Analysis
```
Determine what code must execute before other code.
Control dependencies in programs.
```

### 4. Loop Detection
```
Natural loops have single entry point (dominator).
Back edges target loop headers that dominate tail.
```

## Complexity Analysis

| Phase | Time | Notes |
|-------|------|-------|
| DFS numbering | O(V + E) | Standard DFS |
| Compute sdom | O(E · α(V)) | Union-find with path compression |
| Build buckets | O(V) | One pass |
| Finalize idom | O(V) | One pass |
| **Total** | **O((V+E) · α(V))** | Nearly linear |

## Dominator Tree Properties

```
Property 1: Tree structure
  Each vertex (except root) has exactly one idom.
  Edges idom[v] → v form a tree.

Property 2: Transitivity
  If a dominates b and b dominates c,
  then a dominates c.

Property 3: Ancestors in dominator tree
  v dominates w iff v is ancestor of w in dominator tree.

Property 4: Unique entry
  Every path from root to v passes through all
  ancestors of v in dominator tree.
```

## Dominance Frontier

```
Definition: DF[v] = {w : v dominates pred of w but not w}

Intuition: Nodes "just outside" v's dominance region.

Computation (after dominator tree):
  For each node v:
    For each CFG successor w of v:
      runner = v
      while runner != idom[w]:
        DF[runner].add(w)
        runner = idom[runner]

Used for: SSA phi node placement
```

## Implementation Notes

- Handle unreachable vertices (no dominator)
- Root has no immediate dominator (idom = -1 or self)
- Union-find requires careful implementation
- Path compression essential for efficiency
- Can extend to post-dominators (reverse edges)

## Dominator vs Reachability

| Property | Dominator | Reachability |
|----------|-----------|--------------|
| Direction | All paths must pass | Any path exists |
| Uniqueness | Unique idom | Many predecessors |
| Structure | Tree | DAG |
| Query | O(log n) with LCA | O(1) with preprocessing |

