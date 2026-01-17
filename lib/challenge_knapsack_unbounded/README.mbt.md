# Challenge: Unbounded Knapsack

Unbounded (complete) knapsack lets you take **any item multiple times** to
maximize total value under a weight capacity.

This is similar to 0/1 knapsack, but the loop order changes to allow reuse.

## Problem statement

Given:

- weights `w[i]`
- values `v[i]`
- capacity `W`

Find the maximum value achievable with total weight <= W, where each item can
be taken unlimited times.

## Core idea

Let:

```
dp[cap] = best value achievable with capacity cap
```

Because items can be reused, we iterate **capacity forward**:

```
for each item (w_i, v_i):
  for cap from w_i to W:
    dp[cap] = max(dp[cap], dp[cap - w_i] + v_i)
```

Forward iteration allows the same item to contribute multiple times in a single
pass.

## Diagram: why forward order matters

Capacity W = 6, item (w=2, v=3)

Forward update (unbounded):

```
cap 2: dp[2] = dp[0] + 3 = 3
cap 4: dp[4] = dp[2] + 3 = 6  (uses the same item twice)
cap 6: dp[6] = dp[4] + 3 = 9  (three copies)
```

If we iterated backward, we would only allow one copy (0/1 knapsack behavior).

## Examples

### Example 1: basic case

```mbt check
///|
test "knapsack unbounded basic" {
  let weights : Array[Int] = [2, 3]
  let values : Array[Int] = [4, 5]
  let best = @challenge_knapsack_unbounded.knapsack_unbounded(
    weights[:],
    values[:],
    7,
  )
  inspect(best, content="13") // 3 + 2 + 2 (5 + 4 + 4)
}
```

### Example 2: single item repeated

```mbt check
///|
test "knapsack unbounded single item" {
  let weights : Array[Int] = [3]
  let values : Array[Int] = [4]
  let best = @challenge_knapsack_unbounded.knapsack_unbounded(
    weights[:],
    values[:],
    10,
  )
  inspect(best, content="12") // 3 + 3 + 3
}
```

### Example 3: prefer smaller weight with better ratio

```mbt check
///|
test "knapsack unbounded ratio" {
  let weights : Array[Int] = [4, 5]
  let values : Array[Int] = [7, 9]
  let best = @challenge_knapsack_unbounded.knapsack_unbounded(
    weights[:],
    values[:],
    20,
  )
  inspect(best, content="36") // 5 * 4
}
```

### Example 4: capacity too small

```mbt check
///|
test "knapsack unbounded too small" {
  let weights : Array[Int] = [5, 6]
  let values : Array[Int] = [10, 12]
  let best = @challenge_knapsack_unbounded.knapsack_unbounded(
    weights[:],
    values[:],
    4,
  )
  inspect(best, content="0")
}
```

### Example 5: mixed items

```mbt check
///|
test "knapsack unbounded mixed" {
  let weights : Array[Int] = [2, 5, 7]
  let values : Array[Int] = [3, 10, 12]
  let best = @challenge_knapsack_unbounded.knapsack_unbounded(
    weights[:],
    values[:],
    14,
  )
  inspect(best, content="26") // 7 + 7
}
```

## Complexity

Let `n = number of items`, `W = capacity`:

- Time: O(n * W)
- Space: O(W)

## Practical notes and pitfalls

- Forward iteration is essential for unbounded usage.
- If `W` is large (e.g., > 1e7), this DP may be too slow.
- If weights and values have different lengths, the shorter length is used.

## When to use it

Use unbounded knapsack when each item can be chosen multiple times and you need
an exact optimum under a moderate capacity.
