# Minimum s-t Cut (via Max Flow)

This package computes the **minimum s-t cut** of a directed graph by running
max flow and reading the residual graph.

If you are new to flows, think of each edge as a pipe with capacity. The min
cut is the cheapest set of pipes you must cut to stop all flow from `s` to `t`.

## 1. What is an s-t cut?

An **s-t cut** is a partition of vertices into two groups `(S, T)` such that:

- `s` is in `S`
- `t` is in `T`
- the cut capacity is the sum of capacities of edges from `S` to `T`

Tiny warm-up example:

```
0 --3--> 1 --2--> 2
 \--1---------------->

s = 0, t = 2
```

Two possible cuts:

- `S = {0}`, `T = {1, 2}`:
  cut edges = `0->1 (3)` and `0->2 (1)` => capacity `4`
- `S = {0, 1}`, `T = {2}`:
  cut edges = `1->2 (2)` and `0->2 (1)` => capacity `3`

So the minimum s-t cut here has capacity `3`.

## 2. Why max flow gives the min cut

The **max-flow min-cut theorem** says:

```
max_flow(s, t) = min_cut_capacity(s, t)
```

Intuition: if you push as much flow as possible, every remaining path from `s`
to `t` must be blocked by a fully saturated edge. Those saturated edges form
the bottleneck that is exactly the min cut.

## 3. Residual graph refresher

For each edge `u -> v` with capacity `c` and current flow `f`:

```
Residual forward  capacity = c - f
Residual backward capacity = f
```

You can traverse an edge in the residual graph only if its residual capacity is
positive.

## 4. The algorithm (step by step)

1. Build the flow network from `n` and `edges`.
2. Run max flow (Dinic).
3. Do a BFS/DFS from `s` in the residual graph.
4. Let `S` be all reachable vertices; let `T` be the rest.
5. Return:
   - `value = max_flow`
   - `source_side = S`

The cut edges are **all original edges from `S` to `T`**.

## 5. Example A: balanced branches

Edges:

```
0 -> 1 (cap 3)
0 -> 2 (cap 2)
1 -> 3 (cap 2)
2 -> 3 (cap 3)
```

Diagram:

```
    0
   / \
 3/   \2
 /     \
1       2
 \     /
  \2  /3
    3
```

Max flow from 0 to 3:

- Path `0->1->3` sends 2
- Path `0->2->3` sends 2

Total flow = 4, so the min cut must also be 4.

Residual reachability from 0:

- `0->1` still has capacity 1, so 1 is reachable
- `0->2` is saturated, so 2 is not reachable
- `1->3` is saturated, so 3 is not reachable

Therefore:

```
S = {0, 1}
T = {2, 3}
```

Cut edges are `0->2 (2)` and `1->3 (2)`, total capacity 4.

```mbt check
///|
test "min cut st balanced branches" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 3L),
    (0, 2, 2L),
    (1, 3, 2L),
    (2, 3, 3L),
  ]
  let result = @min_cut_st.min_cut_st(4, edges[:], 0, 3).unwrap()
  inspect(result.value, content="4")
}
```

## 6. Example B: a narrow bottleneck into the sink

Here the bottleneck is obvious: only two unit edges enter the sink.

```
0 --5--> 1 --1--> 3
 \--5--> 2 --1--> 3
```

The min cut is the two edges into `3`, so capacity `2`.

```mbt check
///|
test "min cut st bottleneck into sink" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 5L),
    (0, 2, 5L),
    (1, 3, 1L),
    (2, 3, 1L),
  ]
  let result = @min_cut_st.min_cut_st(4, edges[:], 0, 3).unwrap()
  inspect(result.value, content="2")
}
```

## 7. Input format and return value

Signature (from `pkg.generated.mbti`):

- `min_cut_st(n, edges, source, sink) -> MinCutSTResult?`

Parameters:

- `n`: number of vertices, labeled `0 .. n-1`
- `edges`: `ArrayView[(Int, Int, Int64)]` of `(from, to, capacity)`
- `source`, `sink`: vertex indices

Returns `None` if:

- `n <= 0`
- any vertex index is out of range
- `source == sink`

On success, you get:

- `value`: min cut capacity (equals max flow)
- `source_side`: vertices in `S` (reachable from `source` in residual graph)

## 8. Listing the actual cut edges

The package does not list cut edges directly, but it gives you `source_side`,
which is enough to compute them.

The fast method builds a boolean lookup table so membership is O(1). This uses
mutation for performance, which is appropriate when you have many edges.

```mbt check
///|
fn cut_edges_fast(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source_side : Array[Int],
) -> Array[(Int, Int, Int64)] {
  let in_source = Array::make(n, false)
  for v in source_side {
    if v >= 0 && v < n {
      in_source[v] = true
    }
  }
  let cut : Array[(Int, Int, Int64)] = []
  for edge in edges {
    let (u, v, cap) = edge
    if in_source[u] && not(in_source[v]) {
      cut.push((u, v, cap))
    }
  }
  cut
}

///|
fn sum_cap(acc : Int64, edge : (Int, Int, Int64)) -> Int64 {
  let (_, _, cap) = edge
  acc + cap
}

///|
test "cut edges sum to min cut value" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 3L),
    (0, 2, 2L),
    (1, 3, 2L),
    (2, 3, 3L),
  ]
  let result = @min_cut_st.min_cut_st(4, edges[:], 0, 3).unwrap()
  let cut = cut_edges_fast(4, edges[:], result.source_side)
  let sum = cut.fold(init=0L, sum_cap)
  inspect(sum, content="4")
}
```

For very small graphs, a simpler (but slower) check is also fine:

```
edge (u -> v) is in the cut if
  source_side.contains(u) && not(source_side.contains(v))
```

## 9. Example C: no path from s to t

If `t` is unreachable, the max flow (and min cut) is `0`.

```mbt check
///|
test "min cut st no path" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = @min_cut_st.min_cut_st(3, edges[:], 0, 2).unwrap()
  inspect(result.value, content="0")
}
```

## 10. Complexity

The heavy part is Dinic's algorithm:

```
Time:  O(V^2 * E)   (worst case for general graphs)
Space: O(V + E)
```

The final residual BFS is just `O(V + E)`.

## 11. s-t min cut vs global min cut

- **s-t min cut**: source and sink are fixed (this package)
- **global min cut**: minimum cut over all pairs of vertices

Global min cut uses other algorithms (e.g., Stoer-Wagner).

## 12. Summary

This package gives you:

- the min cut value (equal to max flow),
- and the source-side set that defines the cut.

With those two pieces, you can easily list cut edges, visualize the cut, or
confirm the bottleneck in your network.
