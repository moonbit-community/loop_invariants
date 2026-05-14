# Gale-Shapley Stable Matching

## Overview

The deferred-acceptance algorithm for the **stable marriage** problem.
Given `n` proposers and `n` reviewers, each with a complete strict
preference ranking over the other side, find a one-to-one matching
with **no blocking pair** — i.e. no two unmatched individuals who
both prefer each other over their assigned partners.

- **Time**: O(n²)
- **Space**: O(n²) for preference inputs + O(n) for matching state
- **Signatures**:
  - `stable_match(proposer_prefs, reviewer_prefs) -> Array[Int]`
  - `is_stable(proposer_prefs, reviewer_prefs, m) -> Bool`

Gale & Shapley (1962) showed that a stable matching always exists.
Roth & Shapley shared the **2012 Nobel Prize in Economics** for the
practical applications: hospital-residency placement (NRMP),
school-choice systems (Boston, NYC), and kidney-exchange networks
all use variants of this algorithm.

---

## The algorithm

```
for every proposer p:
  next_idx[p] = 0
while some proposer p is unmatched and has more candidates:
  r = p's next-most-preferred reviewer
  if r is unmatched:
    tentatively match (p, r)
  else:
    let p' = r's current match
    if r prefers p over p':
      match (p, r), evicting p'
    else:
      p remains unmatched and tries their next preference
```

The "deferred acceptance" name comes from reviewers *holding* their
best offer so far rather than committing immediately. Final matches
are only fixed when no more proposals can change them.

---

## Properties

| Property | Guarantee |
|---|---|
| **Stable** | The output has no blocking pair (provably). |
| **Proposer-optimal** | Every proposer ends up with their best-possible stable partner. |
| **Reviewer-pessimal** | The mirror: reviewers get their worst stable partner. |
| **Terminating** | At most `n²` proposals: each proposer proposes to each reviewer at most once. |
| **Strategy-proof** for proposers | A proposer cannot do better by lying about preferences. |
| **Manipulable** by reviewers | Reviewers *can* benefit by lying — a famous tension exploited in real markets. |

---

## The invariant

Throughout execution:

1. Every reviewer's current match (if any) is the best-ranking
   proposer they have seen so far.
2. Every proposer has proposed to a strict prefix of their preference
   list.
3. No proposer ever revisits a reviewer they've already proposed to.

