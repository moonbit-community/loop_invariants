# Challenge: Coin Change (Min Coins)

Unbounded knapsack DP for minimum coin count.

## Core Idea

Let `dp[x]` be the minimum coins needed to make sum `x`.

Transition:
```
dp[x] = min(dp[x], dp[x - coin] + 1)
```

Initialize `dp[0] = 0`, others to infinity. If `dp[target]` is still infinity,
the sum is unreachable.

## Example

```mbt check
///|
test "coin change example" {
  let coins : Array[Int] = [1, 3, 4]
  let ans = @challenge_coin_change_min.min_coins(coins[:], 6)
  inspect(ans, content="Some(2)")
}
```

## Another Example

```mbt check
///|
test "coin change unreachable" {
  let coins : Array[Int] = [2, 5]
  let ans = @challenge_coin_change_min.min_coins(coins[:], 3)
  inspect(ans, content="None")
}
```

## Notes

- Coins can be used multiple times.
- Time complexity is O(target * number_of_coins).
