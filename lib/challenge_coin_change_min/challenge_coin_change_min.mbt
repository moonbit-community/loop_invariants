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
  let n = coins.length()
  for i = 0; i < n; i = i + 1 {
    let c = coins[i]
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
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Coin DP):
      #|After processing coins[0..i), dp[a] is minimal coins for total a.
      #|MAINTENANCE:
      #|Relax using coin coins[i].
      #|TERMINATION:
      #|At i = n, dp contains optimal answers.
    ),
  }
  if dp[amount] == INF {
    None
  } else {
    Some(dp[amount])
  }
}
