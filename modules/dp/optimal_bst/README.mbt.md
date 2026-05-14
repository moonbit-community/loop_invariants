# Optimal Binary Search Tree

## Overview

Given `n` sorted keys with access weights `w[1..n]`, build the **BST
that minimises expected search cost**:

```
cost(T)  =  Σ_k  w[k] · depth_T(k)
```

where the root is at depth 1. The optimisation is by Knuth (1971):
a classical `O(n²)` dynamic-programming algorithm that exploits the
*monotone-root property*.

This is one of the historical poster children for **algorithm
optimisation via problem-specific structure**. The naive DP is
`O(n³)`; Knuth's optimisation drops a factor of `n` by observing
that the optimal root of `[i..j]` lies between the optimal roots of
`[i..j-1]` and `[i+1..j]`.

- **Time**: `O(n²)`
- **Space**: `O(n²)`
- **Signatures**:
  - `min_cost(w) -> Double` — the minimum expected cost
  - `min_cost_with_tree(w) -> (Double, Array[Int])` — also returns parent indices

---

## The basic DP

Let

- `e[i][j]` = minimum expected cost of a BST built from keys `k_i ... k_j`
- `w[i][j]` = `w[i] + w[i+1] + ... + w[j]`

For any choice of root `k_r` with `i ≤ r ≤ j`:

```
e[i][j]  =  min_{r in [i, j]}  ( e[i][r-1] + e[r+1][j] + w[i][j] )
```

with base case `e[i][i-1] = 0` (empty subtree).

Why the `+ w[i][j]`? Picking `r` as root pushes every key in `[i, j]`
one level deeper, contributing `+1` per key, weighted: that's
`w[i][j]`.

---

## Knuth's optimisation

Let `root[i][j]` be the optimal `r` for `e[i][j]`. The non-obvious
fact (Knuth 1971) is:

```
root[i][j-1]  ≤  root[i][j]  ≤  root[i+1][j]
```

So the inner loop searches `r ∈ [root[i][j-1], root[i+1][j]]` instead
of `[i, j]`. The lengths of those intervals telescope to `O(n)` for
each diagonal of fixed `j - i`, and there are `n` diagonals, so total
work is `O(n²)`.

The same trick (the "quadrangle inequality") applies to several other
DPs — like *optimal matrix chain multiplication*, *optimal alphabetic
trees*, and parts of *speech-recognition decoding*.

---

## The invariant

> After processing all `(i, j)` with `j - i + 1 ≤ L`, `e[i'][j']` is
> the minimum expected cost of a BST on keys `k_{i'} ... k_{j'}` for
> all `(i', j')` with `j' - i' + 1 ≤ L`.

Each pass extends `L` by 1.

---

## Reference implementation

```
pub fn min_cost(w : Array[Double]) -> Double
pub fn min_cost_with_tree(w : Array[Double]) -> (Double, Array[Int])
```

`min_cost_with_tree` returns a `parent` array indexed from `1..n`
where `parent[k] = -1` denotes the root.

---

## Tests and examples

```mbt check
///|
test "obst three equal-weight" {
  // [1, 1, 1]: balanced tree, cost = 1 + 2 + 2 = 5.
  debug_inspect(@optimal_bst.min_cost([1.0, 1.0, 1.0]), content="5")
}
```

```mbt check
///|
test "obst skewed favours heavy root" {
  // [1, 1, 100]: optimal puts the 100-weight key as root.
  // Cost: 100 + (1 + 1) * 2 = 100 + 4 ... no wait.
  // Actually: root=3, left={1,2}, right=empty.
  // Cost: 100*1 + (cost of {1,2} BST + w[1..2] = 1+1 = 2)
  //     = 100 + 3 + 2 = ... we computed 105 = 100 + (1*2 + 1*3) = 105.
  debug_inspect(@optimal_bst.min_cost([1.0, 1.0, 100.0]), content="105")
}
```

```mbt check
///|
test "obst single key" {
  debug_inspect(@optimal_bst.min_cost([7.0]), content="7")
}
```

```mbt check
///|
test "obst empty" {
  debug_inspect(@optimal_bst.min_cost([]), content="0")
}
```

---

## Complexity

| Variant | Time | Space |
|---|---|---|
| Naive DP | `O(n³)` | `O(n²)` |
| **Knuth (this)** | `O(n²)` | `O(n²)` |
| Hu-Tucker (alphabetic merge) | `O(n log n)` | `O(n)` |

Hu-Tucker is asymptotically better but only handles the
**alphabetic-tree** problem (a slight variant) and is much trickier
to implement correctly.

---

## Use cases

- **Compiler symbol-table layout** — frequently accessed identifiers
  near the root.
- **Database indexing with skewed access patterns** — if you know your
  query distribution, OBST gives the cache-optimal binary tree.
- **Code-book design** — same Q-tree problem comes up in
  information theory under "weighted prefix codes."
- **Huffman codes** are *related but different*: Huffman is unweighted
  binary prefix coding (sibling-property tree); OBST is BST-shaped
  with weighted internal-node visits.

---

## Pitfalls

- **Indexing**. This package uses 1-based internal indexing (matching
  textbook presentations), but the input array `w` is 0-based, so the
  weight of internal key `k_i` is `w[i - 1]`. The returned `parent`
  array is 1-based.
- **Floating-point comparisons**. The `c < best` comparison can be
  sensitive to tie-breaking when many roots give exactly equal cost.
  Cross-check against the naive DP to confirm.
- **Probabilities vs. weights**. The DP doesn't care if `w` sums to 1;
  the result is in the same units as the input.
- **Dummy nodes**. The classical CLRS presentation adds "dummy keys"
  for the gaps between real keys (failed searches). This package
  handles only the "successful search" case; if you need dummies,
  pad your weights with the dummies and adjust indices accordingly.

---

## Related concepts

```
Optimal BST (this)            Knuth 1971, O(n²) with quadrangle inequality
Huffman coding                weighted prefix code, sibling tree, O(n log n)
Hu-Tucker                     alphabetic binary tree, O(n log n)
Garsia-Wachs                  alternative O(n log n) for alphabetic trees
SOS / monotone-matrix DP      Yao's speedup that subsumes Knuth's optimisation
```
