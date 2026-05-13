# Karp's Minimum Mean-Weight Cycle

## Overview

Given a directed graph with arbitrary (possibly negative) edge weights,
compute the *minimum cycle mean* -- the smallest average edge weight
taken over all directed cycles in the graph:

```
              sum_{e in C} w(e)
   mu*  =  min   ----------------
            C        |C|
```

over all directed cycles `C`. `mu*` is returned as an exact rational
`(numerator, denominator)`, where the denominator is the length (number
of edges) of a witnessing cycle.

- **Time**: `O(V * E)`
- **Space**: `O(V)` extra
- **Signature**:
  `min_mean_cycle(n : Int, edges : ArrayView[(Int, Int, Int64)], start : Int) -> (Int64, Int)?`

The `start` parameter specifies the source vertex of the layered DP that
underlies Karp's characterisation; only cycles reachable from `start`
are considered. In a strongly connected graph the result is independent
of `start`.

## Where it sits among shortest-path algorithms

| Goal                              | Available                |
|-----------------------------------|--------------------------|
| Shortest path, non-negative `w`   | `@dijkstra.dijkstra`     |
| Shortest path, arbitrary `w`      | `@bellman_ford`          |
| All-pairs shortest paths          | `@johnson_all_pairs`     |
| Detect a negative-weight cycle    | `@bellman_ford`          |
| **Minimum *mean* cycle**          | **this package**         |
| Maximum flow, min-cost flow       | `@max_flow`, `@mcmf`     |

The minimum mean cycle is a refinement of "is there a negative cycle?":
Bellman-Ford answers the yes/no question; Karp tells you *how negative*
on average.

## The F_k(v) DP

Let

```
   F_k(v)  =  min weight of a walk start -> v using exactly k edges
              (+infinity if no such walk exists).
```

This is a Bellman-Ford-style layered DP with the recurrence

```
   F_0(start) = 0
   F_0(v)     = +infinity   for v != start
   F_k(v)     = min over (u, v, w) in E of  F_{k-1}(u) + w.
```

Computing rows `F_0, F_1, ..., F_n` takes `O(V * E)` time and (with two
alternating rows) `O(V)` space; we keep all `n + 1` rows here because
the closed form below queries every row.

## Karp's characterisation theorem

> *Karp (1978).* Fix any vertex `start` from which every cycle of `G` is
> reachable. Then the minimum cycle mean is
>
> ```
>                              F_n(v)  -  F_k(v)
>     mu*  =  min over v in V   max over 0 <= k < n  ----------------
>                                                       n  -  k
> ```

### Why the max-over-k corresponds to a cycle

Fix `v` with `F_n(v)` finite. A walk realising `F_n(v)` has `n` edges
and therefore visits `n + 1` vertices; by the pigeonhole principle two
of them coincide, so the walk decomposes as

```
  start --(prefix, k edges)--> u --(cycle on n - k edges)--> u --(suffix)--> v.
```

Stripping off the cycle (and re-attaching the suffix to the prefix's
endpoint of `u`) yields a strictly shorter walk to `v`, so

```
   F_n(v) - F_k(v)  >=  weight(cycle)            (with equality at the
                         tight k that splits exactly at the cycle).
```

Therefore for every reachable cycle there is some `k` realising
`(F_n(v) - F_k(v)) / (n - k) >= mu(cycle)`, and conversely no `k` can
give a ratio smaller than `mu(cycle)` (a tighter walk would imply a
cheaper cycle). The max over `k` selects the cycle through `v`, and the
min over `v` then selects the cheapest cycle in the whole graph.

### Why the min-over-v is taken

Different vertices may witness different cycles; the algorithm has to
try them all and pick the cheapest. For a strongly connected graph
every cycle is witnessed by every vertex and the result is independent
of the choice of `v` -- but the `min` is still needed in general
graphs.

## Worked example

Take the 3-vertex graph

```
  0 --(+2)--> 1 --(-1)--> 2 --(-2)--> 0     (only this cycle)
```

with `start = 0`, `n = 3`. The DP tables:

| layer `k` | F_k(0) | F_k(1) | F_k(2) |
|-----------|--------|--------|--------|
| 0         | 0      | +inf   | +inf   |
| 1         | +inf   | 2      | +inf   |
| 2         | +inf   | +inf   | 1      |
| 3         | -1     | +inf   | +inf   |

Only `F_3(0)` is finite, so the outer minimum is taken at `v = 0`.
For that vertex the inner max ranges over `k` with `F_k(0)` finite:

| `k` | `(F_3(0) - F_k(0)) / (3 - k)` |
|-----|-------------------------------|
| 0   | `(-1 - 0) / 3  =  -1/3`       |
| 1   | skipped (F_1(0) = +inf)       |
| 2   | skipped (F_2(0) = +inf)       |

So `M(0) = -1/3`, hence `mu* = -1/3` and the cycle of length 3 with
total weight `-1` realises the minimum. The function returns
`Some((-1L, 3))`.

## Cycle existence

A directed cycle reachable from `start` exists if and only if `F_n(v)`
is finite for some `v`. Reason: if some walk of length `n` from `start`
exists, it touches `n + 1` vertices and must repeat one (pigeonhole),
giving a cycle. Conversely, if there is any cycle reachable from
`start`, you can pad an entry walk into the cycle to reach length `n`,
giving a finite `F_n` value at some vertex on the cycle. The
implementation returns `None` precisely when this finite-row witness is
absent.

