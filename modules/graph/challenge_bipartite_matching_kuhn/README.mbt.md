# Challenge: Bipartite Matching (Kuhn DFS)

This challenge implements **maximum bipartite matching** using the classic
DFS-based augmenting path algorithm (often called Kuhn's algorithm).

A bipartite graph has two disjoint sets of nodes:

- left side (L)
- right side (R)

Edges only go from L to R. A **matching** is a set of edges where no node is
used more than once. The goal is to **maximize** the number of matched pairs.

## Problem statement

Given:

- `left_n` left vertices labeled `0..left_n-1`
- `right_n` right vertices labeled `0..right_n-1`
- a list of edges `(u, v)` with `u` in left, `v` in right

Find the maximum number of pairs `(u, v)` with no repeated vertex.

## Key idea: augmenting paths

Start with an empty matching. Repeatedly try to find an **augmenting path**:

- it alternates between unmatched and matched edges
- it starts from an unmatched left vertex
- it ends at an unmatched right vertex

Flipping the edges on that path increases the matching size by 1.

## Algorithm outline (Kuhn DFS)

For each left vertex `u`:

1. Run a DFS from `u` to find an augmenting path.
2. Mark right vertices visited in this DFS (to avoid cycles).
3. If you reach an unmatched right vertex, or can reroute its current match,
   you have found an augmenting path.

## Diagram example

```
Left:   0   1   2
Right:  0   1   2

Edges:
0 -- 0
0 -- 1
1 -- 1
2 -- 2
```

A maximum matching is size 3: `(0,0)`, `(1,1)`, `(2,2)`.

## Examples

### Example 1: basic matching

```mbt check
///|
test "basic matching" {
  let edges : Array[(Int, Int)] = [(0, 0), (0, 1), (1, 1), (2, 2)]
  let adj = @challenge_bipartite_matching_kuhn.build_adj(3, 3, edges)
  let m = @challenge_bipartite_matching_kuhn.max_matching(adj, 3)
  debug_inspect(m, content="3")
}
```

### Example 2: not perfect

```mbt check
///|
test "not perfect" {
  let edges : Array[(Int, Int)] = [(0, 0), (1, 0), (2, 0)]
  let adj = @challenge_bipartite_matching_kuhn.build_adj(3, 1, edges)
  let m = @challenge_bipartite_matching_kuhn.max_matching(adj, 1)
  debug_inspect(m, content="1")
}
```

### Example 3: empty graph

```mbt check
///|
test "empty graph" {
  let edges : Array[(Int, Int)] = []
  let adj = @challenge_bipartite_matching_kuhn.build_adj(2, 2, edges)
  let m = @challenge_bipartite_matching_kuhn.max_matching(adj, 2)
  debug_inspect(m, content="0")
}
```

### Example 4: uneven sizes

```mbt check
///|
test "uneven sizes" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 0), (2, 1), (3, 2)]
  let adj = @challenge_bipartite_matching_kuhn.build_adj(4, 3, edges)
  let m = @challenge_bipartite_matching_kuhn.max_matching(adj, 3)
  debug_inspect(m, content="3")
}
```

## Complexity

- Worst case: O(V * E)
- Often faster on sparse graphs

`V = left_n + right_n` and `E = edges.length()`.

## Practical notes and pitfalls

- The adjacency list is **left to right** only.
- Recreate the `seen` array for each DFS from a left node.
- This algorithm returns only the size. If you need the pairs, track them via
  the `match_r` array.

## When to use it

Use Kuhn's algorithm for small to medium graphs where simplicity matters.
For very large graphs, Hopcroft-Karp is asymptotically faster.