When the loop terminates (no more pending proposers), the matching is
complete and stable. The proof of stability: suppose `(p, r)` were a
blocking pair. Then `p` prefers `r` over their match, so `p` *must*
have proposed to `r` earlier (by invariant 2). Reviewer `r` either
already had a better proposer at that moment (contradiction: they'd
still have someone strictly better than `p`'s current rank) or
accepted `p` and was later replaced by someone strictly better than
`p` (so `r`'s current match outranks `p`, contradicting the assumption
that `r` prefers `p`).

---

## Worked example

3 proposers, 3 reviewers:

| | r0 | r1 | r2 |
|---|---|---|---|
| **p0** prefers | 1st | 2nd | 3rd |
| **p1** prefers | 1st | 3rd | 2nd |
| **p2** prefers | 2nd | 1st | 3rd |

| | p0 | p1 | p2 |
|---|---|---|---|
| **r0** prefers | 2nd | 1st | 3rd |
| **r1** prefers | 1st | 2nd | 3rd |
| **r2** prefers | 3rd | 2nd | 1st |

Trace:

1. p0 → r0. r0 unmatched, accept. State: `{r0: p0}`.
2. p1 → r0. r0 prefers p1 over p0 (rank 1 vs 2). Evict p0. State: `{r0: p1}`, p0 pending.
3. p2 → r1. r1 unmatched, accept. State: `{r0: p1, r1: p2}`.
4. p0 → r1. r1 prefers p0 over p2 (rank 1 vs 3). Evict p2. State: `{r0: p1, r1: p0}`, p2 pending.
5. p2 → r0. r0 prefers p1 over p2 (rank 1 vs 3). Reject. p2 pending.
6. p2 → r2. r2 unmatched, accept. State: `{r0: p1, r1: p0, r2: p2}`.

Result: `[1, 0, 2]` — p0 paired with r1, p1 with r0, p2 with r2.
Verify stability by checking: every potential blocking pair `(p, r)`
fails because at least one party prefers their current match.

---

## Reference implementation

```
pub fn stable_match(
  proposer_prefs : ArrayView[Array[Int]],
  reviewer_prefs : ArrayView[Array[Int]],
) -> Array[Int]

pub fn is_stable(
  proposer_prefs : ArrayView[Array[Int]],
  reviewer_prefs : ArrayView[Array[Int]],
  m : ArrayView[Int],
) -> Bool
```

---

## Tests and examples

```mbt check
///|
test "gale-shapley three-person" {
  let pp : Array[Array[Int]] = [[0, 1, 2], [0, 2, 1], [1, 0, 2]]
  let rp : Array[Array[Int]] = [[1, 0, 2], [0, 1, 2], [2, 1, 0]]
  let m = @gale_shapley_stable_matching.stable_match(pp[:], rp[:])
  debug_inspect(m, content="[1, 0, 2]")
}
```

```mbt check
///|
test "gale-shapley produces stable matching" {
  let pp : Array[Array[Int]] = [
    [2, 0, 1, 3],
    [3, 2, 0, 1],
    [1, 3, 0, 2],
    [0, 1, 2, 3],
  ]
  let rp : Array[Array[Int]] = [
    [1, 0, 3, 2],
    [3, 1, 2, 0],
    [2, 0, 1, 3],
    [0, 2, 3, 1],
  ]
  let m = @gale_shapley_stable_matching.stable_match(pp[:], rp[:])
  debug_inspect(
    @gale_shapley_stable_matching.is_stable(pp[:], rp[:], m[:]),
    content="true",
  )
}
```

```mbt check
///|
test "gale-shapley mutual top match" {
  let pp : Array[Array[Int]] = [
    [2, 0, 1, 3],
    [0, 1, 2, 3],
    [1, 0, 2, 3],
    [3, 2, 1, 0],
  ]
  let rp : Array[Array[Int]] = [
    [1, 0, 2, 3],
    [2, 0, 1, 3],
    [0, 1, 2, 3],
    [3, 2, 1, 0],
  ]
  let m = @gale_shapley_stable_matching.stable_match(pp[:], rp[:])
  // p0 and r2 are each other's top choice -- they must be matched.
  debug_inspect(m[0], content="2")
}
```

```mbt check
///|
test "gale-shapley single pair" {
  let pp : Array[Array[Int]] = [[0]]
  let rp : Array[Array[Int]] = [[0]]
  debug_inspect(
    @gale_shapley_stable_matching.stable_match(pp[:], rp[:]),
    content="[0]",
  )
}
```

---

## Complexity

| Step | Time |
|------|------|
| Rank-table preprocessing | O(n²) |
| Main proposal loop | O(n²) total (each proposer proposes ≤ n times) |
| `is_stable` validation | O(n²) |

The space is dominated by the input preference matrices (O(n²)) plus
the rank tables. Bookkeeping uses O(n).

---

## When to reach for it

- **One-sided market matching** under preferences: hospital
  residencies, university admissions, school choice, kidney exchange.
- **Auction-like assignment problems** where stability matters more
  than total welfare. (For total-welfare-maximising assignment, use
  the Hungarian algorithm, `@mcmf.solve_assignment` in this repo.)
- **As a primitive in matroid intersection and other combinatorial
  algorithms** that need a stable feasible solution to bootstrap.

---

## Common pitfalls

- **Complete preferences required**. The basic Gale-Shapley assumes
  every proposer ranks every reviewer (and vice versa). Variants
  handle incomplete or weak rankings (with ties), with subtly
  different stability definitions.
- **The "optimal" side is the proposer side**. If you want a
  reviewer-optimal stable matching, swap the roles. This asymmetry
  matters in practice (school choice swapped from students-propose
  to schools-propose in many districts to favour students).
- **Numerical proposer / reviewer IDs**. This package uses Int
  indices throughout; build a name-to-index dictionary in your
  application layer if you need string labels.

---

## Related concepts

```
Gale-Shapley (this)         deferred acceptance, proposer-optimal stable
Roommates problem           one-sided variant; no stable matching may exist
Top Trading Cycles          for matching with priorities / endowments
Hungarian algorithm         max-weight bipartite matching (not stability)
Many-to-one matching        e.g. hospital residency (k slots per hospital)
Roth-Sotomayor theory       general theory of two-sided matching markets
```
