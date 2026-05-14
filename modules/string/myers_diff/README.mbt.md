# Myers Diff

## Overview

Myers' 1986 paper *An O(ND) Difference Algorithm and Its Variations*
gives the algorithm behind `git diff`, GNU `diff`, `colordiff`, and
essentially every modern line-diff tool. It computes the **shortest
edit script** (SES) — the minimum number of insertions and deletions
— that transforms one sequence into another. SES length equals
`n + m - 2 · LCS(a, b)`.

- **Time**: `O((n + m) · D)` where `D` is the SES length
- **Space**: `O(n + m)` for the dual-line `V` array
- **Signatures**:
  - `shortest_edit_distance(a, b) -> Int`
  - `diff(a, b) -> Array[Edit]`

For nearly-identical inputs (`D ≪ n + m`) Myers is **near-linear**.
For wildly different inputs (`D` near `n + m`) it degrades to `O((n
+ m)²)` — still far better than the naïve DP's `O(n m)` constant
factor, because Myers visits only the *frontier* of the edit graph.

---

## The edit graph

Picture an `(n+1) × (m+1)` grid where each cell `(i, j)` represents
*"`i` chars of `a` consumed, `j` chars of `b` consumed"*. There are
three move types:

| Move | Cost | Meaning |
|---|---|---|
| **down** `(i, j) → (i, j+1)` | 1 | insert `b[j]` |
| **right** `(i, j) → (i+1, j)` | 1 | delete `a[i]` |
| **diagonal** `(i, j) → (i+1, j+1)` | 0 | `a[i] == b[j]`, free |

We start at `(0, 0)`, want to reach `(n, m)`. The shortest such path,
counting only non-diagonal moves, has length `D` = SES.

---

## Myers' trick

Run BFS in (D, k) space where `k = i - j` is the diagonal. The
data structure is a 1D array `V[k]` indexed by diagonal, storing

> "the furthest `x = i` reachable on diagonal `k` at edit-distance `D`"

Each BFS step extends `V` from `(D-1)` to `D` by considering, for each
`k`, whether to come from `V[k-1]` (one down) or `V[k+1]` (one right),
plus all the free diagonal moves at the new cell.

---

## The invariant

> After the BFS step for distance `d`, `V[k]` is the **maximum `i`
> reachable at edit-distance exactly `d` on diagonal `k`**.

The first `d` at which `V[n - m] ≥ n` is `D`.

---

## Reference implementation

```
pub enum Edit { Equal(Int), Insert(Int), Delete(Int) }

pub fn shortest_edit_distance(a : Array[Int], b : Array[Int]) -> Int
pub fn diff(a : Array[Int], b : Array[Int]) -> Array[Edit]
```

This package works on `Array[Int]` rather than strings; convert
strings to int-arrays of code points before calling. Returned
edit scripts can be reapplied:

```
result = []
for op in diff(a, b):
  match op:
    Equal(x):   result.append(x)
    Insert(x):  result.append(x)
    Delete(_):  pass
assert result == b
```

---

## Tests and examples

```mbt check
///|
test "myers identical" {
  debug_inspect(
    @myers_diff.shortest_edit_distance([1, 2, 3], [1, 2, 3]),
    content="0",
  )
}
```

```mbt check
///|
test "myers prefix change" {
  // a = [1, 2, 3, 4, 5], b = [1, 2, 3, 8, 9]
  // 3 in common, 2 deletes, 2 inserts -> D = 4
  debug_inspect(
    @myers_diff.shortest_edit_distance([1, 2, 3, 4, 5], [1, 2, 3, 8, 9]),
    content="4",
  )
}
```

```mbt check
///|
test "myers all different" {
  // No commonality: D = n + m
  debug_inspect(
    @myers_diff.shortest_edit_distance([1, 2, 3], [9, 8, 7]),
    content="6",
  )
}
```

```mbt check
///|
test "myers diff reconstructs target" {
  let ops = @myers_diff.diff([1, 2, 3, 4, 5], [2, 4, 5, 6])
  let result : Array[Int] = []
  for op in ops {
    match op {
      Equal(v) => result.push(v)
      Insert(v) => result.push(v)
      Delete(_) => ()
    }
  }
  debug_inspect(result, content="[2, 4, 5, 6]")
}
```

---

## Complexity

| Case | Time |
|---|---|
| Best (identical) | `O(n + m)` — Myers' frontier hits the goal in 1 BFS step |
| Typical (real-world `git diff`) | `O((n + m) · D)` with `D` small |
| Worst (all different) | `O((n + m)²)` |

The original Myers paper shows that linear refinement (split-and-merge
on the midpoint) reduces space to `O(n + m)` permanently and time to
`O((n + m) · D)` with smaller constants. This package uses the
simpler "snapshot every V" reconstruction, which is `O((n + m) · D)`
in *both* time and space.

---

## Pitfalls

- **`O(D²)` memory**. The simple reconstruction snapshots `V` at each
  distance; total `O((n + m) · D)` memory. Use Myers' linear-space
  variant for very large diffs.
- **Tie-breaking in path reconstruction**. The condition
  `V[k-1] < V[k+1]` decides whether we came from a "down" or a "right".
  Always-down (or always-right) produces *different but equally short*
  diffs — both are correct SES. Some diff tools post-process to
  produce the "prettiest" diff (e.g. align edits to line boundaries).
- **Diagonal moves are free, but `a[x] == b[y]` is a strict equality**.
  For text diff with `whitespace == "ignored"`, normalise the inputs
  first.

---

## Related concepts

```
Myers diff (this)           classical O((n+m) D) edit-script algorithm
Patience diff               Bram Cohen's heuristic; longer LCS but slow worst case
Histogram diff              Git's default since 2.34; combination of patience and Myers
Levenshtein distance        substitution allowed; O(nm) DP
Hunt-McIlroy                older LCS algorithm via equivalence classes
Wagner-Fischer              the classical edit-distance DP
```
