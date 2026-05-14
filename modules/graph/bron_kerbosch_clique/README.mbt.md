# Bron-Kerbosch Maximal Clique Enumeration

## Overview

Enumerate **all maximal cliques** of an undirected graph. The
Bron-Kerbosch backtracking algorithm (1973) with the
Tomita-Tanaka-Takahashi pivot optimisation (2006) is the standard
method and runs in worst-case `O(3^(n/3))` time — optimal because
that's also the maximum possible number of maximal cliques on `n`
vertices (Moon & Moser 1965).

- **Time**: `O(3^(n/3))` worst case
- **Space**: `O(n + E)` adjacency + recursion-depth stack
- **Signature**: `maximal_cliques(n, edges) -> Array[Array[Int]]`

Used heavily in social-network community detection, protein-interaction
analysis, constraint satisfaction, and any "find tightly-connected
groups" problem.

---

## The state

The recursion carries three vertex sets `R, P, X`:

- **`R`** — the clique being grown. Every vertex in `R` is pairwise
  adjacent.
- **`P`** — candidates: vertices adjacent to every vertex of `R`,
  available to extend `R`.
- **`X`** — excluded: vertices adjacent to every vertex of `R` that
  have already had their "extend with this as the next vertex" branch
  considered. Used to avoid emitting the same clique twice.

A maximal clique is reported precisely when **both `P` and `X` are
empty** at a leaf of the recursion tree — meaning we cannot extend
`R` and we are not missing a strictly larger maximal clique.

---

## The pivot trick (Tomita 2006)

Without a pivot, we'd branch on every `v ∈ P`. With a pivot we choose
`u ∈ P ∪ X` maximising `|N(u) ∩ P|` and only branch on
`v ∈ P \ N(u)`.

Why is this correct? Every maximal clique extending `R` and containing
`u` will be discovered through some descendant recursion — those
descendants will inherit the responsibility for exploring `u`'s
neighbours in `P`. So branching only on `P \ N(u)` covers every
maximal extension. The pivot prunes the recursion tree dramatically.

This brings the worst-case complexity to `O(3^(n/3))`. Without the
pivot, the bound is much worse on dense graphs.

---

## Pseudocode

```
extend(R, P, X):
  if P is empty and X is empty:
    report R                 -- a maximal clique
    return
  pivot = argmax_{u ∈ P ∪ X}  |N(u) ∩ P|
  for v ∈ P \ N(pivot):
    extend(R ∪ {v},
           P ∩ N(v),
           X ∩ N(v))
    P := P \ {v}
    X := X ∪ {v}
```

---

## The invariants

| Invariant | Meaning |
|---|---|
| **I1** | Every two vertices in `R` are adjacent. |
| **I2** | Every vertex in `P` is adjacent to every vertex of `R`. |
| **I3** | Every vertex in `X` is adjacent to every `R`-vertex AND has had its "branch with this as new vertex" already explored. |
| **I4** | Every maximal clique that contains `R` is reported in exactly one leaf descendant. |

I4 is what guarantees no duplicates and no missed cliques. The proof
uses an inductive argument on `|P| + |X|`.

---

## Tests and examples

```mbt check
///|
test "bk triangle" {
  let cliques = @bron_kerbosch_clique.maximal_cliques(
    3,
    [(0, 1), (1, 2), (0, 2)][:],
  )
  // One maximal clique: {0, 1, 2}.
  debug_inspect(cliques.length(), content="1")
}
```

```mbt check
///|
test "bk path graph" {
  // Path 0 - 1 - 2 - 3 has three maximal cliques (the edges).
  let cliques = @bron_kerbosch_clique.maximal_cliques(
    4,
    [(0, 1), (1, 2), (2, 3)][:],
  )
  debug_inspect(cliques.length(), content="3")
}
```

```mbt check
///|
test "bk K4 complete" {
  let cliques = @bron_kerbosch_clique.maximal_cliques(
    4,
    [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)][:],
  )
  // One maximal clique: {0, 1, 2, 3}.
  debug_inspect(cliques.length(), content="1")
}
```

```mbt check
///|
test "bk two triangles share vertex" {
  // {0,1,2} and {0,3,4} share vertex 0.
  let cliques = @bron_kerbosch_clique.maximal_cliques(
    5,
    [(0, 1), (1, 2), (0, 2), (0, 3), (3, 4), (0, 4)][:],
  )
  debug_inspect(cliques.length(), content="2")
}
```

---

## Complexity

| Step | Cost |
|------|------|
| Adjacency-list construction | `O(n + E)` |
| Pivot selection (per recursion) | `O((|P| + |X|) · (|P|))` |
| Set intersections via two-pointer | `O(|P|)` each |
| Total worst case | `O(3^(n/3))` |
| Space | `O(n + E + depth · |R|)` |

For sparse, well-behaved graphs, runtime is dramatically better than
the worst-case bound suggests — usually polynomial in the output size.

---

## When to reach for it

- **Community detection** on small-to-medium graphs (up to ~1000
  vertices on a laptop).
- **Set cover / packing problems** reduced to clique enumeration on
  conflict graphs.
- **Cheminformatics**: finding common substructure in molecules
  (clique in product graph).
- **SAT preprocessing**: identify maximal cliques of
  literal-compatibility graphs.

Use a different algorithm for **maximum** clique (just one
largest-cardinality clique) — that's NP-hard in general; common
heuristics include branch-and-bound on the colouring upper bound.

---

## Common pitfalls

- **Output explosion**: a graph with `n` vertices can have up to
  `3^(n/3)` maximal cliques. Reserve memory accordingly.
- **Repeated edges and self-loops**: the implementation tolerates and
  ignores both, but does not de-duplicate vertices.
- **Pivot quality matters**. The "max neighbours in P" heuristic is
  the standard; weaker pivots (e.g. arbitrary) work but are slower.
- **The output cliques are sorted ascending** within each clique;
  ordering between cliques is unspecified.

---

## Related concepts

```
Bron-Kerbosch (this)         enumerate all maximal cliques
Maximum clique (NP-hard)     find ONE largest; branch-and-bound with colouring
Independent set              complement of a clique on the complement graph
Vertex cover                 complement of an independent set on same graph
Triangle counting            often a useful subroutine even when listing all
                              cliques is too expensive
```
