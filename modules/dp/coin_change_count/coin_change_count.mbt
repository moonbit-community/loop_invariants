// ============================================================================
// COIN CHANGE  -  count and enumerate ways to make a target
// ============================================================================
//
// PROBLEM
//
// Given an array `coins` of distinct positive denominations and a
// non-negative target `amount`, compute:
//
//   1. `count_unordered(coins, amount)` -- number of multisets of coin
//      values that sum to `amount`. Unlimited supply of each coin.
//   2. `count_ordered(coins, amount)`   -- number of *sequences*
//      (compositions) of coin values that sum to `amount`. Order
//      matters.
//
// THE TWO DPs ARE DIFFERENT
//
// **Unordered** (also called the "coin change ways" problem):
//
//   dp[j] = number of multisets summing to j using coins[0..i]
//   for each coin c:
//     for j from c to amount:
//       dp[j] += dp[j - c]
//
// The **outer loop over coins** prevents double-counting permutations.
//
// **Ordered** (also called "staircase" or "compositions"):
//
//   dp[j] = number of sequences summing to j
//   for j from 1 to amount:
//     for each coin c <= j:
//       dp[j] += dp[j - c]
//
// The outer loop is over the target; each coin can be the *last* coin
// of an arbitrary previous sequence.
//
// COMPLEXITY
//
//   Time : O(n * amount)
//   Space: O(amount)
//
// THE INVARIANT (unordered)
//
//   "After processing coin coins[k], dp[j] equals the number of
//    multisets of denominations in coins[0..k] that sum to j."

///|
const MOD : Int64 = 1000000007L

///|
/// Number of **multisets** of coin denominations summing to `amount`.
/// `coins` should contain distinct positive values; behaviour with
/// zeros or negatives is undefined.
///
/// Result is taken modulo `1e9 + 7` to avoid overflow on large targets.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // {1, 2, 5} making 5: {5}, {2, 2, 1}, {2, 1, 1, 1}, {1, 1, 1, 1, 1} -> 4
///   @debug.assert_eq(@coin_change_count.count_unordered([1, 2, 5], 5), 4L)
/// }
/// ```
pub fn count_unordered(coins : Array[Int], amount : Int) -> Int64 {
  if amount < 0 {
    return 0L
  }
  let dp = Array::make(amount + 1, 0L)
  dp[0] = 1L
  for c in coins {
    if c <= 0 {
      continue
    }
    for j in c..<=amount {
      dp[j] = (dp[j] + dp[j - c]) % MOD
    }
  }
  dp[amount]
}

///|
/// Number of **ordered** sequences of coin denominations summing to
/// `amount`. Order matters.
///
/// Result is taken modulo `1e9 + 7`.
pub fn count_ordered(coins : Array[Int], amount : Int) -> Int64 {
  if amount < 0 {
    return 0L
  }
  let dp = Array::make(amount + 1, 0L)
  dp[0] = 1L
  for j in 1..<=amount {
    for c in coins {
      if c > 0 && c <= j {
        dp[j] = (dp[j] + dp[j - c]) % MOD
      }
    }
  }
  dp[amount]
}

///|
/// Minimum number of coins required to make `amount`, or `-1` when
/// impossible. Returns `0` for `amount == 0`.
pub fn min_coins(coins : Array[Int], amount : Int) -> Int {
  if amount < 0 {
    return -1
  }
  let inf = amount + 1
  let dp = Array::make(amount + 1, inf)
  dp[0] = 0
  for j in 1..<=amount {
    for c in coins {
      if c > 0 && c <= j && dp[j - c] + 1 < dp[j] {
        dp[j] = dp[j - c] + 1
      }
    }
  }
  if dp[amount] == inf {
    -1
  } else {
    dp[amount]
  }
}

///|
test "unordered classic" {
  @debug.assert_eq(count_unordered([1, 2, 5], 5), 4L)
  @debug.assert_eq(count_unordered([1, 2, 5], 11), 11L)
}

///|
test "unordered zero amount one way" {
  @debug.assert_eq(count_unordered([1, 2, 5], 0), 1L)
}

///|
test "unordered no coins" {
  @debug.assert_eq(count_unordered([], 5), 0L)
  @debug.assert_eq(count_unordered([], 0), 1L)
}

///|
test "unordered single coin" {
  // Only 2s: amount 6 -> 1 way (3 twos); amount 5 -> 0 ways.
  @debug.assert_eq(count_unordered([2], 6), 1L)
  @debug.assert_eq(count_unordered([2], 5), 0L)
}

///|
test "ordered different from unordered" {
  // {1, 2} making 3: ordered = 3 (1+1+1, 1+2, 2+1); unordered = 2 ({1,1,1}, {1,2}).
  @debug.assert_eq(count_ordered([1, 2], 3), 3L)
  @debug.assert_eq(count_unordered([1, 2], 3), 2L)
}

///|
test "min_coins basic" {
  @debug.assert_eq(min_coins([1, 2, 5], 11), 3) // 5 + 5 + 1
  @debug.assert_eq(min_coins([2], 3), -1) // impossible
  @debug.assert_eq(min_coins([1], 0), 0)
}

///|
test "min_coins canonical pennies" {
  @debug.assert_eq(min_coins([1, 5, 10, 25], 67), 6) // 25+25+10+5+1+1
}

///|
test "unordered larger amount" {
  // Number of ways to break a dollar (100) using US coins {1, 5, 10, 25, 50}
  // is the classical 293.
  @debug.assert_eq(count_unordered([1, 5, 10, 25, 50], 100), 292L)
  // (The 293 figure includes the "one fifty-cent piece + 50 pennies"
  // and so on; precise value depends on coin set.) For [1,5,10,25,50]
  // the answer is 292.
}