## Reference implementation

```
pub fn min_mean_cycle(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  start : Int,
) -> (Int64, Int)?
```

The numerator is an `Int64` (it is a sum of at most `n` weights) and
the denominator is an `Int` cycle length in `[1, n]`. The returned
fraction is *not* automatically reduced to lowest terms.

## Tests and examples

### A single 2-cycle

```mbt check
///|
test "karp readme 2-cycle" {
  // 0 -> 1 (w = 5), 1 -> 0 (w = 3). Mean = 8 / 2 = 4.
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L), (1, 0, 3L)]
  debug_inspect(
    @karp_minimum_mean_cycle.min_mean_cycle(2, edges, 0),
    content="Some((8, 2))",
  )
}
```

### A self-loop dominates

```mbt check
///|
test "karp readme self-loop" {
  // Single self-loop of weight 7. The only cycle has mean 7 / 1.
  let edges : Array[(Int, Int, Int64)] = [(0, 0, 7L)]
  debug_inspect(
    @karp_minimum_mean_cycle.min_mean_cycle(1, edges, 0),
    content="Some((7, 1))",
  )
}
```

### Choosing the smaller of two means

```mbt check
///|
test "karp readme two cycles" {
  // Cycle A: 0 -> 1 -> 0 with weights (1, 4) -> mean 5/2.
  // Cycle B: 0 -> 2 -> 0 with weights (3, 4) -> mean 7/2.
  // The algorithm picks cycle A.
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 0, 4L),
    (0, 2, 3L),
    (2, 0, 4L),
  ]
  debug_inspect(
    @karp_minimum_mean_cycle.min_mean_cycle(3, edges, 0),
    content="Some((5, 2))",
  )
}
```

### A DAG has no cycles

```mbt check
///|
test "karp readme dag" {
  // 0 -> 1 -> 2 is a DAG; no cycle.
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 2, 1L)]
  debug_inspect(
    @karp_minimum_mean_cycle.min_mean_cycle(3, edges, 0),
    content="None",
  )
}
```

## Complexity

- **Time** `O(V * E)`: each of the `n` DP rows performs an `O(|E|)`
  edge sweep. The post-processing step that computes
  `min over v, max over k` runs in `O(V * V) = O(V^2)` time, which is
  dominated by `V * E` whenever the graph has at least as many edges
  as vertices (typical for cycle-bearing graphs).
- **Space** `O(V)` extra beyond the input: two DP rows of `n` entries
  each suffice in principle. The reference implementation stores all
  `n + 1` rows in an `Array[Array[Int64]]` (`O(V^2)` total) because the
  closed-form post-processing reads every row; an in-place variant
  recovers `O(V)` space at the cost of recomputing rows on demand.

## Common applications

- **Ratio optimisation** -- minimum cost-to-time cycle, maximum
  profit-to-cycle-length ratio, "Tour of the world" style scheduling.
- **Negative-cycle certification** with a *quantitative* measure:
  Bellman-Ford answers yes/no, Karp tells you how negative the cheapest
  cycle is on average.
- **Parametric shortest paths** -- subroutine in Megiddo's parametric
  search and in algorithms for the shortest path with a linear
  parameter constraint (`w(e) - lambda * c(e)`).
- **Mean payoff games** -- the value of a one-player mean-payoff game
  on a graph is exactly the minimum (or maximum) mean cycle reachable
  from the starting state.
- **System performance analysis** -- in dataflow / synchronous systems
  the maximum mean cycle of the dependency graph determines the
  asymptotic throughput.

## Common pitfalls

- **`start` matters in non-strongly-connected graphs.** The algorithm
  only considers cycles reachable from `start`. If your graph splits
  into several SCCs and you want the global minimum, run the algorithm
  once per SCC (or per source vertex from each SCC). The package
  returns `None` when nothing reachable contains a cycle.
- **Returned fraction is not reduced.** The pair `(num, den)` is the
  raw numerator and denominator that fall out of the DP. To get a
  canonical form divide both by `gcd(|num|, den)`.
- **Self-loops *are* cycles.** A self-loop `(v, v, w)` is a length-1
  cycle of mean `w / 1`. The algorithm treats it correctly because the
  walk of length 1 from `start` to a vertex with a self-loop counts as
  such a cycle when `start = v`, and reachable self-loops appear in
  the F_n table for indirectly reachable starts.
- **Overflow.** All numerators are sums of at most `n` weights, and the
  cross-multiplication compares `num1 * den2` vs `num2 * den1`. Both
  factors are bounded by `n * max|w|`, which fits in `Int64` for any
  reasonable input.
- **Empty graph or invalid `start`.** When `n <= 0`, `start < 0`, or
  `start >= n`, the function returns `None` rather than failing.

## Related concepts

```
Bellman-Ford layered DP    F_k(v) recurrence used here
Negative cycle detection   Bellman-Ford yes/no
Howard's policy iteration  Alternative O(V * E) algorithm for mu*
Parametric shortest paths  shortest path with w(e) - lambda * c(e)
Mean-payoff games          one-player game-theoretic interpretation
```
