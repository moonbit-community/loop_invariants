# Challenge: Coin Change (Min Coins)

This challenge solves the classic **minimum coin change** problem using
unbounded knapsack DP.

You can use each coin any number of times, and you want the **fewest coins**
that sum to the target.

## Problem statement

Given a list of coin values and a target amount, return:

- `Some(min_count)` if the target can be formed
- `None` if it is impossible

## DP state

Let:

```
dp[x] = minimum number of coins needed to make sum x
```

Initialization:

- `dp[0] = 0`
- everything else is INF (unreachable)

Transition (unbounded):

```
for each coin c:
  for x from c to amount:
    dp[x] = min(dp[x], dp[x - c] + 1)
```

Because we iterate `x` increasing, we allow reuse of the same coin.

## Diagram: example DP table

Coins = [1, 3, 4], target = 6

After coin 1:

```
index: 0 1 2 3 4 5 6
 dp  : 0 1 2 3 4 5 6
```

After coin 3:

```
index: 0 1 2 3 4 5 6
 dp  : 0 1 2 1 2 3 2
```

After coin 4:

```
index: 0 1 2 3 4 5 6
 dp  : 0 1 2 1 1 2 2
```

Answer for 6 is 2 (3+3 or 4+1+1).

## Examples

### Example 1: basic case

```mbt check
///|
test "coin change example" {
  let coins : Array[Int] = [1, 3, 4]
  let ans = @challenge_coin_change_min.min_coins(coins[:], 6)
  inspect(ans, content="Some(2)")
}
```

### Example 2: larger target

```mbt check
///|
test "coin change larger" {
  let coins : Array[Int] = [1, 5, 7]
  let ans = @challenge_coin_change_min.min_coins(coins[:], 11)
  inspect(ans, content="Some(3)") // 5 + 5 + 1
}
```

### Example 3: unreachable

```mbt check
///|
test "coin change unreachable" {
  let coins : Array[Int] = [2, 5]
  let ans = @challenge_coin_change_min.min_coins(coins[:], 3)
  inspect(ans, content="None")
}
```

### Example 4: non-trivial combination

```mbt check
///|
test "coin change nontrivial" {
  let coins : Array[Int] = [2, 3, 6]
  let ans = @challenge_coin_change_min.min_coins(coins[:], 13)
  inspect(ans, content="Some(4)") // 6 + 3 + 2 + 2
}
```

## Complexity

Let `A = amount` and `C = number of coins`:

- Time: O(A * C)
- Space: O(A)

## Practical notes and pitfalls

- Coins must be positive; non-positive values are ignored.
- The order of loops matters: coin outer, amount inner (increasing) gives
  unbounded usage.
- If you want the actual coin choices, store a predecessor array.

## When to use it

Use this DP when the target amount is moderate and you want exact minimum
coin counts.
