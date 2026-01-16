// ============================================================================
// Challenge: Unbounded Knapsack (Complete Knapsack)
// ============================================================================

///|
/// Maximum value with unlimited copies of each item.
#warnings("+missing_invariant+missing_reasoning")
pub fn knapsack_unbounded(
  weights : ArrayView[Int],
  values : ArrayView[Int],
  capacity : Int,
) -> Int {
  let n = if weights.length() < values.length() {
    weights.length()
  } else {
    values.length()
  }
  let dp : Array[Int] = Array::make(capacity + 1, 0)
  for i in 0..<n {
    let w_i = weights[i]
    let v_i = values[i]
    for w in w_i..=capacity {
      let cand = dp[w - w_i] + v_i
      if cand > dp[w] {
        dp[w] = cand
      }
    }
  }
  dp[capacity]
}

///|
test "knapsack_unbounded" {
  let weights : Array[Int] = [2, 3]
  let values : Array[Int] = [4, 5]
  assert_eq(knapsack_unbounded(weights[:], values[:], 7), 13)
  assert_eq(knapsack_unbounded(weights[:], values[:], 1), 0)
}
