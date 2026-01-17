# Challenge: 0/1 Knapsack

0/1 Knapsack asks for the **maximum total value** you can pack without
exceeding a weight limit. Each item can be used **at most once**.

## Problem statement

Given:

- weights `w[i]`
- values `v[i]`
- capacity `W`

Find the maximum sum of values of a subset of items with total weight <= W.

## Core idea

Use a 1D DP array where:

```
dp[cap] = best value using items processed so far with capacity cap
```

For each item `(w_i, v_i)`, update `dp` **from high to low** so the item is
not reused in the same iteration.

Transition:

```
for cap from W down to w_i:
  dp[cap] = max(dp[cap], dp[cap - w_i] + v_i)
```

## Why descending order matters

If you loop upward, you would allow the same item to be used multiple times
because dp[cap - w_i] may have been updated by the current item already.

Descending order guarantees each item is used at most once.

## Diagram: DP update for one item

Capacity W = 5, item (w=2, v=4)

```
Before: dp = [0, 0, 0, 0, 0, 0]
Update (cap 5..2):
 cap 5: dp[5] = max(0, dp[3] + 4) = 4
 cap 4: dp[4] = max(0, dp[2] + 4) = 4
 cap 3: dp[3] = max(0, dp[1] + 4) = 4
 cap 2: dp[2] = max(0, dp[0] + 4) = 4
After:  dp = [0, 0, 4, 4, 4, 4]
```

## Examples

### Example 1: basic case

```mbt check
///|
test "knapsack 01 basic" {
  let weights : Array[Int] = [2, 3, 4]
  let values : Array[Int] = [4, 5, 6]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 5)
  inspect(best, content="9") // items 2 + 3
}
```

### Example 2: choose a better combination

```mbt check
///|
test "knapsack 01 choose combo" {
  let weights : Array[Int] = [1, 3, 4]
  let values : Array[Int] = [15, 20, 30]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 4)
  inspect(best, content="35") // 1 + 3
}
```

### Example 3: capacity too small

```mbt check
///|
test "knapsack 01 small capacity" {
  let weights : Array[Int] = [5, 6]
  let values : Array[Int] = [10, 12]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 4)
  inspect(best, content="0")
}
```

### Example 4: larger set

```mbt check
///|
test "knapsack 01 larger" {
  let weights : Array[Int] = [2, 2, 6, 5, 4]
  let values : Array[Int] = [6, 3, 5, 4, 6]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 10)
  inspect(best, content="15")
}
```

One optimal choice is weights 2, 2, and 4 (total weight 8) with value 15.

### Example 5: mismatched lengths

If weights and values differ in length, the shorter length is used.

```mbt check
///|
test "knapsack 01 mismatched lengths" {
  let weights : Array[Int] = [2, 3]
  let values : Array[Int] = [4, 5, 100]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 3)
  inspect(best, content="5")
}
```

## Complexity

Let `n = number of items`, `W = capacity`:

- Time: O(n * W)
- Space: O(W)

## Practical notes and pitfalls

- Descending loop order is essential for 0/1 knapsack.
- If you need the actual chosen items, store predecessor info in another array.
- For large W (e.g., 1e7), this DP is too slow; consider alternative methods.

## When to use it

Use 0/1 knapsack when each item can be taken at most once and you need the
exact maximum value.
