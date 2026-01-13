# Stoer-Wagner Global Minimum Cut

## Overview

The **global minimum cut** of an undirected weighted graph is the smallest
possible total weight of edges you need to remove to split the graph into two
non-empty parts.

Stoer-Wagner is the classic deterministic algorithm for this problem when
**all edge weights are non-negative**. It repeatedly grows a set of vertices and
contracts the graph, keeping the smallest cut found.

- **Time**: O(V^3)
- **Space**: O(V^2)

## Key Idea: Maximum Adjacency Search

In each phase we build a set **A** by repeatedly adding the vertex with the
largest total edge weight to **A**.

Let `t` be the last vertex added. Then the cut
`{t} | (V \ {t})` has weight `w[t]` and is a valid cut for the current graph.
We keep the best cut across all phases.

After each phase, we **contract** `t` into the previous vertex `s` and repeat.

## API

- `stoer_wagner_min_cut(n, edges)`
  - Returns `Some({ weight, cut })`
  - `cut` is one side of the min cut (array of vertex ids)
  - Returns `None` if `n <= 1`

## Example Usage

```mbt check
///|
test "stoer wagner cycle" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 1L),
    (2, 3, 1L),
    (3, 0, 1L),
  ]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(4, edges[:]).unwrap()
  inspect(result.weight, content="2")
}
```

```mbt check
///|
test "stoer wagner disconnected" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(3, edges[:]).unwrap()
  inspect(result.weight, content="0")
}
```

## Why It Works (Informal)

- The maximum adjacency search ensures the last vertex `t` is as "attached" as
  possible to the current set `A`.
- The weight `w[t]` is exactly the cut separating `t` from the rest of the
  graph in this phase.
- Contracting preserves all cut weights, so the minimum cut in the contracted
  graph corresponds to a cut in the original graph.
- Taking the minimum over all phases yields the global min cut.
