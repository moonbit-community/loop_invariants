# Karger's Randomised Min-Cut

## Overview

Find the minimum edge cut of an undirected (multi-)graph by repeatedly
contracting a uniformly random edge. Single-trial success probability
is `≥ 2 / (n · (n-1))`, so running `Θ(n² log n)` trials drives the
failure probability below `1 / n^c`.

- **Time**: O(trials · (n + E))
- **Space**: O(n + E)
- **Signature**: `karger_min_cut(n, edges, trials, seed~) -> Int`

This algorithm is famous for being *as simple as possible*: just three
pages of analysis cover both the algorithm and the matching lower
bound. Compare with `@stoer_wagner_min_cut` (deterministic, O(n·E) one
shot) — Karger is conceptually simpler but needs many independent
trials.

---

## The algorithm

```
trial:
  initialise DSU of singletons
  while #super-vertices > 2:
    pick uniformly random edge (u, v)
    if find(u) != find(v):
      union(u, v)               -- this is the "contraction"
  return |{ edges (u, v) with find(u) != find(v) }|

karger_min_cut:
  best = +infinity
  for t in 0..<trials:
    cut = trial(seed_t)
    if cut < best: best = cut
  return best
```

That is the entire algorithm. Each contraction merges two vertices
into a super-vertex; parallel edges between them remain in the graph
and "vote" for the next contraction with higher weight. When two
super-vertices remain, the edges between them are *a* cut. With
positive probability, it's the **minimum** cut.

---

## Why it works

Let `k` = size of the (unknown) minimum cut.

At any point in a trial, every super-vertex has degree at least `k`
(it would be otherwise cuttable below `k`). So if `V'` super-vertices
and `E'` edges remain,

```
2 · E'  =  sum of degrees  ≥  V' · k
```

Therefore the probability of picking a min-cut edge to contract next
is at most

```
k / E'  ≤  k / (V' · k / 2)  =  2 / V'.
```

The probability that **no** min-cut edge is ever contracted is at least

```
(1 - 2/n)(1 - 2/(n-1)) … (1 - 2/3)  =  2 / (n · (n-1)).
```

So a single trial succeeds with probability `Ω(1/n²)`. Running `T`
independent trials gives failure probability at most

```
(1 - 2 / (n · (n-1)))^T  ≤  exp(-2T / (n · (n-1)))
```

so `T = Θ(n² log n)` is enough for any inverse-polynomial failure bound.

---

## Worked example

`K_4` (the complete graph on 4 vertices): six edges, each vertex of
degree 3, min cut = 3. The first contraction picks an edge uniformly;
say it merges `0` and `1`. The two parallel edges from `{0,1}` to `2`
remain, and so do the two parallel edges from `{0,1}` to `3`. Plus
the edges `(2,3)`. Pick again; say we merge `(2,3)`. Now we have:

- `{0, 1}` super-vertex
- `{2, 3}` super-vertex
- Edges crossing: 4 (two from `{0,1}` to `2`, two from `{0,1}` to `3`).

So this trial finds a cut of size 4 — not the min cut (which is 3).
Other trials may find the cut of size 3. Aggregating over enough
trials, the minimum is 3 with high probability.

---

## Tests and examples

```mbt check
///|
test "karger 4-cycle" {
  // 4-cycle: every vertex has degree 2, so min cut = 2.
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
  debug_inspect(
    @karger_min_cut.karger_min_cut(4, edges[:], 50, seed=1L),
    content="2",
  )
}
```

```mbt check
///|
test "karger bridge" {
  // Two triangles joined by one bridge: min cut = 1.
  let edges : ReadOnlyArray[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 0),
    (3, 4),
    (4, 5),
    (5, 3),
    (2, 3),
  ]
  debug_inspect(
    @karger_min_cut.karger_min_cut(6, edges[:], 200, seed=7L),
    content="1",
  )
}
```

```mbt check
///|
test "karger K4" {
  let edges : ReadOnlyArray[(Int, Int)] = [
    (0, 1),
    (0, 2),
    (0, 3),
    (1, 2),
    (1, 3),
    (2, 3),
  ]
  debug_inspect(
    @karger_min_cut.karger_min_cut(4, edges[:], 100, seed=99L),
    content="3",
  )
}
```

```mbt check
///|
test "karger deterministic same seed" {
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3)]
  let a = @karger_min_cut.karger_min_cut(4, edges[:], 20, seed=1234L)
  let b = @karger_min_cut.karger_min_cut(4, edges[:], 20, seed=1234L)
  debug_inspect(a == b, content="true")
}
```

---

## Complexity

| Step | Cost |
|------|------|
| One contraction (DSU `union` w/ path compression) | `O(α(n))` amortised |
| One full trial (n-2 contractions) | `O((n + E) α(n))` |
| Across `trials` trials | `O(trials · (n + E))` |

For high-probability success, set `trials = ceil(n*(n-1)/2 · ln(n))`.
That gives a total of `O(n² · log n · E)`, comparable to but slightly
worse than Stoer-Wagner's deterministic `O(n · E + n² · log n)`.
The Karger-Stein improvement gets it down to `O(n² · log³ n)` with
recursive sub-sampling.

---

## When to reach for it

- **Pedagogical clarity**: the proof is one of the most accessible
  randomised-algorithm arguments. Three lines of probability, one
  binomial bound.
- **Lower bounds on cut size**: the analysis shows that any graph has
  at most `binomial(n, 2)` distinct minimum cuts — an *enumeration*
  bound that has no equivalent in the deterministic min-cut
  literature.
- **Parallel min-cut**: each trial is embarrassingly parallel, unlike
  Stoer-Wagner's inherently sequential phases.

---

## Common pitfalls

- **Single trial is hopeless**: with one trial, the success probability
  is `Ω(1/n²)`. Always run many trials and take the minimum.
- **Multi-edges count**: parallel edges in `edges` matter — they
  weight the random pick. This is how Karger handles weighted
  min-cut: replicate each edge `w` times.
- **Disconnected graphs**: the algorithm still terminates; the
  reported "cut" is whatever crosses the final two super-vertices,
  which is `0` if the graph wasn't connected.

---

## Related concepts

```
Karger (this)        randomised, simple, expected O(n^2 log n · E)
Karger-Stein         recursive Karger; O(n^2 log^3 n) high probability
Stoer-Wagner         deterministic, O(n · E + n^2 log n)
Edmonds-Karp         max-flow / min-cut between fixed s and t
Gomory-Hu tree       all-pairs min-cut in O(n) max-flow computations
```
