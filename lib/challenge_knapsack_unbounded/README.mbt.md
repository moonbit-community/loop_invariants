# Challenge: Unbounded Knapsack

Choose items multiple times to maximize value within a capacity limit.

## What you learn

- DP over capacity with unlimited item usage
- Forward iteration to allow reuse in the same iteration

## Core Idea

Let dp[cap] be the best value for capacity cap. Iterate capacity forward so
each item can be used multiple times within the same pass.

## Pseudocode sketch

```mbt nocheck
for cap in 0..W:
  for item in items:
    dp[cap] = max(dp[cap], dp[cap - w] + value)
```

## Example

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
  inspect(best, content="13")
}
```

## Another Example

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
  inspect(best, content="12")
}
```

## Notes

- Time complexity: O(n * W)
- Space complexity: O(W)
