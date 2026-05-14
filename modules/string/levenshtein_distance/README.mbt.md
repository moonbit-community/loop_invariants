# Levenshtein Distance

## Overview

The **Levenshtein distance** between two sequences is the minimum
number of single-character **insertions**, **deletions**, and
**substitutions** required to transform one into the other. It is the
standard string-edit metric and the most-used distance in
spellcheckers, fuzzy search, and bioinformatics.

It differs from [Myers diff](../myers_diff) in one crucial way: Myers
counts only insertions and deletions (so a "substitution" costs 2),
while Levenshtein gives substitutions a unit cost.

- **Time**: `O(n · m)` Wagner-Fischer DP
- **Space**: `O(min(n, m))` with the two-rolling-row trick
- **Signatures**:
  - `distance(a, b) -> Int` — unit costs
  - `distance_weighted(a, b, cost_insert~, cost_delete~, cost_subst~) -> Int`

This package operates on `Array[Int]` so it works for any character
encoding; convert strings to int-arrays of code points before calling.

---

## The DP

Let `d[i][j]` be the Levenshtein distance between `a[0..i)` and
`b[0..j)`:

```
d[0][0]   = 0
d[i][0]   = i                                  (delete all of a)
d[0][j]   = j                                  (insert all of b)
d[i][j]   = d[i-1][j-1]                        if a[i-1] == b[j-1]
            min( d[i-1][j]   + 1,              (delete a[i-1])
                 d[i][j-1]   + 1,              (insert b[j-1])
                 d[i-1][j-1] + 1 )             (substitute)  otherwise
```

The result is `d[n][m]`.

This is the classical **Wagner-Fischer** algorithm (1974). It is
remarkably simple — three nested branches — and is the canonical
example of bottom-up dynamic programming in algorithms textbooks.

---

## The invariant

> After computing row `i` of the DP table, `d[i][j]` is the
> Levenshtein distance between `a[0..i)` and `b[0..j)` for every
> `j ∈ [0, m]`.

The transitions correspond exactly to the three edit operations
above; correctness follows by induction.

---

## Two-row rolling

Naïve implementation uses `O(n · m)` memory. Notice the recurrence
references only the previous row `d[i-1][*]` and the current row
`d[i][*]`. So we maintain just two arrays of length `m + 1`, swapping
them each iteration. The result fits in `O(min(n, m))` after the
optional swap-to-shorter-axis step (this package always uses `m + 1`,
relying on the caller to put the shorter sequence as `b`).

---

## Reference implementation

```
pub fn distance(a : Array[Int], b : Array[Int]) -> Int

pub fn distance_weighted(
  a : Array[Int],
  b : Array[Int],
  cost_insert~ : Int,
  cost_delete~ : Int,
  cost_subst~  : Int,
) -> Int
```

---

## Tests and examples

```mbt check
///|
test "levenshtein kitten -> sitting" {
  let kitten = [
    'k'.to_int(),
    'i'.to_int(),
    't'.to_int(),
    't'.to_int(),
    'e'.to_int(),
    'n'.to_int(),
  ]
  let sitting = [
    's'.to_int(),
    'i'.to_int(),
    't'.to_int(),
    't'.to_int(),
    'i'.to_int(),
    'n'.to_int(),
    'g'.to_int(),
  ]
  debug_inspect(@levenshtein_distance.distance(kitten, sitting), content="3")
}
```

```mbt check
///|
test "levenshtein no overlap" {
  debug_inspect(
    @levenshtein_distance.distance([1, 2, 3], [4, 5, 6]),
    content="3",
  )
}
```

```mbt check
///|
test "levenshtein weighted substitute" {
  // Expensive subst forces delete+insert path.
  let kit = ['k'.to_int(), 'i'.to_int(), 't'.to_int()]
  let cat = ['c'.to_int(), 'a'.to_int(), 't'.to_int()]
  // Unit costs: 2 substitutions.
  debug_inspect(@levenshtein_distance.distance(kit, cat), content="2")
  // Make subst cost 5: 2 deletes + 2 inserts = 4 < 10.
  debug_inspect(
    @levenshtein_distance.distance_weighted(
      kit,
      cat,
      cost_insert=1,
      cost_delete=1,
      cost_subst=5,
    ),
    content="4",
  )
}
```

---

## Complexity

| Variant | Time | Space |
|---|---|---|
| Naïve DP (full table) | `O(n m)` | `O(n m)` |
| **Two-row rolling (this)** | `O(n m)` | `O(min(n, m))` |
| Bit-parallel (Hyyrö 2004) | `O(n · ⌈m/64⌉)` | `O(⌈m/64⌉)` |
| Ukkonen banded | `O(D · min(n, m))` | `O(min(n, m))` |

Bit-parallel and Ukkonen variants are faster when `D` (the actual
distance) is small or when `min(n, m)` fits in a word — but they're
tricky to implement correctly. The rolling-row version is the gold
standard.

---

## Triangle inequality

Levenshtein distance is a true metric:

- `L(a, a) = 0`
- `L(a, b) ≥ 0`
- `L(a, b) = L(b, a)` (insertions and deletions are dual)
- `L(a, c) ≤ L(a, b) + L(b, c)`

This lets you use Levenshtein as the metric for BK-trees and other
similarity-search data structures.

---

## Pitfalls

- **Substitution cost asymmetry**. Different substitution costs (e.g.
  `'a' → 'e'` cheap, `'a' → 'z'` expensive — common in
  phonetic-matching applications) require a 26×26 cost table. This
  package handles unit costs only.
- **Damerau-Levenshtein** adds transpositions (`ab ↔ ba`) as a 4th
  edit type at unit cost. The DP is similar but has one extra term.
- **Bit-parallel speedup**. For short patterns (`m ≤ 64`) the
  Hyyrö-Myers bit-parallel algorithm runs ~64× faster but requires
  bitwise tricks beyond the scope of this package.
- **String vs. character array**. UTF-8 strings need code-point
  decoding first. Comparing raw bytes can mislead on multi-byte chars.

---

## Use cases

```
Spellcheck and "did you mean"        L distance + corpus lookup
Fuzzy search                          L within budget D
Bioinformatics alignment              variations of L with affine gaps
Plagiarism detection                  document-level diff metric
Phonetic matching (Soundex etc.)     pre-encode, then L distance
DNA sequence comparison              Levenshtein with custom subst matrix
```

---

## Related concepts

```
Levenshtein (this)               Wagner-Fischer DP, unit-cost edit distance
Damerau-Levenshtein              + transpositions
Myers diff                       insertions/deletions only, O((n+m) D)
Needleman-Wunsch                 global alignment with affine gap costs
Smith-Waterman                   local alignment, bioinformatics standard
Hamming distance                 substitutions only, |a| == |b|
Jaro / Jaro-Winkler              record-linkage similarity metric
BK-tree                          uses L for fast O(log n) lookup
```
