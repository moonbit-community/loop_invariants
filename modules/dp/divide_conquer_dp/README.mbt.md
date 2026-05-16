# Divide-and-Conquer DP Optimization

## Overview

Many DPs have the **partition / layered** shape

```
dp_t[j] = min_{i ≤ j}  ( dp_{t-1}[i] + cost(i, j) )
```

Naive evaluation is `O(T · N²)`. When `cost` satisfies the
**Knuth–Yao quadrangle inequality**

```
cost(a, c) + cost(b, d) ≤ cost(a, d) + cost(b, c)   for a ≤ b ≤ c ≤ d
```

the argmin function `opt[t][j]` is monotone non-decreasing in `j`.
Exploiting this monotonicity with divide-and-conquer cuts each layer to
`O(N log N)`, for a total of `O(T · N log N)`.

| Operation | Time | Space |
|---|---|---|
| `solve(base, T, cost)` | `O(T · N log N)` | `O(N)` |

---

## Algorithm

To compute one DP layer for `j ∈ [lo, hi]` knowing that `opt[j] ∈ [a, b]`:

1. Pick `mid = (lo + hi) / 2`.
2. Scan `i ∈ [a, min(mid, b)]` to find `opt[mid]` and `dp[t][mid]`.
3. Recurse on `[lo, mid − 1]` with `[a, opt[mid]]`.
4. Recurse on `[mid + 1, hi]` with `[opt[mid], b]`.

Because the bounds telescope, the total work across all recursive
calls at one recursion depth is `O(N)`; there are `O(log N)` depths.

---

## The invariant

> Throughout the recursion within one layer:
>
> - For every `j ∈ [lo, hi]`, the unknown `opt[j]` lies in `[a, b]`.
> - Each side of the recursion preserves this because of the
>   monotonicity `opt[j_1] ≤ opt[j_2]` whenever `j_1 ≤ j_2`.

Once `cur[mid]` is computed, we know `opt[mid] = arg`, so the left half
is bounded by `[a, arg]` and the right half by `[arg, b]`.

---

## API

```
pub fn solve(
  base : Array[Int64],
  layers : Int,
  cost : (Int, Int) -> Int64,
) -> Array[Int64]
```

- `base[j]` is `dp_0[j]`.
- `layers` is `T`. `layers = 0` returns `base` unchanged.
- `cost(i, j)` must be defined for `0 ≤ i ≤ j < n` and satisfy the
  quadrangle inequality. The function may use `INF = 2^62 - 1` as a
  sentinel for "infeasible".

Returns `dp_T` as a new array of length `n`.

---

## Tests and examples

```mbt check
///|
test "dc dp 1-layer cumulative sum" {
  // cost(i, j) = sum of squares of weights in [i, j).
  let w = [1L, 3L, 2L, 5L]
  let cost = fn(i : Int, j : Int) -> Int64 {
    let mut s = 0L
    let mut k = i
    while k < j {
      s = s + w[k] * w[k]
      k = k + 1
    }
    s
  }
  let base : Array[Int64] = [0L, 4611686018427387903L, 4611686018427387903L, 4611686018427387903L]
  let dp = @divide_conquer_dp.solve(base, 1, cost)
  // dp[j] should match cost(0, j) = sum of squares of w[0..j).
  // dp[3] = 1 + 9 + 4 = 14.
  debug_inspect(dp[3], content="14")
}
```

```mbt check
///|
test "dc dp zero layers is identity" {
  let base = [3L, 5L, 7L]
  let dp = @divide_conquer_dp.solve(base, 0, fn(_a, _b) { 0L })
  debug_inspect(dp, content="[3, 5, 7]")
}
```

---

## Use cases

When does the quadrangle inequality hold? A few common situations:

- **Convex inverse Ackermann / weighted distance** costs `cost(i, j)`
  derived from `f(j - i)` for **convex** `f`.
- **Sum-of-something** in a range, when partitioned by squared length
  or quadratic weight.
- **Optimal binary search tree** (Knuth's original setting).
- **Largest empty rectangle** in some monotone-cost partitions.

When it does not hold, use **SMAWK** (totally monotone matrices) or
**Knuth's O(N²) optimization** instead.

---

## Pitfalls

- **The hypothesis matters.** If `cost` does *not* satisfy the
  quadrangle inequality, the divide-and-conquer split is unsound and
  the answer may be wrong. Validate against an `O(N²)` brute force on
  small inputs.
- **Recursion depth.** `O(log N)` recursion depth is fine for any `N`
  fitting in memory, but tail-recursion is not guaranteed. For huge
  arrays, convert to an iterative driver.
- **Sentinel arithmetic.** Using `Int64.max_value` as INF can overflow
  on `prev[i] + cost(i, mid)`. This package uses `INF = 2^62 - 1` and
  guards with `prev[i] != INF`. Don't mix with `Int64.max_value` in
  the caller's `base`.

---

## Related concepts

```
Knuth's O(N²) optimization     when opt is doubly monotone
SMAWK algorithm                O(N) for totally monotone matrices
Aliens trick (Lagrangian)      another linear-loss / convex DP technique
Convex hull trick              when the recurrence is min over linear functions
```
