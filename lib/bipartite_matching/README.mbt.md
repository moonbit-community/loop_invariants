# Bipartite Matching (Maximum Matching)

A **bipartite graph** has two disjoint vertex sets: **left** and **right**.
Edges only go between the sets. A **matching** is a set of edges where no
vertex appears more than once.

This package computes a **maximum matching**: the largest possible number of
non-conflicting pairs.

## Problem statement

Given:

- `n_left` left vertices labeled `0..n_left-1`
- `n_right` right vertices labeled `0..n_right-1`
- a list of edges `(u, v)` with `u` on the left and `v` on the right

Find a maximum-size set of pairs `(u, v)` where no left or right vertex is
used twice.

## The key idea: augmenting paths

An **augmenting path** is a path that alternates:

- unmatched edge
- matched edge
- unmatched edge
- ...

and starts at an unmatched left vertex and ends at an unmatched right vertex.
Flipping the matched/unmatched status of every edge on that path increases the
matching size by 1.

If no augmenting path exists, the matching is maximum.

## Algorithm used here (Kuhn / DFS)

The public function `max_matching` uses the classic DFS-based algorithm:

1. Start with an empty matching.
2. For each left vertex `u`, try to find an augmenting path with DFS.
3. If found, update the matching.

This is simple to implement and works well for medium-sized graphs.

## Public API

```
@bipartite_matching.max_matching(n_left, n_right, edges)
```

Returns an array of `(left, right)` pairs that form a maximum matching.
The order of pairs is not guaranteed.

## Examples

### Example 1: small matching

```mbt check
///|
test "small matching" {
  let edges : Array[(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
  let matching = @bipartite_matching.max_matching(2, 2, edges[:])
  let sorted = matching.copy()
  sorted.sort_by((a, b) => a.0 - b.0)
  inspect(sorted, content="[(0, 0), (1, 1)]")
  inspect(matching.length(), content="2")
}
```

### Example 2: more left vertices than right

```mbt check
///|
test "unbalanced sets" {
  let edges : Array[(Int, Int)] = [(0, 0), (1, 0), (2, 1), (3, 1)]
  let matching = @bipartite_matching.max_matching(4, 2, edges[:])
  inspect(matching.length(), content="2")
}
```

Only two right vertices exist, so the maximum matching size is 2.

### Example 3: assignment style

Workers on the left, jobs on the right. An edge means a worker can do a job.

```mbt check
///|
test "assignment example" {
  let edges : Array[(Int, Int)] = [(0, 0), (0, 2), (1, 0), (1, 1), (2, 1)]
  let matching = @bipartite_matching.max_matching(3, 3, edges[:])
  inspect(matching.length(), content="3")
}
```

## Practical notes and pitfalls

- Edges must point from left to right; `(u, v)` is invalid if `u` or `v` is out
  of range.
- Duplicate edges are allowed but may slow down DFS.
- The order of pairs in the result depends on DFS order; sort if you need a
  stable presentation.

## Complexity

- Time: O(V * E)
- Space: O(V + E)

`V = n_left + n_right` and `E = edges.length()`.

## When to use it

Use bipartite matching when you need:

- Assignments (workers to jobs, students to courses)
- Pairing tasks without conflicts
- Maximum compatibility matches

If the graph is very large, Hopcroft-Karp is faster, but the core idea is the
same.
