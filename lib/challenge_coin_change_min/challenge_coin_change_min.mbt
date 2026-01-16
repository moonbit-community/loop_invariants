// ============================================================================
// Challenge: Coin Change (Minimum Coins)
// Unbounded knapsack DP
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Minimum number of coins to make amount, or None if impossible.
#warnings("+missing_invariant+missing_reasoning")
pub fn min_coins(coins : ArrayView[Int], amount : Int) -> Int? {
  if amount < 0 {
    return None
  }
  let dp = Array::make(amount + 1, INF)
  dp[0] = 0
  for c in coins {
    if c <= 0 {
      continue
    }
    for a = c; a <= amount; a = a + 1 {
      if dp[a - c] != INF {
        let cand = dp[a - c] + 1
        if cand < dp[a] {
          dp[a] = cand
        }
      }
    } where {
      invariant: a >= c && a <= amount + 1,
      reasoning: (
        #|INVARIANT (Coin relax):
        #|dp[x] for x in [c..a) reflects best using coins[0..i].
        #|MAINTENANCE:
        #|Try adding coin c to improve dp[a].
        #|TERMINATION:
        #|At a = amount+1, all totals are relaxed for coin c.
      ),
    }
  }
  if dp[amount] == INF {
    None
  } else {
    Some(dp[amount])
  }
}
