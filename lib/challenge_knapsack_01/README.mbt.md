# Challenge: 0/1 Knapsack

Choose each item at most once to maximize value within a capacity limit.

## What you learn

- DP over items and capacity
- Transition by taking or skipping an item
- Iteration order to avoid reuse

## Core Idea

Use a 1D dp array where dp[cap] is the best value for capacity cap. Iterate
capacity in decreasing order so each item is used at most once.

## Pseudocode sketch

```mbt nocheck
for item in items:
  for cap from W down to weight[item]:
    dp[cap] = max(dp[cap], dp[cap - w] + value)
```

## Example

```mbt check
///|
test "knapsack 01 basic" {
  let weights : Array[Int] = [2, 3, 4]
  let values : Array[Int] = [4, 5, 6]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 5)
  inspect(best, content="9")
}
```

## Another Example

```mbt check
///|
test "knapsack 01 choose combo" {
  let weights : Array[Int] = [1, 3, 4]
  let values : Array[Int] = [15, 20, 30]
  let best = @challenge_knapsack_01.knapsack_01(weights[:], values[:], 4)
  inspect(best, content="35")
}
```

## Notes

- Time complexity: O(n * W)
- Space complexity: O(W)
